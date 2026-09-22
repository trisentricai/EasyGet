from rest_framework import serializers

from .models import AppUpdate, OfflineData, PWAConfigModel, PushSubscription


class PWAConfigSerializer(serializers.ModelSerializer):
    manifest = serializers.SerializerMethodField()

    class Meta:
        model = PWAConfigModel
        fields = [
            "id", "name", "short_name", "description", "theme_color",
            "background_color", "display", "orientation", "scope",
            "start_url", "icons", "screenshots", "categories",
            "shortcuts", "related_applications", "prefer_related_applications",
            "manifest", "updated_at",
        ]
        read_only_fields = ["id", "updated_at", "manifest"]

    def get_manifest(self, obj):
        return obj.get_manifest()


class OfflineDataSerializer(serializers.ModelSerializer):
    class Meta:
        model = OfflineData
        fields = ["id", "data_type", "key", "data", "expires_at", "created_at", "updated_at"]
        read_only_fields = ["id", "created_at", "updated_at"]


class OfflineDataCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = OfflineData
        fields = ["data_type", "key", "data", "expires_at"]

    def create(self, validated_data):
        validated_data["user"] = self.context["request"].user
        return super().create(validated_data)


class PushSubscriptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = PushSubscription
        fields = ["id", "endpoint", "p256dh", "auth", "user_agent", "is_active", "created_at"]
        read_only_fields = ["id", "created_at"]


class PushSubscriptionCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = PushSubscription
        fields = ["endpoint", "p256dh", "auth", "user_agent"]

    def create(self, validated_data):
        validated_data["user"] = self.context["request"].user
        subscription, _ = PushSubscription.objects.update_or_create(
            user=validated_data["user"],
            endpoint=validated_data["endpoint"],
            defaults=validated_data,
        )
        return subscription


class AppUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = AppUpdate
        fields = [
            "id", "version", "platform", "release_notes", "download_url",
            "is_mandatory", "min_supported_version", "status",
            "released_at", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "created_at", "updated_at"]


class AppUpdateCheckSerializer(serializers.Serializer):
    platform = serializers.ChoiceField(choices=[("ANDROID", "Android"), ("IOS", "iOS"), ("WEB", "Web")])
    current_version = serializers.CharField(max_length=20)

    def validate_current_version(self, value):
        from packaging import version
        try:
            version.parse(value)
        except:
            raise serializers.ValidationError("Invalid version format")
        return value