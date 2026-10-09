"""Announcement-bar (ticker) content + style.

Edited in admin (Storefront page), stored in SystemConfig under key "ticker"
as JSON flagged public. The platform storefront payload embeds it, so the
customer app renders merchant copy with zero code changes.

Shape:
    {
      "items": ["Free delivery over Rs.499", ...],  # max 12, 120 chars each
      "speed": 26,        # seconds per loop (8-120)
      "color": "#b91c1c", # text hex
      "bg": "#fef2f2",    # strip background hex
      "symbol": "✦",   # separator between items (max 4 chars)
      "fontSize": 12,     # px (10-24)
      "radius": 0,        # strip corner px (0-24)
    }

Anything missing, non-public, or malformed falls back to DEFAULT_TICKER, so
the strip always renders something sane.
"""

DEFAULT_TICKER = {
    "items": [
        "Free delivery over Rs.499",
        "7-day easy returns",
        "Cash on delivery available",
        "Everyday low prices",
    ],
    "speed": 26,
    "color": "#b91c1c",
    "bg": "#fef2f2",
    "symbol": "✦",
    "fontSize": 12,
    "radius": 0,
}

_TICKER_KEY = "ticker"


def _is_hex(value):
    if not isinstance(value, str):
        return False
    text = value.strip().lstrip("#")
    return len(text) in (3, 6) and all(c in "0123456789abcdefABCDEF" for c in text)


def _num(value, default, minimum, maximum):
    try:
        number = float(value)
    except (TypeError, ValueError):
        return default
    return min(maximum, max(minimum, number))


def sanitize_ticker(raw):
    """Coerce arbitrary stored JSON into a safe TickerConfig dict."""
    if not isinstance(raw, dict):
        return dict(DEFAULT_TICKER)
    items = raw.get("items")
    if not isinstance(items, list):
        items = []
    clean_items = [str(i).strip()[:120] for i in items if str(i).strip()][:12]
    if not clean_items:
        clean_items = list(DEFAULT_TICKER["items"])
    color = raw.get("color")
    bg = raw.get("bg")
    symbol = raw.get("symbol")
    return {
        "items": clean_items,
        "speed": _num(raw.get("speed"), DEFAULT_TICKER["speed"], 8, 120),
        "color": color if _is_hex(color) else DEFAULT_TICKER["color"],
        "bg": bg if _is_hex(bg) else DEFAULT_TICKER["bg"],
        "symbol": str(symbol)[:4] if symbol else DEFAULT_TICKER["symbol"],
        "fontSize": _num(raw.get("fontSize"), DEFAULT_TICKER["fontSize"], 10, 24),
        "radius": _num(raw.get("radius"), DEFAULT_TICKER["radius"], 0, 24),
    }


def get_ticker_config():
    """Public ticker config (SystemConfig) or defaults. Never raises."""
    try:
        from admin_panel.models import SystemConfig

        row = SystemConfig.objects.filter(key=_TICKER_KEY, is_public=True).first()
        if row is None:
            return dict(DEFAULT_TICKER)
        return sanitize_ticker(row.get_typed_value())
    except Exception:
        return dict(DEFAULT_TICKER)
