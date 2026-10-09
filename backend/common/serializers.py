"""DRF serializer helpers for media URLs.

Public payloads should carry absolute image URLs so any client (customer
web, admin web, Flutter, preview scrapers) can render them without knowing
where the API lives. When a serializer runs without a request in its
context we fall back to the storage backend's own URL — relative on the
local FileSystemStorage, already absolute on Supabase S3 — never a broken
half-path.
"""

from rest_framework import serializers


class AbsoluteImageField(serializers.ImageField):
    """ImageField whose representation is always a renderable URL.

    Only ``to_representation`` is overridden: uploads (``to_internal_value``)
    behave exactly like a plain ImageField, so multipart write endpoints are
    unaffected.
    """

    def to_representation(self, value):
        if not value:
            return None
        try:
            url = value.url
        except (ValueError, AttributeError):
            # No file bound to the field (or storage refused) — nothing to
            # link to; None beats a broken thumbnail.
            return None
        request = self.context.get("request") if self.context else None
        if request is not None and not str(url).startswith(("http://", "https://")):
            return request.build_absolute_uri(str(url))
        return url
