from decimal import Decimal

from django.utils.text import slugify
from rest_framework import serializers

from categories.serializers import CategoryBriefSerializer

from .models import Product, ProductImage, ProductVariant


class ProductImageListSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductImage
        fields = ["id", "image", "caption", "is_primary", "sort_order"]
        read_only_fields = fields


class ProductImageWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductImage
        fields = ["image", "caption", "is_primary", "sort_order"]


class ProductVariantListSerializer(serializers.ModelSerializer):
    discount_percent = serializers.IntegerField(read_only=True)

    class Meta:
        model = ProductVariant
        fields = [
            "id",
            "name",
            "sku",
            "price",
            "discount_percent",
            "is_active",
        ]
        read_only_fields = fields


class ProductVariantWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductVariant
        fields = ["name", "sku", "attributes", "price", "is_active"]


class VariantBriefSerializer(serializers.ModelSerializer):
    """Tiny variant payload referenced by inventory/cart modules."""

    class Meta:
        model = ProductVariant
        fields = ["id", "name", "sku", "attributes", "price", "is_active"]
        read_only_fields = fields


class ProductListSerializer(serializers.ModelSerializer):
    category = CategoryBriefSerializer(read_only=True)
    discount_percent = serializers.SerializerMethodField()
    base_price = serializers.SerializerMethodField()
    primary_image = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = [
            "id",
            "name",
            "slug",
            "category",
            "brand",
            "mrp",
            "base_price",
            "discount_percent",
            "is_featured",
            "is_active",
            "primary_image",
        ]
        read_only_fields = fields

    def get_base_price(self, obj):
        # Use annotated min_variant_price when available (list view) to
        # avoid N+1 queries over remote DB (Supabase). Fall back to property.
        annotated = getattr(obj, "min_variant_price", None)
        price = annotated if annotated is not None else obj.base_price
        return str(price) if price is not None else None

    def get_discount_percent(self, obj):
        annotated = getattr(obj, "min_variant_price", None)
        base = annotated if annotated is not None else obj.base_price
        if obj.mrp and base is not None and Decimal(obj.mrp) > 0:
            return int(round((Decimal(obj.mrp) - base) / Decimal(obj.mrp) * 100))
        return 0

    def get_primary_image(self, obj):
        # Use prefetched images cache (obj.images.all() hits prefetch, while
        # .filter().first() would issue a new query per product on Supabase).
        try:
            imgs = list(obj.images.all())
        except Exception:
            return None
        if not imgs:
            return None
        primary = next((i for i in imgs if getattr(i, "is_primary", False)), imgs[0])
        img = getattr(primary, "image", None)
        try:
            return img.url if img else None
        except Exception:
            return str(img) if img else None


class ProductDetailSerializer(serializers.ModelSerializer):
    category = CategoryBriefSerializer(read_only=True)
    variants = ProductVariantListSerializer(many=True, read_only=True)
    images = ProductImageListSerializer(many=True, read_only=True)
    discount_percent = serializers.SerializerMethodField()
    base_price = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = [
            "id",
            "name",
            "slug",
            "category",
            "description",
            "brand",
            "mrp",
            "base_price",
            "discount_percent",
            "is_featured",
            "is_active",
            "primary_image",
            "variants",
            "images",
            "created_at",
            "updated_at",
        ]
        read_only_fields = fields

    def get_base_price(self, obj):
        price = obj.base_price
        return str(price) if price is not None else None

    def get_discount_percent(self, obj):
        return obj.discount_percent


class ProductWriteSerializer(serializers.ModelSerializer):
    variants = ProductVariantWriteSerializer(many=True, required=False)
    images = ProductImageWriteSerializer(many=True, required=False)
    slug = serializers.SlugField(read_only=True)

    class Meta:
        model = Product
        fields = [
            "id",
            "slug",
            "name",
            "category",
            "description",
            "brand",
            "mrp",
            "is_featured",
            "is_active",
            "variants",
            "images",
        ]

    def validate_mrp(self, value):
        if value is not None and value < 0:
            raise serializers.ValidationError("MRP must be non-negative.")
        return value

    def create(self, validated_data):
        variants = validated_data.pop("variants", [])
        images = validated_data.pop("images", [])
        product = Product.objects.create(**validated_data)
        for variant in variants:
            ProductVariant.objects.create(product=product, **variant)
        for image in images:
            ProductImage.objects.create(product=product, **image)
        return product

    def update(self, instance, validated_data):
        variants = validated_data.pop("variants", None)
        images = validated_data.pop("images", None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        instance.save()
        if variants is not None:
            instance.variants.all().delete()
            for variant in variants:
                ProductVariant.objects.create(product=instance, **variant)
        if images is not None:
            instance.images.all().delete()
            for image in images:
                ProductImage.objects.create(product=instance, **image)
        return instance
