from decimal import Decimal
from datetime import timedelta

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.utils import timezone

from .models import AdminAction, Banner, Coupon, ScheduledTask, SystemConfig

User = get_user_model()


class SystemConfigTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(email="config@test.com", password="pass")

    def test_create_config(self):
        config = SystemConfig.objects.create(
            key="site_name",
            value="EasyGet",
            config_type=SystemConfig.ConfigType.STRING,
            description="Site name",
            is_public=True,
        )
        self.assertEqual(config.get_typed_value(), "EasyGet")

    def test_typed_values(self):
        configs = [
            ("int_val", "42", SystemConfig.ConfigType.INTEGER, 42),
            ("dec_val", "3.14", SystemConfig.ConfigType.DECIMAL, Decimal("3.14")),
            ("bool_val", "true", SystemConfig.ConfigType.BOOLEAN, True),
            ('json_val', '{"a": 1}', SystemConfig.ConfigType.JSON, {"a": 1}),
        ]
        for key, val, ctype, expected in configs:
            config = SystemConfig.objects.create(
                key=key, value=val, config_type=ctype
            )
            self.assertEqual(config.get_typed_value(), expected)


class BannerTests(TestCase):
    def test_create_banner(self):
        banner = Banner.objects.create(
            title="Summer Sale",
            subtitle="Up to 50% off",
            image="banners/summer.jpg",
            link_url="/sale",
            link_text="Shop Now",
            type=Banner.BannerType.CAROUSEL,
            position=1,
        )
        self.assertTrue(banner.is_valid())
        self.assertEqual(str(banner), "Summer Sale")


class CouponTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(email="coupon@test.com", password="pass")

    def test_percentage_coupon(self):
        coupon = Coupon.objects.create(
            code="SAVE20",
            name="20% Off",
            discount_type=Coupon.DiscountType.PERCENTAGE,
            discount_value=20,
            start_date=timezone.now(),
            end_date=timezone.now() + timedelta(days=30),
        )
        valid, _ = coupon.is_valid(order_value=Decimal("1000"))
        self.assertTrue(valid)

    def test_fixed_coupon(self):
        coupon = Coupon.objects.create(
            code="SAVE100",
            name="Save 100",
            discount_type=Coupon.DiscountType.FIXED,
            discount_value=100,
            start_date=timezone.now(),
            end_date=timezone.now() + timedelta(days=30),
        )
        valid, _ = coupon.is_valid(order_value=Decimal("500"))
        self.assertTrue(valid)

    def test_coupon_expired(self):
        coupon = Coupon.objects.create(
            code="OLD",
            name="Expired",
            discount_type=Coupon.DiscountType.FIXED,
            discount_value=50,
            start_date=timezone.now() - timedelta(days=10),
            end_date=timezone.now() - timedelta(days=1),
        )
        valid, _ = coupon.is_valid()
        self.assertFalse(valid)


class ScheduledTaskTests(TestCase):
    def test_create_task(self):
        task = ScheduledTask.objects.create(
            name="Daily Report",
            task_type=ScheduledTask.TaskType.CELERY_TASK,
            target="analytics.tasks.generate_daily_report",
            schedule="0 0 * * *",
        )
        self.assertEqual(task.status, ScheduledTask.Status.PENDING)
        self.assertEqual(task.task_type, "CELERY_TASK")

class ReviewModerationTests(TestCase):
    """Admin review moderation API: list, approve/hide, delete, permissions."""

    def setUp(self):
        from rest_framework.test import APIClient

        from categories.models import Category
        from inventory.models import StockItem
        from products.models import Product, ProductReview, ProductVariant
        from stores.models import Store

        self.client = APIClient()
        self.admin = User.objects.create_user(
            "mod@test.com", "pass", role=User.Role.ADMIN
        )
        self.shopper = User.objects.create_user("shopper@test.com", "pass")
        self.category = Category.objects.create(
            name="Mod Cat", is_active=True, sort_order=0
        )
        self.store = Store.objects.create(
            name="Mod Store", city="Pune", state="MH",
            postal_code="411001", latitude=Decimal("18.5204"),
            longitude=Decimal("73.8567"), is_active=True,
        )
        self.product = Product.objects.create(
            name="Moderated Product", category=self.category,
            brand="ModCo", is_active=True,
        )
        v = ProductVariant.objects.create(
            product=self.product, name="std", sku="MOD-1",
            price=Decimal("99.00"), is_active=True,
        )
        StockItem.objects.create(store=self.store, variant=v, quantity=1)
        self.review = ProductReview.objects.create(
            product=self.product, user=self.shopper, rating=4,
            body="needs moderation", is_approved=False,
        )

    def _list(self, **params):
        self.client.force_authenticate(user=self.admin)
        return self.client.get("/api/v1/admin/reviews/", params)

    def test_admin_sees_unapproved_filtered_list(self):
        res = self._list(approved="false")
        self.assertEqual(res.status_code, 200, res.data)
        # No default DRF pagination: the list endpoint returns a bare array.
        ids = [r["id"] for r in res.data]
        self.assertIn(self.review.id, ids)
        row = next(r for r in res.data if r["id"] == self.review.id)
        self.assertEqual(row["product_slug"], self.product.slug)
        self.assertEqual(row["user_email"], "shopper@test.com")
        self.assertFalse(row["is_approved"])

    def test_admin_approves_review(self):
        self.client.force_authenticate(user=self.admin)
        res = self.client.patch(
            f"/api/v1/admin/reviews/{self.review.id}/",
            {"is_approved": True}, format="json",
        )
        self.assertEqual(res.status_code, 200, res.data)
        self.review.refresh_from_db()
        self.assertTrue(self.review.is_approved)

    def test_admin_deletes_review(self):
        self.client.force_authenticate(user=self.admin)
        res = self.client.delete(f"/api/v1/admin/reviews/{self.review.id}/")
        self.assertIn(res.status_code, (200, 204))
        self.assertFalse(
            type(self.review).objects.filter(pk=self.review.pk).exists()
        )

    def test_customer_forbidden(self):
        self.client.force_authenticate(user=self.shopper)
        res = self.client.get("/api/v1/admin/reviews/")
        self.assertEqual(res.status_code, 403)

    def test_anonymous_forbidden(self):
        res = self.client.get("/api/v1/admin/reviews/")
        self.assertIn(res.status_code, (401, 403))
