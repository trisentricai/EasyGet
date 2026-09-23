from django.contrib import admin

from .models import Notification, NotificationPreference, NotificationTemplate


@admin.register(NotificationTemplate)
class NotificationTemplateAdmin(admin.ModelAdmin):
    list_display = ("name", "channel", "is_active", "created_at")
    list_filter = ("channel", "is_active")
    search_fields = ("name", "subject_template")
    list_per_page = 25


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ("id", "user", "channel", "subject", "priority", "status", "created_at")
    list_filter = ("channel", "priority", "status", "created_at")
    search_fields = ("user__email", "subject", "body")
    readonly_fields = (
        "user", "template", "channel", "subject", "body", "priority",
        "status", "data", "sent_at", "delivered_at", "read_at",
        "error_message", "created_at",
    )
    list_select_related = ("user", "template")
    list_per_page = 50

    def has_add_permission(self, request):
        return False

    def has_change_permission(self, request, obj=None):
        return False


@admin.register(NotificationPreference)
class NotificationPreferenceAdmin(admin.ModelAdmin):
    list_display = ("user", "event_type", "channel", "is_enabled")
    list_filter = ("event_type", "channel", "is_enabled")
    search_fields = ("user__email",)
    list_per_page = 50