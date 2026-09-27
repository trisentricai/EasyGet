import re
import time

from django.contrib.postgres.search import SearchQuery, SearchRank
from django.db import connection
from django.db.models import Avg, Count, F, Min, OuterRef, Q, Subquery, Value
from rest_framework import status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

from users.permissions import IsAdminOnly

from products.models import Product, ProductReview
from .models import PopularSearch, ProductSearchIndex, SearchQueryLog
from .tasks import bump_popular_search, enqueue, log_search_query
from .serializers import (
    PopularSearchSerializer,
    ProductSearchResultSerializer,
    SearchQueryLogSerializer,
    SearchRequestSerializer,
)


def _normalize_query(text):
    """Lowercase, collapse whitespace and strip punctuation so queries like
    "Black  Board!" behave like "black board"."""
    return re.sub(r"\s+", " ", re.sub(r"[^\w\s]", " ", (text or "").lower())).strip()


def _search_tokens(text):
    """Non-empty, de-duplicated tokens from a normalized query."""
    seen, tokens = set(), []
    for token in _normalize_query(text).split():
        if token not in seen:
            seen.add(token)
            tokens.append(token)
    return tokens


def _build_search_query(tokens):
    """OR-combined websearch query: any token may match, ranked by how many
    do — so "black board" finds both "Blackboard" and "Chalk Board"."""
    return SearchQuery(" or ".join(tokens), search_type="websearch", config="english")


def _prefix_filter(tokens):
    """Case-insensitive substring filter across name/brand/tags/description/
    category — the safety net that catches compound words ("black board" →
    "Blackboard") even when the full-text index is stale or missing."""
    cond = Q()
    for token in tokens:
        cond |= (
            Q(name__icontains=token)
            | Q(brand__icontains=token)
            | Q(tags__icontains=token)
            | Q(description__icontains=token)
            | Q(category__name__icontains=token)
            | Q(search_index__search_text__icontains=token)
        )
    return cond


class SearchViewSet(viewsets.GenericViewSet):
    """Product search with PostgreSQL full-text search.

    Public (marketplace-style guest browsing): both the search endpoint and
    autocomplete work without an account; the anon rate throttle guards
    against scraping. Cart/checkout/wishlist remain authenticated."""

    permission_classes = [AllowAny]
    serializer_class = ProductSearchResultSerializer

    def get_queryset(self):
        # Same read-shape as the product list endpoint: category joined,
        # images prefetched, min variant price + rating stats annotated —
        # otherwise every serialized row costs 3+ extra queries (N+1).
        from products.views import with_rating_stats

        return with_rating_stats(
            Product.objects.filter(is_active=True)
            .select_related("category")
            .prefetch_related("images")
            .annotate(
                min_variant_price=Min(
                    "variants__price",
                    filter=Q(variants__is_active=True) & Q(variants__price__isnull=False),
                )
            )
        )

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

        # Tokenized search. On PostgreSQL: full-text match on ANY token,
        # unioned with a prefix ILIKE across name/brand/tags/description/
        # category so compound titles ("Blackboard") match "black board".
        # On SQLite (local dev) the prefix ILIKE alone applies — same
        # matching contract, no PostgreSQL-only operators.
        tokens = _search_tokens(query_text)
        if tokens:
            prefix_cond = _prefix_filter(tokens)
            if connection.vendor == "postgresql":
                search_query = _build_search_query(tokens)
                queryset = queryset.annotate(
                    rank=SearchRank("search_index__document", search_query),
                ).filter(Q(search_index__document=search_query) | prefix_cond)
            else:
                queryset = queryset.filter(prefix_cond).annotate(rank=Value(0))
        else:
            queryset = queryset.annotate(rank=Value(0))

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
        elif sort == "rating":
            stats = (
                ProductReview.objects.filter(
                    product=OuterRef("pk"), is_approved=True
                )
                .values("product")
                .annotate(avg=Avg("rating"))
                .values("avg")[:1]
            )
            queryset = queryset.annotate(review_avg=Subquery(stats)).order_by(
                F("review_avg").desc(nulls_last=True), "-created_at"
            )

        # Pagination
        page = params.get("page", 1)
        page_size = params.get("page_size", 20)
        start_idx = (page - 1) * page_size
        end_idx = start_idx + page_size
        total = queryset.count()
        results = queryset[start_idx:end_idx]

        took_ms = int((time.perf_counter() - start) * 1000)

        # Log search + update popular searches off the request thread
        # (Celery when a worker is up; inline fallback so local dev without
        # Redis still records analytics).
        enqueue(
            log_search_query,
            query=query_text or "*",
            user_id=None if request.user.is_anonymous else request.user.id,
            results_count=total,
            filters={k: v for k, v in params.items() if k not in ["page", "page_size", "q"]},
            took_ms=took_ms,
        )
        if query_text:
            enqueue(bump_popular_search, query=query_text)

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
        """Autocomplete suggestions — tokenized so multi-word partials like
        "black boa" still surface "Blackboard"."""
        raw_q = request.query_params.get("q", "").strip()
        if len(raw_q) < 2:
            return Response([])

        # Popular searches starting with the raw query
        popular = PopularSearch.objects.filter(
            query__istartswith=raw_q
        ).order_by("-count")[:5]

        # Product names matching ANY token
        tokens = _search_tokens(raw_q)
        cond = Q()
        for token in tokens:
            cond |= Q(name__icontains=token) | Q(tags__icontains=token)
        products = (
            Product.objects.filter(cond, is_active=True)
            .values_list("name", flat=True)[:8]
        )

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