from django.contrib import admin

from .models import SectionItem, StoreSection, StorefrontTheme


class SectionItemInline(admin.TabularInline):
    model = SectionItem
    extra = 0


@admin.register(StorefrontTheme)
class StorefrontThemeAdmin(admin.ModelAdmin):
    list_display = ("store", "primary_color", "font_family", "button_style")


@admin.register(StoreSection)
class StoreSectionAdmin(admin.ModelAdmin):
    list_display = ("store", "section_type", "title", "position", "is_active")
    list_filter = ("section_type", "is_active")
    ordering = ("store", "position")
    inlines = [SectionItemInline]


@admin.register(SectionItem)
class SectionItemAdmin(admin.ModelAdmin):
    list_display = ("section", "item_type", "caption", "position")
    list_filter = ("item_type",)
