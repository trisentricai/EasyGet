import uuid

from django.conf import settings
from django.db import models
from django.utils import timezone


class PWAConfigModel(models.Model):
    """PWA configuration settings."""

    name = models.CharField(max_length=100, default="EasyGet")
    short_name = models.CharField(max_length=20, default="EasyGet")
    description = models.TextField(blank=True, default="Quick Commerce Platform")
    theme_color = models.CharField(max_length=7, default="#2563eb")
    background_color = models.CharField(max_length=7, default="#ffffff")
    display = models.CharField(max_length=20, default="standalone")
    orientation = models.CharField(max_length=20, default="portrait-primary")
    scope = models.CharField(max_length=100, default="/")
    start_url = models.CharField(max_length=100, default="/")
    icons = models.JSONField(default=list)  # List of {src, sizes, type, purpose}
    screenshots = models.JSONField(default=list)
    categories = models.JSONField(default=list)
    shortcuts = models.JSONField(default=list)
    related_applications = models.JSONField(default=list)
    prefer_related_applications = models.BooleanField(default=False)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "PWA Config"
        verbose_name_plural = "PWA Config"

    def __str__(self):
        return f"PWA Config: {self.name}"

    def get_manifest(self):
        return {
            "name": self.name,
            "short_name": self.short_name,
            "description": self.description,
            "theme_color": self.theme_color,
            "background_color": self.background_color,
            "display": self.display,
            "orientation": self.orientation,
            "scope": self.scope,
            "start_url": self.start_url,
            "icons": self.icons or [
                {"src": "/static/pwa/icon-72.png", "sizes": "72x72", "type": "image/png"},
                {"src": "/static/pwa/icon-96.png", "sizes": "96x96", "type": "image/png"},
                {"src": "/static/pwa/icon-128.png", "sizes": "128x128", "type": "image/png"},
                {"src": "/static/pwa/icon-144.png", "sizes": "144x144", "type": "image/png"},
                {"src": "/static/pwa/icon-152.png", "sizes": "152x152", "type": "image/png"},
                {"src": "/static/pwa/icon-192.png", "sizes": "192x192", "type": "image/png", "purpose": "any maskable"},
                {"src": "/static/pwa/icon-384.png", "sizes": "384x384", "type": "image/png"},
                {"src": "/static/pwa/icon-512.png", "sizes": "512x512", "type": "image/png"},
            ],
            "screenshots": self.screenshots or [],
            "categories": self.categories or ["shopping", "food"],
            "shortcuts": self.shortcuts or [],
            "related_applications": self.related_applications or [],
            "prefer_related_applications": self.prefer_related_applications,
        }


class OfflineData(models.Model):
    """Cached data for offline support."""

    class DataType(models.TextChoices):
        PRODUCTS = "PRODUCTS", "Products"
        CATEGORIES = "CATEGORIES", "Categories"
        STORES = "STORES", "Stores"
        CART = "CART", "Cart"
        ORDERS = "ORDERS", "Orders"
        USER_PROFILE = "USER_PROFILE", "User Profile"
        SETTINGS = "SETTINGS", "Settings"

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="offline_data",
    )
    data_type = models.CharField(max_length=20, choices=DataType.choices)
    key = models.CharField(max_length=200)
    data = models.JSONField()
    expires_at = models.DateTimeField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = [["user", "data_type", "key"]]
        ordering = ["-updated_at"]

    def __str__(self):
        return f"{self.user.email} - {self.data_type} - {self.key}"

    def is_expired(self):
        return timezone.now() > self.expires_at


class PushSubscription(models.Model):
    """Web Push subscription for PWA."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="push_subscriptions",
    )
    endpoint = models.URLField()
    p256dh = models.CharField(max_length=100)
    auth = models.CharField(max_length=50)
    user_agent = models.TextField(blank=True, default="")
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = [["user", "endpoint"]]
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.user.email} - {self.endpoint[:50]}..."

    def get_subscription_info(self):
        return {
            "endpoint": self.endpoint,
            "keys": {
                "p256dh": self.p256dh,
                "auth": self.auth,
            },
        }


class AppUpdate(models.Model):
    """App update management."""

    class Platform(models.TextChoices):
        ANDROID = "ANDROID", "Android"
        IOS = "IOS", "iOS"
        WEB = "WEB", "Web"

    class Status(models.TextChoices):
        DRAFT = "DRAFT", "Draft"
        PENDING = "PENDING", "Pending Review"
        APPROVED = "APPROVED", "Approved"
        REJECTED = "REJECTED", "Rejected"
        DEPLOYED = "DEPLOYED", "Deployed"

    version = models.CharField(max_length=20)
    platform = models.CharField(max_length=10, choices=Platform.choices)
    release_notes = models.TextField()
    download_url = models.URLField(blank=True, default="")
    is_mandatory = models.BooleanField(default=False)
    min_supported_version = models.CharField(max_length=20, blank=True, default="")
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.DRAFT)
    released_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-created_at"]
        unique_together = [["platform", "version"]]

    def __str__(self):
        return f"v{self.version} ({self.platform})"