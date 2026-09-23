from django.contrib import admin
from django.db.models import Count

from .models import Category


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = (
        "name",
        "slug",
        "parent",
        "is_active",
        "product_count",
        "sort_order",
    )
    list_filter = ("is_active", "parent")
    search_fields = ("name", "slug")
    prepopulated_fields = {"slug": ("name",)}
    list_select_related = ("parent",)
    list_per_page = 25

    @admin.display(description="Products", ordering="-product_count")
    def product_count(self, obj):
        return getattr(obj, "product_count", 0)

    def get_queryset(self, request):
        return (
            super()
            .get_queryset(request)
            .annotate(product_count=Count("products"))
        )
