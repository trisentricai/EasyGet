from decimal import Decimal
from django.db.models import Count, Sum
from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from users.permissions import IsAdminOnly, IsAdminOrStoreManager

from orders.models import Order
from products.models import Product, ProductReview, ProductVariant
from users.models import User
from .models import AdminAction, Banner, Coupon, ScheduledTask, SystemConfig
from .serializers import (
    AdminActionSerializer,
    BannerPublicSerializer,
    BannerSerializer,
    CouponSerializer,
    CouponValidateSerializer,
    ReviewAdminSerializer,
    ScheduledTaskSerializer,
    SystemConfigPublicSerializer,
    SystemConfigSerializer,
)


class SystemConfigViewSet(viewsets.ModelViewSet):
    """System configuration management."""

    queryset = SystemConfig.objects.all()
    permission_classes = [IsAdminOnly]

    def get_serializer_class(self):
        if self.action == "public":
            return SystemConfigPublicSerializer
        return SystemConfigSerializer

    @action(detail=False, methods=["get"], permission_classes=[IsAuthenticated])
    def public(self, request):
        """Public configs for frontend."""
        configs = SystemConfig.objects.filter(is_public=True)
        serializer = self.get_serializer(configs, many=True)
        return Response({c.key: c.typed_value for c in configs})


class AdminActionViewSet(viewsets.ReadOnlyModelViewSet):
    """Audit log for admin actions."""

    queryset = AdminAction.objects.select_related("admin_user")
    serializer_class = AdminActionSerializer
    permission_classes = [IsAdminOnly]
    filterset_fields = ["admin_user", "action", "target_model"]
    search_fields = ["admin_user__email", "target_model", "target_id"]
    ordering = ["-created_at"]


class BannerViewSet(viewsets.ModelViewSet):
    """Banner management."""

    queryset = Banner.objects.all()
    serializer_class = BannerSerializer
    permission_classes = [IsAdminOnly]

    def get_serializer_class(self):
        if self.action == "public":
            return BannerPublicSerializer
        return BannerSerializer

    @action(detail=False, methods=["get"], permission_classes=[IsAuthenticated])
    def public(self, request):
        now = timezone.now()
        banners = Banner.objects.filter(
            is_active=True,
            start_date__lte=timezone.now(),
        ).exclude(end_date__lt=timezone.now()).order_by("position")
        serializer = self.get_serializer(banners, many=True)
        return Response(serializer.data)


class CouponViewSet(viewsets.ModelViewSet):
    """Coupon management."""

    queryset = Coupon.objects.select_related("category", "product")
    serializer_class = CouponSerializer
    permission_classes = [IsAdminOnly]

    def get_serializer_class(self):
        if self.action == "validate":
            return CouponValidateSerializer
        return CouponSerializer

    @action(detail=False, methods=["post"], permission_classes=[IsAuthenticated])
    def validate(self, request):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        code = serializer.validated_data["code"]
        order_value = serializer.validated_data.get("order_value")

        coupon = Coupon.objects.get(code__iexact=code)
        is_valid, message = coupon.is_valid(request.user, order_value)
        if is_valid:
            discount = Decimal("0")
            if coupon.discount_type == Coupon.DiscountType.PERCENTAGE:
                discount = (order_value or Decimal("0")) * coupon.discount_value / 100
                if coupon.max_discount:
                    discount = min(discount, coupon.max_discount)
            elif coupon.discount_type == Coupon.DiscountType.FIXED:
                discount = coupon.discount_value

            return Response({
                "valid": True,
                "discount": discount,
                "discount_type": coupon.discount_type,
                "coupon": CouponSerializer(coupon).data,
            })
        return Response({"valid": False, "message": message}, status=400)

    @action(detail=True, methods=["post"])
    def increment_usage(self, request, pk=None):
        coupon = self.get_object()
        coupon.usage_count += 1
        coupon.save(update_fields=["usage_count"])
        return Response({"usage_count": coupon.usage_count})


class ScheduledTaskViewSet(viewsets.ModelViewSet):
    """Scheduled task management."""

    queryset = ScheduledTask.objects.select_related("created_by")
    serializer_class = ScheduledTaskSerializer
    permission_classes = [IsAdminOnly]

    @action(detail=True, methods=["post"])
    def run_now(self, request, pk=None):
        task = self.get_object()
        # Trigger Celery task
        from celery import current_app
        try:
            if task.task_type == ScheduledTask.TaskType.CELERY_TASK:
                result = current_app.send_task(task.target, kwargs=task.arguments)
                task.status = ScheduledTask.Status.RUNNING
                task.last_run = timezone.now()
                task.save()
                return Response({"task_id": result.id, "status": "started"})
            return Response({"error": "Only Celery tasks supported"}, status=400)
        except Exception as e:
            return Response({"error": str(e)}, status=500)


class AdminDashboardViewSet(viewsets.GenericViewSet):
    """Admin dashboard summary."""

    permission_classes = [IsAdminOnly]

    @action(detail=False, methods=["get"])
    def summary(self, request):
        from orders.models import Order
        from payments.models import Payment
        from products.models import Product
        from users.models import User

        today = timezone.now().date()
        week_ago = today - timezone.timedelta(days=7)

        # Users
        total_users = User.objects.count()
        new_users_today = User.objects.filter(date_joined__date=today).count()
        new_users_week = User.objects.filter(date_joined__date__gte=week_ago).count()

        # Orders
        total_orders = Order.objects.count()
        orders_today = Order.objects.filter(created_at__date=today).count()
        orders_week = Order.objects.filter(created_at__date__gte=week_ago).count()
        pending_orders = Order.objects.filter(status="PENDING").count()

        # Revenue
        from django.db.models import Sum
        revenue_today = Order.objects.filter(
            created_at__date=today, status__in=["DELIVERED", "OUT_FOR_DELIVERY"]
        ).aggregate(total=Sum("total"))["total"] or 0
        revenue_week = Order.objects.filter(
            created_at__date__gte=week_ago, status__in=["DELIVERED", "OUT_FOR_DELIVERY"]
        ).aggregate(total=Sum("total"))["total"] or 0

        # Products
        total_products = Product.objects.count()
        low_stock = 0
        try:
            from inventory.models import StockItem
            low_stock = StockItem.objects.filter(
                quantity__lte=models.F("low_stock_threshold"), quantity__gt=0
            ).count()
        except:
            pass

        return Response({
            "users": {
                "total": total_users,
                "today": new_users_today,
                "week": new_users_week,
            },
            "orders": {
                "total": total_orders,
                "today": orders_today,
                "week": orders_week,
                "pending": pending_orders,
            },
            "revenue": {
                "today": revenue_today,
                "week": revenue_week,
            },
            "products": {
                "total": total_products,
                "low_stock": low_stock,
            },
        })

class ProductReviewViewSet(viewsets.ModelViewSet):
    """Review moderation: list, approve/hide (PATCH), delete."""

    queryset = ProductReview.objects.select_related("product", "user").all()
    serializer_class = ReviewAdminSerializer
    permission_classes = [IsAdminOnly]
    http_method_names = ["get", "patch", "delete", "head", "options"]

    def get_queryset(self):
        qs = super().get_queryset()
        approved = self.request.query_params.get("approved")
        if approved in ("true", "false"):
            qs = qs.filter(is_approved=(approved == "true"))
        product = self.request.query_params.get("product")
        if product:
            qs = qs.filter(product__slug=product)
        return qs.order_by("-created_at", "-id")
