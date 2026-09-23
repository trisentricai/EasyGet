from django.contrib import admin

from .models import WebhookDelivery, WebhookEndpoint, WebhookEventLog


@admin.register(WebhookEndpoint)
class WebhookEndpointAdmin(admin.ModelAdmin):
    list_display = ("name", "url", "events_display", "is_active", "retry_count", "created_by", "created_at")
    list_filter = ("is_active", "created_at")
    search_fields = ("name", "url", "created_by__email")
    readonly_fields = ("created_at", "updated_at", "created_by")
    list_per_page = 25

    def events_display(self, obj):
        return ", ".join(obj.events) if obj.events else "-"


@admin.register(WebhookDelivery)
class WebhookDeliveryAdmin(admin.ModelAdmin):
    list_display = ("endpoint", "event", "status", "attempt", "response_status", "sent_at", "created_at")
    list_filter = ("status", "event", "endpoint", "created_at")
    search_fields = ("endpoint__name", "event", "payload")
    readonly_fields = (
        "endpoint", "event", "payload", "status", "response_status",
        "response_body", "attempt", "error", "sent_at", "completed_at", "created_at",
    )
    list_per_page = 50

    def has_add_permission(self, request):
        return False


@admin.register(WebhookEventLog)
class WebhookEventLogAdmin(admin.ModelAdmin):
    list_display = ("event_type", "triggered_webhooks", "created_at")
    list_filter = ("event_type", "created_at")
    search_fields = ("event_type", "payload")
    readonly_fields = ("event_type", "payload", "triggered_webhooks", "created_at")
    list_per_page = 50

    def has_add_permission(self, request):
        return False