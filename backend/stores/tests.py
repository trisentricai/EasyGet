from decimal import Decimal

from django.contrib.auth import get_user_model
from django.db import IntegrityError, transaction
from django.test import TestCase
from rest_framework.test import APIClient

from .models import Store

User = get_user_model()


def mk_store(name, **kwargs):
    defaults = dict(
        city="Pune",
        state="MH",
        postal_code="411001",
        latitude=Decimal("18.5204"),
        longitude=Decimal("73.8567"),
        is_active=True,
    )
    defaults.update(kwargs)
    return Store.objects.create(name=name, **defaults)


def rows(res):
    """List payloads are plain arrays; be tolerant of pagination."""
    data = res.data
    if isinstance(data, dict) and "results" in data:
        return data["results"]
    return data


class PlatformStoreFlagTests(TestCase):
    def test_platform_store_auto_created_by_migration(self):
        platform = Store.objects.get(is_platform=True)
        self.assertEqual(platform.name, "EASYGET")
        self.assertEqual(platform.slug, "easyget")
        self.assertIsNone(platform.tenant_id)
        self.assertTrue(platform.is_active)
        self.assertEqual(platform.city, "Bengaluru")

    def test_only_one_platform_store_allowed(self):
        with self.assertRaises(IntegrityError):
            with transaction.atomic():
                Store.objects.create(
                    name="Second Platform",
                    slug="second-platform",
                    is_platform=True,
                    address_line1="x",
                    city="x",
                    state="x",
                    postal_code="1",
                    latitude=Decimal("0"),
                    longitude=Decimal("0"),
                )


class PlatformStoreVisibilityTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.customer = User.objects.create_user(
            "pfcust@example.com", "strongpass123", is_email_verified=True
        )
        self.admin = User.objects.create_superuser("pfadmin@example.com", "strongpass123")
        self.merchant_store = mk_store("Merchant Visible Store")

    def test_store_list_excludes_platform_for_non_staff(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.get("/api/v1/stores/")
        self.assertEqual(res.status_code, 200)
        slugs = [s["slug"] for s in rows(res)]
        self.assertNotIn("easyget", slugs)
        self.assertIn(self.merchant_store.slug, slugs)
        self.assertFalse([s for s in rows(res) if s.get("is_platform")])

    def test_store_list_includes_platform_for_staff_with_flag(self):
        self.client.force_authenticate(user=self.admin)
        res = self.client.get("/api/v1/stores/")
        self.assertEqual(res.status_code, 200)
        platform_rows = [s for s in rows(res) if s.get("is_platform")]
        self.assertEqual(len(platform_rows), 1)
        self.assertEqual(platform_rows[0]["slug"], "easyget")

    def test_store_detail_platform_hidden_from_non_staff(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.get("/api/v1/stores/easyget/")
        self.assertEqual(res.status_code, 404)

    def test_store_detail_platform_visible_to_staff(self):
        self.client.force_authenticate(user=self.admin)
        res = self.client.get("/api/v1/stores/easyget/")
        self.assertEqual(res.status_code, 200)
