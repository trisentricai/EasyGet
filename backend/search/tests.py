from django.contrib.auth import get_user_model
from django.test import TestCase

from categories.models import Category
from products.models import Product, ProductVariant
from stores.models import Store

from .models import PopularSearch, ProductSearchIndex, SearchQueryLog

User = get_user_model()


class SearchModelTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(email="search@test.com", password="pass")
        self.store = Store.objects.create(
            name="Test Store",
            city="Pune",
            state="MH",
            postal_code="411001",
            latitude=18.5204,
            longitude=73.8567,
        )
        category = Category.objects.create(name="Grocery", is_active=True)
        self.product = Product.objects.create(
            name="Basmati Rice 5kg",
            category=category,
            mrp=800.00,
            description="Premium basmati rice",
            brand="India Gate",
            tags="rice,basmati,grocery",
            is_active=True,
        )
        ProductVariant.objects.create(
            product=self.product,
            name="5kg",
            sku="BASMATI-5KG",
            price=700.00,
            is_active=True,
        )

    def test_search_index_creation(self):
        index = ProductSearchIndex.objects.create(product=self.product)
        self.assertEqual(index.product, self.product)

    def test_search_index_update(self):
        index = ProductSearchIndex.objects.create(product=self.product)
        # Skip full-text search update on SQLite (requires PostgreSQL)
        from django.db import connection
        if connection.vendor != "postgresql":
            self.skipTest("Full-text search requires PostgreSQL")
        index.update_index()
        self.assertIn("Basmati", index.search_text)
        self.assertIn("rice", index.search_text)
        self.assertIn("India Gate", index.search_text)

    def test_search_query_log(self):
        log = SearchQueryLog.objects.create(
            query="rice basmati",
            user=self.user,
            results_count=10,
            took_ms=45,
        )
        self.assertEqual(log.query, "rice basmati")
        self.assertEqual(log.results_count, 10)

    def test_popular_search_increment(self):
        popular = PopularSearch.objects.create(query="rice", count=5)
        popular.increment()
        self.assertEqual(popular.count, 6)

    def test_popular_search_get_or_create(self):
        popular, created = PopularSearch.objects.get_or_create(query="new query")
        self.assertTrue(created)
        self.assertEqual(popular.count, 1)

        popular2, created = PopularSearch.objects.get_or_create(query="new query")
        self.assertFalse(created)
        self.assertEqual(popular2.count, 1)