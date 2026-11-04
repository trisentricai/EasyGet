"""Single source of truth for storefront checkout pricing.

The cart, checkout review, and order creation all use these constants and
formulas. Keep the frontend mirror in `customer-web/src/utils/pricing.ts`
in sync — the backend remains authoritative when an order is placed.

No tax rules live here on purpose: `tax` is a pass-through field that stays
zero until a real tax engine supplies a value.
"""

from decimal import Decimal, ROUND_HALF_UP

DELIVERY_FEE = Decimal("29.00")
FREE_DELIVERY_OVER = Decimal("499.00")
# No COD fee is configured today. The checkout still shows the row when COD
# is selected so a real fee can be wired without changing the UI contract.
COD_FEE = Decimal("0.00")
ZERO = Decimal("0.00")
CENT = Decimal("0.01")


def q(value) -> Decimal:
    """Round a money value to paise using commercial rounding."""
    return Decimal(value).quantize(CENT, rounding=ROUND_HALF_UP)


def base_delivery_fee(subtotal) -> Decimal:
    """Gross delivery fee before any coupon waiver."""
    return ZERO if q(subtotal) >= FREE_DELIVERY_OVER else DELIVERY_FEE


def product_discount(coupon, subtotal) -> Decimal:
    """Coupon discount against the item subtotal (never below zero)."""
    if coupon is None:
        return ZERO
    subtotal = q(subtotal)
    if coupon.discount_type == "PERCENTAGE":
        value = q(subtotal * coupon.discount_value / Decimal("100"))
        if coupon.max_discount:
            value = min(value, q(coupon.max_discount))
        return min(value, subtotal)
    if coupon.discount_type == "FIXED":
        return min(q(coupon.discount_value), subtotal)
    return ZERO


def coupon_benefits(coupon, subtotal) -> dict:
    """Return gross delivery plus every coupon benefit for one cart.

    FREE_DELIVERY is represented as a real discount equal to the gross
    delivery fee, so the totals breakdown can show `Delivery ₹29` and
    `Discount −₹29` (net free) without special-case arithmetic.
    """
    subtotal = q(subtotal)
    delivery = base_delivery_fee(subtotal)
    product = product_discount(coupon, subtotal)
    free_delivery = bool(
        coupon is not None and coupon.discount_type == "FREE_DELIVERY"
    )
    delivery_discount = delivery if free_delivery else ZERO
    return {
        "subtotal": subtotal,
        "product_discount": product,
        "delivery_discount": delivery_discount,
        "discount": product + delivery_discount,
        "delivery_fee": delivery,
        "free_delivery": free_delivery,
    }


def checkout_totals(subtotal, coupon, payment_method="cod") -> dict:
    """Cart-level totals used by order creation."""
    benefits = coupon_benefits(coupon, subtotal)
    cod = COD_FEE if payment_method == "cod" else ZERO
    tax = ZERO
    total = (
        benefits["subtotal"]
        - benefits["discount"]
        + benefits["delivery_fee"]
        + cod
        + tax
    )
    return {
        **benefits,
        "cod_fee": cod,
        "tax": tax,
        "total": q(total),
    }


def validate_coupon_code(code, user, subtotal):
    """Resolve and validate a code.

    Returns `(coupon, None)` on success or `(None, message)` when the code is
    unknown/expired/ineligible. Callers translate the message into a DRF
    ValidationError or a `{valid: false}` response.
    """
    from admin_panel.models import Coupon

    text = (code or "").strip()
    if not text:
        return None, None
    coupon = Coupon.objects.filter(code__iexact=text).first()
    if coupon is None:
        return None, "Invalid coupon code."
    is_valid, message = coupon.is_valid(user, subtotal)
    if not is_valid:
        return None, message
    return coupon, None


def allocate(amount, weights) -> list[Decimal]:
    """Split a cart-level amount across per-seller orders by subtotal.

    The last order receives the rounding remainder so the allocations always
    sum to the original amount (no lost/created paise on split checkouts).
    """
    amount = q(amount)
    weights = [q(w) for w in weights]
    total_weight = sum(weights, ZERO)
    if not weights or total_weight <= 0 or amount == 0:
        return [ZERO for _ in weights]
    parts: list[Decimal] = []
    allocated = ZERO
    for weight in weights[:-1]:
        part = q(amount * weight / total_weight)
        parts.append(part)
        allocated += part
    parts.append(amount - allocated)
    return parts
