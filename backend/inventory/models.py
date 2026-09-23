from django.conf import settings
from django.db import models

from products.models import ProductVariant
from stores.models import Store
from tenants.models import Tenant


class StockItem(models.Model):
    DEFAULT_LOW_STOCK_THRESHOLD = 5

    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="stock_items",
        help_text="Denormalized from store.tenant for tenant-scoped queries.",
    )
    store = models.ForeignKey(Store, on_delete=models.CASCADE, related_name="stock_items")
    variant = models.ForeignKey(
        ProductVariant, on_delete=models.CASCADE, related_name="stock_items"
    )
    quantity = models.PositiveIntegerField(default=0)
    low_stock_threshold = models.PositiveIntegerField(default=DEFAULT_LOW_STOCK_THRESHOLD)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-updated_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["store", "variant"], name="unique_stock_item_per_store_variant"
            )
        ]

    @property
    def is_available(self):
        return self.quantity > 0

    @property
    def is_low_stock(self):
        return self.quantity <= self.low_stock_threshold

    def __str__(self):
        return f"{self.store.name}: {self.variant} ({self.quantity})"


class InventoryTransaction(models.Model):
    class Reason(models.TextChoices):
        RESTOCK = "RESTOCK", "Restock"
        SALE = "SALE", "Sale"
        ADJUSTMENT = "ADJUSTMENT", "Adjustment"
        DAMAGE = "DAMAGE", "Damage"
        RETURN = "RETURN", "Return"

    stock_item = models.ForeignKey(
        StockItem, on_delete=models.CASCADE, related_name="transactions"
    )
    change = models.IntegerField()
    reason = models.CharField(max_length=20, choices=Reason.choices)
    note = models.CharField(max_length=255, blank=True, default="")
    performed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="inventory_transactions",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        sign = "+" if self.change >= 0 else ""
        return f"{sign}{self.change} @ {self.stock_item} ({self.reason})"
