from rest_framework import serializers

from products.serializers import VariantBriefSerializer

from .models import Order, OrderItem, OrderStatusHistory


class OrderItemSerializer(serializers.ModelSerializer):
    variant = VariantBriefSerializer(read_only=True)

    class Meta:
        model = OrderItem
        fields = [
            "id",
            "variant",
            "product_name",
            "variant_name",
            "sku",
            "unit_price",
            "quantity",
            "line_total",
            "created_at",
        ]
        read_only_fields = fields


class OrderStatusHistorySerializer(serializers.ModelSerializer):
    changed_by_email = serializers.EmailField(source="changed_by.email", read_only=True)

    class Meta:
        model = OrderStatusHistory
        fields = [
            "id",
            "from_status",
            "to_status",
            "changed_by",
            "changed_by_email",
            "note",
            "created_at",
        ]
        read_only_fields = fields


class OrderListSerializer(serializers.ModelSerializer):
    item_count = serializers.IntegerField(source="items.count", read_only=True)

    class Meta:
        model = Order
        fields = [
            "id",
            "order_number",
            "store",
            "status",
            "subtotal",
            "delivery_fee",
            "discount",
            "total",
            "item_count",
            "estimated_delivery_at",
            "delivered_at",
            "created_at",
        ]
        read_only_fields = fields


class OrderDetailSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    status_history = OrderStatusHistorySerializer(many=True, read_only=True)
    store_name = serializers.CharField(source="store.name", read_only=True)

    class Meta:
        model = Order
        fields = [
            "id",
            "order_number",
            "store",
            "store_name",
            "status",
            "subtotal",
            "delivery_fee",
            "discount",
            "total",
            "delivery_address",
            "delivery_instructions",
            "estimated_delivery_at",
            "delivered_at",
            "cancelled_at",
            "cancellation_reason",
            "items",
            "status_history",
            "created_at",
            "updated_at",
        ]
        read_only_fields = fields


class OrderCreateSerializer(serializers.ModelSerializer):
    """Create order from cart."""

    cart_id = serializers.UUIDField(write_only=True)
    delivery_address = serializers.JSONField()
    delivery_instructions = serializers.CharField(required=False, allow_blank=True)

    class Meta:
        model = Order
        fields = [
            "cart_id",
            "store",
            "delivery_address",
            "delivery_instructions",
        ]

    def validate_cart_id(self, value):
        from cart.models import Cart
        user = self.context["request"].user
        try:
            cart = Cart.objects.get(id=value, user=user)
        except Cart.DoesNotExist:
            raise serializers.ValidationError("Cart not found or not yours")
        if cart.total_items == 0:
            raise serializers.ValidationError("Cart is empty")
        return cart


class OrderStatusUpdateSerializer(serializers.ModelSerializer):
    note = serializers.CharField(required=False, allow_blank=True)

    class Meta:
        model = Order
        fields = ["status", "note"]

    def validate_status(self, value):
        valid_transitions = {
            Order.Status.PENDING: {Order.Status.CONFIRMED, Order.Status.CANCELLED},
            Order.Status.CONFIRMED: {Order.Status.PREPARING, Order.Status.CANCELLED},
            Order.Status.PREPARING: {Order.Status.READY, Order.Status.CANCELLED},
            Order.Status.READY: {Order.Status.OUT_FOR_DELIVERY, Order.Status.CANCELLED},
            Order.Status.OUT_FOR_DELIVERY: {Order.Status.DELIVERED},
            Order.Status.DELIVERED: {Order.Status.REFUNDED},
        }
        current = self.instance.status
        if value not in valid_transitions.get(current, set()):
            raise serializers.ValidationError(
                f"Cannot transition from {current} to {value}"
            )
        return value

    def update(self, instance, validated_data):
        note = validated_data.pop("note", "")
        old_status = instance.status
        instance = super().update(instance, validated_data)
        if instance.status != old_status:
            OrderStatusHistory.objects.create(
                order=instance,
                from_status=old_status,
                to_status=instance.status,
                changed_by=self.context["request"].user,
                note=note,
            )
        return instance


class OrderCancelSerializer(serializers.Serializer):
    reason = serializers.CharField(required=True)