from decimal import Decimal

from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from categories.models import Category
from inventory.models import InventoryTransaction, StockItem
from products.models import Product, ProductVariant
from stores.models import Store
from tenants.models import Tenant, TenantMembership
from tenants.services import provision_tenant

User = get_user_model()

STORES_URL = "/api/v1/stores/"
PRODUCTS_URL = "/api/v1/products/"
INVENTORY_URL = "/api/v1/inventory/"
TRANSACTIONS_URL = "/api/v1/inventory/transactions/"


def adjust_url(pk):
    return f"/api/v1/inventory/{pk}/adjust/"


class TenancyTestBase(TestCase):
    """Two independent merchants (tenants) + a plain customer + a platform admin."""

    def setUp(self):
        self.client = APIClient()

        self.merchant_a = User.objects.create_user(
            "owner.a@example.com", "strongpass123", is_email_verified=True
        )
        self.merchant_b = User.objects.create_user(
            "owner.b@example.com", "strongpass123", is_email_verified=True
        )
        self.customer = User.objects.create_user(
            "customer@example.com", "strongpass123", is_email_verified=True
        )
        self.admin = User.objects.create_superuser(
            "admin@example.com", "strongpass123"
        )

        self.tenant_a = provision_tenant(self.merchant_a, "Merchant A")
        self.tenant_b = provision_tenant(self.merchant_b, "Merchant B")

        self.store_a = self._mk_store("Store A", self.tenant_a)
        self.store_b = self._mk_store("Store B", self.tenant_b)

        self.category = Category.objects.create(name="Grocery", is_active=True)

        self.product_a = self._mk_product("Rice 5kg", self.tenant_a)
        self.variant_a = self._mk_variant(self.product_a, "RICE-5KG")
        self.stock_a = StockItem.objects.create(
            store=self.store_a,
            variant=self.variant_a,
            quantity=10,
            tenant=self.tenant_a,
        )

    # -- factories ---------------------------------------------------------
    def _mk_store(self, name, tenant=None):
        return Store.objects.create(
            name=name,
            city="Pune",
            state="MH",
            postal_code="411001",
            latitude=Decimal("18.5204"),
            longitude=Decimal("73.8567"),
            tenant=tenant,
        )

    def _mk_product(self, name, tenant=None, category=None):
        return Product.objects.create(
            name=name,
            category=category or self.category,
            tenant=tenant,
            mrp=Decimal("800.00"),
            is_active=True,
        )

    def _mk_variant(self, product, sku, price=Decimal("700.00")):
        return ProductVariant.objects.create(
            product=product,
            name=sku,
            sku=sku,
            price=price,
            is_active=True,
        )

    # -- auth helpers ------------------------------------------------------
    def as_user(self, user):
        self.client.force_authenticate(user=user)
        return self.client

    @staticmethod
    def store_payload(**overrides):
        payload = {
            "name": "My New Store",
            "address_line1": "12 MG Road",
            "city": "Pune",
            "state": "MH",
            "postal_code": "411001",
            "latitude": "18.5204",
            "longitude": "73.8567",
        }
        payload.update(overrides)
        return payload


class TenantProvisioningTests(TenancyTestBase):
    def test_store_create_provisions_tenant_with_owner_membership(self):
        new_customer = User.objects.create_user(
            "newmerchant@example.com", "strongpass123", is_email_verified=True
        )
        response = self.as_user(new_customer).post(
            STORES_URL, self.store_payload(), format="json"
        )
        self.assertEqual(response.status_code, 201)
        store = Store.objects.get(slug=response.data["slug"])
        self.assertIsNotNone(store.tenant)
        membership = TenantMembership.objects.get(
            user=new_customer, tenant=store.tenant
        )
        self.assertEqual(membership.role, TenantMembership.Role.OWNER)

    def test_second_store_joins_existing_tenant(self):
        response = self.as_user(self.merchant_a).post(
            STORES_URL, self.store_payload(name="Store A Branch 2"), format="json"
        )
        self.assertEqual(response.status_code, 201)
        store = Store.objects.get(slug=response.data["slug"])
        self.assertEqual(store.tenant_id, self.tenant_a.id)
        # no duplicate membership was created
        self.assertEqual(
            TenantMembership.objects.filter(user=self.merchant_a).count(), 1
        )

    def test_unverified_user_cannot_create_store(self):
        ghost = User.objects.create_user("ghost@example.com", "strongpass123")
        response = self.as_user(ghost).post(
            STORES_URL, self.store_payload(), format="json"
        )
        self.assertEqual(response.status_code, 403)


class StoreIsolationTests(TenancyTestBase):
    def test_owner_can_update_own_store(self):
        response = self.as_user(self.merchant_a).patch(
            f"{STORES_URL}{self.store_a.slug}/",
            {"description": "Fresh groceries daily."},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.store_a.refresh_from_db()
        self.assertEqual(self.store_a.description, "Fresh groceries daily.")

    def test_other_merchant_cannot_update_foreign_store(self):
        response = self.as_user(self.merchant_b).patch(
            f"{STORES_URL}{self.store_a.slug}/",
            {"name": "Hacked Name"},
            format="json",
        )
        self.assertEqual(response.status_code, 403)
        self.store_a.refresh_from_db()
        self.assertEqual(self.store_a.name, "Store A")

    def test_other_merchant_cannot_delete_foreign_store(self):
        response = self.as_user(self.merchant_b).delete(
            f"{STORES_URL}{self.store_a.slug}/"
        )
        self.assertEqual(response.status_code, 403)
        self.assertTrue(Store.objects.filter(pk=self.store_a.pk).exists())

    def test_customer_cannot_update_any_store(self):
        response = self.as_user(self.customer).patch(
            f"{STORES_URL}{self.store_a.slug}/",
            {"name": "Nope"},
            format="json",
        )
        self.assertEqual(response.status_code, 403)


class ProductTenancyTests(TenancyTestBase):
    def test_member_created_product_is_bound_to_their_tenant(self):
        response = self.as_user(self.merchant_b).post(
            PRODUCTS_URL,
            {"name": "Basmati Rice 1kg", "category": self.category.id, "mrp": "200.00"},
            format="json",
        )
        self.assertEqual(response.status_code, 201)
        product = Product.objects.get(slug=response.data["slug"])
        self.assertEqual(product.tenant_id, self.tenant_b.id)

    def test_customer_without_tenant_cannot_create_product(self):
        response = self.as_user(self.customer).post(
            PRODUCTS_URL,
            {"name": "Sneaky Product", "category": self.category.id},
            format="json",
        )
        self.assertEqual(response.status_code, 403)

    def test_other_merchant_cannot_update_foreign_product(self):
        response = self.as_user(self.merchant_b).patch(
            f"{PRODUCTS_URL}{self.product_a.slug}/",
            {"name": "Hacked Product"},
            format="json",
        )
        self.assertIn(response.status_code, {403, 404})
        self.product_a.refresh_from_db()
        self.assertEqual(self.product_a.name, "Rice 5kg")

    def test_unstocked_foreign_product_hidden_from_other_merchants(self):
        hidden = self._mk_product("Secret Prototype", self.tenant_a)
        response = self.as_user(self.merchant_b).get(
            f"{PRODUCTS_URL}{hidden.slug}/"
        )
        self.assertEqual(response.status_code, 404)

    def test_unstocked_own_product_visible_to_owner(self):
        hidden = self._mk_product("Secret Prototype", self.tenant_a)
        response = self.as_user(self.merchant_a).get(
            f"{PRODUCTS_URL}{hidden.slug}/"
        )
        self.assertEqual(response.status_code, 200)

    def test_customer_sees_only_stocked_products_from_active_stores(self):
        stocked = self.product_a  # stocked in active Store A
        unstocked = self._mk_product("Unstocked Item", self.tenant_a)

        response = self.as_user(self.customer).get(PRODUCTS_URL)
        self.assertEqual(response.status_code, 200)
        slugs = {item["slug"] for item in response.data["results"]} if isinstance(
            response.data, dict
        ) else {item["slug"] for item in response.data}

        self.assertIn(stocked.slug, slugs)
        self.assertNotIn(unstocked.slug, slugs)


class InventoryIsolationTests(TenancyTestBase):
    def test_stock_create_binds_store_tenant(self):
        product_b = self._mk_product("Tea Powder", self.tenant_b)
        variant_b = self._mk_variant(product_b, "TEA-500G", Decimal("150.00"))
        response = self.as_user(self.merchant_b).post(
            INVENTORY_URL,
            {"store": self.store_b.id, "variant": variant_b.id, "quantity": 25},
            format="json",
        )
        self.assertEqual(response.status_code, 201)
        item = StockItem.objects.get(pk=response.data["id"])
        self.assertEqual(item.tenant_id, self.tenant_b.id)

    def test_stock_create_rejects_cross_tenant_combination(self):
        product_b = self._mk_product("Tea Powder", self.tenant_b)
        variant_b = self._mk_variant(product_b, "TEA-500G", Decimal("150.00"))
        response = self.as_user(self.merchant_b).post(
            INVENTORY_URL,
            {"store": self.store_a.id, "variant": variant_b.id, "quantity": 25},
            format="json",
        )
        self.assertEqual(response.status_code, 400)

    def test_other_merchant_cannot_adjust_foreign_stock(self):
        response = self.as_user(self.merchant_b).post(
            adjust_url(self.stock_a.id),
            {"change": -5, "reason": "SALE"},
            format="json",
        )
        self.assertEqual(response.status_code, 404)
        self.stock_a.refresh_from_db()
        self.assertEqual(self.stock_a.quantity, 10)

    def test_owner_can_adjust_own_stock_and_audit_row_written(self):
        response = self.as_user(self.merchant_a).post(
            adjust_url(self.stock_a.id),
            {"change": -3, "reason": "SALE", "note": "morning rush"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.stock_a.refresh_from_db()
        self.assertEqual(self.stock_a.quantity, 7)
        self.assertTrue(
            InventoryTransaction.objects.filter(
                stock_item=self.stock_a, change=-3, performed_by=self.merchant_a
            ).exists()
        )

    def test_customer_cannot_adjust_any_stock(self):
        response = self.as_user(self.customer).post(
            adjust_url(self.stock_a.id),
            {"change": 5, "reason": "RESTOCK"},
            format="json",
        )
        self.assertEqual(response.status_code, 404)

    def test_transaction_list_scoped_by_tenant(self):
        # Each merchant restocks their own item once.
        for merchant, stock in (
            (self.merchant_a, self.stock_a),
            (
                self.merchant_b,
                StockItem.objects.create(
                    store=self.store_b,
                    variant=self._mk_variant(
                        self._mk_product("Soap", self.tenant_b), "SOAP-1"
                    ),
                    quantity=5,
                    tenant=self.tenant_b,
                ),
            ),
        ):
            response = self.as_user(merchant).post(
                adjust_url(stock.id),
                {"change": 2, "reason": "RESTOCK"},
                format="json",
            )
            self.assertEqual(response.status_code, 200)

        a_items = set(
            StockItem.objects.filter(tenant=self.tenant_a).values_list("id", flat=True)
        )
        b_items = set(
            StockItem.objects.filter(tenant=self.tenant_b).values_list("id", flat=True)
        )

        response_a = self.as_user(self.merchant_a).get(TRANSACTIONS_URL)
        self.assertTrue(response_a.data)
        for row in response_a.data:
            self.assertIn(row["stock_item"], a_items)

        response_b = self.as_user(self.merchant_b).get(TRANSACTIONS_URL)
        self.assertTrue(response_b.data)
        for row in response_b.data:
            self.assertIn(row["stock_item"], b_items)


class AdminBypassTests(TenancyTestBase):
    def test_staff_can_update_foreign_store(self):
        response = self.as_user(self.admin).patch(
            f"{STORES_URL}{self.store_a.slug}/",
            {"description": "Verified by platform"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)

    def test_staff_sees_all_products(self):
        response = self.as_user(self.admin).get(PRODUCTS_URL)
        names = (
            [p["name"] for p in response.data["results"]]
            if isinstance(response.data, dict)
            else [p["name"] for p in response.data]
        )
        self.assertIn(self.product_a.name, names)

    def test_staff_can_adjust_any_stock(self):
        response = self.as_user(self.admin).post(
            adjust_url(self.stock_a.id),
            {"change": -1, "reason": "DAMAGE"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
