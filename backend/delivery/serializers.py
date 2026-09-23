from django.contrib.auth import get_user_model
from rest_framework import serializers

from orders.models import Order

from .models import DeliveryAssignment

User = get_user_model()

ASSIGNABLE_ORDER_STATUSES = {
    Order.Status.CONFIRMED,
    Order.Status.PREPARING,
    Order.Status.READY,
}


class DeliveryAssignmentSerializer(serializers.ModelSerializer):
    order_number = serializers.CharField(source="order.order_number", read_only=True)
    store_name = serializers.CharField(source="order.store.name", read_only=True)
    agent_email = serializers.EmailField(source="agent.email", read_only=True)

    class Meta:
        model = DeliveryAssignment
        fields = [
            "id",
            "order",
            "order_number",
            "store_name",
            "agent",
            "agent_email",
            "status",
            "note",
            "assigned_at",
            "accepted_at",
            "picked_up_at",
            "delivered_at",
            "cancelled_at",
        ]
        read_only_fields = [
            "id",
            "order_number",
            "store_name",
            "agent_email",
            "status",
            "assigned_at",
            "accepted_at",
            "picked_up_at",
            "delivered_at",
            "cancelled_at",
        ]


class DeliveryAssignSerializer(serializers.Serializer):
    """Assign an agent to an order (manual v1 assignment)."""

    order = serializers.PrimaryKeyRelatedField(queryset=Order.objects.all())
    agent = serializers.PrimaryKeyRelatedField(queryset=User.objects.all())
    note = serializers.CharField(required=False, allow_blank=True, default="")

    def validate_agent(self, value):
        if value.role != User.Role.DELIVERY_AGENT:
            raise serializers.ValidationError("User is not a delivery agent.")
        if not value.is_email_verified:
            raise serializers.ValidationError("Agent email is not verified.")
        if not value.is_active:
            raise serializers.ValidationError("Agent account is not active.")
        return value

    def validate(self, attrs):
        order = attrs["order"]
        if hasattr(order, "delivery_assignment"):
            raise serializers.ValidationError(
                {"order": "Order already has a delivery assignment."}
            )
        if order.status not in ASSIGNABLE_ORDER_STATUSES:
            raise serializers.ValidationError(
                {
                    "order": (
                        f"Order in {order.status} cannot be assigned "
                        "(needs CONFIRMED, PREPARING or READY)."
                    )
                }
            )
        return attrs


class DeliveryStatusUpdateSerializer(serializers.Serializer):
    status = serializers.ChoiceField(
        choices=[
            DeliveryAssignment.Status.ACCEPTED,
            DeliveryAssignment.Status.PICKED_UP,
            DeliveryAssignment.Status.OUT_FOR_DELIVERY,
            DeliveryAssignment.Status.DELIVERED,
            DeliveryAssignment.Status.CANCELLED,
        ]
    )
    note = serializers.CharField(required=False, allow_blank=True, default="")
