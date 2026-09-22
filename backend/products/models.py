from decimal import Decimal

from django.conf import settings
from django.db import models
from django.utils.text import slugify

from categories.models import Category
from tenants.models import Tenant


class Product(models.Model):
    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="products",
        help_text="Merchant organization that owns this catalog item.",
    )
    category = models.ForeignKey(
        Category,
        on_delete=models.PROTECT,
        related_name="products",
    )
    name = models.CharField(max_length=255)
    slug = models.SlugField(max_length=280, unique=True, blank=True)
    description = models.TextField(blank=True, default="")
    brand = models.CharField(max_length=120, blank=True, default="")
    mrp = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    is_active = models.BooleanField(default=True)
    is_featured = models.BooleanField(default=False)
    tags = models.CharField(max_length=500, blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-updated_at"]

    def save(self, *args, **kwargs):
        if not self.slug:
            base = slugify(self.name) or "product"
            slug = base
            suffix = 1
            while Product.objects.filter(slug=slug).exists():
                slug = f"{base}-{suffix}"
                suffix += 1
            self.slug = slug
        super().save(*args, **kwargs)

    @property
    def base_price(self):
        prices = list(
            self.variants.filter(is_active=True)
            .exclude(price__isnull=True)
            .values_list("price", flat=True)
        )
        return min(prices) if prices else None

    @property
    def discount_percent(self):
        if self.mrp and self.base_price and Decimal(self.mrp) > 0:
            return int(round((Decimal(self.mrp) - self.base_price) / Decimal(self.mrp) * 100))
        return 0

    @property
    def primary_image(self):
        return (
            self.images.filter(is_primary=True).first()
            or self.images.first()
        )

    def __str__(self):
        return self.name


class ProductVariant(models.Model):
    product = models.ForeignKey(
        Product, on_delete=models.CASCADE, related_name="variants"
    )
    name = models.CharField(max_length=200, blank=True, default="")
    sku = models.CharField(max_length=64, unique=True, blank=True)
    attributes = models.JSONField(default=dict, blank=True)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["sku"]

    def save(self, *args, **kwargs):
        if not self.sku:
            base = slugify(self.product.name)[:8].upper() or "SKU"
            suffix = 1
            sku = f"{base}-{suffix}"
            while ProductVariant.objects.filter(sku=sku).exists():
                suffix += 1
                sku = f"{base}-{suffix}"
            self.sku = sku
        super().save(*args, **kwargs)

    @property
    def discount_percent(self):
        if self.product.mrp and Decimal(self.product.mrp) > 0:
            return int(round((Decimal(self.product.mrp) - self.price) / Decimal(self.product.mrp) * 100))
        return 0

    def __str__(self):
        label = self.name or self.sku
        return f"{self.product.name} — {label}"


class ProductImage(models.Model):
    product = models.ForeignKey(
        Product, on_delete=models.CASCADE, related_name="images"
    )
    image = models.ImageField(upload_to="products/", blank=True, null=True)
    caption = models.CharField(max_length=200, blank=True, default="")
    is_primary = models.BooleanField(default=False)
    sort_order = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["sort_order", "id"]

    def __str__(self):
        return f"{self.product.name} image #{self.sort_order}"
