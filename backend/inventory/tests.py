from decimal import Decimal

from django.contrib.auth import get_user_model
from django.test import TestCase

from categories.models import Category
from products.models import Product, ProductVariant
from stores.models import Store

from .models import StockItem

User = get_user_model()


class StockItemTests(TestCase):
    def setUp(self):
        self.store = Store.objects.create(
            name="Main Store",
            city="Pune",
            state="MH",
            postal_code="411001",
            latitude=Decimal("18.5204"),
            longitude=Decimal("73.8567"),
        )
        category = Category.objects.create(name="Grocery", is_active=True)
        product = Product.objects.create(
            name="Rice 5kg",
            category=category,
            mrp=Decimal("800.00"),
            is_active=True,
        )
        self.variant = ProductVariant.objects.create(
            product=product,
            name="5kg",
            sku="RICE-5KG",
            price=Decimal("700.00"),
            is_active=True,
        )

    def test_default_quantity_is_zero(self):
        item = StockItem.objects.create(store=self.store, variant=self.variant)
        self.assertEqual(item.quantity, 0)
        self.assertFalse(item.is_available)
        self.assertTrue(item.is_low_stock)

    def test_low_stock_threshold(self):
        item = StockItem.objects.create(
            store=self.store,
            variant=self.variant,
            quantity=3,
            low_stock_threshold=5,
        )
        self.assertTrue(item.is_low_stock)
        self.assertTrue(item.is_available)

    def test_above_threshold_not_low(self):
        item = StockItem.objects.create(
            store=self.store,
            variant=self.variant,
            quantity=10,
            low_stock_threshold=5,
        )
        self.assertFalse(item.is_low_stock)
        self.assertTrue(item.is_available)


class StockItemApiSecurityTests(TestCase):
    """POST /api/v1/inventory/ must reject merchants writing into a store
    that belongs to another tenant."""

    def setUp(self):
        from rest_framework.test import APIClient

        from tenants.services import provision_tenant

        self.client = APIClient()
        self.merchant_a = User.objects.create_user(
            "inv.a@example.com", "strongpass123", is_email_verified=True
        )
        self.merchant_b = User.objects.create_user(
            "inv.b@example.com", "strongpass123", is_email_verified=True
        )
        self.tenant_a = provision_tenant(self.merchant_a, "Inv Tenant A")
        self.tenant_b = provision_tenant(self.merchant_b, "Inv Tenant B")
        self.store_a = Store.objects.create(
            name="Inv Store A", city="Pune", state="MH", postal_code="411001",
            latitude=Decimal("18.5204"), longitude=Decimal("73.8567"),
            tenant=self.tenant_a,
        )
        category = Category.objects.create(name="Grocery Sec", is_active=True)
        product_a = Product.objects.create(
            name="Tenant A Rice", category=category, tenant=self.tenant_a,
            mrp=Decimal("800.00"), is_active=True,
        )
        self.variant_a = ProductVariant.objects.create(
            product=product_a, name="5kg", sku="INVSEC-A-5KG",
            price=Decimal("700.00"), is_active=True,
        )

    def test_merchant_cannot_create_stock_in_foreign_store(self):
        self.client.force_authenticate(user=self.merchant_b)
        res = self.client.post(
            "/api/v1/inventory/",
            {"store": self.store_a.id, "variant": self.variant_a.id, "quantity": 1},
            format="json",
        )
        self.assertEqual(res.status_code, 400)
        self.assertFalse(StockItem.objects.filter(store=self.store_a).exists())

    def test_merchant_can_create_stock_in_own_store(self):
        self.client.force_authenticate(user=self.merchant_a)
        res = self.client.post(
            "/api/v1/inventory/",
            {"store": self.store_a.id, "variant": self.variant_a.id, "quantity": 5},
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        item = StockItem.objects.get(store=self.store_a, variant=self.variant_a)
        self.assertEqual(item.quantity, 5)
        self.assertEqual(item.tenant_id, self.tenant_a.id)
