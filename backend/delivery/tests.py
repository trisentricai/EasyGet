from decimal import Decimal

from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from categories.models import Category
from orders.models import Order
from products.models import Product, ProductVariant
from stores.models import Store
from tenants.services import provision_tenant

from .models import DeliveryAssignment

User = get_user_model()


class DeliveryTenancyTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.merchant_a = User.objects.create_user(
            "del.a@example.com", "strongpass123", is_email_verified=True
        )
        self.merchant_b = User.objects.create_user(
            "del.b@example.com", "strongpass123", is_email_verified=True
        )
        self.agent = User.objects.create_user(
            "del.agent@example.com", "strongpass123",
            role=User.Role.DELIVERY_AGENT, is_email_verified=True,
        )
        self.plain = User.objects.create_user(
            "del.plain@example.com", "strongpass123", is_email_verified=True
        )
        self.customer = User.objects.create_user(
            "del.cust@example.com", "strongpass123", is_email_verified=True
        )
        self.tenant_a = provision_tenant(self.merchant_a, "Del Tenant A")
        self.tenant_b = provision_tenant(self.merchant_b, "Del Tenant B")
        self.store_a = Store.objects.create(
            name="Del Store A", city="Pune", state="MH", postal_code="411001",
            latitude=Decimal("18.5204"), longitude=Decimal("73.8567"),
            tenant=self.tenant_a,
        )
        category = Category.objects.create(name="Grocery", is_active=True)
        product_a = Product.objects.create(
            name="Tenant A Rice", category=category, tenant=self.tenant_a,
            mrp=Decimal("800.00"), is_active=True,
        )
        ProductVariant.objects.create(
            product=product_a, name="5kg", sku="DEL-A-5KG",
            price=Decimal("700.00"), is_active=True,
        )
        self.order_a = Order.objects.create(
            user=self.customer, store=self.store_a,
            subtotal=Decimal("700.00"), total=Decimal("700.00"),
            status=Order.Status.CONFIRMED,
        )

    def _assign(self, user, order=None, agent=None):
        self.client.force_authenticate(user=user)
        return self.client.post(
            "/api/v1/delivery/assign/",
            {"order": str((order or self.order_a).id),
             "agent": (agent or self.agent).id},
            format="json",
        )

    def test_assign_binds_tenant(self):
        res = self._assign(self.merchant_a)
        self.assertEqual(res.status_code, 201)
        a = DeliveryAssignment.objects.get(order=self.order_a)
        self.assertEqual(a.tenant_id, self.tenant_a.id)
        self.assertEqual(a.status, DeliveryAssignment.Status.ASSIGNED)

    def test_assign_rejects_non_agent(self):
        res = self._assign(self.merchant_a, agent=self.plain)
        self.assertEqual(res.status_code, 400)

    def test_assign_rejects_unready_order(self):
        self.order_a.status = Order.Status.PENDING
        self.order_a.save()
        res = self._assign(self.merchant_a)
        self.assertEqual(res.status_code, 400)

    def test_other_merchant_assign_returns_404(self):
        res = self._assign(self.merchant_b)
        self.assertEqual(res.status_code, 404)
        self.assertFalse(
            DeliveryAssignment.objects.filter(order=self.order_a).exists()
        )

    def test_agent_advance_flow_syncs_order(self):
        self._assign(self.merchant_a)
        a = DeliveryAssignment.objects.get(order=self.order_a)
        self.client.force_authenticate(user=self.agent)
        for nxt in ["ACCEPTED", "PICKED_UP", "OUT_FOR_DELIVERY", "DELIVERED"]:
            res = self.client.post(
                f"/api/v1/delivery/{a.id}/advance/", {"status": nxt}, format="json"
            )
            self.assertEqual(res.status_code, 200, nxt)
        a.refresh_from_db()
        self.order_a.refresh_from_db()
        self.assertEqual(a.status, "DELIVERED")
        self.assertEqual(self.order_a.status, Order.Status.DELIVERED)
        self.assertIsNotNone(a.delivered_at)

    def test_advance_rejects_skip(self):
        self._assign(self.merchant_a)
        a = DeliveryAssignment.objects.get(order=self.order_a)
        self.client.force_authenticate(user=self.agent)
        res = self.client.post(
            f"/api/v1/delivery/{a.id}/advance/",
            {"status": "DELIVERED"},
            format="json",
        )
        self.assertEqual(res.status_code, 400)

    def test_other_merchant_cannot_see_assignment(self):
        self._assign(self.merchant_a)
        a = DeliveryAssignment.objects.get(order=self.order_a)
        self.client.force_authenticate(user=self.merchant_b)
        res = self.client.get(f"/api/v1/delivery/{a.id}/")
        self.assertEqual(res.status_code, 404)

    def test_agent_sees_own_queue(self):
        self._assign(self.merchant_a)
        self.client.force_authenticate(user=self.agent)
        res = self.client.get("/api/v1/delivery/")
        ids = [str(r["id"]) for r in res.data]
        a = DeliveryAssignment.objects.get(order=self.order_a)
        self.assertIn(str(a.id), ids)

    def test_agents_endpoint_lists_agents(self):
        self.client.force_authenticate(user=self.merchant_a)
        res = self.client.get("/api/v1/delivery/agents/")
        self.assertEqual(res.status_code, 200)
        emails = [r["email"] for r in res.data]
        self.assertIn(self.agent.email, emails)
        self.assertNotIn(self.plain.email, emails)

    def test_agents_endpoint_hides_other_tenants_agents(self):
        # Once assigned inside tenant A, the agent must disappear from
        # merchant B's list (unassigned agents remain a shared pool).
        self._assign(self.merchant_a)
        self.client.force_authenticate(user=self.merchant_b)
        res = self.client.get("/api/v1/delivery/agents/")
        self.assertEqual(res.status_code, 200)
        emails = [r["email"] for r in res.data]
        self.assertNotIn(self.agent.email, emails)

        self.client.force_authenticate(user=self.merchant_a)
        res = self.client.get("/api/v1/delivery/agents/")
        self.assertIn(self.agent.email, [r["email"] for r in res.data])

    def test_raw_create_blocked_for_non_admin(self):
        self.client.force_authenticate(user=self.plain)
        res = self.client.post(
            "/api/v1/delivery/",
            {"order": str(self.order_a.id), "agent": self.agent.id},
            format="json",
        )
        self.assertIn(res.status_code, (401, 403))
        self.assertFalse(DeliveryAssignment.objects.exists())

    def test_customer_cannot_repoint_own_assignment(self):
        self._assign(self.merchant_a)
        a = DeliveryAssignment.objects.get(order=self.order_a)
        self.client.force_authenticate(user=self.customer)
        res = self.client.patch(
            f"/api/v1/delivery/{a.id}/",
            {"agent": self.plain.id},
            format="json",
        )
        self.assertIn(res.status_code, (401, 403))
        a.refresh_from_db()
        self.assertEqual(a.agent_id, self.agent.id)
