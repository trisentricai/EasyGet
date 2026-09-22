from rest_framework import serializers

from .models import (
    DailyMetrics,
    FunnelAnalysis,
    FunnelStep,
    ProductPerformance,
    RetentionCohort,
    RevenueByChannel,
    UserEvent,
)


class DailyMetricsSerializer(serializers.ModelSerializer):
    class Meta:
        model = DailyMetrics
        fields = [
            "date",
            "new_users",
            "active_users",
            "returning_users",
            "total_orders",
            "completed_orders",
            "cancelled_orders",
            "gmv",
            "aov",
            "products_viewed",
            "products_added_to_cart",
            "revenue",
            "refunds",
            "net_revenue",
            "conversion_rate",
        ]
        read_only_fields = fields


class UserEventSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserEvent
        fields = [
            "id",
            "user",
            "session_id",
            "event_type",
            "properties",
            "timestamp",
        ]
        read_only_fields = fields


class UserEventCreateSerializer(serializers.ModelSerializer):
    """Batch create events."""

    events = UserEventSerializer(many=True)

    class Meta:
        model = UserEvent
        fields = ["events"]

    def create(self, validated_data):
        events_data = validated_data.pop("events")
        UserEvent.objects.bulk_create([
            UserEvent(**event) for event in events_data
        ])
        return {"created": len(events_data)}


class FunnelStepSerializer(serializers.ModelSerializer):
    class Meta:
        model = FunnelStep
        fields = ["id", "name", "event_type", "order", "is_required"]


class FunnelAnalysisSerializer(serializers.ModelSerializer):
    class Meta:
        model = FunnelAnalysis
        fields = [
            "funnel_name",
            "date",
            "step_order",
            "event_type",
            "entered",
            "completed",
            "conversion_rate",
            "avg_time_seconds",
        ]
        read_only_fields = fields


class FunnelOverviewSerializer(serializers.Serializer):
    funnel_name = serializers.CharField()
    date = serializers.DateField()
    steps = FunnelAnalysisSerializer(many=True)
    overall_conversion = serializers.DecimalField(max_digits=5, decimal_places=2)


class RetentionCohortSerializer(serializers.ModelSerializer):
    class Meta:
        model = RetentionCohort
        fields = ["cohort_date", "period", "users_in_cohort", "users_active", "retention_rate"]
        read_only_fields = fields


class RevenueByChannelSerializer(serializers.ModelSerializer):
    class Meta:
        model = RevenueByChannel
        fields = ["date", "channel", "orders", "revenue", "new_customers", "returning_customers"]
        read_only_fields = fields


class ProductPerformanceSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductPerformance
        fields = [
            "date",
            "product_id",
            "product_name",
            "views",
            "add_to_carts",
            "purchases",
            "revenue",
            "conversion_rate",
        ]
        read_only_fields = fields


class DashboardSummarySerializer(serializers.Serializer):
    """Aggregated dashboard summary."""

    today = DailyMetricsSerializer()
    yesterday = DailyMetricsSerializer()
    week_over_week = serializers.DictField()
    month_to_date = serializers.DictField()
    top_products = ProductPerformanceSerializer(many=True)
    revenue_by_channel = RevenueByChannelSerializer(many=True)