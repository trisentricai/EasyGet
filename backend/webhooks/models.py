import uuid
import hashlib
import hmac

from django.conf import settings
from django.db import models
from django.utils import timezone


class WebhookEndpoint(models.Model):
    """Registered webhook endpoints."""

    class Event(models.TextChoices):
        ORDER_CREATED = "ORDER_CREATED", "Order Created"
        ORDER_CONFIRMED = "ORDER_CONFIRMED", "Order Confirmed"
        ORDER_SHIPPED = "ORDER_SHIPPED", "Order Shipped"
        ORDER_DELIVERED = "ORDER_DELIVERED", "Order Delivered"
        ORDER_CANCELLED = "ORDER_CANCELLED", "Order Cancelled"
        PAYMENT_SUCCESS = "PAYMENT_SUCCESS", "Payment Success"
        PAYMENT_FAILED = "PAYMENT_FAILED", "Payment Failed"
        REFUND_PROCESSED = "REFUND_PROCESSED", "Refund Processed"
        INVENTORY_LOW = "INVENTORY_LOW", "Inventory Low"
        INVENTORY_OUT = "INVENTORY_OUT", "Inventory Out of Stock"
        USER_REGISTERED = "USER_REGISTERED", "User Registered"
        PRODUCT_CREATED = "PRODUCT_CREATED", "Product Created"
        PRODUCT_UPDATED = "PRODUCT_UPDATED", "Product Updated"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200)
    url = models.URLField()
    secret = models.CharField(max_length=64, blank=True, default="")
    events = models.JSONField(default=list)  # List of Event values
    is_active = models.BooleanField(default=True)
    retry_count = models.PositiveIntegerField(default=3)
    timeout_seconds = models.PositiveIntegerField(default=30)
    headers = models.JSONField(default=dict, blank=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="webhook_endpoints",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.name} ({self.url})"

    def matches_event(self, event):
        return event in self.events or "*" in self.events

    def sign_payload(self, payload):
        """Generate HMAC signature for payload."""
        if not self.secret:
            return ""
        return hmac.new(
            self.secret.encode(),
            payload,
            hashlib.sha256
        ).hexdigest()


class WebhookDelivery(models.Model):
    """Log of webhook delivery attempts."""

    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending"
        SUCCESS = "SUCCESS", "Success"
        FAILED = "FAILED", "Failed"
        RETRYING = "RETRYING", "Retrying"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    endpoint = models.ForeignKey(
        WebhookEndpoint,
        on_delete=models.CASCADE,
        related_name="deliveries",
    )
    event = models.CharField(max_length=50)
    payload = models.JSONField()
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    response_status = models.PositiveIntegerField(null=True, blank=True)
    response_body = models.TextField(blank=True, default="")
    attempt = models.PositiveIntegerField(default=1)
    error = models.TextField(blank=True, default="")
    sent_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["endpoint", "status"]),
            models.Index(fields=["event", "created_at"]),
        ]

    def __str__(self):
        return f"{self.endpoint.name} - {self.event} - {self.status}"


class WebhookEventLog(models.Model):
    """Log of all events that could trigger webhooks."""

    class EventType(models.TextChoices):
        ORDER_CREATED = "ORDER_CREATED", "Order Created"
        ORDER_CONFIRMED = "ORDER_CONFIRMED", "Order Confirmed"
        ORDER_SHIPPED = "ORDER_SHIPPED", "Order Shipped"
        ORDER_DELIVERED = "ORDER_DELIVERED", "Order Delivered"
        ORDER_CANCELLED = "ORDER_CANCELLED", "Order Cancelled"
        PAYMENT_SUCCESS = "PAYMENT_SUCCESS", "Payment Success"
        PAYMENT_FAILED = "PAYMENT_FAILED", "Payment Failed"
        REFUND_PROCESSED = "REFUND_PROCESSED", "Refund Processed"
        INVENTORY_LOW = "INVENTORY_LOW", "Inventory Low"
        INVENTORY_OUT = "INVENTORY_OUT", "Inventory Out of Stock"
        USER_REGISTERED = "USER_REGISTERED", "User Registered"
        PRODUCT_CREATED = "PRODUCT_CREATED", "Product Created"
        PRODUCT_UPDATED = "PRODUCT_UPDATED", "Product Updated"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    event_type = models.CharField(max_length=50, choices=EventType.choices)
    payload = models.JSONField()
    triggered_webhooks = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["event_type", "created_at"]),
        ]

    def __str__(self):
        return f"{self.event_type} - {self.created_at}"