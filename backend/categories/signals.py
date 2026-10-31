"""Keep the public category list fresh.

The anonymous category list is cached for 1 hour (see CategoryListView);
without these receivers, admin edits (rename, icon, visibility) would stay
invisible to customers until the TTL expires. Staff reads bypass the cache,
which is why the admin UI always looked correct while the storefront lagged.
"""

from django.db.models.signals import post_delete, post_save
from django.dispatch import receiver

from common.cache import invalidate

from .models import Category


@receiver(
    [post_save, post_delete],
    sender=Category,
    dispatch_uid="easyget.invalidate-category-cache",
)
def invalidate_category_cache(sender, instance, **kwargs):
    # Category names/icons ride along in product and storefront payloads, so
    # those namespaces go too — cheap pattern deletes, always correct.
    invalidate(("categories", "products", "storefront"))
