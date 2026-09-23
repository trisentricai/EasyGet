from django.contrib import admin

from .models import DeliveryAssignment


@admin.register(DeliveryAssignment)
class DeliveryAssignmentAdmin(admin.ModelAdmin):
    list_display = ("order", "agent", "status", "assigned_at")
    list_filter = ("status", "tenant")
    search_fields = ("order__order_number", "agent__email")
    readonly_fields = ("assigned_at", "updated_at")
