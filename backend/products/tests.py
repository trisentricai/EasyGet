from datetime import timedelta
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from categories.models import Category
from inventory.models import StockItem
from stores.models import Store

from .models import Product, ProductVariant

User = get_user_model()


class ProductModelTests(TestCase):
    def setUp(self):
        self.category = Category.objects.create(
            name="Grocery", is_active=True, sort_order=0
        )

    def test_slug_auto_generated(self):
        product = Product.objects.create(
            name="Basmati Rice 5kg",
            category=self.category,
            mrp=Decimal("800.00"),
            is_active=True,
        )
        self.assertEqual(product.slug, "basmati-rice-5kg")
        self.assertEqual(product.discount_percent, Decimal("0"))

    def test_discount_percent_uses_mrp_minus_base_price(self):
        product = Product.objects.create(
            name="Almonds 1kg",
            category=self.category,
            mrp=Decimal("1000.00"),
            is_active=True,
        )
        ProductVariant.objects.create(
            product=product,
            name="1kg",
            sku="ALMONDS-1KG",
            price=Decimal("850.00"),
            is_active=True,
        )
        self.assertEqual(product.discount_percent, Decimal("15.00"))

    def test_negative_mrp_guards(self):
        product = Product.objects.create(
            name="Test",
            category=self.category,
            mrp=Decimal("-5.00"),
            is_active=True,
        )
        self.assertEqual(product.discount_percent, Decimal("0"))


class ProductDiscoveryTests(TestCase):
    """Marketplace filters: brand, min_discount, sort, brands endpoint."""

    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            "shopper@example.com", "strongpass123", is_email_verified=True
        )
        self.client.force_authenticate(user=self.user)
        self.category = Category.objects.create(
            name="Grocery", is_active=True, sort_order=0
        )
        # Customer-visible products must be stocked in an active store.
        self.store = Store.objects.create(
            name="Discovery Store", city="Pune", state="MH",
            postal_code="411001", latitude=Decimal("18.5204"),
            longitude=Decimal("73.8567"), is_active=True,
        )
        self.cheap = self._mk("Budget Rice", brand="FarmLite",
                              mrp="100.00", price="95.00")
        self.deal = self._mk("Deal Dal", brand="FarmLite",
                             mrp="200.00", price="120.00")
        self.premium = self._mk("Premium Oil", brand="GoldPress",
                                mrp="500.00", price="450.00")

    def _mk(self, name, brand, mrp, price):
        p = Product.objects.create(
            name=name, category=self.category, brand=brand,
            mrp=Decimal(mrp), is_active=True,
        )
        v = ProductVariant.objects.create(
            product=p, name="std", sku=f"SKU-{name[:6]}",
            price=Decimal(price), is_active=True,
        )
        StockItem.objects.create(store=self.store, variant=v, quantity=10)
        return p

    def _slugs(self, params):
        res = self.client.get("/api/v1/products/", params)
        self.assertEqual(res.status_code, 200)
        return [r["slug"] for r in res.data["results"]]

    def test_brand_filter_case_insensitive(self):
        slugs = self._slugs({"brand": "farmlite"})
        self.assertIn(self.cheap.slug, slugs)
        self.assertIn(self.deal.slug, slugs)
        self.assertNotIn(self.premium.slug, slugs)

    def test_min_discount_filter(self):
        # Deal Dal = 40% off; others <= 10% off.
        slugs = self._slugs({"min_discount": "25"})
        self.assertEqual(slugs, [self.deal.slug])

    def test_sort_price_asc(self):
        slugs = self._slugs({"sort": "price_asc"})
        self.assertEqual(slugs, [self.cheap.slug, self.deal.slug, self.premium.slug])

    def test_sort_price_desc(self):
        slugs = self._slugs({"sort": "price_desc"})
        self.assertEqual(slugs[0], self.premium.slug)

    def test_sort_newest(self):
        slugs = self._slugs({"sort": "newest"})
        self.assertEqual(slugs[0], self.premium.slug)

    def test_brands_endpoint(self):
        res = self.client.get("/api/v1/products/brands/")
        self.assertEqual(res.status_code, 200)
        names = [r["name"] for r in res.data]
        self.assertIn("FarmLite", names)
        self.assertIn("GoldPress", names)


class ProductReviewTests(TestCase):
    """Reviews API: one-per-user, masked names, aggregates, verified flag."""

    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            "reviewer@example.com", "strongpass123",
            first_name="Rahul", last_name="Bharathi", is_email_verified=True,
        )
        self.client.force_authenticate(user=self.user)
        self.category = Category.objects.create(
            name="Grocery", is_active=True, sort_order=0
        )
        self.store = Store.objects.create(
            name="Review Store", city="Pune", state="MH",
            postal_code="411001", latitude=Decimal("18.5204"),
            longitude=Decimal("73.8567"), is_active=True,
        )
        self.product = Product.objects.create(
            name="Test Coffee", category=self.category, brand="BrewCo",
            is_active=True,
        )
        self.variant = ProductVariant.objects.create(
            product=self.product, name="250g", sku="COFFEE-250",
            price=Decimal("250.00"), is_active=True,
        )
        StockItem.objects.create(
            store=self.store, variant=self.variant, quantity=5
        )

    def _post(self, payload):
        return self.client.post(
            f"/api/v1/products/{self.product.slug}/reviews/", payload, format="json"
        )

    def test_create_review_masks_name(self):
        res = self._post({"rating": 5, "title": "Great", "body": "Loved it"})
        self.assertEqual(res.status_code, 201, res.data)
        self.assertEqual(res.data["reviewer_name"], "Rahul B.")
        self.assertFalse(res.data["is_verified_purchase"])

    def test_rating_out_of_range_rejected(self):
        self.assertEqual(self._post({"rating": 0}).status_code, 400)
        self.assertEqual(self._post({"rating": 6}).status_code, 400)

    def test_one_review_per_user_conflict(self):
        self.assertEqual(self._post({"rating": 4}).status_code, 201)
        res = self._post({"rating": 2, "body": "changed my mind"})
        self.assertEqual(res.status_code, 409)

    def test_unauthenticated_rejected(self):
        anon = APIClient()
        res = anon.post(
            f"/api/v1/products/{self.product.slug}/reviews/",
            {"rating": 5}, format="json",
        )
        self.assertIn(res.status_code, (401, 403))

    def test_product_list_exposes_rating_aggregates(self):
        self._post({"rating": 4})
        res = self.client.get("/api/v1/products/")
        self.assertEqual(res.status_code, 200)
        row = next(r for r in res.data["results"] if r["slug"] == self.product.slug)
        self.assertEqual(row["rating_avg"], 4.0)
        self.assertEqual(row["rating_count"], 1)

    def test_unapproved_reviews_hidden_from_list_and_aggregates(self):
        from .models import ProductReview

        ProductReview.objects.create(
            product=self.product, user=self.user, rating=1, is_approved=False
        )
        res = self.client.get(f"/api/v1/products/{self.product.slug}/reviews/")
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data["count"], 0)
        res = self.client.get(f"/api/v1/products/{self.product.slug}/")
        self.assertEqual(res.data["rating_count"], 0)
        self.assertIsNone(res.data["rating_avg"])

    def test_verified_purchase_from_delivered_order(self):
        from orders.models import Order, OrderItem

        order = Order.objects.create(
            user=self.user, store=self.store, subtotal=Decimal("250.00"),
            total=Decimal("250.00"), status=Order.Status.DELIVERED,
        )
        OrderItem.objects.create(
            order=order, variant=self.variant, product_name="Test Coffee",
            sku=self.variant.sku, unit_price=Decimal("250.00"), quantity=1,
            line_total=Decimal("250.00"),
        )
        res = self._post({"rating": 5, "body": "Delivered perfectly"})
        self.assertEqual(res.status_code, 201, res.data)
        self.assertTrue(res.data["is_verified_purchase"])

class ProductWishlistTests(TestCase):
    """Server-backed wishlist: add, idempotency, list, remove, auth."""

    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            "wish@example.com", "strongpass123", is_email_verified=True
        )
        self.client.force_authenticate(user=self.user)
        self.category = Category.objects.create(
            name="Grocery", is_active=True, sort_order=0
        )
        self.store = Store.objects.create(
            name="Wish Store", city="Pune", state="MH",
            postal_code="411001", latitude=Decimal("18.5204"),
            longitude=Decimal("73.8567"), is_active=True,
        )
        self.product = Product.objects.create(
            name="Wish Coffee", category=self.category, brand="BrewCo",
            is_active=True,
        )
        v = ProductVariant.objects.create(
            product=self.product, name="std", sku="WISH-1",
            price=Decimal("200.00"), is_active=True,
        )
        StockItem.objects.create(store=self.store, variant=v, quantity=3)

    def _url(self):
        return f"/api/v1/products/wishlist/{self.product.slug}/"

    def test_requires_auth(self):
        anon = APIClient()
        res = anon.get("/api/v1/products/wishlist/")
        self.assertIn(res.status_code, (401, 403))
        res = anon.post(self._url())
        self.assertIn(res.status_code, (401, 403))

    def test_add_then_list_then_remove(self):
        res = self.client.post(self._url())
        self.assertEqual(res.status_code, 201, res.data)
        self.assertTrue(res.data["added"])
        self.assertEqual(res.data["count"], 1)

        res = self.client.get("/api/v1/products/wishlist/")
        self.assertEqual(res.status_code, 200)
        slugs = [r["slug"] for r in res.data["results"]]
        self.assertEqual(slugs, [self.product.slug])

        res = self.client.delete(self._url())
        self.assertEqual(res.status_code, 200)
        self.assertFalse(res.data["added"])
        self.assertEqual(res.data["count"], 0)
        res = self.client.get("/api/v1/products/wishlist/")
        self.assertEqual(res.data["count"], 0)

    def test_add_is_idempotent(self):
        self.client.post(self._url())
        res = self.client.post(self._url())
        self.assertEqual(res.status_code, 200, res.data)
        self.assertFalse(res.data["added"])
        self.assertEqual(res.data["count"], 1)

    def test_delete_missing_is_idempotent(self):
        res = self.client.delete(self._url())
        self.assertEqual(res.status_code, 200)
        self.assertEqual(res.data["count"], 0)


class ProductRatingSortAndOffersTests(TestCase):
    """sort=rating ordering + coupon-backed 'offers' on product detail."""

    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(
            "buyer@example.com", "strongpass123", is_email_verified=True
        )
        self.client.force_authenticate(user=self.user)
        self.category = Category.objects.create(
            name="Grocery", is_active=True, sort_order=0
        )
        self.store = Store.objects.create(
            name="Sort Store", city="Pune", state="MH",
            postal_code="411001", latitude=Decimal("18.5204"),
            longitude=Decimal("73.8567"), is_active=True,
        )
        self.unrated = self._mk("Unrated Item")
        self.four = self._mk("Four Star Item")
        self.five = self._mk("Five Star Item")

    def _mk(self, name):
        p = Product.objects.create(
            name=name, category=self.category, brand="SortCo",
            is_active=True,
        )
        v = ProductVariant.objects.create(
            product=p, name="std", sku=f"S-{name[:5]}",
            price=Decimal("100.00"), is_active=True,
        )
        StockItem.objects.create(store=self.store, variant=v, quantity=5)
        return p

    def _review(self, product, rating):
        from .models import ProductReview

        ProductReview.objects.create(
            product=product, user=self.user, rating=rating, body="ok",
            is_approved=True,
        )

    def test_sort_by_rating_desc_nulls_last(self):
        self._review(self.four, 4)
        self._review(self.five, 5)
        res = self.client.get("/api/v1/products/", {"sort": "rating"})
        self.assertEqual(res.status_code, 200)
        slugs = [r["slug"] for r in res.data["results"]]
        self.assertEqual(slugs, [self.five.slug, self.four.slug, self.unrated.slug])

    def test_sorted_list_still_hides_inactive_stockless_products(self):
        # Regression: early sort returns used to skip visibility filters.
        ghost = Product.objects.create(
            name="Ghost", category=self.category, brand="SortCo",
            is_active=False,
        )
        for sort in ("rating", "price_asc", "newest"):
            res = self.client.get("/api/v1/products/", {"sort": sort})
            slugs = [r["slug"] for r in res.data["results"]]
            self.assertNotIn(ghost.slug, slugs)

    def test_detail_embeds_active_applicable_coupons(self):
        from django.utils import timezone

        from admin_panel.models import Coupon

        now = timezone.now()
        live = Coupon.objects.create(
            code="SAVE50", name="Flat 50 off", discount_type="FIXED",
            discount_value=Decimal("50.00"), applies_to="ALL",
            start_date=now - timedelta(days=1), end_date=now + timedelta(days=30),
        )
        Coupon.objects.create(
            code="EXPIRED10", name="Old deal", discount_type="PERCENTAGE",
            discount_value=Decimal("10.00"), applies_to="ALL",
            start_date=now - timedelta(days=30), end_date=now - timedelta(days=1),
        )
        Coupon.objects.create(
            code="OTHERCAT", name="Other cat", discount_type="PERCENTAGE",
            discount_value=Decimal("5.00"), applies_to="PRODUCT",
            start_date=now - timedelta(days=1), end_date=now + timedelta(days=30),
            product=self.unrated,  # applies only to a different product
        )
        res = self.client.get(f"/api/v1/products/{self.four.slug}/")
        self.assertEqual(res.status_code, 200)
        codes = [o["code"] for o in res.data["offers"]]
        self.assertEqual(codes, [live.code])

        res = self.client.get(f"/api/v1/products/{self.unrated.slug}/")
        codes = [o["code"] for o in res.data["offers"]]
        self.assertIn("SAVE50", codes)
        self.assertIn("OTHERCAT", codes)
