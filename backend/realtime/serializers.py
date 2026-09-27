from rest_framework import serializers

from .models import (
    ChatMessage,
    ChatRoom,
    Device,
    InventorySubscription,
    WebSocketConnection,
)


class DeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Device
        fields = [
            "id",
            "platform",
            "device_token",
            "user_agent",
            "is_active",
            "last_seen",
            "created_at",
        ]
        read_only_fields = ["id", "last_seen", "created_at"]


class DeviceRegisterSerializer(serializers.ModelSerializer):
    class Meta:
        model = Device
        fields = ["platform", "device_token", "user_agent"]

    def create(self, validated_data):
        user = self.context["request"].user
        device, _ = Device.objects.update_or_create(
            user=user,
            device_token=validated_data["device_token"],
            defaults={
                "platform": validated_data["platform"],
                "user_agent": validated_data.get("user_agent", ""),
                "is_active": True,
            },
        )
        return device


class WebSocketConnectionSerializer(serializers.ModelSerializer):
    class Meta:
        model = WebSocketConnection
        fields = [
            "id",
            "channel_name",
            "channel_type",
            "session_key",
            "connected_at",
            "last_ping",
            "is_active",
        ]
        read_only_fields = fields


class ChatRoomSerializer(serializers.ModelSerializer):
    participant_emails = serializers.SerializerMethodField()
    last_message = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()

    class Meta:
        model = ChatRoom
        fields = [
            "id",
            "name",
            "type",
            "participants",
            "participant_emails",
            "order",
            "last_message",
            "unread_count",
            "is_active",
            "created_at",
            "updated_at",
        ]
        # participants is read-only: membership changes go through
        # add_participant/remove_participant (staff-only). perform_create adds
        # the creator.
        read_only_fields = ["id", "participants", "created_at", "updated_at"]

    def validate_order(self, value):
        if value is None:
            return value
        request = self.context.get("request")
        if request and value.user_id != request.user.id and not request.user.is_staff:
            raise serializers.ValidationError("You are not part of this order.")
        return value

    def get_participant_emails(self, obj):
        return list(obj.participants.values_list("email", flat=True))

    def get_last_message(self, obj):
        msg = obj.messages.order_by("-created_at").first()
        if msg:
            return {
                "id": str(msg.id),
                "content": msg.content[:100],
                "sender": msg.sender.email,
                "created_at": msg.created_at,
            }
        return None

    def get_unread_count(self, obj):
        request = self.context.get("request")
        if request and request.user.is_authenticated:
            return obj.messages.filter(is_read=False).exclude(sender=request.user).count()
        return 0


class ChatMessageSerializer(serializers.ModelSerializer):
    sender_email = serializers.EmailField(source="sender.email", read_only=True)

    class Meta:
        model = ChatMessage
        fields = [
            "id",
            "room",
            "sender",
            "sender_email",
            "message_type",
            "content",
            "attachment_url",
            "reply_to",
            "is_read",
            "created_at",
            "updated_at",
        ]
        read_only_fields = ["id", "sender", "created_at", "updated_at"]

    def validate_room(self, value):
        request = self.context.get("request")
        if request and request.user.is_authenticated:
            if not request.user.is_staff and not value.participants.filter(
                id=request.user.id
            ).exists():
                raise serializers.ValidationError(
                    "You are not a participant of this room."
                )
        return value

    def validate(self, attrs):
        room = attrs.get("room")
        reply_to = attrs.get("reply_to")
        if room is not None and reply_to is not None and reply_to.room_id != room.id:
            raise serializers.ValidationError(
                {"reply_to": "Reply target belongs to a different room."}
            )
        return attrs


class InventorySubscriptionSerializer(serializers.ModelSerializer):
    variant_sku = serializers.CharField(source="product_variant.sku", read_only=True)
    variant_name = serializers.CharField(source="product_variant.name", read_only=True)
    product_name = serializers.CharField(source="product_variant.product.name", read_only=True)

    class Meta:
        model = InventorySubscription
        fields = [
            "id",
            "product_variant",
            "variant_sku",
            "variant_name",
            "product_name",
            "trigger",
            "threshold",
            "is_active",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]


class InventorySubscriptionCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = InventorySubscription
        fields = ["product_variant", "trigger", "threshold"]

    def validate(self, attrs):
        trigger = attrs.get("trigger")
        if trigger == "LOW_STOCK" and not attrs.get("threshold"):
            raise serializers.ValidationError("Threshold required for LOW_STOCK trigger")
        return attrs

    def create(self, validated_data):
        validated_data["user"] = self.context["request"].user
        return super().create(validated_data)