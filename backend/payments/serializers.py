from rest_framework import serializers

from .models import Payment, PaymentMethod, Refund


class PaymentMethodSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaymentMethod
        fields = [
            "id",
            "type",
            "is_default",
            "card_last4",
            "card_brand",
            "card_exp_month",
            "card_exp_year",
            "upi_id",
            "wallet_provider",
            "is_active",
            "created_at",
        ]
        read_only_fields = fields


class PaymentMethodCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaymentMethod
        fields = [
            "type",
            "is_default",
            "card_last4",
            "card_brand",
            "card_exp_month",
            "card_exp_year",
            "upi_id",
            "wallet_provider",
            "gateway_token",
            "gateway_customer_id",
        ]

    def validate(self, attrs):
        method_type = attrs.get("type")
        if method_type == PaymentMethod.Type.CARD:
            required = ["card_last4", "card_brand", "card_exp_month", "card_exp_year"]
            for field in required:
                if not attrs.get(field):
                    raise serializers.ValidationError(
                        {field: f"Required for card type"}
                    )
        elif method_type == PaymentMethod.Type.UPI:
            if not attrs.get("upi_id"):
                raise serializers.ValidationError({"upi_id": "Required for UPI"})
        return attrs


class PaymentSerializer(serializers.ModelSerializer):
    payment_method = PaymentMethodSerializer(read_only=True)
    order_number = serializers.CharField(source="order.order_number", read_only=True)

    class Meta:
        model = Payment
        fields = [
            "id",
            "payment_id",
            "order",
            "order_number",
            "payment_method",
            "gateway",
            "status",
            "amount",
            "currency",
            "gateway_payment_id",
            "gateway_order_id",
            "failure_reason",
            "refunded_amount",
            "processed_at",
            "created_at",
            "updated_at",
        ]
        read_only_fields = fields


class PaymentCreateSerializer(serializers.ModelSerializer):
    """Create payment for an order."""

    payment_method_id = serializers.UUIDField(write_only=True, required=False)

    class Meta:
        model = Payment
        fields = [
            "order",
            "payment_method_id",
            "gateway",
            "amount",
        ]

    def validate(self, attrs):
        order = attrs.get("order")
        request = self.context.get("request")
        if (
            order is not None
            and request
            and not request.user.is_staff
            and order.user_id != request.user.id
        ):
            # Same message as a missing order — no existence leak.
            raise serializers.ValidationError({"order": "Order not found."})
        if hasattr(order, "payment"):
            raise serializers.ValidationError("Order already has a payment")
        if order.total != attrs.get("amount"):
            raise serializers.ValidationError("Payment amount must match order total")
        return attrs


class RefundSerializer(serializers.ModelSerializer):
    class Meta:
        model = Refund
        fields = [
            "id",
            "refund_id",
            "payment",
            "amount",
            "reason",
            "status",
            "gateway_refund_id",
            "processed_at",
            "created_at",
        ]
        read_only_fields = fields


class RefundCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Refund
        fields = ["amount", "reason"]

    def validate(self, attrs):
        payment = self.context.get("payment")
        if payment is None:
            raise serializers.ValidationError("Refund context missing payment.")
        if payment.status != Payment.Status.SUCCEEDED:
            raise serializers.ValidationError("Can only refund successful payments")
        if attrs.get("amount") > payment.amount - payment.refunded_amount:
            raise serializers.ValidationError("Refund amount exceeds refundable amount")
        return attrs