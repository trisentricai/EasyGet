from rest_framework import serializers

from .models import Category


class CategoryDetailSerializer(serializers.ModelSerializer):
    product_count = serializers.IntegerField(read_only=True)
    children = serializers.SerializerMethodField()
    is_subcategory = serializers.BooleanField(read_only=True)

    class Meta:
        model = Category
        fields = [
            "id",
            "name",
            "slug",
            "parent",
            "description",
            "icon",
            "is_active",
            "sort_order",
            "product_count",
            "is_subcategory",
            "children",
            "created_at",
            "updated_at",
        ]
        read_only_fields = fields

    def get_children(self, obj):
        kids = obj.children.filter(is_active=True)
        if not kids.exists():
            return []
        return CategoryListSerializer(kids, many=True, context=self.context).data


class CategoryListSerializer(serializers.ModelSerializer):
    product_count = serializers.IntegerField(read_only=True)
    is_subcategory = serializers.BooleanField(read_only=True)
    has_children = serializers.SerializerMethodField()

    class Meta:
        model = Category
        fields = [
            "id",
            "name",
            "slug",
            "parent",
            "is_active",
            "is_subcategory",
            "has_children",
            "product_count",
        ]
        read_only_fields = fields

    def get_has_children(self, obj):
        return obj.children.filter(is_active=True).exists()


class CategoryWriteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = [
            "name",
            "parent",
            "description",
            "icon",
            "is_active",
            "sort_order",
        ]


class CategoryBriefSerializer(serializers.ModelSerializer):
    """Lightweight category payload embedded in Product serializers."""

    class Meta:
        model = Category
        fields = [
            "id",
            "name",
            "slug",
            "is_subcategory",
        ]
        read_only_fields = fields
