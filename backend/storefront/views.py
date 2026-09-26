from django.db.models import Max
from django.shortcuts import get_object_or_404
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from stores.models import Store

from .models import SectionItem, StoreSection, StorefrontTheme
from .permissions import IsStorefrontManager, can_manage_store
from .serializers import (
    SectionItemSerializer,
    SectionItemWriteSerializer,
    StoreSectionSerializer,
    StoreSectionWriteSerializer,
    StorefrontRenderSerializer,
    StorefrontThemeSerializer,
)


def _product_allowed_for_store(product, store, user):
    """Section items must not become a cross-tenant read channel: linked
    product name/slug/price are served publicly by the render endpoint."""
    if product is None or user.is_staff:
        return True
    if store.is_platform:
        # The platform storefront aggregates the whole marketplace: any
        # active product from any tenant may be featured there.
        return bool(product.is_active)
    if product.tenant_id is None:
        return True  # platform-level product
    return product.tenant_id == store.tenant_id


class PlatformStorefrontView(APIView):
    """GET /api/v1/storefront/platform/ — public render of the single
    platform-level (EASYGET) storefront row. Lookup by flag, not slug, so a
    rename of the platform row can never break the customer app."""

    permission_classes = [AllowAny]

    def get(self, request):
        store = get_object_or_404(Store, is_platform=True, is_active=True)
        return Response(StorefrontRenderSerializer(store).data)


class StorefrontRenderView(APIView):
    """GET /api/v1/storefront/{store_slug}/ — public. One request returns the
    theme + ordered sections (+ items) that customer-web/Flutter render."""

    permission_classes = [AllowAny]

    def get(self, request, store_slug):
        store = get_object_or_404(Store, slug=store_slug, is_active=True)
        return Response(StorefrontRenderSerializer(store).data)


class StorefrontThemeView(APIView):
    """GET public; PATCH by store managers (JSON or multipart for images)."""

    permission_classes = [IsAuthenticated, IsStorefrontManager]
    parser_classes = [JSONParser, MultiPartParser, FormParser]

    def get_store(self):
        return get_object_or_404(Store, slug=self.kwargs["store_slug"], is_active=True)

    def get_permissions(self):
        if self.request.method == "GET":
            return [AllowAny()]
        return super().get_permissions()

    def get(self, request, store_slug):
        store = self.get_store()
        theme = getattr(store, "storefront_theme", None)
        if theme is None:
            return Response(None)
        return Response(StorefrontThemeSerializer(theme).data)

    def patch(self, request, store_slug):
        store = self.get_store()
        theme, _ = StorefrontTheme.objects.get_or_create(store=store)
        serializer = StorefrontThemeSerializer(theme, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)


class SectionListCreateView(APIView):
    """GET — public sees active sections; managers also see inactive ones
    (that is what the dashboard edits). POST — manager; auto-appended last."""

    permission_classes = [IsAuthenticated, IsStorefrontManager]
    parser_classes = [JSONParser, MultiPartParser, FormParser]

    def get_store(self):
        return get_object_or_404(Store, slug=self.kwargs["store_slug"], is_active=True)

    def get_permissions(self):
        if self.request.method == "GET":
            return [AllowAny()]
        return super().get_permissions()

    def get(self, request, store_slug):
        store = self.get_store()
        qs = store.storefront_sections.all().prefetch_related(
            "items", "items__product", "items__category"
        )
        if not can_manage_store(request.user, store):
            qs = qs.filter(is_active=True)
        return Response(StoreSectionSerializer(qs, many=True).data)

    def post(self, request, store_slug):
        store = self.get_store()
        serializer = StoreSectionWriteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        max_pos = store.storefront_sections.aggregate(m=Max("position"))["m"]
        section = serializer.save(
            store=store, position=0 if max_pos is None else max_pos + 1
        )
        return Response(StoreSectionSerializer(section).data, status=201)


class SectionDetailView(APIView):
    """PATCH/DELETE a section — store managers only."""

    permission_classes = [IsAuthenticated, IsStorefrontManager]
    parser_classes = [JSONParser, MultiPartParser, FormParser]

    def get_object(self):
        section = get_object_or_404(StoreSection, pk=self.kwargs["pk"])
        self.check_object_permissions(self.request, section)
        return section

    def patch(self, request, pk):
        section = self.get_object()
        serializer = StoreSectionWriteSerializer(section, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(StoreSectionSerializer(section).data)

    def delete(self, request, pk):
        section = self.get_object()
        section.delete()
        return Response(status=204)


class SectionReorderView(APIView):
    """POST {"order": [section ids...]} — sets each section's position to its
    index in the list. This is the endpoint a drag-and-drop dashboard calls."""

    permission_classes = [IsAuthenticated, IsStorefrontManager]

    def get_store(self):
        return get_object_or_404(Store, slug=self.kwargs["store_slug"], is_active=True)

    def post(self, request, store_slug):
        store = self.get_store()
        order = request.data.get("order")
        if not isinstance(order, list):
            return Response({"detail": "Body must be {\"order\": [ids]}."}, status=400)
        sections = {s.id: s for s in store.storefront_sections.filter(id__in=order)}
        missing = [i for i in order if i not in sections]
        if missing:
            return Response({"detail": f"Unknown section ids: {missing}"}, status=400)
        for position, section_id in enumerate(order):
            sections[section_id].position = position
            sections[section_id].save(update_fields=["position", "updated_at"])
        return Response(
            StoreSectionSerializer(store.storefront_sections.all(), many=True).data
        )


class SectionItemsView(APIView):
    """GET — public items of a section; POST — manager, auto-appended last."""

    permission_classes = [IsAuthenticated, IsStorefrontManager]
    parser_classes = [JSONParser, MultiPartParser, FormParser]

    def get_object(self):
        section = get_object_or_404(StoreSection, pk=self.kwargs["pk"])
        self.check_object_permissions(self.request, section)
        return section

    def get_permissions(self):
        if self.request.method == "GET":
            return [AllowAny()]
        return super().get_permissions()

    def get(self, request, pk):
        section = get_object_or_404(StoreSection, pk=pk)
        # Unpublished sections are management state — only their store's
        # managers (or staff) may read them by ID.
        if not section.is_active:
            user = request.user
            if not (
                user
                and user.is_authenticated
                and (user.is_staff or can_manage_store(user, section.store))
            ):
                from django.http import Http404

                raise Http404("No StoreSection matches the given query.")
        return Response(SectionItemSerializer(section.items.all(), many=True).data)

    def post(self, request, pk):
        section = self.get_object()
        serializer = SectionItemWriteSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        product = serializer.validated_data.get("product")
        if product is not None and not _product_allowed_for_store(
            product, section.store, request.user
        ):
            return Response(
                {"product": "Product does not belong to this store's tenant."},
                status=400,
            )
        max_pos = section.items.aggregate(m=Max("position"))["m"]
        item = serializer.save(section=section, position=0 if max_pos is None else max_pos + 1)
        return Response(SectionItemSerializer(item).data, status=201)


class ItemDetailView(APIView):
    """PATCH/DELETE an item — store managers only."""

    permission_classes = [IsAuthenticated, IsStorefrontManager]
    parser_classes = [JSONParser, MultiPartParser, FormParser]

    def get_object(self):
        item = get_object_or_404(SectionItem, pk=self.kwargs["pk"])
        self.check_object_permissions(self.request, item)
        return item

    def patch(self, request, pk):
        item = self.get_object()
        serializer = SectionItemWriteSerializer(item, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        product = serializer.validated_data.get("product")
        if product is not None and not _product_allowed_for_store(
            product, item.section.store, request.user
        ):
            return Response(
                {"product": "Product does not belong to this store's tenant."},
                status=400,
            )
        serializer.save()
        return Response(SectionItemSerializer(item).data)

    def delete(self, request, pk):
        item = self.get_object()
        item.delete()
        return Response(status=204)


class ItemReorderView(APIView):
    """POST {"order": [item ids...]} — drag-and-drop within a section."""

    permission_classes = [IsAuthenticated, IsStorefrontManager]

    def get_object(self):
        section = get_object_or_404(StoreSection, pk=self.kwargs["pk"])
        self.check_object_permissions(self.request, section)
        return section

    def post(self, request, pk):
        section = self.get_object()
        order = request.data.get("order")
        if not isinstance(order, list):
            return Response({"detail": "Body must be {\"order\": [ids]}."}, status=400)
        items = {i.id: i for i in section.items.filter(id__in=order)}
        missing = [i for i in order if i not in items]
        if missing:
            return Response({"detail": f"Unknown item ids: {missing}"}, status=400)
        for position, item_id in enumerate(order):
            items[item_id].position = position
            items[item_id].save(update_fields=["position"])
        return Response(SectionItemSerializer(section.items.all(), many=True).data)
