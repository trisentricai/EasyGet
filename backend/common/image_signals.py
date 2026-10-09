"""Wire upload compression into every image-bearing model via pre_save.

Runs once per saved instance *before* the row is written, so what lands in
storage (and in the DB) is already the compressed WebP.
"""

from django.db import connection  # noqa: F401  (import cost only)
from django.db.models.signals import pre_save
from django.dispatch import receiver

from .images import compress_image_field

# model -> [(field, max width)]. Banners/hero art get 1200px; product
# imagery, category icons and storefront art get 800px.
COMPRESS_RULES = {
    "admin_panel.Banner": [("image", 1200)],
    "products.ProductImage": [("image", 800)],
    "categories.Category": [("icon", 800)],
    "storefront.StorefrontTheme": [("logo", 800), ("hero_image", 1200)],
    "storefront.StoreSection": [("image", 1200)],
    "storefront.SectionItem": [("image", 800)],
}


@receiver(pre_save, dispatch_uid="easyget.compress_uploads")
def compress_uploads(sender, instance, **kwargs):
    rules = COMPRESS_RULES.get(f"{sender.__module__.rsplit('.', 1)[0]}.{sender.__name__}")
    if not rules:
        return
    for field_name, max_width in rules:
        compress_image_field(instance, field_name, max_width)
