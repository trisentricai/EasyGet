from django.contrib import admin

from .models import Product, ProductImage, ProductReview, ProductVariant


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
        "caption",
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


@admin.register(ProductReview)
class ProductReviewAdmin(admin.ModelAdmin):
    list_display = ("product", "rating", "reviewer", "verified", "is_approved", "created_at")
    list_filter = ("rating", "is_approved", "is_verified_purchase")
    search_fields = ("product__name", "title", "body", "user__email")
    list_select_related = ("product", "user")
    list_per_page = 25

    def reviewer(self, obj):
        return obj.reviewer_name

    def verified(self, obj):
        return obj.is_verified_purchase

    verified.boolean = True
