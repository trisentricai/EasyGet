from django.db import models

from stores.models import Store


class StorefrontTheme(models.Model):
    """Visual identity of a storefront: colors, fonts, logo, effects.

    One per store. Every value is plain data the client can edit from the
    dashboard — a rebrand is an edit, never a code change.
    """

    class ButtonStyle(models.TextChoices):
        ROUNDED = "ROUNDED", "Rounded"
        SQUARE = "SQUARE", "Square"
        PILL = "PILL", "Pill"

    store = models.OneToOneField(
        Store, on_delete=models.CASCADE, related_name="storefront_theme"
    )
    primary_color = models.CharField(max_length=9, default="#1A73E8")
    secondary_color = models.CharField(max_length=9, default="#FFB300")
    background_color = models.CharField(max_length=9, default="#FFFFFF")
    font_family = models.CharField(max_length=100, default="system-ui")
    logo = models.ImageField(upload_to="storefront/logos/", null=True, blank=True)
    hero_image = models.ImageField(upload_to="storefront/heroes/", null=True, blank=True)
    button_style = models.CharField(
        max_length=20, choices=ButtonStyle.choices, default=ButtonStyle.ROUNDED
    )
    effects = models.JSONField(
        default=dict,
        blank=True,
        help_text='Visual effects, e.g. {"hero_animation": "fade", "hover_zoom": true}.',
    )
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Theme for {self.store.name}"


class StoreSection(models.Model):
    """One ordered row of the storefront page (hero, banner, grids, text...).

    The page layout is simply the sections of a store ordered by `position` —
    exactly what a click-and-drag dashboard rearranges.
    """

    class SectionType(models.TextChoices):
        HERO = "HERO", "Hero banner"
        BANNER = "BANNER", "Banner strip"
        CATEGORY_GRID = "CATEGORY_GRID", "Category grid"
        PRODUCT_ROW = "PRODUCT_ROW", "Product row"
        IMAGE_GALLERY = "IMAGE_GALLERY", "Image gallery"
        RICH_TEXT = "RICH_TEXT", "Rich text block"

    store = models.ForeignKey(
        Store, on_delete=models.CASCADE, related_name="storefront_sections"
    )
    section_type = models.CharField(max_length=20, choices=SectionType.choices)
    title = models.CharField(max_length=200, blank=True, default="")
    subtitle = models.CharField(max_length=300, blank=True, default="")
    image = models.ImageField(
        upload_to="storefront/sections/", null=True, blank=True
    )
    config = models.JSONField(
        default=dict,
        blank=True,
        help_text=(
            "Layout knobs: columns, rows, size (sm|md|lg), effects, placeholder "
            "text — validated loosely; unknown keys are preserved."
        ),
    )
    position = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["position", "id"]

    def __str__(self):
        return f"{self.store.name} · {self.section_type} #{self.position}"


class SectionItem(models.Model):
    """One card inside a section: a product, a category, or a custom tile."""

    class ItemType(models.TextChoices):
        PRODUCT = "PRODUCT", "Product"
        CATEGORY = "CATEGORY", "Category"
        CUSTOM = "CUSTOM", "Custom"

    section = models.ForeignKey(
        StoreSection, on_delete=models.CASCADE, related_name="items"
    )
    item_type = models.CharField(
        max_length=20, choices=ItemType.choices, default=ItemType.CUSTOM
    )
    product = models.ForeignKey(
        "products.Product",
        null=True,
        blank=True,
        on_delete=models.CASCADE,
        related_name="storefront_items",
    )
    category = models.ForeignKey(
        "categories.Category",
        null=True,
        blank=True,
        on_delete=models.CASCADE,
        related_name="storefront_items",
    )
    caption = models.CharField(max_length=200, blank=True, default="")
    image = models.ImageField(
        upload_to="storefront/items/", null=True, blank=True
    )
    link = models.CharField(max_length=500, blank=True, default="")
    config = models.JSONField(default=dict, blank=True)
    position = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["position", "id"]

    def __str__(self):
        label = self.caption or (
            self.product.name if self.product_id else ""
        ) or (
            self.category.name if self.category_id else ""
        ) or f"{self.item_type} #{self.pk}"
        return f"{self.section} → {label}"
