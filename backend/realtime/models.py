import uuid

from django.conf import settings
from django.db import models
from django.utils import timezone


class Device(models.Model):
    """User device for push notifications and WebSocket sessions."""

    class Platform(models.TextChoices):
        IOS = "IOS", "iOS"
        ANDROID = "ANDROID", "Android"
        WEB = "WEB", "Web"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="devices",
    )
    platform = models.CharField(max_length=10, choices=Platform.choices)
    device_token = models.CharField(max_length=255, blank=True, default="")
    user_agent = models.TextField(blank=True, default="")
    is_active = models.BooleanField(default=True)
    last_seen = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [["user", "device_token"]]
        ordering = ["-last_seen"]

    def __str__(self):
        return f"{self.user.email} - {self.platform}"


class WebSocketConnection(models.Model):
    """Track active WebSocket connections."""

    class ChannelType(models.TextChoices):
        NOTIFICATIONS = "NOTIFICATIONS", "Notifications"
        ORDER_TRACKING = "ORDER_TRACKING", "Order Tracking"
        INVENTORY = "INVENTORY", "Inventory Updates"
        CHAT = "CHAT", "Chat"
        DASHBOARD = "DASHBOARD", "Dashboard"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="ws_connections",
    )
    channel_name = models.CharField(max_length=100)
    channel_type = models.CharField(max_length=20, choices=ChannelType.choices)
    session_key = models.CharField(max_length=64, blank=True, default="")
    connected_at = models.DateTimeField(auto_now_add=True)
    last_ping = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        indexes = [
            models.Index(fields=["user", "is_active"]),
            models.Index(fields=["channel_type", "is_active"]),
        ]

    def __str__(self):
        return f"{self.user.email} - {self.channel_type}"


class ChatRoom(models.Model):
    """Chat room for support/ticket system."""

    class RoomType(models.TextChoices):
        SUPPORT = "SUPPORT", "Customer Support"
        ORDER = "ORDER", "Order Discussion"
        GROUP = "GROUP", "Group Chat"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200)
    type = models.CharField(max_length=20, choices=RoomType.choices, default=RoomType.SUPPORT)
    participants = models.ManyToManyField(
        settings.AUTH_USER_MODEL,
        related_name="chat_rooms",
    )
    order = models.ForeignKey(
        "orders.Order",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="chat_rooms",
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["-updated_at"]

    def __str__(self):
        return f"{self.name} ({self.type})"


class ChatMessage(models.Model):
    """Chat message in a room."""

    class MessageType(models.TextChoices):
        TEXT = "TEXT", "Text"
        IMAGE = "IMAGE", "Image"
        FILE = "FILE", "File"
        SYSTEM = "SYSTEM", "System"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    room = models.ForeignKey(
        ChatRoom,
        on_delete=models.CASCADE,
        related_name="messages",
    )
    sender = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="sent_messages",
    )
    message_type = models.CharField(max_length=10, choices=MessageType.choices, default=MessageType.TEXT)
    content = models.TextField()
    attachment_url = models.URLField(blank=True, default="")
    reply_to = models.ForeignKey(
        "self",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="replies",
    )
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["created_at"]
        indexes = [
            models.Index(fields=["room", "created_at"]),
            models.Index(fields=["sender", "created_at"]),
        ]

    def __str__(self):
        return f"{self.sender.email} in {self.room.name}: {self.content[:50]}"


class InventorySubscription(models.Model):
    """User/merchant subscriptions to inventory changes."""

    class Trigger(models.TextChoices):
        LOW_STOCK = "LOW_STOCK", "Low Stock"
        OUT_OF_STOCK = "OUT_OF_STOCK", "Out of Stock"
        RESTOCK = "RESTOCK", "Restock"
        PRICE_CHANGE = "PRICE_CHANGE", "Price Change"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="inventory_subscriptions",
    )
    product_variant = models.ForeignKey(
        "products.ProductVariant",
        on_delete=models.CASCADE,
        related_name="subscriptions",
    )
    trigger = models.CharField(max_length=20, choices=Trigger.choices)
    threshold = models.PositiveIntegerField(null=True, blank=True)  # For low stock
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = [["user", "product_variant", "trigger"]]

    def __str__(self):
        return f"{self.user.email} - {self.product_variant.sku} - {self.trigger}"