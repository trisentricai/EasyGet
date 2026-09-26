from rest_framework.decorators import api_view, permission_classes, throttle_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response


@api_view(["GET"])
@permission_classes([AllowAny])
@throttle_classes([])  # health checks must never be throttled or hit the cache
def health(request):
    return Response({"status": "ok", "service": "easyget-api"})


import re as _re

_PINCODE_CACHE = {}  # process-local; postal lookups are stable for years
_POSTAL_API = "https://api.postalpincode.in/pincode/{pin}"

# The postal API returns full state names; stores may use 2-letter codes.
_STATE_ALIASES = {
    "an": "andaman and nicobar islands", "ap": "andhra pradesh",
    "ar": "arunachal pradesh", "as": "assam", "br": "bihar",
    "ch": "chandigarh", "cg": "chhattisgarh", "dd": "daman and diu",
    "dl": "delhi", "ga": "goa", "gj": "gujarat", "hr": "haryana",
    "hp": "himachal pradesh", "jk": "jammu and kashmir", "jh": "jharkhand",
    "ka": "karnataka", "kl": "kerala", "la": "ladakh", "ld": "lakshadweep",
    "mp": "madhya pradesh", "mh": "maharashtra", "mn": "manipur",
    "ml": "meghalaya", "mz": "mizoram", "nl": "nagaland", "or": "odisha",
    "py": "puducherry", "pb": "punjab", "rj": "rajasthan", "sk": "sikkim",
    "tn": "tamil nadu", "ts": "telangana", "tr": "tripura",
    "up": "uttar pradesh", "ut": "uttarakhand", "wb": "west bengal",
}


def _norm_state(value: str) -> str:
    v = (value or "").strip().lower()
    return _STATE_ALIASES.get(v, v)


def _store_state():
    """State of the primary active store - same-state orders ship in 2 days."""
    try:
        from stores.models import Store

        store = (
            Store.objects.filter(is_active=True, is_platform=False)
            .order_by("created_at")
            .first()
        )
        return (getattr(store, "state", "") or "").strip() if store else ""
    except Exception:
        return ""


@api_view(["GET"])
@permission_classes([AllowAny])
def pincode(request, pin):
    """Validate an Indian pincode and return delivery ETA/fee.

    Lookup: api.postalpincode.in (public, no key). If unreachable, falls
    back to a format-only heuristic - the PDP never hard-fails.
    """
    if not _re.fullmatch(r"\d{6}", pin):
        return Response(
            {"valid": False, "reason": "Pincode must be exactly 6 digits."},
            status=400,
        )

    if pin in _PINCODE_CACHE:
        return Response(_PINCODE_CACHE[pin])

    payload = {
        "valid": True,
        "pincode": pin,
        "city": None,
        "state": None,
        "eta_days": 4,
        "delivery_fee": "29.00",
        "free_delivery_over": "499.00",
        "source": "fallback",
    }

    try:
        import requests

        # The postal API drops requests carrying python-requests' default UA.
        resp = requests.get(
            _POSTAL_API.format(pin=pin),
            headers={"User-Agent": "Mozilla/5.0 (compatible; EasyGet/1.0)"},
            timeout=4,
        )
        data = resp.json()
        entry = data[0] if isinstance(data, list) and data else {}
        if entry.get("Status") == "Error" or not entry.get("PostOffice"):
            payload = {
                "valid": False,
                "reason": "We do not deliver to this pincode yet.",
                "pincode": pin,
            }
            return Response(payload, status=404)
        offices = entry["PostOffice"]
        head = offices[0] or {}
        payload["city"] = head.get("District")
        payload["state"] = head.get("State")
        payload["source"] = "api"
        store_state = _store_state()
        if store_state and payload["state"]:
            payload["eta_days"] = (
                2
                if _norm_state(store_state) == _norm_state(payload["state"])
                else 4
            )
    except Exception:
        payload["source"] = "fallback"  # network down: 6-digit format only

    _PINCODE_CACHE[pin] = payload
    return Response(payload)
