import uuid

from django.conf import settings
from django.db import models
from django.utils import timezone


class DailyMetrics(models.Model):
    """Pre-aggregated daily metrics for dashboards."""

    date = models.DateField(unique=True)
    # User metrics
    new_users = models.PositiveIntegerField(default=0)
    active_users = models.PositiveIntegerField(default=0)
    returning_users = models.PositiveIntegerField(default=0)
    # Order metrics
    total_orders = models.PositiveIntegerField(default=0)
    completed_orders = models.PositiveIntegerField(default=0)
    cancelled_orders = models.PositiveIntegerField(default=0)
    gmv = models.DecimalField(max_digits=14, decimal_places=2, default=0)  # Gross Merchandise Value
    aov = models.DecimalField(max_digits=10, decimal_places=2, default=0)  # Average Order Value
    # Product metrics
    products_viewed = models.PositiveIntegerField(default=0)
    products_added_to_cart = models.PositiveIntegerField(default=0)
    # Revenue metrics
    revenue = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    refunds = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    net_revenue = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    # Conversion
    conversion_rate = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-date"]
        indexes = [
            models.Index(fields=["-date"]),
        ]

    def __str__(self):
        return f"Metrics {self.date}"

    def save(self, *args, **kwargs):
        if self.total_orders > 0:
            self.aov = self.gmv / self.total_orders
        if self.total_orders > 0:
            self.conversion_rate = (self.completed_orders / self.total_orders) * 100
        self.net_revenue = self.revenue - self.refunds
        super().save(*args, **kwargs)


class UserEvent(models.Model):
    """Raw user events for funnel analysis."""

    class EventType(models.TextChoices):
        PAGE_VIEW = "PAGE_VIEW", "Page View"
        PRODUCT_VIEW = "PRODUCT_VIEW", "Product View"
        ADD_TO_CART = "ADD_TO_CART", "Add to Cart"
        REMOVE_FROM_CART = "REMOVE_FROM_CART", "Remove from Cart"
        CHECKOUT_START = "CHECKOUT_START", "Checkout Start"
        PAYMENT_ATTEMPT = "PAYMENT_ATTEMPT", "Payment Attempt"
        ORDER_COMPLETE = "ORDER_COMPLETE", "Order Complete"
        ORDER_CANCEL = "ORDER_CANCEL", "Order Cancel"
        SEARCH = "SEARCH", "Search"
        CATEGORY_BROWSE = "CATEGORY_BROWSE", "Category Browse"
        LOGIN = "LOGIN", "Login"
        SIGNUP = "SIGNUP", "Sign Up"
        APP_OPEN = "APP_OPEN", "App Open"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="events",
    )
    session_id = models.CharField(max_length=64, db_index=True)
    event_type = models.CharField(max_length=20, choices=EventType.choices)
    properties = models.JSONField(default=dict, blank=True)
    timestamp = models.DateTimeField(default=timezone.now, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-timestamp"]
        indexes = [
            models.Index(fields=["user", "timestamp"]),
            models.Index(fields=["event_type", "timestamp"]),
            models.Index(fields=["session_id", "timestamp"]),
        ]

    def __str__(self):
        return f"{self.event_type} - {self.user or 'anon'} - {self.timestamp}"


class FunnelStep(models.Model):
    """Funnel configuration."""

    name = models.CharField(max_length=100)
    event_type = models.CharField(max_length=20, choices=UserEvent.EventType.choices)
    order = models.PositiveIntegerField()
    is_required = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["order"]
        unique_together = [["name", "order"]]

    def __str__(self):
        return f"{self.name} - Step {self.order}: {self.event_type}"


class FunnelAnalysis(models.Model):
    """Pre-computed funnel analysis results."""

    funnel_name = models.CharField(max_length=100)
    date = models.DateField()
    step_order = models.PositiveIntegerField()
    event_type = models.CharField(max_length=20)
    entered = models.PositiveIntegerField(default=0)
    completed = models.PositiveIntegerField(default=0)
    conversion_rate = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    avg_time_seconds = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["funnel_name", "date", "step_order"]
        unique_together = [["funnel_name", "date", "step_order"]]

    def __str__(self):
        return f"{self.funnel_name} {self.date} Step {self.step_order}"

    def save(self, *args, **kwargs):
        if self.entered > 0:
            self.conversion_rate = round((self.completed / self.entered) * 100, 2)
        else:
            self.conversion_rate = 0
        super().save(*args, **kwargs)


class RetentionCohort(models.Model):
    """User retention cohorts."""

    cohort_date = models.DateField()
    period = models.PositiveIntegerField()  # 0=day0, 1=day1, 7=day7, 30=day30
    users_in_cohort = models.PositiveIntegerField()
    users_active = models.PositiveIntegerField()
    retention_rate = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-cohort_date", "period"]
        unique_together = [["cohort_date", "period"]]

    def __str__(self):
        return f"Cohort {self.cohort_date} Day {self.period}: {self.retention_rate}%"

    def save(self, *args, **kwargs):
        if self.users_in_cohort > 0:
            self.retention_rate = round((self.users_active / self.users_in_cohort) * 100, 2)
        else:
            self.retention_rate = 0
        super().save(*args, **kwargs)


class RevenueByChannel(models.Model):
    """Revenue breakdown by acquisition channel."""

    date = models.DateField()
    channel = models.CharField(max_length=50)
    orders = models.PositiveIntegerField(default=0)
    revenue = models.DecimalField(max_digits=14, decimal_places=2, default=0)
    new_customers = models.PositiveIntegerField(default=0)
    returning_customers = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-date", "channel"]
        unique_together = [["date", "channel"]]


class ProductPerformance(models.Model):
    """Product-level analytics."""

    date = models.DateField()
    product_id = models.UUIDField()
    product_name = models.CharField(max_length=255)
    views = models.PositiveIntegerField(default=0)
    add_to_carts = models.PositiveIntegerField(default=0)
    purchases = models.PositiveIntegerField(default=0)
    revenue = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    conversion_rate = models.DecimalField(max_digits=5, decimal_places=2, default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-date", "-revenue"]
        unique_together = [["date", "product_id"]]

    def __str__(self):
        return f"{self.product_name} ({self.date})"

    def save(self, *args, **kwargs):
        if self.views > 0:
            self.conversion_rate = round((self.purchases / self.views) * 100, 2)
        else:
            self.conversion_rate = 0
        super().save(*args, **kwargs)