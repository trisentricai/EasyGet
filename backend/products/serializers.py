from decimal import Decimal

from django.utils.text import slugify
from rest_framework import serializers

from categories.serializers import CategoryBriefSerializer

from .models import Product, ProductImage, ProductReview, ProductVariant


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
    rating_avg = serializers.SerializerMethodField()
    rating_count = serializers.SerializerMethodField()

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
            "rating_avg",
            "rating_count",
        ]
        read_only_fields = fields

    def get_rating_avg(self, obj):
        avg = getattr(obj, "review_rating_avg", None)
        return round(float(avg), 1) if avg is not None else None

    def get_rating_count(self, obj):
        return getattr(obj, "review_rating_count", None) or 0

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


    def get_rating_avg(self, obj):
        avg, _ = _review_stats(obj)
        return round(float(avg), 1) if avg is not None else None

    def get_rating_count(self, obj):
        _, n = _review_stats(obj)
        return n


def _review_stats(obj):
    """(avg, count) from queryset subquery-annotation, else one fallback query."""
    if hasattr(obj, "review_rating_avg"):
        return obj.review_rating_avg, (obj.review_rating_count or 0)
    from django.db.models import Avg, Count

    agg = obj.reviews.filter(is_approved=True).aggregate(
        avg=Avg("rating"), n=Count("id")
    )
    return agg["avg"], agg["n"] or 0


class ProductDetailSerializer(serializers.ModelSerializer):
    category = CategoryBriefSerializer(read_only=True)
    variants = ProductVariantListSerializer(many=True, read_only=True)
    images = ProductImageListSerializer(many=True, read_only=True)
    discount_percent = serializers.SerializerMethodField()
    base_price = serializers.SerializerMethodField()
    rating_avg = serializers.SerializerMethodField()
    rating_count = serializers.SerializerMethodField()

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
            "rating_avg",
            "rating_count",
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

    def get_rating_avg(self, obj):
        avg, _ = _review_stats(obj)
        return round(float(avg), 1) if avg is not None else None

    def get_rating_count(self, obj):
        _, n = _review_stats(obj)
        return n


class ReviewSerializer(serializers.ModelSerializer):
    """Public review payload: masked name, no emails/ids leaked."""

    reviewer_name = serializers.CharField(read_only=True)

    class Meta:
        model = ProductReview
        fields = [
            "id",
            "rating",
            "title",
            "body",
            "reviewer_name",
            "is_verified_purchase",
            "created_at",
        ]
        read_only_fields = fields


class ReviewCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductReview
        fields = ["rating", "title", "body"]

    def validate_rating(self, value):
        if not 1 <= int(value) <= 5:
            raise serializers.ValidationError("Rating must be between 1 and 5.")
        return value


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
