import uuid

from django.contrib.postgres.search import SearchVectorField
from django.db import models
from django.utils import timezone

from products.models import Product


class ProductSearchIndex(models.Model):
    """Full-text search index for products."""

    product = models.OneToOneField(
        Product,
        on_delete=models.CASCADE,
        related_name="search_index",
    )
    document = SearchVectorField(null=True)
    search_text = models.TextField(blank=True, default="")
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=["updated_at"]),
        ]

    def __str__(self):
        return f"Index: {self.product.name}"

    def update_index(self):
        """Update search vector from product data."""
        from django.contrib.postgres.search import SearchVector
        from django.db.models import F

        self.search_text = " ".join(filter(None, [
            self.product.name,
            self.product.description,
            self.product.brand,
            self.product.category.name if self.product.category else "",
            self.product.tags,
        ]))
        ProductSearchIndex.objects.filter(pk=self.pk).update(
            document=SearchVector("search_text"),
            updated_at=timezone.now(),
        )
        self.refresh_from_db()


class SearchQueryLog(models.Model):
    """Log of search queries for analytics."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    query = models.CharField(max_length=500)
    user = models.ForeignKey(
        "users.User",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="search_queries",
    )
    session_key = models.CharField(max_length=40, blank=True, default="")
    results_count = models.PositiveIntegerField(default=0)
    filters = models.JSONField(default=dict, blank=True)
    took_ms = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["user", "created_at"]),
            models.Index(fields=["query"]),
        ]

    def __str__(self):
        return f"Search: {self.query[:50]} ({self.results_count} results)"


class PopularSearch(models.Model):
    """Aggregated popular search terms."""

    query = models.CharField(max_length=500, unique=True)
    count = models.PositiveIntegerField(default=1)
    last_searched = models.DateTimeField(auto_now=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-count"]
        indexes = [
            models.Index(fields=["-count"]),
        ]

    def __str__(self):
        return f"{self.query} ({self.count})"

    def increment(self):
        self.count += 1
        self.save(update_fields=["count", "last_searched"])