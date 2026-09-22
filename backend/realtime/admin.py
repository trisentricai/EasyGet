from django.contrib import admin

from .models import ChatMessage, ChatRoom, Device, InventorySubscription, WebSocketConnection


@admin.register(Device)
class DeviceAdmin(admin.ModelAdmin):
    list_display = ("user", "platform", "device_token", "is_active", "last_seen", "created_at")
    list_filter = ("platform", "is_active", "created_at")
    search_fields = ("user__email", "device_token")
    readonly_fields = ("last_seen", "created_at")
    list_per_page = 25


@admin.register(WebSocketConnection)
class WebSocketConnectionAdmin(admin.ModelAdmin):
    list_display = ("user", "channel_type", "channel_name", "connected_at", "last_ping", "is_active")
    list_filter = ("channel_type", "is_active")
    search_fields = ("user__email", "channel_name", "session_key")
    readonly_fields = ("connected_at", "last_ping")
    list_per_page = 50

    def has_add_permission(self, request):
        return False


@admin.register(ChatRoom)
class ChatRoomAdmin(admin.ModelAdmin):
    list_display = ("name", "type", "order", "participant_count", "message_count", "is_active", "updated_at")
    list_filter = ("type", "is_active", "created_at")
    search_fields = ("name", "participants__email")
    filter_horizontal = ("participants",)
    list_per_page = 25

    def participant_count(self, obj):
        return obj.participants.count()

    def message_count(self, obj):
        return obj.messages.count()


@admin.register(ChatMessage)
class ChatMessageAdmin(admin.ModelAdmin):
    list_display = ("room", "sender", "message_type", "content_preview", "is_read", "created_at")
    list_filter = ("message_type", "is_read", "created_at")
    search_fields = ("content", "sender__email", "room__name")
    readonly_fields = ("sender", "room", "message_type", "content", "attachment_url", "reply_to", "created_at", "updated_at")
    list_per_page = 50

    def content_preview(self, obj):
        return obj.content[:100]

    def has_add_permission(self, request):
        return False


@admin.register(InventorySubscription)
class InventorySubscriptionAdmin(admin.ModelAdmin):
    list_display = ("user", "product_variant", "trigger", "threshold", "is_active", "created_at")
    list_filter = ("trigger", "is_active", "created_at")
    search_fields = ("user__email", "product_variant__sku", "product_variant__product__name")
    list_per_page = 25