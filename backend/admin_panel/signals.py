"""Bust cached storefront payloads when site-wide config changes.

The platform render (theme, sections, ticker) is cached for an hour; admin
edits must reflect immediately, not at TTL expiry.
"""

from django.db.models.signals import post_delete, post_save
from django.dispatch import receiver

from common.cache import invalidate

from .models import SystemConfig


@receiver(
    [post_save, post_delete],
    sender=SystemConfig,
    dispatch_uid="easyget.invalidate-config-cache",
)
def invalidate_config_cache(sender, instance, **kwargs):
    invalidate(("storefront",))
