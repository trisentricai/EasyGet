from decimal import Decimal

from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from categories.models import Category
from orders.models import Order
from products.models import Product, ProductVariant
from stores.models import Store
from tenants.services import provision_tenant

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


class PaymentTenancyTests(TestCase):
    """Payments inherit tenancy via order; refunds scoped the same way."""

    def setUp(self):
        self.client = APIClient()
        self.merchant_a = User.objects.create_user(
            "pay.a@example.com", "strongpass123", is_email_verified=True
        )
        self.merchant_b = User.objects.create_user(
            "pay.b@example.com", "strongpass123",
            role=User.Role.STORE_MANAGER, is_email_verified=True,
        )
        self.customer = User.objects.create_user(
            "pay.cust@example.com", "strongpass123", is_email_verified=True
        )
        self.tenant_a = provision_tenant(self.merchant_a, "Pay Tenant A")
        self.tenant_b = provision_tenant(self.merchant_b, "Pay Tenant B")
        self.store_a = Store.objects.create(
            name="Pay Store A", city="Pune", state="MH", postal_code="411001",
            latitude=Decimal("18.5204"), longitude=Decimal("73.8567"),
            tenant=self.tenant_a,
        )
        self.order_a = Order.objects.create(
            user=self.customer, store=self.store_a,
            subtotal=Decimal("700.00"), total=Decimal("700.00"),
        )
        self.payment_a = Payment.objects.create(
            order=self.order_a, user=self.customer,
            gateway=Payment.Gateway.COD, amount=Decimal("700.00"),
        )

    def test_other_merchant_cannot_see_foreign_payment(self):
        self.client.force_authenticate(user=self.merchant_b)
        res = self.client.get(f"/api/v1/payments/{self.payment_a.id}/")
        self.assertEqual(res.status_code, 404)

    def test_own_merchant_sees_tenant_payment(self):
        self.client.force_authenticate(user=self.merchant_a)
        res = self.client.get(f"/api/v1/payments/{self.payment_a.id}/")
        self.assertEqual(res.status_code, 200)

    def test_customer_sees_own_payment(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.get(f"/api/v1/payments/{self.payment_a.id}/")
        self.assertEqual(res.status_code, 200)

    def test_other_merchant_sees_no_refunds(self):
        Refund.objects.create(
            payment=self.payment_a, amount=Decimal("100.00"), reason="Test",
        )
        self.client.force_authenticate(user=self.merchant_b)
        res = self.client.get("/api/v1/payments/refunds/")
        data = res.data["results"] if isinstance(res.data, dict) else res.data
        self.assertEqual(list(data), [])

class PaymentApiSecurityTests(TestCase):
    """Order ownership on payment create, staff-only webhook, URL-payment
    refund validation."""

    def setUp(self):
        self.client = APIClient()
        self.customer = User.objects.create_user(
            "sec.cust@example.com", "strongpass123", is_email_verified=True
        )
        self.stranger = User.objects.create_user(
            "sec.stranger@example.com", "strongpass123", is_email_verified=True
        )
        self.merchant = User.objects.create_user(
            "sec.merchant@example.com", "strongpass123",
            role=User.Role.STORE_MANAGER, is_email_verified=True,
        )
        self.admin = User.objects.create_user(
            "sec.admin@example.com", "strongpass123",
            role=User.Role.ADMIN, is_staff=True, is_email_verified=True,
        )
        self.tenant = provision_tenant(self.merchant, "Sec Tenant")
        self.store = Store.objects.create(
            name="Sec Store", city="Pune", state="MH", postal_code="411001",
            latitude=Decimal("18.5204"), longitude=Decimal("73.8567"),
            tenant=self.tenant,
        )
        self.order = Order.objects.create(
            user=self.customer, store=self.store,
            subtotal=Decimal("700.00"), total=Decimal("700.00"),
        )

    def test_cannot_attach_payment_to_foreign_order(self):
        self.client.force_authenticate(user=self.stranger)
        res = self.client.post(
            "/api/v1/payments/",
            {"order": str(self.order.id), "gateway": "COD", "amount": "700.00"},
            format="json",
        )
        self.assertEqual(res.status_code, 400)
        self.assertFalse(Payment.objects.filter(order=self.order).exists())

    def test_owner_can_attach_payment(self):
        self.client.force_authenticate(user=self.customer)
        res = self.client.post(
            "/api/v1/payments/",
            {"order": str(self.order.id), "gateway": "COD", "amount": "700.00"},
            format="json",
        )
        self.assertEqual(res.status_code, 201)

    def test_webhook_rejected_for_store_manager(self):
        self.client.force_authenticate(user=self.merchant)
        res = self.client.post(
            "/api/v1/payments/webhook/",
            {
                "gateway": "RAZORPAY",
                "event": "payment.succeeded",
                "payload": {"payment_id": "whatever"},
            },
            format="json",
        )
        self.assertEqual(res.status_code, 403)

    def test_refund_validates_against_url_payment(self):
        payment = Payment.objects.create(
            order=self.order, user=self.customer,
            gateway=Payment.Gateway.COD, amount=Decimal("700.00"),
        )
        payment.mark_succeeded()
        self.client.force_authenticate(user=self.merchant)
        res = self.client.post(
            f"/api/v1/payments/{payment.id}/refund/",
            {"amount": "100.00", "reason": "Return"},
            format="json",
        )
        self.assertEqual(res.status_code, 201)
        refund = Refund.objects.get(payment=payment)
        self.assertEqual(refund.amount, Decimal("100.00"))

    def test_refund_amount_cap_enforced(self):
        payment = Payment.objects.create(
            order=self.order, user=self.customer,
            gateway=Payment.Gateway.COD, amount=Decimal("700.00"),
        )
        payment.mark_succeeded()
        self.client.force_authenticate(user=self.merchant)
        res = self.client.post(
            f"/api/v1/payments/{payment.id}/refund/",
            {"amount": "9999.00", "reason": "Greedy"},
            format="json",
        )
        self.assertEqual(res.status_code, 400)
