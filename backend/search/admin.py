from django.contrib import admin

from .models import PopularSearch, ProductSearchIndex, SearchQueryLog


@admin.register(ProductSearchIndex)
class ProductSearchIndexAdmin(admin.ModelAdmin):
    list_display = ("product", "updated_at")
    search_fields = ("product__name", "product__sku")
    list_per_page = 50


@admin.register(SearchQueryLog)
class SearchQueryLogAdmin(admin.ModelAdmin):
    list_display = ("query", "user", "results_count", "took_ms", "created_at")
    list_filter = ("created_at",)
    search_fields = ("query", "user__email")
    readonly_fields = ("query", "user", "session_key", "results_count", "filters", "took_ms", "created_at")
    list_per_page = 50

    def has_add_permission(self, request):
        return False


@admin.register(PopularSearch)
class PopularSearchAdmin(admin.ModelAdmin):
    list_display = ("query", "count", "last_searched")
    search_fields = ("query",)
    readonly_fields = ("query", "count", "last_searched", "created_at")
    list_per_page = 50

    def has_add_permission(self, request):
        return False