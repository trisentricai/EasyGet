from datetime import timedelta
from django.db.models import Avg, Count, Sum, F, Q
from django.db.models.functions import TruncDate
from django.utils import timezone
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from users.permissions import IsAdminOnly

from .models import (
    DailyMetrics,
    FunnelAnalysis,
    FunnelStep,
    ProductPerformance,
    RetentionCohort,
    RevenueByChannel,
    UserEvent,
)
from .serializers import (
    DashboardSummarySerializer,
    DailyMetricsSerializer,
    FunnelAnalysisSerializer,
    FunnelStepSerializer,
    ProductPerformanceSerializer,
    RetentionCohortSerializer,
    RevenueByChannelSerializer,
    UserEventCreateSerializer,
    UserEventSerializer,
)


class UserEventViewSet(viewsets.ModelViewSet):
    """Track user events (client-side)."""

    queryset = UserEvent.objects.all()
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        if self.action == "create":
            return UserEventCreateSerializer
        return UserEventSerializer

    def get_queryset(self):
        return UserEvent.objects.filter(user=self.request.user)

    @action(detail=False, methods=["post"])
    def batch(self, request):
        """Batch ingest events."""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response({"status": "ok"}, status=status.HTTP_201_CREATED)


class DailyMetricsViewSet(viewsets.ReadOnlyModelViewSet):
    """Daily business metrics."""

    queryset = DailyMetrics.objects.all()
    serializer_class = DailyMetricsSerializer
    permission_classes = [IsAdminOnly]

    @action(detail=False, methods=["get"])
    def latest(self, request):
        latest = DailyMetrics.objects.first()
        if not latest:
            return Response({"detail": "No metrics available"}, status=status.HTTP_404_NOT_FOUND)
        return Response(DailyMetricsSerializer(latest).data)

    @action(detail=False, methods=["get"])
    def range(self, request):
        days = int(request.query_params.get("days", 30))
        end = timezone.now().date()
        start = end - timedelta(days=days)
        metrics = DailyMetrics.objects.filter(date__gte=start, date__lte=end)
        return Response(DailyMetricsSerializer(metrics, many=True).data)


class FunnelViewSet(viewsets.ReadOnlyModelViewSet):
    """Funnel analysis."""

    queryset = FunnelStep.objects.all()
    serializer_class = FunnelStepSerializer
    permission_classes = [IsAdminOnly]

    @action(detail=False, methods=["get"])
    def analysis(self, request):
        funnel_name = request.query_params.get("funnel", "checkout")
        date = request.query_params.get("date")
        if date:
            from datetime import datetime
            date = datetime.strptime(date, "%Y-%m-%d").date()
        else:
            date = timezone.now().date()

        steps = FunnelAnalysis.objects.filter(funnel_name=funnel_name, date=date).order_by("step_order")
        if not steps.exists():
            return Response({"detail": "No data"}, status=status.HTTP_404_NOT_FOUND)

        serializer = FunnelAnalysisSerializer(steps, many=True)
        overall = steps.last().conversion_rate if steps else 0
        return Response({
            "funnel_name": funnel_name,
            "date": date,
            "steps": serializer.data,
            "overall_conversion": overall,
        })

    @action(detail=False, methods=["post"], permission_classes=[IsAdminOnly])
    def compute(self, request):
        """Compute funnel from raw events."""
        funnel_name = request.data.get("funnel", "checkout")
        date = request.data.get("date", timezone.now().date())
        steps_config = request.data.get("steps", [
            {"event_type": "CHECKOUT_START", "order": 1},
            {"event_type": "PAYMENT_ATTEMPT", "order": 2},
            {"event_type": "ORDER_COMPLETE", "order": 3},
        ])

        # Clear existing
        FunnelAnalysis.objects.filter(funnel_name=funnel_name, date=date).delete()

        # Build funnel
        user_sessions = {}
        for event in UserEvent.objects.filter(
            event_type__in=[s["event_type"] for s in steps_config],
            timestamp__date=date
        ).order_by("session_id", "timestamp"):
            if event.session_id not in user_sessions:
                user_sessions[event.session_id] = []
            user_sessions[event.session_id].append(event.event_type)

        results = []
        for i, step in enumerate(steps_config):
            event_type = step["event_type"]
            if i == 0:
                entered = len(user_sessions)
            else:
                entered = sum(1 for events in user_sessions.values() if event_type in events)
            completed = sum(1 for events in user_sessions.values() if event_type in events)

            FunnelAnalysis.objects.create(
                funnel_name=funnel_name,
                date=date,
                step_order=i + 1,
                event_type=event_type,
                entered=entered,
                completed=completed,
                conversion_rate=(completed / entered * 100) if entered else 0,
            )

        return Response({"status": "computed", "steps": len(steps_config)})


class RetentionViewSet(viewsets.ReadOnlyModelViewSet):
    """User retention cohorts."""

    queryset = RetentionCohort.objects.all()
    serializer_class = RetentionCohortSerializer
    permission_classes = [IsAdminOnly]

    @action(detail=False, methods=["get"])
    def matrix(self, request):
        days = int(request.query_params.get("days", 30))
        cohorts = RetentionCohort.objects.filter(
            cohort_date__gte=timezone.now().date() - timedelta(days=days)
        ).order_by("-cohort_date", "period")
        return Response(RetentionCohortSerializer(cohorts, many=True).data)

    @action(detail=False, methods=["post"], permission_classes=[IsAdminOnly])
    def compute(self, request):
        """Compute retention cohorts."""
        days_back = request.data.get("days", 90)
        end_date = timezone.now().date()
        start_date = end_date - timedelta(days=days_back)

        from django.contrib.auth import get_user_model
        User = get_user_model()

        RetentionCohort.objects.all().delete()

        for cohort_date in (start_date + timedelta(days=i) for i in range((end_date - start_date).days + 1)):
            cohort_users = User.objects.filter(date_joined__date=cohort_date)
            cohort_size = cohort_users.count()
            if cohort_size == 0:
                continue

            for period in [0, 1, 3, 7, 14, 30]:
                target_date = cohort_date + timedelta(days=period)
                if target_date > end_date:
                    break
                active = cohort_users.filter(last_login__date=target_date).count()
                RetentionCohort.objects.create(
                    cohort_date=cohort_date,
                    period=period,
                    users_in_cohort=cohort_size,
                    users_active=active,
                    retention_rate=(active / cohort_size * 100) if cohort_size else 0,
                )

        return Response({"status": "computed"})


class RevenueViewSet(viewsets.ReadOnlyModelViewSet):
    """Revenue analytics."""

    permission_classes = [IsAdminOnly]

    @action(detail=False, methods=["get"])
    def by_channel(self, request):
        days = int(request.query_params.get("days", 30))
        start = timezone.now().date() - timedelta(days=days)
        data = RevenueByChannel.objects.filter(date__gte=start)
        return Response(RevenueByChannelSerializer(data, many=True).data)

    @action(detail=False, methods=["get"])
    def summary(self, request):
        days = int(request.query_params.get("days", 30))
        start = timezone.now().date() - timedelta(days=days)

        from orders.models import Order
        from payments.models import Payment

        total_revenue = Order.objects.filter(
            created_at__date__gte=timezone.now().date() - timedelta(days=days),
            status__in=["DELIVERED", "OUT_FOR_DELIVERY"]
        ).aggregate(total=Sum("total"))["total"] or 0

        orders = Order.objects.filter(created_at__date__gte=timezone.now().date() - timedelta(days=days))
        total_orders = orders.count()
        completed = orders.filter(status="DELIVERED").count()

        return Response({
            "total_revenue": total_revenue,
            "total_orders": total_orders,
            "completed_orders": completed,
            "conversion_rate": (completed / total_orders * 100) if total_orders else 0,
        })


class ProductAnalyticsViewSet(viewsets.ReadOnlyModelViewSet):
    """Product performance analytics."""

    queryset = ProductPerformance.objects.all()
    serializer_class = ProductPerformanceSerializer
    permission_classes = [IsAdminOnly]

    @action(detail=False, methods=["get"])
    def top(self, request):
        days = int(request.query_params.get("days", 30))
        limit = int(request.query_params.get("limit", 20))
        start = timezone.now().date() - timedelta(days=days)

        top = ProductPerformance.objects.filter(date__gte=start).order_by("-revenue")[:limit]
        return Response(ProductPerformanceSerializer(top, many=True).data)


class DashboardViewSet(viewsets.GenericViewSet):
    """Admin dashboard summary."""

    permission_classes = [IsAdminOnly]

    @action(detail=False, methods=["get"])
    def summary(self, request):
        today = timezone.now().date()
        yesterday = today - timedelta(days=1)

        today_metrics = DailyMetrics.objects.filter(date=today).first()
        yesterday_metrics = DailyMetrics.objects.filter(date=yesterday).first()

        from orders.models import Order
        from products.models import Product

        top_products = ProductPerformance.objects.filter(date=today).order_by("-revenue")[:5]
        revenue_channels = RevenueByChannel.objects.filter(date=today).order_by("-revenue")[:5]

        return Response({
            "today": DailyMetricsSerializer(today_metrics).data if today_metrics else None,
            "yesterday": DailyMetricsSerializer(yesterday_metrics).data if yesterday_metrics else None,
            "top_products": ProductPerformanceSerializer(top_products, many=True).data,
            "revenue_by_channel": RevenueByChannelSerializer(
                RevenueByChannel.objects.filter(date=today).order_by("-revenue")[:5], many=True
            ).data,
        })

    @action(detail=False, methods=["get"])
    def analytics(self, request):
        """
        Comprehensive analytics for the admin dashboard.
        Returns:
        - total_revenue, avg_order_value, mom_growth
        - top_selling_products (by quantity)
        - revenue_trend (last 30 days)
        - top_categories (by revenue)
        """
        from orders.models import Order, OrderItem
        from products.models import Product, Category
        from django.db.models import Sum, Count, DecimalField
        from django.db.models.functions import TruncDate, Coalesce
        from decimal import Decimal

        today = timezone.now().date()
        thirty_days_ago = today - timedelta(days=30)
        sixty_days_ago = today - timedelta(days=60)

        # Base queryset: exclude cancelled orders
        base_orders = Order.objects.exclude(status="CANCELLED")

        # Total revenue (all time, excluding cancelled)
        total_revenue = base_orders.aggregate(total=Sum("total"))["total"] or Decimal("0")

        # Total valid orders (excluding cancelled)
        total_valid_orders = base_orders.count()

        # Average Order Value
        avg_order_value = (total_revenue / total_valid_orders) if total_valid_orders > 0 else Decimal("0")

        # MoM Growth: Compare current month vs previous month
        current_month_start = today.replace(day=1)
        prev_month_end = current_month_start - timedelta(days=1)
        prev_month_start = prev_month_end.replace(day=1)

        current_month_revenue = base_orders.filter(
            created_at__date__gte=current_month_start
        ).aggregate(total=Sum("total"))["total"] or Decimal("0")

        prev_month_revenue = base_orders.filter(
            created_at__date__gte=prev_month_start,
            created_at__date__lte=prev_month_end
        ).aggregate(total=Sum("total"))["total"] or Decimal("0")

        if prev_month_revenue > 0:
            mom_growth = round(
                ((current_month_revenue - prev_month_revenue) / prev_month_revenue) * 100, 2
            )
        else:
            mom_growth = 0 if current_month_revenue == 0 else 100

        # Top 5 selling products by quantity ordered
        top_products_qs = OrderItem.objects.filter(
            order__in=base_orders
        ).values(
            "product_name", "variant_name", "sku"
        ).annotate(
            total_quantity=Sum("quantity"),
            total_revenue=Sum("line_total")
        ).order_by("-total_quantity")[:5]

        top_products = list(top_products_qs)

        # 30-day revenue trend (daily)
        daily_revenue = base_orders.filter(
            created_at__date__gte=thirty_days_ago
        ).annotate(
            date=TruncDate("created_at")
        ).values("date").annotate(
            revenue=Sum("total"),
            orders=Count("id")
        ).order_by("date")

        # Fill in missing dates with 0
        revenue_trend = []
        for i in range(31):
            date = thirty_days_ago + timedelta(days=i)
            day_data = next((d for d in daily_revenue if d["date"] == date), None)
            revenue_trend.append({
                "date": date.isoformat(),
                "revenue": float(day_data["revenue"]) if day_data else 0,
                "orders": day_data["orders"] if day_data else 0,
            })

        # Top categories by revenue (using order items)
        category_revenue = OrderItem.objects.filter(
            order__in=base_orders.filter(created_at__date__gte=thirty_days_ago)
        ).select_related("variant__product__category").values(
            "variant__product__category__name",
            "variant__product__category__slug"
        ).annotate(
            revenue=Sum("line_total"),
            quantity=Sum("quantity")
        ).order_by("-revenue")[:10]

        top_categories = list(category_revenue)

        return Response({
            "total_revenue": float(total_revenue),
            "avg_order_value": float(avg_order_value),
            "mom_growth": mom_growth,
            "total_orders": total_valid_orders,
            "top_products": [
                {
                    "name": p["product_name"],
                    "variant": p["variant_name"],
                    "sku": p["sku"],
                    "quantity": p["total_quantity"],
                    "revenue": float(p["total_revenue"]),
                }
                for p in top_products
            ],
            "revenue_trend": revenue_trend,
            "top_categories": [
                {
                    "name": c["variant__product__category__name"] or "Uncategorized",
                    "slug": c["variant__product__category__slug"],
                    "revenue": float(c["revenue"]),
                    "quantity": c["quantity"],
                }
                for c in top_categories
            ],
        })