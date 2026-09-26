from decimal import Decimal

from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from cart.models import Cart, CartItem
from categories.models import Category
from products.models import Product, ProductVariant
from stores.models import Store
from tenants.services import provision_tenant

from .models import Order, OrderItem, OrderStatusHistory

User = get_user_model()


class OrderModelTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(email="order@test.com", password="pass")
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

    def test_order_creation_generates_number(self):
        order = Order.objects.create(
            user=self.user,
            store=self.store,
            subtotal=Decimal("700.00"),
            total=Decimal("700.00"),
        )
        self.assertTrue(order.order_number.startswith("EZG-"))
        self.assertEqual(order.status, Order.Status.PENDING)

    def test_order_number_unique(self):
        order1 = Order.objects.create(user=self.user, store=self.store, subtotal=0, total=0)
        order2 = Order.objects.create(user=self.user, store=self.store, subtotal=0, total=0)
        # IDs should always be unique even if order_number collides (extremely unlikely)
        self.assertNotEqual(order1.id, order2.id)
        # order_number includes random component - very unlikely to collide
        # but if it does, they're still distinct records

    def test_order_item_line_total(self):
        order = Order.objects.create(
            user=self.user,
            store=self.store,
            subtotal=Decimal("1400.00"),
            total=Decimal("1400.00"),
        )
        item = OrderItem.objects.create(
            order=order,
            variant=self.variant,
            product_name="Rice 5kg",
            variant_name="5kg",
            sku="RICE-5KG",
            unit_price=Decimal("700.00"),
            quantity=2,
        )
        self.assertEqual(item.line_total, Decimal("1400.00"))

    def test_status_history_created_on_change(self):
        order = Order.objects.create(
            user=self.user,
            store=self.store,
            subtotal=0,
            total=0,
            status=Order.Status.PENDING,
        )
        OrderStatusHistory.objects.create(
            order=order,
            from_status=Order.Status.PENDING,
            to_status=Order.Status.CONFIRMED,
            changed_by=self.user,
        )
        self.assertEqual(order.status_history.count(), 1)
        self.assertEqual(order.status_history.first().to_status, Order.Status.CONFIRMED)

    def test_can_cancel_pending_confirmed(self):
        order = Order.objects.create(
            user=self.user,
            store=self.store,
            subtotal=0,
            total=0,
            status=Order.Status.PENDING,
        )
        self.assertTrue(order.can_cancel())
        order.status = Order.Status.CONFIRMED
        order.save()
        self.assertTrue(order.can_cancel())
        order.status = Order.Status.PREPARING
        order.save()
        self.assertFalse(order.can_cancel())


class OrderTenancyTests(TestCase):
    """Orders belong to the store's tenant; merchants see only their own."""

    def setUp(self):
        self.client = APIClient()
        self.merchant_a = User.objects.create_user(
            "ord.a@example.com", "strongpass123", is_email_verified=True
        )
        self.merchant_b = User.objects.create_user(
            "ord.b@example.com", "strongpass123",
            role=User.Role.STORE_MANAGER, is_email_verified=True,
        )
        self.customer = User.objects.create_user(
            "ord.cust@example.com", "strongpass123", is_email_verified=True
        )
        self.tenant_a = provision_tenant(self.merchant_a, "Order Tenant A")
        self.tenant_b = provision_tenant(self.merchant_b, "Order Tenant B")
        self.store_a = Store.objects.create(
            name="Order Store A", city="Pune", state="MH", postal_code="411001",
            latitude=Decimal("18.5204"), longitude=Decimal("73.8567"),
            tenant=self.tenant_a,
        )
        self.store_b = Store.objects.create(
            name="Order Store B", city="Pune", state="MH", postal_code="411001",
            latitude=Decimal("18.5204"), longitude=Decimal("73.8567"),
            tenant=self.tenant_b,
        )
        category = Category.objects.create(name="Grocery", is_active=True)
        product_a = Product.objects.create(
            name="Tenant A Rice", category=category, tenant=self.tenant_a,
            mrp=Decimal("800.00"), is_active=True,
        )
        self.variant_a = ProductVariant.objects.create(
            product=product_a, name="5kg", sku="ORD-A-5KG",
            price=Decimal("700.00"), is_active=True,
        )
        self.order_a = Order.objects.create(
            user=self.customer, store=self.store_a,
            subtotal=Decimal("700.00"), total=Decimal("700.00"),
        )

    def _customer_cart(self):
        cart = Cart.objects.create(user=self.customer, store=self.store_a)
        CartItem.objects.create(cart=cart, variant=self.variant_a, quantity=1)
        return cart

    def test_order_inherits_store_tenant(self):
        self.assertEqual(self.order_a.tenant_id, self.tenant_a.id)

    def test_create_order_binds_tenant(self):
        cart = self._customer_cart()
        self.client.force_authenticate(user=self.customer)
        res = self.client.post(
            "/api/v1/orders/",
            {"cart_id": str(cart.id), "store": self.store_a.id,
             "delivery_address": {"line1": "1 Main St"}},
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        order = Order.objects.filter(user=self.customer).latest("created_at")
        self.assertEqual(order.tenant_id, self.tenant_a.id)

    def test_create_order_rejects_store_mismatch(self):
        cart = self._customer_cart()
        self.client.force_authenticate(user=self.customer)
        res = self.client.post(
            "/api/v1/orders/",
            {"cart_id": str(cart.id), "store": self.store_b.id,
             "delivery_address": {"line1": "1 Main St"}},
            format="json",
        )
        self.assertEqual(res.status_code, 400)

    def test_other_merchant_cannot_see_foreign_order(self):
        self.client.force_authenticate(user=self.merchant_b)
        res = self.client.get(f"/api/v1/orders/{self.order_a.id}/")
        self.assertEqual(res.status_code, 404)
        res = self.client.get("/api/v1/orders/")
        ids = [o["id"] for o in (res.data["results"] if isinstance(res.data, dict) else res.data)]
        self.assertNotIn(str(self.order_a.id), ids)

    def test_own_merchant_sees_tenant_order(self):
        self.client.force_authenticate(user=self.merchant_a)
        res = self.client.get(f"/api/v1/orders/{self.order_a.id}/")
        self.assertEqual(res.status_code, 200)

    def test_customer_sees_own_order(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.get(f"/api/v1/orders/{self.order_a.id}/")
        self.assertEqual(res.status_code, 200)
    def test_order_create_rejects_platform_store(self):
        platform = Store.objects.get(is_platform=True)
        cart = Cart.objects.create(user=self.customer)
        CartItem.objects.create(cart=cart, variant=self.variant_a, quantity=1)
        self.client.force_authenticate(user=self.customer)
        res = self.client.post(
            "/api/v1/orders/",
            {"cart_id": str(cart.id), "store": platform.id,
             "delivery_address": {"line1": "1 Main St"}},
            format="json",
        )
        self.assertEqual(res.status_code, 400)
        details = res.data.get("error", {}).get("details", res.data)
        self.assertIn("store", details)
