"""Auto-invalidate the public API caches when content changes.

Any add/edit/delete of products, categories, banners, storefront sections or
the theme (whether through the Django admin, the dashboard API, or a seed
command) clears the affected cache namespaces, so shoppers never see stale
content for more than the immediate next request.
"""

from django.db.models.signals import post_delete, post_save
from django.dispatch import receiver

from .cache import invalidate

# sender label -> namespaces to clear
INVALIDATION_RULES = {
    "products.Product": ("products", "search", "storefront"),
    "categories.Category": ("categories", "products", "storefront"),
    "admin_panel.Banner": ("storefront",),
    "storefront.StoreSection": ("storefront",),
    "storefront.SectionItem": ("storefront",),
    "storefront.StorefrontTheme": ("storefront",),
}


@receiver(post_save, dispatch_uid="easyget.cache_invalidate_save")
def invalidate_on_save(sender, instance, **kwargs):
    from django.db import transaction

    # Defer to after-commit so a rollback never leaves a cleared cache
    # serving content that was never persisted.
    try:
        transaction.on_commit(lambda: _clear(sender))
    except Exception:  # no transaction active
        _clear(sender)


@receiver(post_delete, dispatch_uid="easyget.cache_invalidate_delete")
def invalidate_on_delete(sender, instance, **kwargs):
    from django.db import transaction

    try:
        transaction.on_commit(lambda: _clear(sender))
    except Exception:
        _clear(sender)


def _clear(sender):
    label = f"{sender.__module__.rsplit('.', 1)[0]}.{sender.__name__}"
    namespaces = INVALIDATION_RULES.get(label)
    if namespaces:
        invalidate(namespaces)
