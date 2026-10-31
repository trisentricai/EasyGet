from django.contrib.auth import get_user_model
from django.test import TestCase, override_settings
from rest_framework.test import APIClient

from categories.models import Category
from products.models import Product, ProductVariant

from .models import PopularSearch, ProductSearchIndex, SearchQueryLog

User = get_user_model()


class SearchModelTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(email="search@test.com", password="pass")
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

    def test_search_index_auto_created_by_signal(self):
        # Creating a product auto-creates its index row (post_save signal).
        self.assertTrue(ProductSearchIndex.objects.filter(product=self.product).exists())
        index = ProductSearchIndex.objects.get(product=self.product)
        self.assertEqual(index.product, self.product)

    def test_search_index_update(self):
        index = ProductSearchIndex.objects.get(product=self.product)
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


@override_settings(CELERY_TASK_ALWAYS_EAGER=True)
class SearchAPITests(TestCase):
    """End-to-end search endpoint tests, including the multi-word and
    compound-word matching contract ("black board" must find "Blackboard").

    Celery runs eagerly in tests so analytics writes execute inline instead
    of attempting a broker connection."""

    def setUp(self):
        self.user = User.objects.create_user(email="shopper@test.com", password="pass12345")
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)

        self.category = Category.objects.create(name="Stationery", is_active=True)
        self.blackboard = Product.objects.create(
            name="Blackboard",
            category=self.category,
            brand="Classmate",
            description="Wall-mountable chalk board for classrooms.",
            tags="black board,chalk,school",
            is_active=True,
        )
        self.chalk = Product.objects.create(
            name="Chalk Board Eraser",
            category=self.category,
            brand="Duster",
            description="Felt eraser for chalk boards.",
            tags="blackboard,duster",
            is_active=True,
        )
        self.unrelated = Product.objects.create(
            name="Steel Water Bottle",
            category=self.category,
            brand="Milton",
            description="Vacuum insulated flask.",
            tags="bottle,drinkware",
            is_active=True,
        )

    def _search(self, q):
        res = self.client.post("/api/v1/search/", {"q": q}, format="json")
        self.assertEqual(res.status_code, 200, res.content)
        return res.data

    def test_multi_word_query_matches_compound_title(self):
        # "black board" (two words) must find the one-word product "Blackboard"
        data = self._search("black board")
        names = [r["name"] for r in data["results"]]
        self.assertIn("Blackboard", names)
        self.assertNotIn("Steel Water Bottle", names)

    def test_search_is_case_and_space_insensitive(self):
        for query in ("BLACK BOARD", "Black   Board", "  black board  "):
            data = self._search(query)
            self.assertIn(
                "Blackboard",
                [r["name"] for r in data["results"]],
                msg=f"query {query!r} failed",
            )

    def test_single_token_matches_tags_and_category(self):
        data = self._search("stationery")  # category name, not in any title
        names = [r["name"] for r in data["results"]]
        self.assertEqual(len(names), 3)

    def test_no_results_for_gibberish(self):
        data = self._search("zzqqxxyy")
        self.assertEqual(data["total"], 0)

    def test_suggestions_include_multi_word_match(self):
        res = self.client.get("/api/v1/search/suggestions/?q=black boa")
        self.assertEqual(res.status_code, 200)
        self.assertIn("Blackboard", res.data)

    def test_search_is_public(self):
        # Guests can browse and search — login is only for cart/checkout.
        anon = APIClient()
        res = anon.post("/api/v1/search/", {"q": "black"}, format="json")
        self.assertEqual(res.status_code, 200, res.content)
        self.assertIn("total", res.data)