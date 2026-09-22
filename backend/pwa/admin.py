from django.contrib import admin

from .models import AppUpdate, OfflineData, PWAConfigModel, PushSubscription


@admin.register(PWAConfigModel)
class PWAConfigModelAdmin(admin.ModelAdmin):
    list_display = ("name", "short_name", "theme_color", "updated_at")
    readonly_fields = ("updated_at",)
    list_per_page = 10


@admin.register(PushSubscription)
class PushSubscriptionAdmin(admin.ModelAdmin):
    list_display = ("user", "endpoint", "is_active", "created_at")
    list_filter = ("is_active", "created_at")
    search_fields = ("user__email", "endpoint")
    readonly_fields = ("created_at", "updated_at")
    list_per_page = 25


@admin.register(OfflineData)
class OfflineDataAdmin(admin.ModelAdmin):
    list_display = ("user", "data_type", "key", "expires_at", "updated_at")
    list_filter = ("data_type", "created_at")
    search_fields = ("user__email", "key")
    readonly_fields = ("created_at", "updated_at")
    list_per_page = 50


@admin.register(AppUpdate)
class AppUpdateAdmin(admin.ModelAdmin):
    list_display = ("version", "platform", "status", "is_mandatory", "released_at", "created_at")
    list_filter = ("platform", "status", "is_mandatory")
    search_fields = ("version", "release_notes")
    readonly_fields = ("created_at", "updated_at")
    list_per_page = 25