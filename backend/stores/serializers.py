from rest_framework import serializers

from .models import Store


class StoreListSerializer(serializers.ModelSerializer):
    distance_km = serializers.SerializerMethodField()

    class Meta:
        model = Store
        fields = [
            "id",
            "name",
            "slug",
            "city",
            "state",
            "latitude",
            "longitude",
            "delivery_radius_km",
            "is_active",
            "distance_km",
        ]
        read_only_fields = fields

    def get_distance_km(self, obj):
        request = self.context.get("request")
        if not request:
            return None
        lat = request.query_params.get("lat")
        lng = request.query_params.get("lng")
        if not (lat and lng):
            return None
        try:
            return round(obj.distance_km(float(lat), float(lng)), 2)
        except (TypeError, ValueError):
            return None


class StoreDetailSerializer(serializers.ModelSerializer):
    distance_km = serializers.SerializerMethodField()
    serves = serializers.SerializerMethodField()

    class Meta:
        model = Store
        fields = [
            "id",
            "tenant",
            "name",
            "slug",
            "description",
            "address_line1",
            "address_line2",
            "city",
            "state",
            "postal_code",
            "country",
            "latitude",
            "longitude",
            "delivery_radius_km",
            "contact_phone",
            "opening_time",
            "closing_time",
            "is_active",
            "distance_km",
            "serves",
        ]
        read_only_fields = fields

    def get_distance_km(self, obj):
        request = self.context.get("request")
        if not request:
            return None
        lat = request.query_params.get("lat")
        lng = request.query_params.get("lng")
        if not (lat and lng):
            return None
        try:
            return round(obj.distance_km(float(lat), float(lng)), 2)
        except (TypeError, ValueError):
            return None

    def get_serves(self, obj):
        request = self.context.get("request")
        if not request:
            return None
        lat = request.query_params.get("lat")
        lng = request.query_params.get("lng")
        if not (lat and lng):
            return None
        try:
            return obj.serves(float(lat), float(lng))
        except (TypeError, ValueError):
            return None


class StoreWriteSerializer(serializers.ModelSerializer):
    slug = serializers.SlugField(read_only=True)

    class Meta:
        model = Store
        fields = [
            "id",
            "slug",
            "name",
            "description",
            "address_line1",
            "address_line2",
            "city",
            "state",
            "postal_code",
            "country",
            "latitude",
            "longitude",
            "delivery_radius_km",
            "contact_phone",
            "opening_time",
            "closing_time",
            "is_active",
        ]


class StoreBriefSerializer(serializers.ModelSerializer):
    """Ligh-payload store reference used within inventory responses."""

    class Meta:
        model = Store
        fields = [
            "id",
            "name",
            "slug",
            "city",
            "state",
            "postal_code",
            "is_active",
        ]
        read_only_fields = fields
