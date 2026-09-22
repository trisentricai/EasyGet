import uuid

from django.conf import settings
from django.db import models
from django.utils import timezone


class NotificationTemplate(models.Model):
    """Reusable notification templates."""

    class Channel(models.TextChoices):
        EMAIL = "EMAIL", "Email"
        SMS = "SMS", "SMS"
        PUSH = "PUSH", "Push Notification"
        IN_APP = "IN_APP", "In-App"

    name = models.CharField(max_length=100, unique=True)
    channel = models.CharField(max_length=10, choices=Channel.choices)
    subject_template = models.CharField(max_length=200, blank=True, default="")
    body_template = models.TextField()
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return f"{self.name} ({self.channel})"

    def render(self, context):
        from django.template import Context, Template
        subject = Template(self.subject_template).render(Context(context))
        body = Template(self.body_template).render(Context(context))
        return subject.strip(), body.strip()


class Notification(models.Model):
    """Individual notification sent to a user."""

    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending"
        SENT = "SENT", "Sent"
        DELIVERED = "DELIVERED", "Delivered"
        FAILED = "FAILED", "Failed"
        READ = "READ", "Read"

    class Priority(models.TextChoices):
        LOW = "LOW", "Low"
        NORMAL = "NORMAL", "Normal"
        HIGH = "HIGH", "High"
        URGENT = "URGENT", "Urgent"

    class Channel(models.TextChoices):
        EMAIL = "EMAIL", "Email"
        SMS = "SMS", "SMS"
        PUSH = "PUSH", "Push Notification"
        IN_APP = "IN_APP", "In-App"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="notifications",
    )
    template = models.ForeignKey(
        NotificationTemplate,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="notifications",
    )
    channel = models.CharField(max_length=10, choices=Channel.choices)
    subject = models.CharField(max_length=200, blank=True, default="")
    body = models.TextField()
    priority = models.CharField(max_length=10, choices=Priority.choices, default=Priority.NORMAL)
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.PENDING)
    data = models.JSONField(default=dict, blank=True)
    sent_at = models.DateTimeField(null=True, blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)
    read_at = models.DateTimeField(null=True, blank=True)
    error_message = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["user", "status"]),
            models.Index(fields=["user", "channel"]),
            models.Index(fields=["created_at"]),
        ]

    def __str__(self):
        return f"{self.channel} to {self.user.email}: {self.subject[:50]}"

    def mark_sent(self):
        self.status = self.Status.SENT
        self.sent_at = timezone.now()
        self.save(update_fields=["status", "sent_at"])

    def mark_delivered(self):
        self.status = self.Status.DELIVERED
        self.delivered_at = timezone.now()
        self.save(update_fields=["status", "delivered_at"])

    def mark_failed(self, error):
        self.status = self.Status.FAILED
        self.error_message = error
        self.save(update_fields=["status", "error_message"])

    def mark_read(self):
        if self.status != self.Status.READ:
            self.status = self.Status.READ
            self.read_at = timezone.now()
            self.save(update_fields=["status", "read_at"])


class NotificationPreference(models.Model):
    """User notification preferences per channel and event type."""

    class EventType(models.TextChoices):
        ORDER_PLACED = "ORDER_PLACED", "Order Placed"
        ORDER_CONFIRMED = "ORDER_CONFIRMED", "Order Confirmed"
        ORDER_SHIPPED = "ORDER_SHIPPED", "Order Shipped"
        ORDER_DELIVERED = "ORDER_DELIVERED", "Order Delivered"
        ORDER_CANCELLED = "ORDER_CANCELLED", "Order Cancelled"
        PAYMENT_SUCCESS = "PAYMENT_SUCCESS", "Payment Success"
        PAYMENT_FAILED = "PAYMENT_FAILED", "Payment Failed"
        REFUND_PROCESSED = "REFUND_PROCESSED", "Refund Processed"
        CART_ABANDONED = "CART_ABANDONED", "Cart Abandoned"
        PRICE_DROP = "PRICE_DROP", "Price Drop"
        BACK_IN_STOCK = "BACK_IN_STOCK", "Back in Stock"
        PROMOTION = "PROMOTION", "Promotion"
        SYSTEM = "SYSTEM", "System"

    class Channel(models.TextChoices):
        EMAIL = "EMAIL", "Email"
        SMS = "SMS", "SMS"
        PUSH = "PUSH", "Push Notification"
        IN_APP = "IN_APP", "In-App"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="notification_preferences",
    )
    event_type = models.CharField(max_length=30, choices=EventType.choices)
    channel = models.CharField(max_length=10, choices=Channel.choices)
    is_enabled = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = [["user", "event_type", "channel"]]
        ordering = ["user", "event_type"]

    def __str__(self):
        return f"{self.user.email} - {self.event_type} - {self.channel}"