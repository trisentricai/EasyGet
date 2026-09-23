import uuid

from django.conf import settings
from django.db import models
from django.utils import timezone

from products.models import ProductVariant
from stores.models import Store
from tenants.models import Tenant


class Order(models.Model):
    """Customer order."""

    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending"
        CONFIRMED = "CONFIRMED", "Confirmed"
        PREPARING = "PREPARING", "Preparing"
        READY = "READY", "Ready for Pickup"
        OUT_FOR_DELIVERY = "OUT_FOR_DELIVERY", "Out for Delivery"
        DELIVERED = "DELIVERED", "Delivered"
        CANCELLED = "CANCELLED", "Cancelled"
        REFUNDED = "REFUNDED", "Refunded"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    order_number = models.CharField(max_length=20, unique=True, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="orders",
    )
    store = models.ForeignKey(
        Store,
        on_delete=models.PROTECT,
        related_name="orders",
    )
    tenant = models.ForeignKey(
        Tenant,
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="orders",
        help_text="Denormalized from store.tenant; items/history inherit via order.",
    )
    status = models.CharField(
        max_length=20, choices=Status.choices, default=Status.PENDING
    )
    subtotal = models.DecimalField(max_digits=10, decimal_places=2)
    delivery_fee = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    discount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    total = models.DecimalField(max_digits=10, decimal_places=2)
    delivery_address = models.JSONField(default=dict)
    delivery_instructions = models.TextField(blank=True, default="")
    estimated_delivery_at = models.DateTimeField(null=True, blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)
    cancelled_at = models.DateTimeField(null=True, blank=True)
    cancellation_reason = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["user", "status"]),
            models.Index(fields=["store", "status"]),
            models.Index(fields=["order_number"]),
        ]

    def __str__(self):
        return f"Order {self.order_number} ({self.status})"

    def save(self, *args, **kwargs):
        if not self.order_number:
            self.order_number = self.generate_order_number()
        if not self.total:
            self.total = self.subtotal + self.delivery_fee - self.discount
        if self.store_id:
            store_tenant_id = Store.objects.filter(pk=self.store_id).values_list(
                "tenant_id", flat=True
            ).first()
            if store_tenant_id:
                self.tenant_id = store_tenant_id
        super().save(*args, **kwargs)

    def generate_order_number(self):
        """Generate unique order number like EZG-20260920-A1B2."""
        import random
        import string
        date_part = timezone.now().strftime("%Y%m%d")
        random_part = "".join(random.choices(string.ascii_uppercase + string.digits, k=4))
        return f"EZG-{date_part}-{random_part}"

    def can_cancel(self):
        return self.status in {
            self.Status.PENDING,
            self.Status.CONFIRMED,
        }

    def can_refund(self):
        return self.status in {self.Status.DELIVERED}


class OrderItem(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name="items")
    variant = models.ForeignKey(
        ProductVariant,
        on_delete=models.PROTECT,
        related_name="order_items",
    )
    product_name = models.CharField(max_length=255)
    variant_name = models.CharField(max_length=200, blank=True, default="")
    sku = models.CharField(max_length=64)
    unit_price = models.DecimalField(max_digits=10, decimal_places=2)
    quantity = models.PositiveIntegerField()
    line_total = models.DecimalField(max_digits=10, decimal_places=2)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at"]

    def __str__(self):
        return f"{self.quantity}x {self.product_name} ({self.sku})"

    def save(self, *args, **kwargs):
        if not self.line_total:
            self.line_total = self.unit_price * self.quantity
        super().save(*args, **kwargs)


class OrderStatusHistory(models.Model):
    """Audit trail for order status changes."""

    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name="status_history")
    from_status = models.CharField(max_length=20, choices=Order.Status.choices, blank=True, default="")
    to_status = models.CharField(max_length=20, choices=Order.Status.choices)
    changed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="order_status_changes",
    )
    note = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        verbose_name_plural = "Order status histories"

    def __str__(self):
        return f"{self.order.order_number}: {self.from_status} → {self.to_status}"