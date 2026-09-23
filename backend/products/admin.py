from django.contrib import admin

from .models import Product, ProductImage, ProductVariant


class ProductVariantInline(admin.TabularInline):
    model = ProductVariant
    extra = 0
    fields = (
        "name",
        "sku",
        "price",
        "is_active",
    )


class ProductImageInline(admin.TabularInline):
    model = ProductImage
    extra = 0
    fields = (
        "image",
        "alt_text",
        "is_primary",
        "sort_order",
    )


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = (
        "name",
        "category",
        "brand",
        "mrp",
        "is_featured",
        "is_active",
        "created_at",
    )
    list_filter = ("is_active", "is_featured", "category")
    search_fields = ("name", "slug", "brand", "tags")
    prepopulated_fields = {"slug": ("name",)}
    list_select_related = ("category",)
    inlines = [ProductImageInline, ProductVariantInline]
    list_per_page = 25
