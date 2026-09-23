from rest_framework import serializers

from categories.models import Category
from products.models import Product
from stores.models import Store

from .models import SectionItem, StoreSection, StorefrontTheme


class StorefrontThemeSerializer(serializers.ModelSerializer):
    class Meta:
        model = StorefrontTheme
        fields = [
            "primary_color",
            "secondary_color",
            "background_color",
            "font_family",
            "logo",
            "hero_image",
            "button_style",
            "effects",
            "updated_at",
        ]
        read_only_fields = ["updated_at"]

    def validate_effects(self, value):
        if not isinstance(value, dict):
            raise serializers.ValidationError("effects must be a JSON object.")
        return value


class SectionItemSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source="product.name", read_only=True)
    product_slug = serializers.CharField(source="product.slug", read_only=True)
    product_price = serializers.SerializerMethodField()
    category_name = serializers.CharField(source="category.name", read_only=True)
    category_slug = serializers.CharField(source="category.slug", read_only=True)

    class Meta:
        model = SectionItem
        fields = [
            "id",
            "item_type",
            "product",
            "product_name",
            "product_slug",
            "product_price",
            "category",
            "category_name",
            "category_slug",
            "caption",
            "image",
            "link",
            "config",
            "position",
        ]

    def get_product_price(self, obj):
        if obj.product_id and obj.product.base_price is not None:
            return str(obj.product.base_price)
        return None

    def validate_config(self, value):
        if not isinstance(value, dict):
            raise serializers.ValidationError("config must be a JSON object.")
        return value

    def validate(self, attrs):
        item_type = attrs.get("item_type", getattr(self.instance, "item_type", SectionItem.ItemType.CUSTOM))
        product = attrs.get("product", getattr(self.instance, "product", None))
        category = attrs.get("category", getattr(self.instance, "category", None))
        caption = attrs.get("caption", getattr(self.instance, "caption", ""))
        image = attrs.get("image", getattr(self.instance, "image", None))

        if item_type == SectionItem.ItemType.PRODUCT and product is None:
            raise serializers.ValidationError(
                {"product": "PRODUCT items need a product."}
            )
        if item_type == SectionItem.ItemType.CATEGORY and category is None:
            raise serializers.ValidationError(
                {"category": "CATEGORY items need a category."}
            )
        if item_type == SectionItem.ItemType.CUSTOM and not (caption or image):
            raise serializers.ValidationError(
                {"caption": "CUSTOM items need a caption or an image."}
            )
        return attrs


class SectionItemWriteSerializer(SectionItemSerializer):
    """Positions are assigned automatically on create (appended to the end);
    use the reorder endpoint to rearrange."""

    position = serializers.IntegerField(required=False)


class StoreSectionSerializer(serializers.ModelSerializer):
    items = SectionItemSerializer(many=True, read_only=True)

    class Meta:
        model = StoreSection
        fields = [
            "id",
            "section_type",
            "title",
            "subtitle",
            "image",
            "config",
            "position",
            "is_active",
            "items",
            "updated_at",
        ]
        read_only_fields = ["position", "updated_at"]

    def validate_config(self, value):
        if not isinstance(value, dict):
            raise serializers.ValidationError("config must be a JSON object.")
        columns = value.get("columns")
        if columns is not None and (
            not isinstance(columns, int) or not (1 <= columns <= 6)
        ):
            raise serializers.ValidationError(
                "config.columns must be an integer between 1 and 6."
            )
        size = value.get("size")
        if size is not None and size not in {"sm", "md", "lg"}:
            raise serializers.ValidationError("config.size must be sm, md or lg.")
        if "effects" in value and not isinstance(value["effects"], (dict, str)):
            raise serializers.ValidationError("config.effects must be an object or string.")
        return value


class StoreSectionWriteSerializer(serializers.ModelSerializer):
    """Write-side section serializer: no nested items (they have their own
    endpoints); position is assigned by the view on create."""

    class Meta:
        model = StoreSection
        fields = [
            "section_type",
            "title",
            "subtitle",
            "image",
            "config",
            "is_active",
        ]

    def validate_config(self, value):
        if not isinstance(value, dict):
            raise serializers.ValidationError("config must be a JSON object.")
        columns = value.get("columns")
        if columns is not None and (
            not isinstance(columns, int) or not (1 <= columns <= 6)
        ):
            raise serializers.ValidationError(
                "config.columns must be an integer between 1 and 6."
            )
        size = value.get("size")
        if size is not None and size not in {"sm", "md", "lg"}:
            raise serializers.ValidationError("config.size must be sm, md or lg.")
        if "effects" in value and not isinstance(value["effects"], (dict, str)):
            raise serializers.ValidationError(
                "config.effects must be an object or string."
            )
        return value


class StorefrontRenderSerializer(serializers.Serializer):
    """The full public payload customer-web/Flutter render in one request."""

    store = serializers.SerializerMethodField()
    theme = serializers.SerializerMethodField()
    sections = serializers.SerializerMethodField()

    def get_store(self, store):
        return {
            "name": store.name,
            "slug": store.slug,
            "city": store.city,
            "description": store.description,
        }

    def get_theme(self, store):
        theme = getattr(store, "storefront_theme", None)
        return StorefrontThemeSerializer(theme).data if theme else None

    def get_sections(self, store):
        qs = store.storefront_sections.filter(is_active=True).prefetch_related(
            "items", "items__product", "items__category"
        )
        return StoreSectionSerializer(qs, many=True).data
