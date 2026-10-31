"""Cache-aside helpers for the public read-heavy endpoints.

Payloads (serialized, JSON-ready Python) are cached in Redis for 1 hour;
django-redis is configured with IGNORE_EXCEPTIONS so a down Redis degrades
to cache-miss / no-caching instead of taking the API down. Cache keys are
namespaced so invalidation is a handful of pattern deletes.
"""

import hashlib
import json
import logging

from django.core.cache import cache

logger = logging.getLogger(__name__)

TTL_SECONDS = 60 * 60  # 1 hour

# Every namespace a cached payload may live under. Invalidation clears whole
# namespaces — cheap and always-correct (no per-object key bookkeeping).
NAMESPACES = ("storefront", "categories", "products", "search")


def _key(namespace: str, parts) -> str:
    raw = json.dumps(list(parts), sort_keys=True, default=str)
    digest = hashlib.sha256(raw.encode()).hexdigest()[:24]
    return f"api:v1:{namespace}:{digest}"


def get_or_set(namespace: str, parts, producer):
    """Cache-aside: return the cached payload for (namespace, parts) or run
    `producer()` (a callable returning a JSON-serializable payload), cache it
    for 1 hour and return it. Never raises on cache failures."""
    key = _key(namespace, parts)
    try:
        hit = cache.get(key)
        if hit is not None:
            return hit
    except Exception:  # cache backend misbehaving — treat as a miss
        logger.warning("Cache read failed for %s", key, exc_info=True)

    payload = producer()

    try:
        cache.set(key, payload, TTL_SECONDS)
    except Exception:
        logger.warning("Cache write failed for %s", key, exc_info=True)
    return payload


def invalidate(namespaces=NAMESPACES) -> int:
    """Drop every cached payload under the given namespaces. Called from
    post_save/post_delete signals so admin edits reflect immediately."""
    count = 0
    for namespace in namespaces:
        try:
            count += cache.delete_pattern(f"api:v1:{namespace}:*")
        except Exception:
            logger.warning("Cache invalidation failed for %s", namespace, exc_info=True)
    return count
