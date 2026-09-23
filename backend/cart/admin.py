from django.contrib import admin

from .models import Cart, CartItem


class CartItemInline(admin.TabularInline):
    model = CartItem
    extra = 0
    readonly_fields = ("created_at", "updated_at")


@admin.register(Cart)
class CartAdmin(admin.ModelAdmin):
    list_display = ("id", "user", "session_key", "store", "total_items", "created_at")
    list_filter = ("store", "created_at")
    search_fields = ("user__email", "session_key", "id")
    readonly_fields = ("created_at", "updated_at", "expires_at")
    list_select_related = ("user", "store")
    inlines = [CartItemInline]
    list_per_page = 25


@admin.register(CartItem)
class CartItemAdmin(admin.ModelAdmin):
    list_display = ("cart", "variant", "quantity", "line_total", "created_at")
    list_filter = ("created_at",)
    search_fields = ("cart__id", "variant__sku", "variant__name")
    list_select_related = ("cart", "variant__product")
    list_per_page = 50