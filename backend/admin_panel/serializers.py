from rest_framework import serializers

from .models import AdminAction, Banner, Coupon, ScheduledTask, SystemConfig


class SystemConfigSerializer(serializers.ModelSerializer):
    typed_value = serializers.SerializerMethodField()

    class Meta:
        model = SystemConfig
        fields = [
            "id", "key", "value", "typed_value", "config_type",
            "description", "is_public", "is_editable",
            "created_at", "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


class SystemConfigPublicSerializer(serializers.ModelSerializer):
    typed_value = serializers.SerializerMethodField()

    class Meta:
        model = SystemConfig
        fields = ["key", "typed_value"]
        read_only_fields = ["key", "typed_value"]


class AdminActionSerializer(serializers.ModelSerializer):
    admin_email = serializers.EmailField(source="admin_user.email", read_only=True)

    class Meta:
        model = AdminAction
        fields = [
            "id", "admin_user", "admin_email", "action", "target_model",
            "target_id", "changes", "ip_address", "user_agent", "created_at",
        ]
        read_only_fields = fields


class ScheduledTaskSerializer(serializers.ModelSerializer):
    class Meta:
        model = ScheduledTask
        fields = [
            "id", "name", "task_type", "target", "arguments", "schedule",
            "status", "last_run", "next_run", "result", "error",
            "is_active", "created_by", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at", "last_run", "next_run"]


class BannerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Banner
        fields = [
            "id", "title", "subtitle", "image", "link_url", "link_text",
            "type", "position", "is_active", "start_date", "end_date",
            "created_at", "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


class BannerPublicSerializer(serializers.ModelSerializer):
    class Meta:
        model = Banner
        fields = ["id", "title", "subtitle", "image", "link_url", "link_text", "type", "position"]


class CouponSerializer(serializers.ModelSerializer):
    class Meta:
        model = Coupon
        fields = [
            "id", "code", "name", "description", "discount_type", "discount_value",
            "applies_to", "category", "product", "min_order_value", "max_discount",
            "usage_limit", "usage_count", "user_limit",
            "start_date", "end_date", "is_active",
            "created_at", "updated_at",
        ]
        read_only_fields = ["id", "usage_count", "created_at", "updated_at"]


class CouponValidateSerializer(serializers.Serializer):
    code = serializers.CharField(max_length=50)
    order_value = serializers.DecimalField(max_digits=10, decimal_places=2, required=False)

    def validate_code(self, value):
        from .models import Coupon
        try:
            coupon = Coupon.objects.get(code__iexact=value)
        except Coupon.DoesNotExist:
            raise serializers.ValidationError("Invalid coupon code")
        return value

class ReviewAdminSerializer(serializers.ModelSerializer):
    """Moderation payload for the admin Reviews page."""

    product_name = serializers.CharField(source="product.name", read_only=True)
    product_slug = serializers.CharField(source="product.slug", read_only=True)
    user_email = serializers.CharField(source="user.email", read_only=True)

    class Meta:
        from products.models import ProductReview

        model = ProductReview
        fields = [
            "id", "product_name", "product_slug", "rating", "title", "body",
            "reviewer_name", "user_email", "is_verified_purchase", "is_approved",
            "created_at",
        ]
        read_only_fields = [f for f in fields if f != "is_approved"]
