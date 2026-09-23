from rest_framework import serializers

from .models import Notification, NotificationPreference, NotificationTemplate


class NotificationTemplateSerializer(serializers.ModelSerializer):
    class Meta:
        model = NotificationTemplate
        fields = [
            "id",
            "name",
            "channel",
            "subject_template",
            "body_template",
            "is_active",
            "created_at",
        ]
        read_only_fields = ["id", "created_at"]


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = [
            "id",
            "template",
            "channel",
            "subject",
            "body",
            "priority",
            "status",
            "data",
            "sent_at",
            "delivered_at",
            "read_at",
            "created_at",
        ]
        read_only_fields = fields


class NotificationListSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = [
            "id",
            "channel",
            "subject",
            "priority",
            "status",
            "created_at",
        ]
        read_only_fields = fields


class NotificationPreferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = NotificationPreference
        fields = ["id", "event_type", "channel", "is_enabled", "updated_at"]
        read_only_fields = ["id", "updated_at"]


class NotificationSendSerializer(serializers.Serializer):
    """Send ad-hoc notification."""

    user_ids = serializers.ListField(
        child=serializers.UUIDField(), min_length=1, max_length=1000
    )
    channel = serializers.ChoiceField(choices=NotificationTemplate.Channel.choices)
    subject = serializers.CharField(max_length=200)
    body = serializers.CharField()
    priority = serializers.ChoiceField(
        choices=Notification.Priority.choices, default=Notification.Priority.NORMAL
    )
    data = serializers.JSONField(required=False, default=dict)