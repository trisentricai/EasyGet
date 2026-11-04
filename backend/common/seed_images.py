"""Curated demo imagery for the storefront seed commands.

ImageFields store files, not remote URLs. Rather than teaching every client a
second image field, the seed commands download a small set of curated Unsplash
photos and write them through the normal upload pipeline (the shared pre_save
signal converts them to compressed WebP). Serializers then return ordinary
absolute storage URLs, so admin, customer-web and Flutter all share one path.

The downloads are best-effort: if the network is unavailable the field is left
empty (or a dangling reference is cleared), and clients fall back to the
existing gradient / initials / monogram placeholders instead of a broken image.
"""

from __future__ import annotations

import hashlib
import logging
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from django.core.files.uploadedfile import SimpleUploadedFile
from django.utils.text import slugify

logger = logging.getLogger(__name__)

_TIMEOUT_SECONDS = 20
_MAX_BYTES = 8 * 1024 * 1024
_USER_AGENT = "EasyGetSeed/1.0 (+https://easyget.app)"
_EXTENSIONS = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
}


def _photo(photo_id: str, *, width: int, height: int, quality: int = 80) -> str:
    """Build a deterministic, pre-cropped Unsplash URL."""
    return (
        f"https://images.unsplash.com/{photo_id}"
        f"?auto=format&fit=crop&w={width}&h={height}&q={quality}&fm=jpg"
    )


# Square catalog tiles, keyed by category slug. Slugs match both the platform
# demo categories and the Shop Stock Checklist seed.
CATEGORY_IMAGE_URLS: dict[str, str] = {
    "fancy-items": _photo("photo-1515562141207-7a88fb7ce338", width=800, height=800),
    "footwear": _photo("photo-1600185365483-26d7a4cc7519", width=800, height=800),
    "kitchen-tools": _photo("photo-1556909114-f6e7ad7d3136", width=800, height=800),
    "daily-usage-things": _photo(
        "photo-1584622650111-993a426fbf0a", width=800, height=800
    ),
    "glass-items": _photo("photo-1544145945-f90425340c7e", width=800, height=800),
    "gift-items": _photo("photo-1549465220-1a8b9238cd48", width=800, height=800),
    "wall-frames": _photo("photo-1513519245088-0e12902e5a38", width=800, height=800),
    "grocery": _photo("photo-1542838132-92c53300491e", width=800, height=800),
    "kitchen-items-ss-aluminium-clay": _photo(
        "photo-1556911220-bff31c812dba", width=800, height=800
    ),
    "skin-care": _photo("photo-1602143407151-7111542de6e8", width=800, height=800),
    # The demo PC row slug is simply "category"; keep the more descriptive
    # alias too so custom stores in either shape get the same art.
    "category": _photo("photo-1496181133206-80ce9b88a853", width=800, height=800),
    "pc-category": _photo("photo-1496181133206-80ce9b88a853", width=800, height=800),
}

# Wide art for HERO/BANNER carousel slides.
HERO_IMAGE_URLS: list[str] = [
    _photo("photo-1441986300917-64674bd600d8", width=1600, height=900),
    _photo("photo-1542838132-92c53300491e", width=1600, height=900),
    _photo("photo-1556909114-f6e7ad7d3136", width=1600, height=900),
    _photo("photo-1483985988355-763728e1935b", width=1600, height=900),
]


def _download(url: str) -> tuple[bytes, str] | tuple[None, None]:
    request = Request(url, headers={"User-Agent": _USER_AGENT})
    try:
        with urlopen(request, timeout=_TIMEOUT_SECONDS) as response:
            content_type = response.headers.get_content_type()
            if not content_type.startswith("image/"):
                logger.warning("Seed image is not an image (%s): %s", content_type, url)
                return None, None
            data = response.read(_MAX_BYTES + 1)
    except (HTTPError, URLError, TimeoutError, OSError, ValueError) as exc:
        logger.warning("Seed image download failed: %s (%s)", url, exc)
        return None, None

    if not data or len(data) > _MAX_BYTES:
        logger.warning("Seed image download was empty or too large: %s", url)
        return None, None
    return data, content_type


def _clear(instance, field_name: str) -> None:
    """Remove a dangling storage reference so clients render a fallback."""
    field = getattr(instance, field_name)
    try:
        field.delete(save=False)
    except Exception:
        # The storage may already be missing the file; clearing the DB
        # reference is still the right outcome.
        logger.debug("Could not delete stale seed image", exc_info=True)
    setattr(instance, field_name, None)
    instance.save(update_fields=[field_name])


def ensure_image(
    instance,
    field_name: str,
    url: str | None,
    *,
    force: bool = False,
    prefix: str = "seed",
) -> str:
    """Ensure ``instance.<field_name>`` points at a reachable seeded image.

    Returns one of ``kept`` (existing file is present), ``seeded`` (download
    written), ``cleared`` (dangling reference removed), ``failed`` (download
    failed and there was nothing to keep) or ``skipped`` (no URL configured).
    """
    field = getattr(instance, field_name)
    current_name = field.name if field else None
    exists: bool | None = None
    if current_name:
        try:
            exists = field.storage.exists(current_name)
        except Exception:
            logger.warning(
                "Could not check seed image storage for %s", current_name,
                exc_info=True,
            )
            exists = None

    if current_name and exists and not force:
        return "kept"

    if not url:
        if current_name and exists is False:
            _clear(instance, field_name)
            return "cleared"
        return "skipped"

    data, content_type = _download(url)
    if not data:
        if current_name and exists is False:
            _clear(instance, field_name)
            return "cleared"
        return "failed"

    if current_name:
        try:
            field.delete(save=False)
        except Exception:
            logger.debug("Could not remove old seed image", exc_info=True)

    stem = slugify(prefix) or "seed"
    digest = hashlib.sha1(url.encode("utf-8")).hexdigest()[:10]
    extension = _EXTENSIONS.get(content_type, ".jpg")
    filename = f"{stem}-{digest}{extension}"
    upload = SimpleUploadedFile(filename, data, content_type=content_type)
    # Assign then save (rather than FieldFile.save) so the project's pre_save
    # compression signal sees a fresh upload and converts it to WebP.
    setattr(instance, field_name, upload)
    instance.save(update_fields=[field_name])
    return "seeded"
