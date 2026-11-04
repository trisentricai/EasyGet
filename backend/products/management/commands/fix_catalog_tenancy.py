"""Bind orphan (tenant-less) catalog rows to a real seller store.

Products with ``tenant_id=NULL`` are treated as platform products: they stay
visible on the storefront, but split checkout rejects them ("Some items can't
be ordered right now") because there is no seller store to fulfil them.

This command repairs that state idempotently:

* assigns every product with no tenant to the target tenant;
* moves stock rows that live in the platform/null-tenant store to the target
  seller store (merging quantities when a row already exists);
* ensures every active variant has a stock row in the target store;
* creates a default variant + stock for a product that has no variants.

Usage (from backend/):

    python manage.py fix_catalog_tenancy
    python manage.py fix_catalog_tenancy --tenant-id 2 --store-id 2
    python manage.py fix_catalog_tenancy --quantity 10 --dry-run

Without ``--store-id`` / ``--tenant-id`` the first active, tenant-owned,
non-platform store is used, which is the demo store on a local database.
"""

from decimal import Decimal

from django.core.management.base import BaseCommand, CommandError
from django.db import transaction

from inventory.models import StockItem
from products.models import Product, ProductVariant
from stores.models import Store


class Command(BaseCommand):
    help = "Assign tenant-less products to a seller store and make them checkout-ready."

    def add_arguments(self, parser):
        parser.add_argument(
            "--tenant-id",
            type=int,
            default=None,
            help="Target tenant ID (defaults to the store owner's tenant).",
        )
        parser.add_argument(
            "--store-id",
            type=int,
            default=None,
            help="Target store ID (defaults to the first active seller store).",
        )
        parser.add_argument(
            "--quantity",
            type=int,
            default=10,
            help="Stock quantity to create for variants that have none (default 10).",
        )
        parser.add_argument(
            "--default-price",
            type=str,
            default="99.00",
            help="Price for a default variant created on a product with no variants.",
        )
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Report what would change without writing.",
        )

    def _resolve_store(self, options):
        if options["store_id"] is not None:
            store = (
                Store.objects.select_related("tenant")
                .filter(pk=options["store_id"])
                .first()
            )
            if store is None:
                raise CommandError(f"No store with id {options['store_id']}.")
        elif options["tenant_id"] is not None:
            store = (
                Store.objects.select_related("tenant")
                .filter(
                    tenant_id=options["tenant_id"],
                    is_active=True,
                    is_platform=False,
                )
                .order_by("name")
                .first()
            )
            if store is None:
                raise CommandError(
                    f"No active seller store for tenant {options['tenant_id']}."
                )
        else:
            store = (
                Store.objects.select_related("tenant")
                .filter(is_active=True, is_platform=False, tenant__isnull=False)
                .order_by("id")
                .first()
            )
            if store is None:
                raise CommandError(
                    "No active tenant-owned seller store found. Create one first."
                )
        if store.tenant_id is None:
            raise CommandError(
                f"Store {store.name!r} has no tenant; pick a tenant-owned store."
            )
        return store

    @transaction.atomic
    def handle(self, *args, **options):
        store = self._resolve_store(options)
        tenant = store.tenant
        quantity = max(0, options["quantity"])
        default_price = Decimal(options["default_price"])
        dry_run = options["dry_run"]

        products = (
            Product.objects.filter(tenant__isnull=True)
            .prefetch_related("variants__stock_items__store")
            .order_by("id")
        )
        stats = {
            "products": 0,
            "stock_moved": 0,
            "stock_merged": 0,
            "stock_created": 0,
            "variants_created": 0,
        }

        for product in products:
            stats["products"] += 1
            if dry_run:
                if not product.variants.exists():
                    stats["variants_created"] += 1
                for variant in product.variants.all():
                    if not StockItem.objects.filter(
                        store=store, variant=variant
                    ).exists():
                        stats["stock_created"] += 1
                continue

            product.tenant = tenant
            product.save(update_fields=["tenant", "updated_at"])

            # Adopt stock from the platform store (or other unowned stores).
            for stock in StockItem.objects.filter(
                variant__product=product
            ).select_related("store"):
                if stock.store_id == store.id:
                    if stock.tenant_id != tenant.id:
                        stock.tenant = tenant
                        stock.save(update_fields=["tenant", "updated_at"])
                    continue
                owner_tenant_id = stock.store.tenant_id
                if owner_tenant_id is not None and not stock.store.is_platform:
                    # Belongs to another seller; leave it untouched.
                    continue
                existing = (
                    StockItem.objects.filter(store=store, variant=stock.variant)
                    .exclude(pk=stock.pk)
                    .first()
                )
                if existing is not None:
                    existing.quantity += stock.quantity
                    existing.tenant = tenant
                    existing.save(update_fields=["quantity", "tenant", "updated_at"])
                    stock.delete()
                    stats["stock_merged"] += 1
                else:
                    stock.store = store
                    stock.tenant = tenant
                    stock.save(update_fields=["store", "tenant", "updated_at"])
                    stats["stock_moved"] += 1

            active_variants = [v for v in product.variants.all() if v.is_active]
            if not active_variants:
                variant = ProductVariant.objects.create(
                    product=product,
                    name="1 unit",
                    price=product.mrp or default_price,
                    is_active=True,
                )
                active_variants = [variant]
                stats["variants_created"] += 1

            for variant in active_variants:
                stock, created = StockItem.objects.get_or_create(
                    store=store,
                    variant=variant,
                    defaults={"quantity": quantity, "tenant": tenant},
                )
                if created:
                    stats["stock_created"] += 1
                elif stock.tenant_id != tenant.id:
                    stock.tenant = tenant
                    stock.save(update_fields=["tenant", "updated_at"])

        self.stdout.write(
            f"Target: {store.name} (store={store.id}, tenant={tenant.id} {tenant.name})"
        )
        if dry_run:
            self.stdout.write(self.style.WARNING("DRY RUN — nothing written."))
        self.stdout.write(
            self.style.SUCCESS(
                "Products bound: {products} | Stock moved: {stock_moved} | "
                "Stock merged: {stock_merged} | Stock created: {stock_created} | "
                "Variants created: {variants_created}".format(**stats)
            )
        )
