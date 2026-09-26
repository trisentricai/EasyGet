from django.db import transaction
from django.db.models import (
    Avg,
    Count,
    ExpressionWrapper,
    F,
    FloatField,
    Min,
    OuterRef,
    Q,
    Subquery,
)
from rest_framework import generics, status
from rest_framework.pagination import PageNumberPagination
from rest_framework.parsers import FormParser, JSONParser, MultiPartParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.viewsets import ModelViewSet

from tenants.permissions import IsTenantObjectMember, IsTenantWriter
from tenants.services import resolve_tenant_for_create, user_tenant_ids

from .models import Product, ProductReview
from .serializers import (
    ProductDetailSerializer,
    ProductListSerializer,
    ProductWriteSerializer,
    ReviewCreateSerializer,
    ReviewSerializer,
)


def with_rating_stats(qs):
    """Subquery-based rating aggregate — immune to join-row duplication
    from the stock/store visibility joins (an Avg over a multi-join would
    be skewed by duplicated rows)."""
    stats = (
        ProductReview.objects.filter(product=OuterRef("pk"), is_approved=True)
        .values("product")
        .annotate(avg=Avg("rating"), n=Count("id"))
        .values("avg", "n")[:1]
    )
    return qs.annotate(
        review_rating_avg=Subquery(stats.values("avg")),
        review_rating_count=Subquery(stats.values("n")),
    )


class ProductPagination(PageNumberPagination):
    """200+ item catalogs took ~3.5s per unpaginated request on Supabase."""

    page_size = 20
    page_size_query_param = "page_size"
    max_page_size = 100


class ReviewPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = "page_size"
    max_page_size = 50


class ProductBrandListView(generics.ListAPIView):
    """GET /api/v1/products/brands/ — distinct non-empty brands (for filters)."""

    permission_classes = [IsAuthenticated]

    def list(self, request, *args, **kwargs):
        brands = (
            Product.objects.exclude(brand__exact="")
            .exclude(brand__isnull=True)
            .order_by("brand")
            .values_list("brand", flat=True)
            .distinct()
        )
        return Response([{"name": b} for b in brands if (b or "").strip()])


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
        qs = with_rating_stats(
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

        brand = (params.get("brand") or "").strip()
        if brand:
            qs = qs.filter(brand__iexact=brand)

        min_discount = params.get("min_discount")
        if min_discount:
            try:
                threshold = float(min_discount)
            except (TypeError, ValueError):
                threshold = 0
            # Guard first: NULL/zero MRP would divide by zero on Postgres.
            qs = qs.filter(mrp__gt=0, min_variant_price__isnull=False).annotate(
                discount_pct=ExpressionWrapper(
                    (F("mrp") - F("min_variant_price")) * 100.0 / F("mrp"),
                    output_field=FloatField(),
                )
            ).filter(discount_pct__gte=threshold)

        sort = params.get("sort")
        if sort == "price_asc":
            return qs.order_by(F("min_variant_price").asc(nulls_last=True), "-id")
        if sort == "price_desc":
            return qs.order_by(F("min_variant_price").desc(nulls_last=True), "-id")
        if sort == "newest":
            return qs.order_by("-created_at", "-id")

        user = self.request.user
        # Explicit stable ordering: required for correct pagination
        # (silences UnorderedObjectListWarning; id breaks updated_at ties).
        if user.is_staff:
            return qs.order_by("-updated_at", "-id")
        tenant_ids = user_tenant_ids(user)
        if tenant_ids:
            return qs.filter(
                Q(tenant_id__in=tenant_ids)
                | Q(is_active=True, variants__stock_items__store__is_active=True)
            ).distinct().order_by("-updated_at", "-id")
        return qs.filter(
            is_active=True, variants__stock_items__store__is_active=True
        ).distinct().order_by("-updated_at", "-id")

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


class ProductReviewListCreateView(generics.ListCreateAPIView):
    """GET/POST /api/v1/products/<slug>/reviews/ — Flipkart rules:
    approved reviews only, one per shopper per product, verified-purchase
    badge derived from delivered orders server-side."""

    permission_classes = [IsAuthenticated]
    pagination_class = ReviewPagination

    def get_serializer_class(self):
        if self.request.method == "POST":
            return ReviewCreateSerializer
        return ReviewSerializer

    def _get_product(self):
        return generics.get_object_or_404(
            Product.objects.only("id", "slug", "is_active"), slug=self.kwargs["slug"]
        )

    def get_queryset(self):
        product = self._get_product()
        return (
            ProductReview.objects.filter(product=product, is_approved=True)
            .select_related("user")
            .order_by("-created_at", "-id")
        )

    def create(self, request, *args, **kwargs):
        product = self._get_product()
        if not product.is_active and not request.user.is_staff:
            return Response(
                {"detail": "Product not found."}, status=status.HTTP_404_NOT_FOUND
            )

        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        if ProductReview.objects.filter(
            product=product, user=request.user
        ).exists():
            return Response(
                {"detail": "You have already reviewed this product. Edit your existing review instead."},
                status=status.HTTP_409_CONFLICT,
            )

        review = serializer.save(
            product=product,
            user=request.user,
            is_verified_purchase=self._is_verified_purchase(request.user, product),
        )
        return Response(
            ReviewSerializer(review).data, status=status.HTTP_201_CREATED
        )

    def _is_verified_purchase(self, user, product) -> bool:
        from orders.models import Order

        return Order.objects.filter(
            user=user,
            status=Order.Status.DELIVERED,
            items__variant__product=product,
        ).exists()
