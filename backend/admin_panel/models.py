import uuid

from django.conf import settings
from django.db import models
from django.utils import timezone


class AdminAction(models.Model):
    """Audit log for admin actions."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    admin_user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.PROTECT,
        related_name="admin_actions",
    )
    action = models.CharField(max_length=100)
    target_model = models.CharField(max_length=100)
    target_id = models.CharField(max_length=100)
    changes = models.JSONField(default=dict, blank=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True, default="")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["admin_user", "created_at"]),
            models.Index(fields=["target_model", "target_id"]),
        ]

    def __str__(self):
        return f"{self.admin_user.email} - {self.action} - {self.target_model}"


class SystemConfig(models.Model):
    """Dynamic system configuration."""

    class ConfigType(models.TextChoices):
        STRING = "STRING", "String"
        INTEGER = "INTEGER", "Integer"
        DECIMAL = "DECIMAL", "Decimal"
        BOOLEAN = "BOOLEAN", "Boolean"
        JSON = "JSON", "JSON"

    key = models.CharField(max_length=100, unique=True)
    value = models.TextField()
    config_type = models.CharField(max_length=20, choices=ConfigType.choices, default=ConfigType.STRING)
    description = models.TextField(blank=True, default="")
    is_public = models.BooleanField(default=False)  # Exposed to frontend
    is_editable = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["key"]

    def __str__(self):
        return self.key

    def get_typed_value(self):
        if self.config_type == "INTEGER":
            return int(self.value)
        elif self.config_type == "DECIMAL":
            from decimal import Decimal
            return Decimal(self.value)
        elif self.config_type == "BOOLEAN":
            return self.value.lower() in ("true", "1", "yes", "on")
        elif self.config_type == "JSON":
            import json
            return json.loads(self.value)
        return self.value


class ScheduledTask(models.Model):
    """Admin-managed scheduled tasks."""

    class Status(models.TextChoices):
        PENDING = "PENDING", "Pending"
        RUNNING = "RUNNING", "Running"
        COMPLETED = "COMPLETED", "Completed"
        FAILED = "FAILED", "Failed"

    class TaskType(models.TextChoices):
        CELERY_TASK = "CELERY_TASK", "Celery Task"
        CUSTOM_SCRIPT = "CUSTOM_SCRIPT", "Custom Script"
        REPORT_GENERATION = "REPORT_GENERATION", "Report Generation"
        DATA_CLEANUP = "DATA_CLEANUP", "Data Cleanup"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200)
    task_type = models.CharField(max_length=30, choices=TaskType.choices)
    target = models.CharField(max_length=200)  # Celery task name or script path
    arguments = models.JSONField(default=dict, blank=True)
    schedule = models.CharField(max_length=100, blank=True, default="")  # Cron expression
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    last_run = models.DateTimeField(null=True, blank=True)
    next_run = models.DateTimeField(null=True, blank=True)
    result = models.JSONField(default=dict, blank=True)
    error = models.TextField(blank=True, default="")
    is_active = models.BooleanField(default=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name="scheduled_tasks",
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.name} ({self.status})"


class Banner(models.Model):
    """Homepage/carousel banners."""

    class BannerType(models.TextChoices):
        CAROUSEL = "CAROUSEL", "Carousel"
        POPUP = "POPUP", "Popup"
        BANNER = "BANNER", "Banner"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=200)
    subtitle = models.TextField(blank=True, default="")
    image = models.ImageField(upload_to="banners/")
    link_url = models.URLField(blank=True, default="")
    link_text = models.CharField(max_length=50, blank=True, default="")
    type = models.CharField(max_length=20, choices=BannerType.choices, default=BannerType.CAROUSEL)
    position = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)
    start_date = models.DateTimeField(null=True, blank=True)
    end_date = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["position", "-created_at"]

    def __str__(self):
        return self.title

    def is_valid(self):
        now = timezone.now()
        if self.start_date and now < self.start_date:
            return False
        if self.end_date and now > self.end_date:
            return False
        return self.is_active


class Coupon(models.Model):
    """Discount coupons."""

    class DiscountType(models.TextChoices):
        PERCENTAGE = "PERCENTAGE", "Percentage"
        FIXED = "FIXED", "Fixed Amount"
        FREE_DELIVERY = "FREE_DELIVERY", "Free Delivery"

    class AppliesTo(models.TextChoices):
        ALL = "ALL", "All Orders"
        CATEGORY = "CATEGORY", "Specific Category"
        PRODUCT = "PRODUCT", "Specific Product"
        MIN_ORDER = "MIN_ORDER", "Minimum Order Value"
        FIRST_ORDER = "FIRST_ORDER", "First Order Only"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    code = models.CharField(max_length=50, unique=True)
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True, default="")
    discount_type = models.CharField(max_length=20, choices=DiscountType.choices)
    discount_value = models.DecimalField(max_digits=10, decimal_places=2)
    applies_to = models.CharField(max_length=20, choices=AppliesTo.choices, default=AppliesTo.ALL)
    category = models.ForeignKey(
        "categories.Category",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="coupons",
    )
    product = models.ForeignKey(
        "products.Product",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="coupons",
    )
    min_order_value = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    max_discount = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    usage_limit = models.PositiveIntegerField(null=True, blank=True)
    usage_count = models.PositiveIntegerField(default=0)
    user_limit = models.PositiveIntegerField(default=1)  # Per user
    start_date = models.DateTimeField()
    end_date = models.DateTimeField()
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.code} - {self.name}"

    def is_valid(self, user=None, order_value=None):
        from django.utils import timezone
        now = timezone.now()
        if not self.is_active:
            return False, "Coupon is inactive"
        if now < self.start_date or now > self.end_date:
            return False, "Coupon expired"
        if self.usage_limit and self.usage_count >= self.usage_limit:
            return False, "Coupon usage limit reached"
        if user:
            from orders.models import Order
            user_usage = Order.objects.filter(user=user, coupon=self).count()
            if user_usage >= self.user_limit:
                return False, "User usage limit reached"
        if self.applies_to == self.AppliesTo.MIN_ORDER and order_value:
            if order_value < self.min_order_value:
                return False, f"Minimum order value {self.min_order_value} required"
        return True, "Valid"