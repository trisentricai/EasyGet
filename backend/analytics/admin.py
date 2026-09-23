from django.contrib import admin

from .models import (
    DailyMetrics,
    FunnelAnalysis,
    FunnelStep,
    ProductPerformance,
    RetentionCohort,
    RevenueByChannel,
    UserEvent,
)


@admin.register(DailyMetrics)
class DailyMetricsAdmin(admin.ModelAdmin):
    list_display = (
        "date", "new_users", "active_users", "total_orders", "gmv", "aov",
        "conversion_rate", "revenue", "net_revenue"
    )
    date_hierarchy = "date"
    list_per_page = 25


@admin.register(UserEvent)
class UserEventAdmin(admin.ModelAdmin):
    list_display = ("event_type", "user", "session_id", "timestamp")
    list_filter = ("event_type", "timestamp")
    search_fields = ("user__email", "session_id", "properties")
    readonly_fields = ("user", "session_id", "event_type", "properties", "timestamp", "created_at")
    list_per_page = 50

    def has_add_permission(self, request):
        return False


@admin.register(FunnelStep)
class FunnelStepAdmin(admin.ModelAdmin):
    list_display = ("name", "order", "event_type", "is_required")
    list_filter = ("name",)
    ordering = ("name", "order")


@admin.register(FunnelAnalysis)
class FunnelAnalysisAdmin(admin.ModelAdmin):
    list_display = ("funnel_name", "date", "step_order", "event_type", "entered", "completed", "conversion_rate")
    list_filter = ("funnel_name", "date", "step_order")
    readonly_fields = ("funnel_name", "date", "step_order", "event_type", "entered", "completed", "conversion_rate", "avg_time_seconds", "created_at")
    list_per_page = 50

    def has_add_permission(self, request):
        return False


@admin.register(RetentionCohort)
class RetentionCohortAdmin(admin.ModelAdmin):
    list_display = ("cohort_date", "period", "users_in_cohort", "users_active", "retention_rate")
    list_filter = ("cohort_date", "period")
    readonly_fields = ("cohort_date", "period", "users_in_cohort", "users_active", "retention_rate", "created_at")
    list_per_page = 50

    def has_add_permission(self, request):
        return False


@admin.register(RevenueByChannel)
class RevenueByChannelAdmin(admin.ModelAdmin):
    list_display = ("date", "channel", "orders", "revenue", "new_customers")
    list_filter = ("date", "channel")
    date_hierarchy = "date"
    readonly_fields = ("date", "channel", "orders", "revenue", "new_customers", "returning_customers", "created_at")


@admin.register(ProductPerformance)
class ProductPerformanceAdmin(admin.ModelAdmin):
    list_display = ("date", "product_name", "views", "add_to_carts", "purchases", "revenue", "conversion_rate")
    list_filter = ("date",)
    search_fields = ("product_name",)
    readonly_fields = ("date", "product_id", "product_name", "views", "add_to_carts", "purchases", "revenue", "conversion_rate", "created_at")
    list_per_page = 50

    def has_add_permission(self, request):
        return False