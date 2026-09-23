from rest_framework import serializers

from products.models import ProductVariant
from products.serializers import VariantBriefSerializer

from .models import Cart, CartItem


class CartItemSerializer(serializers.ModelSerializer):
    variant = VariantBriefSerializer(read_only=True)
    variant_id = serializers.PrimaryKeyRelatedField(
        queryset=ProductVariant.objects.filter(is_active=True, product__is_active=True),
        source="variant",
        write_only=True,
    )
    line_total = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)

    class Meta:
        model = CartItem
        fields = ["id", "variant", "variant_id", "quantity", "line_total", "created_at"]
        read_only_fields = ["id", "line_total", "created_at"]

    def validate_quantity(self, value):
        if value > 999:
            raise serializers.ValidationError("Quantity cannot exceed 999")
        return value


class CartSerializer(serializers.ModelSerializer):
    items = CartItemSerializer(many=True, read_only=True)
    total_items = serializers.IntegerField(read_only=True)
    subtotal = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)

    class Meta:
        model = Cart
        fields = [
            "id",
            "store",
            "items",
            "total_items",
            "subtotal",
            "created_at",
            "updated_at",
        ]
        read_only_fields = fields


class CartWriteSerializer(serializers.ModelSerializer):
    items = CartItemSerializer(many=True, required=False)

    class Meta:
        model = Cart
        fields = ["store", "items"]

    def create(self, validated_data):
        items_data = validated_data.pop("items", [])
        cart = Cart.objects.create(**validated_data)
        for item_data in items_data:
            CartItem.objects.create(cart=cart, **item_data)
        return cart