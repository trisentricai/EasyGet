"""Signal-wiring tests: admin category edits must bust the public caches.

These assert the receivers fire (the piece that was missing — the anonymous
list stayed stale for the full TTL). The delete_pattern mechanics belong to
django-redis and are not re-tested here.
"""

from unittest import mock

from django.test import TestCase

from categories.models import Category


class CategoryCacheSignalTests(TestCase):
    def test_save_busts_caches(self):
        category = Category.objects.create(name="Cache Probe", is_active=True)
        with mock.patch("categories.signals.invalidate") as bust:
            category.name = "Cache Probe Renamed"
            category.save()
        bust.assert_called_once_with(("categories", "products", "storefront"))

    def test_delete_busts_caches(self):
        category = Category.objects.create(name="Cache Gone", is_active=True)
        with mock.patch("categories.signals.invalidate") as bust:
            category.delete()
        bust.assert_called_once_with(("categories", "products", "storefront"))
