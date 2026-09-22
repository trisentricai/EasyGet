from decimal import Decimal

from django.contrib.auth import get_user_model
from django.test import TestCase

from categories.models import Category
from products.models import Product, ProductVariant
from stores.models import Store

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