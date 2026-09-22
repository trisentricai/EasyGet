"""Seed a merchant's catalog from the Shop Stock Checklist.

Converts the 200-item Shop_Stock_Checklist (10 categories) into real platform
data: global categories, tenant-owned products with one default variant, and
per-store stock items.

Usage (from backend/, with the SQLite override like any local command):

    $env:DATABASE_URL = "sqlite:///db.sqlite3"
    python manage.py seed_shop_catalog --owner-email you@example.com `
        --store-name "My Shop" [--quantity 10] [--default-price 0] [--dry-run]

Idempotent: categories/products/stock that already exist are reused, so the
command can be re-run safely. Variant prices are a placeholder (0 by default)
until the merchant sets real prices; stock starts at --quantity (default 10).
"""

import json
from decimal import Decimal
from pathlib import Path

from django.core.management.base import BaseCommand, CommandError
from django.db import transaction

from categories.models import Category
from inventory.models import StockItem
from products.models import Product, ProductVariant
from stores.models import Store
from tenants.models import TenantMembership
from tenants.services import provision_tenant, resolve_tenant_for_create
from storefront.models import SectionItem, StoreSection, StorefrontTheme

CHECKLIST_PATH = Path(__file__).parent / "shop_stock_checklist.json"
DEFAULT_VARIANT_NAME = "1 unit"


class Command(BaseCommand):
    help = "Seed categories/products/stock from the Shop Stock Checklist."

    def add_arguments(self, parser):
        parser.add_argument("--owner-email", required=True,
                            help="Email of the merchant who will own the store.")
        parser.add_argument("--store-name", default="My Shop",
                            help="Store name (creates or reuses it).")
        parser.add_argument("--store-slug", default="",
                            help="Reuse an existing store by slug instead of creating one.")
        parser.add_argument("--city", default="Chennai")
        parser.add_argument("--state", default="TN")
        parser.add_argument("--postal-code", default="600001")
        parser.add_argument("--latitude", type=str, default="13.0827")
        parser.add_argument("--longitude", type=str, default="80.2707")
        parser.add_argument("--quantity", type=int, default=10,
                            help="Starting stock quantity per item (default 10).")
        parser.add_argument("--default-price", type=str, default="0.00",
                            help="Placeholder variant price (default 0.00 — set real prices later).")
        parser.add_argument("--dry-run", action="store_true",
                            help="Report what would be created without writing.")
        parser.add_argument("--no-storefront", action="store_true",
                            help="Skip creating the starter storefront (theme + sections).")

    @transaction.atomic
    def handle(self, *args, **options):
        from django.contrib.auth import get_user_model

        User = get_user_model()
        quantity = options["quantity"]
        price = Decimal(options["default_price"])
        dry_run = options["dry_run"]

        try:
            owner = User.objects.get(email__iexact=options["owner_email"])
        except User.DoesNotExist:
            raise CommandError(
                f"No user with email {options['owner_email']!r}. Register first."
            )

        # 1. Store + tenant -------------------------------------------------
        if options["store_slug"]:
            store = Store.objects.filter(slug=options["store_slug"]).first()
            if store is None:
                raise CommandError(f"No store with slug {options['store_slug']!r}.")
        else:
            store = Store.objects.filter(
                name__iexact=options["store_name"], tenant__isnull=False
            ).first()
            if store is None:
                tenant = resolve_tenant_for_create(owner)
                if tenant is None:
                    tenant = provision_tenant(owner, options["store_name"])
                elif not dry_run:
                    pass  # reuse the merchant's existing tenant
                store = Store.objects.create(
                    name=options["store_name"],
                    tenant=tenant,
                    city=options["city"],
                    state=options["state"],
                    postal_code=options["postal_code"],
                    latitude=Decimal(options["latitude"]),
                    longitude=Decimal(options["longitude"]),
                    is_active=True,
                )
        tenant = store.tenant
        if tenant is None:
            raise CommandError(
                f"Store {store.slug!r} has no tenant; only tenant-owned stores can be seeded."
            )
        self.stdout.write(f"Store: {store.name} (slug={store.slug}, tenant={tenant.name})")

        # 2. Walk the checklist ---------------------------------------------
        checklist = json.loads(CHECKLIST_PATH.read_text(encoding="utf-8"))
        created = {"categories": 0, "products": 0, "variants": 0, "stock": 0}
        reused = {"categories": 0, "products": 0}

        for block in checklist:
            category = Category.objects.filter(
                slug=self._slug(block["category"])
            ).first()
            if category is None:
                created["categories"] += 1
                if not dry_run:
                    category = Category.objects.create(
                        name=block["category"],
                        sort_order=block["sort_order"],
                        is_active=True,
                    )
            else:
                reused["categories"] += 1

            for entry in block["items"]:
                product = Product.objects.filter(
                    tenant=tenant, name__iexact=entry["name"]
                ).first()
                if product is not None:
                    reused["products"] += 1
                    continue
                created["products"] += 1
                if dry_run:
                    continue
                product = Product.objects.create(
                    name=entry["name"],
                    tenant=tenant,
                    category=category,
                    is_active=True,
                )
                variant = ProductVariant.objects.create(
                    product=product,
                    name=DEFAULT_VARIANT_NAME,
                    price=price,
                    is_active=True,
                )
                created["variants"] += 1
                _, stock_created = StockItem.objects.get_or_create(
                    store=store,
                    variant=variant,
                    defaults={"quantity": quantity, "tenant": tenant},
                )
                if stock_created:
                    created["stock"] += 1

        if dry_run:
            self.stdout.write(self.style.WARNING("DRY RUN — nothing written."))
        self.stdout.write(self.style.SUCCESS(
            f"Created: {created} | Reused: {reused}"
        ))

        if not options["no_storefront"] and not dry_run:
            self._seed_storefront(store)

    def _seed_storefront(self, store):
        """Starter storefront the client can immediately edit in the dashboard:
        a theme plus HERO / CATEGORY_GRID / PRODUCT_ROW / RICH_TEXT sections."""
        theme, created = StorefrontTheme.objects.get_or_create(store=store)
        self.stdout.write(
            f"Storefront theme: {'created' if created else 'exists'} "
            f"(primary={theme.primary_color})"
        )

        if store.storefront_sections.exists():
            self.stdout.write("Storefront sections: exist — skipped.")
            return

        sections = []
        for order, (stype, title, subtitle, config) in enumerate([
            (StoreSection.SectionType.HERO, store.name,
             "Everything your home needs — delivered fast.",
             {"size": "lg", "effects": {"hero_animation": "fade"},
              "placeholder": "Add your hero image here"}),
            (StoreSection.SectionType.CATEGORY_GRID, "Shop by category",
             "", {"columns": 4, "size": "md"}),
            (StoreSection.SectionType.PRODUCT_ROW, "Popular right now",
             "", {"columns": 4, "size": "md", "placeholder": "Drag products here"}),
            (StoreSection.SectionType.RICH_TEXT, "About our shop",
             "A neighbourhood store you can trust.",
             {"placeholder": "Tell your customers about the shop"}),
        ]):
            sections.append(StoreSection.objects.create(
                store=store, section_type=stype, title=title,
                subtitle=subtitle, config=config, position=order,
            ))

        category_grid, product_row = sections[1], sections[2]
        for position, category in enumerate(
            Category.objects.order_by("sort_order", "id")[:8]
        ):
            SectionItem.objects.create(
                section=category_grid, item_type=SectionItem.ItemType.CATEGORY,
                category=category, caption=category.name, position=position,
            )
        for position, product in enumerate(
            Product.objects.filter(tenant=store.tenant)[:8]
        ):
            SectionItem.objects.create(
                section=product_row, item_type=SectionItem.ItemType.PRODUCT,
                product=product, position=position,
            )
        self.stdout.write(
            self.style.SUCCESS(
                f"Storefront: {len(sections)} starter sections "
                f"({sum(s.items.count() for s in sections)} items)."
            )
        )

    @staticmethod
    def _slug(value):
        from django.utils.text import slugify
        return slugify(value) or value.lower().replace(" ", "-")
