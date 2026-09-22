from decimal import Decimal

from django.contrib.auth import get_user_model
from django.test import TestCase

from categories.models import Category
from orders.models import Order
from products.models import Product, ProductVariant
from stores.models import Store

from .models import Payment, PaymentMethod, Refund

User = get_user_model()


class PaymentMethodTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(email="pay@test.com", password="pass")

    def test_create_card_method(self):
        pm = PaymentMethod.objects.create(
            user=self.user,
            type=PaymentMethod.Type.CARD,
            card_last4="4242",
            card_brand="Visa",
            card_exp_month=12,
            card_exp_year=2028,
            gateway_token="tok_123",
        )
        self.assertEqual(pm.card_last4, "4242")
        self.assertTrue(pm.is_active)

    def test_create_upi_method(self):
        pm = PaymentMethod.objects.create(
            user=self.user,
            type=PaymentMethod.Type.UPI,
            upi_id="user@paytm",
            gateway_token="upi_123",
        )
        self.assertEqual(pm.upi_id, "user@paytm")

    def test_only_one_default_per_user(self):
        pm1 = PaymentMethod.objects.create(
            user=self.user, type=PaymentMethod.Type.CARD, is_default=True, gateway_token="t1"
        )
        pm2 = PaymentMethod.objects.create(
            user=self.user, type=PaymentMethod.Type.UPI, is_default=True, gateway_token="t2"
        )
        pm1.refresh_from_db()
        self.assertFalse(pm1.is_default)
        self.assertTrue(pm2.is_default)


class PaymentTests(TestCase):
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
        variant = ProductVariant.objects.create(
            product=product,
            name="5kg",
            sku="RICE-5KG",
            price=Decimal("700.00"),
            is_active=True,
        )
        self.order = Order.objects.create(
            user=self.user,
            store=self.store,
            subtotal=Decimal("700.00"),
            total=Decimal("700.00"),
        )

    def test_payment_creation_generates_id(self):
        payment = Payment.objects.create(
            order=self.order,
            user=self.user,
            gateway=Payment.Gateway.RAZORPAY,
            amount=Decimal("700.00"),
        )
        self.assertTrue(payment.payment_id.startswith("PAY-"))
        self.assertEqual(payment.status, Payment.Status.PENDING)

    def test_mark_succeeded(self):
        payment = Payment.objects.create(
            order=self.order,
            user=self.user,
            gateway=Payment.Gateway.RAZORPAY,
            amount=Decimal("700.00"),
        )
        payment.mark_succeeded(gateway_response={"id": "pay_123"})
        self.assertEqual(payment.status, Payment.Status.SUCCEEDED)
        self.assertIsNotNone(payment.processed_at)

    def test_mark_failed(self):
        payment = Payment.objects.create(
            order=self.order,
            user=self.user,
            gateway=Payment.Gateway.RAZORPAY,
            amount=Decimal("700.00"),
        )
        payment.mark_failed("Card declined", gateway_response={"error": "declined"})
        self.assertEqual(payment.status, Payment.Status.FAILED)
        self.assertEqual(payment.failure_reason, "Card declined")


class RefundTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(email="ref@test.com", password="pass")
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
        variant = ProductVariant.objects.create(
            product=product,
            name="5kg",
            sku="RICE-5KG",
            price=Decimal("700.00"),
            is_active=True,
        )
        self.order = Order.objects.create(
            user=self.user,
            store=self.store,
            subtotal=Decimal("700.00"),
            total=Decimal("700.00"),
        )
        self.payment = Payment.objects.create(
            order=self.order,
            user=self.user,
            gateway=Payment.Gateway.RAZORPAY,
            amount=Decimal("700.00"),
        )
        self.payment.mark_succeeded()

    def test_create_refund(self):
        refund = Refund.objects.create(
            payment=self.payment,
            amount=Decimal("350.00"),
            reason="Partial return",
        )
        self.assertTrue(refund.refund_id.startswith("REF-"))
        self.assertEqual(refund.status, Refund.Status.PENDING)

    def test_refund_exceeds_amount_model_allows(self):
        # Model allows creation (validation is in serializer)
        refund = Refund.objects.create(
            payment=self.payment,
            amount=Decimal("800.00"),
            reason="Too much",
        )
        self.assertEqual(refund.amount, Decimal("800.00"))