from decimal import Decimal

from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from categories.models import Category
from products.models import Product, ProductVariant
from stores.models import Store
from tenants.services import provision_tenant

from .models import Cart, CartItem

User = get_user_model()


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


class CartTenancyTests(TestCase):
    """Carts are customer-owned; the tenant guard blocks cross-catalog mixing."""

    def setUp(self):
        self.client = APIClient()
        self.merchant_a = User.objects.create_user(
            "cart.a@example.com", "strongpass123", is_email_verified=True
        )
        self.merchant_b = User.objects.create_user(
            "cart.b@example.com", "strongpass123", is_email_verified=True
        )
        self.customer = User.objects.create_user(
            "cart.cust@example.com", "strongpass123", is_email_verified=True
        )
        self.tenant_a = provision_tenant(self.merchant_a, "Cart Tenant A")
        self.tenant_b = provision_tenant(self.merchant_b, "Cart Tenant B")
        self.store_a = Store.objects.create(
            name="Cart Store A", city="Pune", state="MH", postal_code="411001",
            latitude=Decimal("18.5204"), longitude=Decimal("73.8567"),
            tenant=self.tenant_a,
        )
        category = Category.objects.create(name="Grocery", is_active=True)
        product_a = Product.objects.create(
            name="Tenant A Rice", category=category, tenant=self.tenant_a,
            mrp=Decimal("800.00"), is_active=True,
        )
        self.variant_a = ProductVariant.objects.create(
            product=product_a, name="5kg", sku="CART-A-5KG",
            price=Decimal("700.00"), is_active=True,
        )
        product_b = Product.objects.create(
            name="Tenant B Rice", category=category, tenant=self.tenant_b,
            mrp=Decimal("800.00"), is_active=True,
        )
        self.variant_b = ProductVariant.objects.create(
            product=product_b, name="5kg", sku="CART-B-5KG",
            price=Decimal("700.00"), is_active=True,
        )

    def test_cart_bound_to_store_inherits_tenant(self):
        cart = Cart.objects.create(user=self.customer, store=self.store_a)
        self.assertEqual(cart.tenant_id, self.tenant_a.id)

    def test_add_same_tenant_variant_ok(self):
        Cart.objects.create(user=self.customer, store=self.store_a)
        self.client.force_authenticate(user=self.customer)
        res = self.client.post(
            "/api/v1/cart/items/",
            {"variant_id": self.variant_a.id, "quantity": 1},
            format="json",
        )
        self.assertEqual(res.status_code, 201)

    def test_add_cross_tenant_variant_rejected(self):
        Cart.objects.create(user=self.customer, store=self.store_a)
        self.client.force_authenticate(user=self.customer)
        res = self.client.post(
            "/api/v1/cart/items/",
            {"variant_id": self.variant_b.id, "quantity": 1},
            format="json",
        )
        self.assertEqual(res.status_code, 400)

    def test_merge_cross_tenant_carts_rejected(self):
        store_b = Store.objects.create(
            name="Cart Store B", city="Pune", state="MH", postal_code="411001",
            latitude=Decimal("18.5204"), longitude=Decimal("73.8567"),
            tenant=self.tenant_b,
        )
        Cart.objects.create(user=self.customer, store=self.store_a)
        Cart.objects.create(session_key="anon-b", store=store_b)
        self.client.force_authenticate(user=self.customer)
        res = self.client.post(
            "/api/v1/cart/merge/", {"session_key": "anon-b"}, format="json"
        )
        self.assertEqual(res.status_code, 400)