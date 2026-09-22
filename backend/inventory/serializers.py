from rest_framework import serializers

from products.serializers import VariantBriefSerializer
from stores.serializers import StoreBriefSerializer

from .models import InventoryTransaction, StockItem


class StockItemListSerializer(serializers.ModelSerializer):
    store = StoreBriefSerializer(read_only=True)
    variant = VariantBriefSerializer(read_only=True)
    is_available = serializers.BooleanField(read_only=True)
    is_low_stock = serializers.BooleanField(read_only=True)

    class Meta:
        model = StockItem
        fields = [
            "id",
            "store",
            "variant",
            "quantity",
            "low_stock_threshold",
            "is_available",
            "is_low_stock",
            "updated_at",
        ]
        read_only_fields = fields


class StockItemWriteSerializer(serializers.ModelSerializer):
    id = serializers.IntegerField(read_only=True)

    class Meta:
        model = StockItem
        fields = [
            "id",
            "store",
            "variant",
            "quantity",
            "low_stock_threshold",
        ]

    def create(self, validated_data):
        store = validated_data["store"]
        variant = validated_data["variant"]
        if (
            store.tenant_id
            and variant.product.tenant_id
            and store.tenant_id != variant.product.tenant_id
        ):
            raise serializers.ValidationError(
                {"variant": "Variant does not belong to this store's tenant."}
            )
        validated_data["tenant"] = store.tenant
        return super().create(validated_data)


class StockItemAdjustSerializer(serializers.Serializer):
    """Adjust stock by +N or -N. Writes an InventoryTransaction."""

    change = serializers.IntegerField(min_value=None)
    reason = serializers.ChoiceField(choices=InventoryTransaction.Reason.choices)
    note = serializers.CharField(max_length=255, required=False, allow_blank=True)

    def validate_change(self, value):
        if value == 0:
            raise serializers.ValidationError("Change must be non-zero.")
        return value


class InventoryTransactionSerializer(serializers.ModelSerializer):
    reason_label = serializers.CharField(source="get_reason_display", read_only=True)

    class Meta:
        model = InventoryTransaction
        fields = [
            "id",
            "stock_item",
            "change",
            "reason",
            "reason_label",
            "note",
            "performed_by",
            "created_at",
        ]
        read_only_fields = ["id", "performed_by", "created_at"]
