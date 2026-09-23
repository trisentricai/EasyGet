from django.db import transaction
from django.db.models import Min, Q
from rest_framework import status
from rest_framework.pagination import PageNumberPagination
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.viewsets import ModelViewSet

from tenants.permissions import IsTenantObjectMember, IsTenantWriter
from tenants.services import resolve_tenant_for_create, user_tenant_ids

from .models import Product
from .serializers import (
    ProductDetailSerializer,
    ProductListSerializer,
    ProductWriteSerializer,
)


class ProductPagination(PageNumberPagination):
    """200+ item catalogs took ~3.5s per unpaginated request on Supabase."""

    page_size = 20
    page_size_query_param = "page_size"
    max_page_size = 100


class ProductViewSet(ModelViewSet):
    """Catalog API.

    Visibility (GET):
      - staff see everything;
      - tenant members additionally see their own catalog (incl. inactive);
      - everyone else only sees active products stocked by an active store —
        merchant catalogs are private until they are actually being sold.

    Writes (POST/PATCH/DELETE): staff or tenant members only. Created products
    are bound to the creator's tenant (staff may create platform products).
    """

    lookup_field = "slug"
    queryset = Product.objects.all()
    parser_classes = [JSONParser, FormParser, MultiPartParser]
    pagination_class = ProductPagination

    def get_permissions(self):
        if self.request.method in {"GET", "HEAD", "OPTIONS"}:
            return [IsAuthenticated()]
        if self.request.method == "POST":
            return [IsAuthenticated(), IsTenantWriter()]
        return [IsAuthenticated(), IsTenantObjectMember()]

    def get_serializer_class(self):
        if self.action == "retrieve":
            return ProductDetailSerializer
        if self.action == "list":
            return ProductListSerializer
        return ProductWriteSerializer

    def get_queryset(self):
        qs = (
            Product.objects.select_related("category")
            # Images feed `primary_image` via the prefetched cache; variants
            # are covered by the annotation, so prefetch only images.
            .prefetch_related("images")
            .annotate(min_variant_price=Min(
                "variants__price",
                filter=Q(variants__is_active=True) & Q(variants__price__isnull=False),
            ))
        )
        params = self.request.query_params

        category_slug = params.get("category")
        if category_slug:
            qs = qs.filter(category__slug=category_slug)

        if params.get("is_featured") == "true":
            qs = qs.filter(is_featured=True)

        min_price = params.get("min_price")
        if min_price:
            qs = qs.filter(min_variant_price__gte=min_price)

        max_price = params.get("max_price")
        if max_price:
            qs = qs.filter(min_variant_price__lte=max_price)

        user = self.request.user
        if user.is_staff:
            return qs
        tenant_ids = user_tenant_ids(user)
        if tenant_ids:
            return qs.filter(
                Q(tenant_id__in=tenant_ids)
                | Q(is_active=True, variants__stock_items__store__is_active=True)
            ).distinct()
        return qs.filter(
            is_active=True, variants__stock_items__store__is_active=True
        ).distinct()

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        tenant = resolve_tenant_for_create(request.user)
        if tenant is None and not request.user.is_staff:
            return Response(
                {
                    "detail": "Join or create a merchant tenant before listing products."
                },
                status=status.HTTP_403_FORBIDDEN,
            )
        with transaction.atomic():
            serializer.save(tenant=tenant)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    def update(self, request, *args, **kwargs):
        partial = kwargs.pop("partial", False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)
