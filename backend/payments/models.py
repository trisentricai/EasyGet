import uuid

from django.conf import settings
from django.db import models
from django.utils import timezone

from orders.models import Order


class PaymentMethod(models.Model):
    """User's saved payment methods."""

    class Type(models.TextChoices):
        CARD = "CARD", "Credit/Debit Card"
        UPI = "UPI", "UPI"
        WALLET = "WALLET", "Wallet"
        COD = "COD", "Cash on Delivery"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="payment_methods",
    )
    type = models.CharField(max_length=10, choices=Type.choices)
    is_default = models.BooleanField(default=False)
    # Card fields (tokenized)
    card_last4 = models.CharField(max_length=4, blank=True, default="")
    card_brand = models.CharField(max_length=20, blank=True, default="")
    card_exp_month = models.PositiveIntegerField(null=True, blank=True)
    card_exp_year = models.PositiveIntegerField(null=True, blank=True)
    # UPI fields
    upi_id = models.CharField(max_length=100, blank=True, default="")
    # Wallet fields
    wallet_provider = models.CharField(max_length=50, blank=True, default="")
    # Metadata
    gateway_token = models.CharField(max_length=200, blank=True, default="")
    gateway_customer_id = models.CharField(max_length=100, blank=True, default="")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-is_default", "-created_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["user", "type", "gateway_token"],
                name="unique_payment_method_per_user",
                condition=models.Q(is_active=True),
            )
        ]

    def __str__(self):
        if self.type == self.Type.CARD:
            return f"{self.card_brand} ending in {self.card_last4}"
        return f"{self.type} ({self.get_type_display()})"

    def save(self, *args, **kwargs):
        if self.is_default:
            PaymentMethod.objects.filter(user=self.user, is_default=True).exclude(
                pk=self.pk
            ).update(is_default=False)
        super().save(*args, **kwargs)


class Payment(models.Model):
    """Payment record for an order."""

    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending"
        PROCESSING = "PROCESSING", "Processing"
        SUCCEEDED = "SUCCEEDED", "Succeeded"
        FAILED = "FAILED", "Failed"
        REFUNDED = "REFUNDED", "Refunded"
        PARTIALLY_REFUNDED = "PARTIALLY_REFUNDED", "Partially Refunded"
        CANCELLED = "CANCELLED", "Cancelled"

    class Gateway(models.TextChoices):
        RAZORPAY = "RAZORPAY", "Razorpay"
        STRIPE = "STRIPE", "Stripe"
        PHONEPE = "PHONEPE", "PhonePe"
        COD = "COD", "Cash on Delivery"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    payment_id = models.CharField(max_length=50, unique=True, editable=False)
    order = models.OneToOneField(
        Order,
        on_delete=models.PROTECT,
        related_name="payment",
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="payments",
    )
    payment_method = models.ForeignKey(
        PaymentMethod,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="payments",
    )
    gateway = models.CharField(max_length=20, choices=Gateway.choices)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(max_length=3, default="INR")
    gateway_payment_id = models.CharField(max_length=100, blank=True, default="")
    gateway_order_id = models.CharField(max_length=100, blank=True, default="")
    gateway_response = models.JSONField(default=dict, blank=True)
    failure_reason = models.TextField(blank=True, default="")
    refunded_amount = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    processed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["order", "status"]),
            models.Index(fields=["user", "status"]),
            models.Index(fields=["gateway_payment_id"]),
        ]

    def __str__(self):
        return f"Payment {self.payment_id} ({self.status})"

    def save(self, *args, **kwargs):
        if not self.payment_id:
            self.payment_id = self.generate_payment_id()
        super().save(*args, **kwargs)

    def generate_payment_id(self):
        import random
        import string
        return f"PAY-{''.join(random.choices(string.ascii_uppercase + string.digits, k=12))}"

    def mark_succeeded(self, gateway_response=None):
        self.status = self.Status.SUCCEEDED
        self.processed_at = timezone.now()
        if gateway_response:
            self.gateway_response = gateway_response
        self.save()

    def mark_failed(self, reason, gateway_response=None):
        self.status = self.Status.FAILED
        self.failure_reason = reason
        if gateway_response:
            self.gateway_response = gateway_response
        self.save()


class Refund(models.Model):
    """Refund record."""

    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending"
        PROCESSING = "PROCESSING", "Processing"
        SUCCEEDED = "SUCCEEDED", "Succeeded"
        FAILED = "FAILED", "Failed"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    payment = models.ForeignKey(
        Payment,
        on_delete=models.PROTECT,
        related_name="refunds",
    )
    refund_id = models.CharField(max_length=50, unique=True, editable=False)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    reason = models.TextField()
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    gateway_refund_id = models.CharField(max_length=100, blank=True, default="")
    gateway_response = models.JSONField(default=dict, blank=True)
    processed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"Refund {self.refund_id} ({self.status})"

    def save(self, *args, **kwargs):
        if not self.refund_id:
            import random
            import string
            self.refund_id = f"REF-{''.join(random.choices(string.ascii_uppercase + string.digits, k=10))}"
        super().save(*args, **kwargs)