from rest_framework import serializers

from .models import WebhookDelivery, WebhookEndpoint, WebhookEventLog


class WebhookEndpointSerializer(serializers.ModelSerializer):
    class Meta:
        model = WebhookEndpoint
        fields = [
            "id", "name", "url", "secret", "events", "is_active",
            "retry_count", "timeout_seconds", "headers",
            "created_by", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at", "created_by"]

    def validate_events(self, value):
        from .models import WebhookEndpoint
        valid_events = [e.value for e in WebhookEndpoint.Event]
        for event in value:
            if event not in valid_events and event != "*":
                raise serializers.ValidationError(f"Invalid event: {event}")
        return value


class WebhookDeliverySerializer(serializers.ModelSerializer):
    class Meta:
        model = WebhookDelivery
        fields = [
            "id", "endpoint", "event", "payload", "status",
            "response_status", "response_body", "attempt",
            "error", "sent_at", "completed_at", "created_at",
        ]
        read_only_fields = fields


class WebhookEventLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = WebhookEventLog
        fields = ["id", "event_type", "payload", "triggered_webhooks", "created_at"]
        read_only_fields = fields


class WebhookTestSerializer(serializers.Serializer):
    """Test webhook delivery."""
    event = serializers.ChoiceField(choices=WebhookEndpoint.Event.choices)
    payload = serializers.JSONField(default=dict)