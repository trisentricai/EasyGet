"""Compose the platform (EASYGET) storefront so customer-web renders a
designed page instead of the empty-state fallback.

Usage (from backend/):

    python manage.py seed_platform_storefront

Idempotent: if the platform store already has sections, nothing is written
(use --force to wipe and recompose). Also ensures a default theme exists.
"""

from django.core.management.base import BaseCommand, CommandError
from django.db import transaction

from categories.models import Category
from products.models import Product
from storefront.models import SectionItem, StoreSection, StorefrontTheme
from stores.models import Store


class Command(BaseCommand):
    help = "Create starter sections for the platform storefront (idempotent)."

    def add_arguments(self, parser):
        parser.add_argument(
            "--force",
            action="store_true",
            help="Delete existing platform sections and recompose them.",
        )

    @transaction.atomic
    def handle(self, *args, **options):
        store = Store.objects.filter(is_platform=True).first()
        if store is None:
            raise CommandError(
                "No platform store found (Store with is_platform=True). "
                "Create it first."
            )
        self.stdout.write(f"Platform store: {store.name} (slug={store.slug})")

        theme, created = StorefrontTheme.objects.get_or_create(store=store)
        if created:
            self.stdout.write("Storefront theme: created (defaults)")
        else:
            self.stdout.write(f"Storefront theme: exists (primary={theme.primary_color})")

        existing = store.storefront_sections.count()
        if existing and not options["force"]:
            self.stdout.write(
                self.style.WARNING(
                    f"Storefront already has {existing} section(s) — skipped. "
                    "Use --force to recompose."
                )
            )
            return
        if existing:
            store.storefront_sections.all().delete()
            self.stdout.write(f"Removed {existing} existing section(s) (--force).")

        sections: list[StoreSection] = []
        layout = [
            (StoreSection.SectionType.BANNER, "Monsoon deals",
             "Everyday low prices · Free delivery over ₹499",
             {"size": "md"}),
            (StoreSection.SectionType.CATEGORY_GRID, "Shop by category",
             "Everything your home needs, delivered fast",
             {"columns": 4, "size": "md"}),
            (StoreSection.SectionType.PRODUCT_ROW, "Popular right now",
             "Trending picks across the store",
             {"columns": 5, "size": "md"}),
        ]
        for position, (stype, title, subtitle, config) in enumerate(layout):
            sections.append(
                StoreSection.objects.create(
                    store=store,
                    section_type=stype,
                    title=title,
                    subtitle=subtitle,
                    config=config,
                    position=position,
                )
            )

        _, category_grid, product_row = sections

        categories = list(Category.objects.filter(is_active=True).order_by("sort_order", "id")[:8])
        for position, category in enumerate(categories):
            SectionItem.objects.create(
                section=category_grid,
                item_type=SectionItem.ItemType.CATEGORY,
                category=category,
                caption=category.name,
                position=position,
            )

        products = list(
            Product.objects.filter(is_active=True)
            .order_by("-is_featured", "-updated_at")[:10]
        )
        for position, product in enumerate(products):
            SectionItem.objects.create(
                section=product_row,
                item_type=SectionItem.ItemType.PRODUCT,
                product=product,
                position=position,
            )

        self.stdout.write(
            self.style.SUCCESS(
                f"Storefront composed: {len(sections)} sections "
                f"({len(categories)} categories, {len(products)} products). "
                "customer-web renders it on next refresh."
            )
        )
