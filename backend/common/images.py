"""Automatic upload compression for product/banner/storefront images.

Every freshly-uploaded raster is converted to WebP (quality 80) and downscaled
to a max width — banners/hero art 1200px, product imagery 800px — before the
model is written, so Supabase storage egress and page weight stay bounded.

Safety rules:
- Only *newly uploaded* files are touched (fields loaded from the DB pass
  through untouched, so existing media references never break).
- Anything Pillow can't identify (SVGs, corrupt files, fonts) is saved
  unchanged; compression failure must never block an admin upload.
"""

import io
import logging

from PIL import Image, UnidentifiedImageError
from django.core.files.base import ContentFile
from django.core.files.uploadedfile import UploadedFile

logger = logging.getLogger(__name__)

QUALITY = 80


def compress_image_field(instance, field_name: str, max_width: int) -> None:
    """Compress `instance.<field_name>` in place if it holds a fresh upload."""
    field_file = getattr(instance, field_name, None)
    if not field_file:
        return
    # Name-only assignments (Banner(image="summer.jpg")) and rows loaded from
    # the DB are committed — nothing uploaded to compress, and opening them
    # from storage here would raise FileNotFoundError on a dangling name.
    if getattr(field_file, "_committed", True):
        return

    try:
        raw = getattr(field_file, "file", None)
    except OSError:
        return
    # Only process a just-uploaded file; a FieldFile loaded from storage has
    # no UploadedFile attached and must pass through untouched.
    if not isinstance(raw, UploadedFile):
        return

    original_name = field_file.name or "image"
    try:
        raw.seek(0)
        with Image.open(raw) as im:
            im.load()
            if im.width <= 0 or im.height <= 0:
                return

            # Animated sources (GIF/WebP) lose frames when re-encoded — skip.
            if getattr(im, "is_animated", False):
                return

            # Keep alpha where present; flatten everything else to RGB.
            if im.mode in ("RGBA", "LA", "P"):
                im = im.convert("RGBA")
            else:
                im = im.convert("RGB")

            if im.width > max_width:
                ratio = max_width / im.width
                size = (max_width, max(1, round(im.height * ratio)))
                im = im.resize(size, Image.LANCZOS)

            buffer = io.BytesIO()
            im.save(buffer, format="WEBP", quality=QUALITY, method=4)
            data = buffer.getvalue()

        stem = original_name.rsplit(".", 1)[0] or "image"
        new_name = f"{stem}.webp"
        field_file.save(new_name, ContentFile(data), save=False)
        # The format changed (e.g. .png -> .webp); drop any stale content-type
        # so storage backends derive it from the new extension.
        if hasattr(field_file, "content_type"):
            field_file.content_type = None
    except (UnidentifiedImageError, OSError, ValueError) as exc:
        # Non-image upload or decoder failure: keep the original bytes.
        logger.warning("Image compression skipped for %s (%s)", original_name, exc)
        return
    except Exception:  # pragma: no cover - never block an upload
        logger.exception("Unexpected image compression failure for %s", original_name)
        return
