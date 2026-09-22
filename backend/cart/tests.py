from decimal import Decimal

from django.test import TestCase

from categories.models import Category
from products.models import Product, ProductVariant
from stores.models import Store

from .models import Cart, CartItem


class CartModelTests(TestCase):
    def setUp(self):
        self.store = Store.objects.create(
            name="Test Store",
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

    def test_cart_creation_with_user(self):
        from django.contrib.auth import get_user_model
        User = get_user_model()
        user = User.objects.create_user(email="test@example.com", password="pass")
        cart = Cart.objects.create(user=user, store=self.store)
        self.assertEqual(cart.user, user)
        self.assertEqual(cart.store, self.store)
        self.assertFalse(cart.is_expired)

    def test_cart_creation_with_session(self):
        cart = Cart.objects.create(session_key="abc123", store=self.store)
        self.assertEqual(cart.session_key, "abc123")
        self.assertIsNone(cart.user)

    def test_add_item_creates_cart_item(self):
        cart = Cart.objects.create(store=self.store)
        item = CartItem.objects.create(cart=cart, variant=self.variant, quantity=2)
        self.assertEqual(item.quantity, 2)
        self.assertEqual(item.line_total, Decimal("1400.00"))

    def test_cart_total_items_and_subtotal(self):
        cart = Cart.objects.create(store=self.store)
        CartItem.objects.create(cart=cart, variant=self.variant, quantity=2)
        self.assertEqual(cart.total_items, 2)
        self.assertEqual(cart.subtotal, Decimal("1400.00"))

    def test_unique_cart_item_per_variant(self):
        cart = Cart.objects.create(store=self.store)
        CartItem.objects.create(cart=cart, variant=self.variant, quantity=1)
        with self.assertRaises(Exception):
            CartItem.objects.create(cart=cart, variant=self.variant, quantity=1)

    def test_merge_carts(self):
        from django.contrib.auth import get_user_model
        User = get_user_model()
        user = User.objects.create_user(email="merge@test.com", password="pass")
        cart1 = Cart.objects.create(user=user, store=self.store)
        CartItem.objects.create(cart=cart1, variant=self.variant, quantity=1)
        cart2 = Cart.objects.create(session_key="sess", store=self.store)
        CartItem.objects.create(cart=cart2, variant=self.variant, quantity=2)
        cart1.merge_with(cart2)
        cart1.refresh_from_db()
        self.assertEqual(cart1.items.get(variant=self.variant).quantity, 3)