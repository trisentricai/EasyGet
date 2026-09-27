"""Keep ProductSearchIndex in sync with Product writes.

Without this, products created outside the admin (seeds, imports, API) never
get a full-text document and silently vanish from search results.
"""

from django.db.models.signals import post_save
from django.dispatch import receiver

from products.models import Product


def _reindex_product(product):
    from .models import ProductSearchIndex

    if product.pk is None:
        return
    index, _ = ProductSearchIndex.objects.get_or_create(product=product)
    index.update_index()


@receiver(post_save, sender=Product)
def product_saved(sender, instance, **kwargs):
    _reindex_product(instance)


@receiver(post_save, sender="categories.Category")
def category_saved(sender, instance, **kwargs):
    """A category rename changes every product's indexed category name."""
    from .models import ProductSearchIndex

    for index in ProductSearchIndex.objects.filter(product__category_id=instance.pk):
        index.update_index()
