from decimal import Decimal

from django.test import TestCase

from categories.models import Category

from .models import Product, ProductVariant


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