from rest_framework import serializers

from products.serializers import ProductListSerializer

from .models import PopularSearch, ProductSearchIndex, SearchQueryLog


class ProductSearchResultSerializer(ProductListSerializer):
    """Product serializer with search highlight."""

    highlight = serializers.SerializerMethodField()
    score = serializers.FloatField(read_only=True)

    class Meta(ProductListSerializer.Meta):
        fields = ProductListSerializer.Meta.fields + ["highlight", "score"]

    def get_highlight(self, obj):
        # In real implementation, use PostgreSQL ts_headline
        return None


class SearchQueryLogSerializer(serializers.ModelSerializer):
    class Meta:
        model = SearchQueryLog
        fields = [
            "id",
            "query",
            "results_count",
            "filters",
            "took_ms",
            "created_at",
        ]
        read_only_fields = fields


class PopularSearchSerializer(serializers.ModelSerializer):
    class Meta:
        model = PopularSearch
        fields = ["query", "count", "last_searched"]
        read_only_fields = fields


class SearchRequestSerializer(serializers.Serializer):
    q = serializers.CharField(max_length=500, required=False, allow_blank=True)
    category = serializers.CharField(max_length=100, required=False)
    store = serializers.UUIDField(required=False)
    min_price = serializers.DecimalField(max_digits=10, decimal_places=2, required=False)
    max_price = serializers.DecimalField(max_digits=10, decimal_places=2, required=False)
    is_featured = serializers.BooleanField(required=False)
    sort = serializers.ChoiceField(
        choices=[
            "relevance", "price_asc", "price_desc", "newest", "popular",
            "rating",
        ],
        default="relevance",
    )
    page = serializers.IntegerField(min_value=1, default=1)
    page_size = serializers.IntegerField(min_value=1, max_value=100, default=20)