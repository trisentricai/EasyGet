from django.contrib import admin

from .models import InventoryTransaction, StockItem


@admin.register(StockItem)
class StockItemAdmin(admin.ModelAdmin):
    list_display = (
        "variant",
        "store",
        "quantity",
        "low_stock_threshold",
        "status",
        "updated_at",
    )
    list_filter = ("store", "variant__is_active")
    search_fields = ("variant__sku", "variant__name", "store__name")
    list_per_page = 50
    list_select_related = ("store", "variant")

    @admin.display(description="Status")
    def status(self, obj):
        if obj.quantity == 0:
            return "OUT"
        if obj.quantity <= obj.low_stock_threshold:
            return "LOW"
        return "OK"

    def get_queryset(self, request):
        return super().get_queryset(request).select_related("store", "variant")


@admin.register(InventoryTransaction)
class InventoryTransactionAdmin(admin.ModelAdmin):
    list_display = ("stock_item", "change", "reason", "performed_by", "created_at")
    list_filter = ("reason", "created_at")
    search_fields = ("note", "stock_item__variant__sku")
    readonly_fields = ("created_at",)
    list_per_page = 50
    list_select_related = ("stock_item", "performed_by")

    @admin.display(description="Transaction")
    def stock_item(self, obj):
        return f"{obj.stock_item.variant.sku} @ {obj.stock_item.store.name}"

    def has_add_permission(self, request):
        return False

    def get_queryset(self, request):
        return super().get_queryset(request).select_related(
            "stock_item", "performed_by"
        )
