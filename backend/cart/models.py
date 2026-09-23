import uuid

from django.conf import settings
from django.db import models
from django.utils import timezone

from products.models import ProductVariant
from stores.models import Store
from tenants.models import Tenant


class Cart(models.Model):
    """Session-based or user-based cart."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="carts",
        null=True,
        blank=True,
    )
    session_key = models.CharField(max_length=40, db_index=True, null=True, blank=True)
    store = models.ForeignKey(
        Store,
        on_delete=models.CASCADE,
        related_name="carts",
        null=True,
        blank=True,
    )
    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="carts",
        help_text="Denormalized from store.tenant; store-less carts stay tenant-free.",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    expires_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-updated_at"]
        indexes = [
            models.Index(fields=["user", "expires_at"]),
            models.Index(fields=["session_key", "expires_at"]),
        ]

    def __str__(self):
        if self.user:
            return f"Cart({self.user.email})"
        return f"Cart(session={self.session_key[:8]})"

    def save(self, *args, **kwargs):
        if not self.expires_at:
            self.expires_at = timezone.now() + timezone.timedelta(days=7)
        # Denormalize ownership: a cart bound to a store belongs to that
        # store's tenant (same pattern as Store/Product/StockItem).
        if self.store_id:
            store_tenant_id = Store.objects.filter(pk=self.store_id).values_list(
                "tenant_id", flat=True
            ).first()
            if store_tenant_id:
                self.tenant_id = store_tenant_id
        super().save(*args, **kwargs)

    @property
    def is_expired(self):
        return timezone.now() > self.expires_at

    @property
    def total_items(self):
        return self.items.aggregate(total=models.Sum("quantity"))["total"] or 0

    @property
    def subtotal(self):
        return sum(item.line_total for item in self.items.select_related("variant__product"))

    def merge_with(self, other_cart):
        """Merge another cart into this one (e.g., on login)."""
        for item in other_cart.items.all():
            existing = self.items.filter(variant=item.variant).first()
            if existing:
                existing.quantity += item.quantity
                existing.save()
            else:
                item.cart = self
                item.save()
        other_cart.delete()


class CartItem(models.Model):
    cart = models.ForeignKey(Cart, on_delete=models.CASCADE, related_name="items")
    variant = models.ForeignKey(
        ProductVariant,
        on_delete=models.CASCADE,
        related_name="cart_items",
    )
    quantity = models.PositiveIntegerField(default=1)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["created_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["cart", "variant"], name="unique_cart_item_per_variant"
            )
        ]

    def __str__(self):
        return f"{self.quantity}x {self.variant}"

    @property
    def line_total(self):
        return self.variant.price * self.quantity

    def clean(self):
        from django.core.exceptions import ValidationError
        if self.quantity > 999:
            raise ValidationError("Quantity cannot exceed 999")
        if not self.variant.is_active:
            raise ValidationError("Variant is not active")
        if self.variant.product and not self.variant.product.is_active:
            raise ValidationError("Product is not active")