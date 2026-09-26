from decimal import Decimal

from django.contrib.auth import get_user_model
from django.test import TestCase
from rest_framework.test import APIClient

from categories.models import Category
from products.models import Product, ProductVariant
from stores.models import Store
from tenants.services import provision_tenant

from .models import SectionItem, StoreSection, StorefrontTheme

User = get_user_model()

RENDER_URL = "/api/v1/storefront/rahuls-store/"
THEME_URL = RENDER_URL + "theme/"
SECTIONS_URL = RENDER_URL + "sections/"
REORDER_URL = SECTIONS_URL + "reorder/"


def section_url(pk):
    return f"/api/v1/storefront/sections/{pk}/"


def items_url(pk):
    return f"/api/v1/storefront/sections/{pk}/items/"


def item_reorder_url(pk):
    return f"/api/v1/storefront/sections/{pk}/items/reorder/"


def item_url(pk):
    return f"/api/v1/storefront/items/{pk}/"


class StorefrontTestBase(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.owner = User.objects.create_user(
            "owner@example.com", "strongpass123", is_email_verified=True
        )
        self.staff = User.objects.create_superuser("staff@example.com", "strongpass123")
        self.outsider = User.objects.create_user(
            "random@example.com", "strongpass123", is_email_verified=True
        )
        self.tenant = provision_tenant(self.owner, "Rahul's Store")
        self.store = Store.objects.create(
            name="Rahul's Store",
            slug="rahuls-store",
            tenant=self.tenant,
            city="Chennai",
            state="TN",
            postal_code="600001",
            latitude=Decimal("13.0827"),
            longitude=Decimal("80.2707"),
        )
        self.category = Category.objects.create(name="Grocery", is_active=True)
        self.product = Product.objects.create(
            name="Rice 5kg", category=self.category, tenant=self.tenant,
            mrp=Decimal("800.00"), is_active=True,
        )
        self.variant = ProductVariant.objects.create(
            product=self.product, name="5kg", sku="RICE-5KG",
            price=Decimal("700.00"), is_active=True,
        )
        self.theme = StorefrontTheme.objects.create(store=self.store)
        self.hero = StoreSection.objects.create(
            store=self.store, section_type=StoreSection.SectionType.HERO,
            title="Welcome", position=0,
        )
        self.grid = StoreSection.objects.create(
            store=self.store, section_type=StoreSection.SectionType.CATEGORY_GRID,
            title="Categories", config={"columns": 4}, position=1,
        )
        self.cat_item = SectionItem.objects.create(
            section=self.grid, item_type=SectionItem.ItemType.CATEGORY,
            category=self.category, position=0,
        )
        self.prod_item = SectionItem.objects.create(
            section=self.grid, item_type=SectionItem.ItemType.PRODUCT,
            product=self.product, position=1,
        )


class PublicRenderTests(StorefrontTestBase):
    def test_render_requires_no_auth_and_returns_full_payload(self):
        response = self.client.get(RENDER_URL)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["store"]["slug"], "rahuls-store")
        self.assertEqual(response.data["theme"]["primary_color"], "#2874F0")
        self.assertEqual(len(response.data["sections"]), 2)
        self.assertEqual(response.data["sections"][0]["title"], "Welcome")
        item_types = {
            i["item_type"] for i in response.data["sections"][1]["items"]
        }
        self.assertEqual(item_types, {"CATEGORY", "PRODUCT"})

    def test_render_includes_product_name_and_price(self):
        response = self.client.get(RENDER_URL)
        items = response.data["sections"][1]["items"]
        product_item = next(i for i in items if i["item_type"] == "PRODUCT")
        self.assertEqual(product_item["product_name"], "Rice 5kg")
        self.assertEqual(product_item["product_price"], "700.00")

    def test_inactive_store_is_not_renderable(self):
        self.store.is_active = False
        self.store.save()
        response = self.client.get(RENDER_URL)
        self.assertEqual(response.status_code, 404)

    def test_inactive_sections_hidden_from_public_but_seen_by_manager(self):
        self.grid.is_active = False
        self.grid.save()
        self.assertEqual(len(self.client.get(RENDER_URL).data["sections"]), 1)
        self.as_user(self.owner)
        self.assertEqual(len(self.client.get(SECTIONS_URL).data), 2)

    def as_user(self, user):
        self.client.force_authenticate(user=user)
        return self.client


class SectionCrudTests(StorefrontTestBase):
    def as_user(self, user):
        self.client.force_authenticate(user=user)
        return self.client

    def test_owner_can_create_section_appended_last(self):
        response = self.as_user(self.owner).post(
            SECTIONS_URL,
            {"section_type": "RICH_TEXT", "title": "About us",
             "config": {"placeholder": "Tell your story"}},
            format="json",
        )
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["position"], 2)

    def test_outsider_cannot_create_section(self):
        response = self.as_user(self.outsider).post(
            SECTIONS_URL, {"section_type": "HERO"}, format="json"
        )
        self.assertEqual(response.status_code, 403)

    def test_owner_can_edit_config_columns_size_effects(self):
        response = self.as_user(self.owner).patch(
            section_url(self.grid.id),
            {"config": {"columns": 3, "size": "lg", "effects": {"hover_zoom": True},
                        "placeholder": "Pick a category"}},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.grid.refresh_from_db()
        self.assertEqual(self.grid.config["columns"], 3)
        self.assertEqual(self.grid.config["size"], "lg")

    def test_invalid_config_rejected(self):
        response = self.as_user(self.owner).patch(
            section_url(self.grid.id), {"config": {"columns": 11}}, format="json"
        )
        self.assertEqual(response.status_code, 400)

    def test_outsider_cannot_edit_or_delete_section(self):
        self.assertEqual(
            self.as_user(self.outsider).patch(
                section_url(self.grid.id), {"title": "Hacked"}, format="json"
            ).status_code,
            403,
        )
        self.assertEqual(
            self.as_user(self.outsider).delete(section_url(self.grid.id)).status_code,
            403,
        )

    def test_staff_can_manage_storefront(self):
        response = self.as_user(self.staff).patch(
            section_url(self.hero.id), {"title": "Platform-fixed title"},
            format="json",
        )
        self.assertEqual(response.status_code, 200)


class ReorderTests(StorefrontTestBase):
    def as_user(self, user):
        self.client.force_authenticate(user=user)
        return self.client

    def test_drag_and_drop_reorder_sections(self):
        response = self.as_user(self.owner).post(
            REORDER_URL, {"order": [self.grid.id, self.hero.id]}, format="json"
        )
        self.assertEqual(response.status_code, 200)
        positions = {s["id"]: s["position"] for s in response.data}
        self.assertEqual(positions[self.grid.id], 0)
        self.assertEqual(positions[self.hero.id], 1)
        self.hero.refresh_from_db()
        self.grid.refresh_from_db()
        self.assertEqual((self.hero.position, self.grid.position), (1, 0))

    def test_reorder_rejects_foreign_ids(self):
        other = StoreSection.objects.create(
            store=Store.objects.create(
                name="Other", city="X", state="X", postal_code="1",
                latitude=Decimal("1"), longitude=Decimal("1"),
            ),
            section_type=StoreSection.SectionType.HERO,
        )
        response = self.as_user(self.owner).post(
            REORDER_URL, {"order": [self.hero.id, other.id]}, format="json"
        )
        self.assertEqual(response.status_code, 400)

    def test_item_reorder_within_section(self):
        response = self.as_user(self.owner).post(
            item_reorder_url(self.grid.id),
            {"order": [self.prod_item.id, self.cat_item.id]},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.cat_item.refresh_from_db()
        self.prod_item.refresh_from_db()
        self.assertEqual((self.cat_item.position, self.prod_item.position), (1, 0))


class ItemCrudTests(StorefrontTestBase):
    def as_user(self, user):
        self.client.force_authenticate(user=user)
        return self.client

    def test_add_product_item_appended_last(self):
        response = self.as_user(self.owner).post(
            items_url(self.grid.id),
            {"item_type": "PRODUCT", "product": self.product.id},
            format="json",
        )
        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.data["position"], 2)

    def test_product_item_requires_product(self):
        response = self.as_user(self.owner).post(
            items_url(self.grid.id), {"item_type": "PRODUCT"}, format="json"
        )
        self.assertEqual(response.status_code, 400)

    def test_custom_item_requires_caption_or_image(self):
        response = self.as_user(self.owner).post(
            items_url(self.grid.id), {"item_type": "CUSTOM"}, format="json"
        )
        self.assertEqual(response.status_code, 400)

    def test_rename_caption_and_delete_item(self):
        response = self.as_user(self.owner).patch(
            item_url(self.cat_item.id), {"caption": "Groceries & more"}, format="json"
        )
        self.assertEqual(response.status_code, 200)
        self.cat_item.refresh_from_db()
        self.assertEqual(self.cat_item.caption, "Groceries & more")

        response = self.as_user(self.owner).delete(item_url(self.cat_item.id))
        self.assertEqual(response.status_code, 204)
        self.assertFalse(SectionItem.objects.filter(pk=self.cat_item.pk).exists())

    def test_outsider_cannot_modify_items(self):
        response = self.as_user(self.outsider).delete(item_url(self.prod_item.id))
        self.assertEqual(response.status_code, 403)


class ThemeTests(StorefrontTestBase):
    def as_user(self, user):
        self.client.force_authenticate(user=user)
        return self.client

    def test_public_get_theme(self):
        response = self.client.get(THEME_URL)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["button_style"], "SQUARE")

    def test_owner_updates_theme(self):
        response = self.as_user(self.owner).patch(
            THEME_URL,
            {"primary_color": "#0B8457", "font_family": "Poppins",
             "button_style": "PILL", "effects": {"hero_animation": "slide"}},
            format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.theme.refresh_from_db()
        self.assertEqual(self.theme.primary_color, "#0B8457")

    def test_outsider_cannot_update_theme(self):
        response = self.as_user(self.outsider).patch(
            THEME_URL, {"primary_color": "#000000"}, format="json"
        )
        self.assertEqual(response.status_code, 403)


class ProductTenantSecurityTests(StorefrontTestBase):
    """Section items must not expose foreign-tenant products or unpublished
    sections through the public item/render endpoints."""

    def setUp(self):
        super().setUp()
        self.other_owner = User.objects.create_user(
            "other.owner@example.com", "strongpass123", is_email_verified=True
        )
        self.other_tenant = provision_tenant(self.other_owner, "Other Tenant")
        self.foreign_product = Product.objects.create(
            name="Foreign Product", category=self.category,
            tenant=self.other_tenant, mrp=Decimal("500.00"), is_active=True,
        )
        self.hidden_section = StoreSection.objects.create(
            store=self.store, section_type=StoreSection.SectionType.HERO,
            title="Unpublished", position=5, is_active=False,
        )
        SectionItem.objects.create(
            section=self.hidden_section,
            item_type=SectionItem.ItemType.PRODUCT,
            product=self.product, position=0,
        )

    def as_user(self, user):
        self.client.force_authenticate(user=user)
        return self.client

    def test_owner_cannot_link_foreign_product(self):
        response = self.as_user(self.owner).post(
            items_url(self.grid.id),
            {"item_type": "PRODUCT", "product": self.foreign_product.id},
            format="json",
        )
        self.assertEqual(response.status_code, 400)
        self.assertFalse(
            SectionItem.objects.filter(product=self.foreign_product).exists()
        )

    def test_inactive_section_items_hidden_from_public(self):
        self.client.force_authenticate()
        response = self.client.get(items_url(self.hidden_section.id))
        self.assertEqual(response.status_code, 404)

    def test_inactive_section_items_visible_to_manager(self):
        response = self.as_user(self.owner).get(items_url(self.hidden_section.id))
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 1)


class PlatformRouteTests(StorefrontTestBase):
    PLATFORM_URL = "/api/v1/storefront/platform/"

    def test_platform_route_renders(self):
        response = self.client.get(self.PLATFORM_URL)
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data["store"]["slug"], "easyget")
        self.assertIn("theme", response.data)
        self.assertIn("sections", response.data)

    def test_platform_route_404_when_missing(self):
        Store.objects.filter(is_platform=True).delete()
        response = self.client.get(self.PLATFORM_URL)
        self.assertEqual(response.status_code, 404)


class PlatformSectionGuardTests(StorefrontTestBase):
    """Spec 4.2: platform links any active product; merchants stay strict."""

    def setUp(self):
        super().setUp()
        self.platform = Store.objects.get(is_platform=True)
        self.foreign_tenant = provision_tenant(self.outsider, "Foreign Tenant")
        self.foreign_product = Product.objects.create(
            name="Foreign Apples", category=self.category,
            tenant=self.foreign_tenant, mrp=Decimal("100.00"), is_active=True,
        )
        self.inactive_foreign = Product.objects.create(
            name="Dead Oranges", category=self.category,
            tenant=self.foreign_tenant, mrp=Decimal("50.00"), is_active=False,
        )

    def test_platform_allows_any_active_product(self):
        from .views import _product_allowed_for_store

        self.assertTrue(
            _product_allowed_for_store(self.foreign_product, self.platform, self.outsider)
        )

    def test_platform_rejects_inactive_product(self):
        from .views import _product_allowed_for_store

        self.assertFalse(
            _product_allowed_for_store(self.inactive_foreign, self.platform, self.outsider)
        )

    def test_merchant_store_still_rejects_foreign_product(self):
        from .views import _product_allowed_for_store

        self.assertFalse(
            _product_allowed_for_store(self.foreign_product, self.store, self.outsider)
        )
