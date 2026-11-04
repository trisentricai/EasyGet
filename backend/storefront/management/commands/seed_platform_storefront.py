"""Compose the platform (EASYGET) storefront so customer-web renders a
designed page instead of the empty-state fallback.

Usage (from backend/):

    python manage.py seed_platform_storefront

Idempotent: the command keeps an existing merchant layout and only repairs
missing seed imagery / adds a category grid when one is absent. Use --force to
wipe and recompose the starter layout from scratch.

Hero and category art is downloaded from Unsplash once and stored through the
normal ImageField pipeline (compressed WebP). Downloads are best-effort: if the
network is unavailable the fields stay empty and the frontend's gradient /
initials fallbacks take over — never a broken image icon.
"""

from collections import Counter

from django.core.management.base import BaseCommand, CommandError
from django.db import transaction
from django.db.models import Max

from categories.models import Category
from common.seed_images import (
    CATEGORY_IMAGE_URLS,
    HERO_IMAGE_URLS,
    ensure_image,
)
from products.models import Product
from storefront.models import SectionItem, StoreSection, StorefrontTheme
from stores.models import Store

# Four starter slides: one HERO + three BANNER sections. The customer-web
# carousel treats HERO and BANNER identically, so this gives a full rotation.
DEMO_SLIDES = [
    (
        "Monsoon deals",
        "Everyday low prices · Free delivery over ₹499",
        "Shop now",
        "browse",
    ),
    (
        "Fresh picks, every day",
        "Groceries and home essentials at your door",
        "Shop groceries",
        "browse?category=grocery",
    ),
    (
        "Upgrade your kitchen",
        "Tools and cookware worth keeping",
        "Explore kitchen",
        "browse?category=kitchen-tools",
    ),
    (
        "A little style, every day",
        "Fashion and accessories at everyday prices",
        "Browse fashion",
        "browse?category=fancy-items",
    ),
]


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
            self.stdout.write(
                f"Storefront theme: exists (primary={theme.primary_color})"
            )

        existing = store.storefront_sections.count()
        if existing and not options["force"]:
            self._refresh_existing(store)
            return

        if existing:
            store.storefront_sections.all().delete()
            self.stdout.write(f"Removed {existing} existing section(s) (--force).")

        self._compose(store)

    # ------------------------------------------------------------------
    # Fresh composition
    # ------------------------------------------------------------------
    def _compose(self, store: Store) -> None:
        categories = list(
            Category.objects.filter(is_active=True).order_by("sort_order", "id")
        )
        icon_stats = self._seed_category_icons(categories)

        sections: list[StoreSection] = []
        for index, (title, subtitle, cta_label, cta_link) in enumerate(DEMO_SLIDES):
            image_url = HERO_IMAGE_URLS[index % len(HERO_IMAGE_URLS)]
            section = StoreSection.objects.create(
                store=store,
                section_type=(
                    StoreSection.SectionType.HERO
                    if index == 0
                    else StoreSection.SectionType.BANNER
                ),
                title=title,
                subtitle=subtitle,
                config={
                    "size": "md",
                    "hero_layout": "feature",
                    "hero_overlay": "dark",
                    "cta_label": cta_label,
                    "cta_link": cta_link,
                },
                position=index,
            )
            self._seed_section_image(section, image_url, prefix=f"hero-{index + 1}")
            sections.append(section)

        category_grid = StoreSection.objects.create(
            store=store,
            section_type=StoreSection.SectionType.CATEGORY_GRID,
            title="Shop by category",
            subtitle="Everything your home needs, delivered fast",
            config={"columns": 4, "size": "md", "category_style": "cards"},
            position=len(sections),
        )
        sections.append(category_grid)
        self._add_category_items(category_grid, categories[:8])

        product_row = StoreSection.objects.create(
            store=store,
            section_type=StoreSection.SectionType.PRODUCT_ROW,
            title="Popular right now",
            subtitle="Trending picks across the store",
            config={"columns": 5, "size": "md"},
            position=len(sections),
        )
        sections.append(product_row)

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
                f"({len(categories[:8])} categories, {len(products)} products). "
                f"Category icons: {self._format_stats(icon_stats)}. "
                "customer-web renders it on next refresh."
            )
        )

    # ------------------------------------------------------------------
    # Repair an existing layout without destroying merchant edits
    # ------------------------------------------------------------------
    def _refresh_existing(self, store: Store) -> None:
        categories = list(
            Category.objects.filter(is_active=True).order_by("sort_order", "id")
        )
        icon_stats = self._seed_category_icons(categories)

        banners = list(
            store.storefront_sections.filter(
                section_type__in=[
                    StoreSection.SectionType.HERO,
                    StoreSection.SectionType.BANNER,
                ]
            ).order_by("position", "id")
        )
        image_stats: Counter[str] = Counter()
        for index, section in enumerate(banners):
            image_stats.update(
                [
                    self._seed_section_image(
                        section,
                        HERO_IMAGE_URLS[index % len(HERO_IMAGE_URLS)],
                        prefix=f"hero-{index + 1}",
                    )
                ]
            )

        # The starter demo should always have a full carousel. Add only the
        # missing slides; existing slides and their order stay untouched.
        next_position = (
            store.storefront_sections.aggregate(max_position=Max("position"))[
                "max_position"
            ]
            or 0
        ) + 1
        missing = max(0, len(DEMO_SLIDES) - len(banners))
        for offset in range(missing):
            index = len(banners) + offset
            title, subtitle, cta_label, cta_link = DEMO_SLIDES[index]
            section = StoreSection.objects.create(
                store=store,
                section_type=StoreSection.SectionType.BANNER,
                title=title,
                subtitle=subtitle,
                config={
                    "size": "md",
                    "hero_layout": "feature",
                    "hero_overlay": "dark",
                    "cta_label": cta_label,
                    "cta_link": cta_link,
                },
                position=next_position + offset,
            )
            image_stats.update(
                [
                    self._seed_section_image(
                        section,
                        HERO_IMAGE_URLS[index % len(HERO_IMAGE_URLS)],
                        prefix=f"hero-{index + 1}",
                    )
                ]
            )
            banners.append(section)

        category_grid = (
            store.storefront_sections.filter(
                section_type=StoreSection.SectionType.CATEGORY_GRID
            )
            .order_by("position", "id")
            .first()
        )
        grid_created = False
        if category_grid is None:
            category_grid = StoreSection.objects.create(
                store=store,
                section_type=StoreSection.SectionType.CATEGORY_GRID,
                title="Shop by category",
                subtitle="Everything your home needs, delivered fast",
                config={"columns": 4, "size": "md", "category_style": "cards"},
                position=next_position + missing,
            )
            grid_created = True
        items_added = 0
        if not category_grid.items.exists():
            items_added = self._add_category_items(category_grid, categories[:8])

        self.stdout.write(
            self.style.SUCCESS(
                "Existing layout kept. "
                f"Hero images: {self._format_stats(image_stats)}. "
                f"Category icons: {self._format_stats(icon_stats)}. "
                f"{'Category grid created' if grid_created else 'Category grid present'}"
                f"{f' ({items_added} tiles added)' if items_added else ''}."
            )
        )

    # ------------------------------------------------------------------
    # Helpers
    # ------------------------------------------------------------------
    def _seed_category_icons(self, categories: list[Category]) -> Counter[str]:
        stats: Counter[str] = Counter()
        for category in categories:
            stats.update(
                [
                    ensure_image(
                        category,
                        "icon",
                        CATEGORY_IMAGE_URLS.get(category.slug),
                        prefix=f"category-{category.slug}",
                    )
                ]
            )
        return stats

    def _seed_section_image(
        self, section: StoreSection, image_url: str, *, prefix: str
    ) -> str:
        return ensure_image(section, "image", image_url, prefix=prefix)

    def _add_category_items(
        self, section: StoreSection, categories: list[Category]
    ) -> int:
        created = 0
        for position, category in enumerate(categories):
            _, was_created = SectionItem.objects.get_or_create(
                section=section,
                category=category,
                defaults={
                    "item_type": SectionItem.ItemType.CATEGORY,
                    "caption": category.name,
                    "position": position,
                },
            )
            if was_created:
                created += 1
        return created

    @staticmethod
    def _format_stats(stats: Counter[str]) -> str:
        if not stats:
            return "none"
        ordered = ("seeded", "kept", "cleared", "failed", "skipped")
        return ", ".join(
            f"{stats[key]} {key}" for key in ordered if stats.get(key)
        ) or "none"
