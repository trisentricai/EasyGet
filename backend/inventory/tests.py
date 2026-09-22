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
