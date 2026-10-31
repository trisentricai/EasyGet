"""Rebuild the full-text search index for every active product.

Usage:  python manage.py rebuild_search_index

Idempotent: creates missing ProductSearchIndex rows and recomputes the
document for every product. Safe to run on a schedule (e.g. nightly cron) and
after bulk imports that bypass save() signals.
"""

from django.core.management.base import BaseCommand

from products.models import Product
from search.models import ProductSearchIndex


class Command(BaseCommand):
    help = "Recreate/refresh the ProductSearchIndex rows for all active products."

    def add_arguments(self, parser):
        parser.add_argument(
            "--all",
            action="store_true",
            help="Include inactive products too (default: active only).",
        )

    def handle(self, *args, **options):
        qs = Product.objects.all() if options["all"] else Product.objects.filter(is_active=True)
        total = qs.count()
        created = 0

        for number, product in enumerate(qs.iterator(chunk_size=200), start=1):
            index, was_created = ProductSearchIndex.objects.get_or_create(product=product)
            index.update_index()
            if was_created:
                created += 1
            if number % 100 == 0 or number == total:
                self.stdout.write(f"  {number}/{total}")

        self.stdout.write(
            self.style.SUCCESS(
                f"Search index rebuilt: {total} products ({created} newly indexed)."
            )
        )
