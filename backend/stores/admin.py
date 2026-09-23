from django.contrib import admin

from .models import Store


@admin.register(Store)
class StoreAdmin(admin.ModelAdmin):
    list_display = ("name", "slug", "city", "state", "is_active")
    list_filter = ("is_active", "city", "state")
    search_fields = ("name", "slug", "city")
    prepopulated_fields = {}  # slug auto-generated in save()
    readonly_fields = ("created_at", "updated_at")
