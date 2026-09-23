from django.contrib import admin

from .models import Order, OrderItem, OrderStatusHistory


class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0
    readonly_fields = (
        "product_name",
        "variant_name",
        "sku",
        "unit_price",
        "quantity",
        "line_total",
    )


class OrderStatusHistoryInline(admin.TabularInline):
    model = OrderStatusHistory
    extra = 0
    readonly_fields = ("from_status", "to_status", "changed_by", "note", "created_at")


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = (
        "order_number",
        "user",
        "store",
        "status",
        "total",
        "created_at",
    )
    list_filter = ("status", "store", "created_at")
    search_fields = ("order_number", "user__email", "user__phone")
    list_select_related = ("user", "store")
    readonly_fields = (
        "order_number",
        "user",
        "store",
        "subtotal",
        "delivery_fee",
        "discount",
        "total",
        "created_at",
        "updated_at",
    )
    inlines = [OrderItemInline, OrderStatusHistoryInline]
    list_per_page = 25

    def get_queryset(self, request):
        return super().get_queryset(request).prefetch_related("items", "status_history")


@admin.register(OrderItem)
class OrderItemAdmin(admin.ModelAdmin):
    list_display = ("order", "variant", "quantity", "unit_price", "line_total")
    list_filter = ("created_at",)
    search_fields = ("order__order_number", "sku", "product_name")
    list_select_related = ("order", "variant")
    list_per_page = 50


@admin.register(OrderStatusHistory)
class OrderStatusHistoryAdmin(admin.ModelAdmin):
    list_display = ("order", "from_status", "to_status", "changed_by", "created_at")
    list_filter = ("from_status", "to_status", "created_at")
    search_fields = ("order__order_number",)
    readonly_fields = ("order", "from_status", "to_status", "changed_by", "note", "created_at")
    list_per_page = 50