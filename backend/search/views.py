import time
from django.contrib.postgres.search import SearchQuery, SearchRank
from django.db.models import Count
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from users.permissions import IsAdminOnly

from products.models import Product
from .models import PopularSearch, ProductSearchIndex, SearchQueryLog
from .serializers import (
    PopularSearchSerializer,
    ProductSearchResultSerializer,
    SearchQueryLogSerializer,
    SearchRequestSerializer,
)


class SearchViewSet(viewsets.GenericViewSet):
    """Product search with PostgreSQL full-text search."""

    permission_classes = [IsAuthenticated]
    serializer_class = ProductSearchResultSerializer

    def get_queryset(self):
        return Product.objects.filter(is_active=True).select_related("category")

    def create(self, request):
        """Search products."""
        serializer = SearchRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        params = serializer.validated_data

        start = time.perf_counter()
        query_text = params.get("q", "").strip()
        queryset = self.get_queryset()

        # Apply filters
        if params.get("category"):
            queryset = queryset.filter(category__slug=params["category"])
        if params.get("store"):
            queryset = queryset.filter(stock_items__store_id=params["store"], stock_items__quantity__gt=0)
        if params.get("min_price"):
            queryset = queryset.filter(base_price__gte=params["min_price"])
        if params.get("max_price"):
            queryset = queryset.filter(base_price__lte=params["max_price"])
        if params.get("is_featured") is not None:
            queryset = queryset.filter(is_featured=params["is_featured"])

        # Full-text search
        if query_text:
            search_query = SearchQuery(query_text, config="english")
            queryset = queryset.annotate(
                rank=SearchRank("search_index__document", search_query),
            ).filter(search_index__document=search_query)
        else:
            queryset = queryset.annotate(rank=0)

        # Sorting
        sort = params.get("sort", "relevance")
        if sort == "relevance":
            queryset = queryset.order_by("-rank", "-is_featured", "-created_at")
        elif sort == "price_asc":
            queryset = queryset.order_by("base_price")
        elif sort == "price_desc":
            queryset = queryset.order_by("-base_price")
        elif sort == "newest":
            queryset = queryset.order_by("-created_at")
        elif sort == "popular":
            queryset = queryset.annotate(
                order_count=Count("order_items")
            ).order_by("-order_count", "-rank")

        # Pagination
        page = params.get("page", 1)
        page_size = params.get("page_size", 20)
        start_idx = (page - 1) * page_size
        end_idx = start_idx + page_size
        total = queryset.count()
        results = queryset[start_idx:end_idx]

        took_ms = int((time.perf_counter() - start) * 1000)

        # Log search
        SearchQueryLog.objects.create(
            query=query_text or "*",
            user=request.user if not request.user.is_anonymous else None,
            results_count=total,
            filters={k: v for k, v in params.items() if k not in ["page", "page_size", "q"]},
            took_ms=took_ms,
        )

        # Update popular searches
        if query_text:
            popular, _ = PopularSearch.objects.get_or_create(query=query_text)
            popular.increment()

        serializer = self.get_serializer(results, many=True)
        return Response({
            "results": serializer.data,
            "total": total,
            "page": page,
            "page_size": page_size,
            "took_ms": took_ms,
            "query": query_text,
        })

    @action(detail=False, methods=["get"])
    def suggestions(self, request):
        """Autocomplete suggestions."""
        q = request.query_params.get("q", "").strip()
        if len(q) < 2:
            return Response([])

        # Get popular searches starting with query
        popular = PopularSearch.objects.filter(
            query__istartswith=q
        ).order_by("-count")[:5]

        # Get product names matching query
        products = Product.objects.filter(
            name__icontains=q, is_active=True
        ).values_list("name", flat=True)[:5]

        suggestions = list(popular.values_list("query", flat=True))
        suggestions.extend(list(products))
        return Response(list(dict.fromkeys(suggestions))[:10])


class PopularSearchViewSet(viewsets.ReadOnlyModelViewSet):
    """Popular search terms."""

    queryset = PopularSearch.objects.all()
    serializer_class = PopularSearchSerializer
    permission_classes = [IsAdminOnly]

    @action(detail=False, methods=["post"], permission_classes=[IsAdminOnly])
    def rebuild(self, request):
        """Rebuild popular searches from query logs."""
        from django.db.models import Count

        PopularSearch.objects.all().delete()
        stats = SearchQueryLog.objects.exclude(query="*").values("query").annotate(
            cnt=Count("id")
        ).order_by("-cnt")[:1000]

        for stat in stats:
            PopularSearch.objects.create(query=stat["query"], count=stat["cnt"])

        return Response({"rebuilt": PopularSearch.objects.count()})


class SearchQueryLogViewSet(viewsets.ReadOnlyModelViewSet):
    """Search query logs (admin)."""

    queryset = SearchQueryLog.objects.all()
    serializer_class = SearchQueryLogSerializer
    permission_classes = [IsAdminOnly]
    filterset_fields = ["user", "created_at"]
    search_fields = ["query"]

    @action(detail=False, methods=["get"])
    def stats(self, request):
        """Search analytics."""
        from django.db.models import Avg, Count
        from django.utils import timezone
        from datetime import timedelta

        now = timezone.now()
        week_ago = now - timedelta(days=7)

        total = SearchQueryLog.objects.count()
        recent = SearchQueryLog.objects.filter(created_at__gte=week_ago).count()
        avg_results = SearchQueryLog.objects.aggregate(avg=Avg("results_count"))["avg"]
        avg_time = SearchQueryLog.objects.aggregate(avg=Avg("took_ms"))["avg"]

        top_queries = SearchQueryLog.objects.values("query").annotate(
            cnt=Count("id")
        ).order_by("-cnt")[:10]

        return Response({
            "total_searches": total,
            "recent_searches": recent,
            "avg_results": round(avg_results or 0, 1),
            "avg_time_ms": round(avg_time or 0),
            "top_queries": list(top_queries),
        })