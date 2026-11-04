import type { AppliedCoupon, CouponType } from "./pricing";
import { toNumber } from "./pricing";

/**
 * The applied coupon survives route changes and a guest→sign-in merge, but
 * not a browser restart: it is revalidated against the current subtotal in
 * CartContext before it is trusted again.
 */
export const COUPON_STORAGE_KEY = "eg-cart-coupon";

const COUPON_TYPES = new Set<CouponType>(["PERCENTAGE", "FIXED", "FREE_DELIVERY"]);

export function readStoredCoupon(): AppliedCoupon | null {
  try {
    const raw = sessionStorage.getItem(COUPON_STORAGE_KEY);
    if (!raw) return null;
    const parsed: unknown = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object") return null;
    const row = parsed as Partial<AppliedCoupon>;
    if (typeof row.code !== "string" || !row.code.trim()) return null;
    if (!row.discount_type || !COUPON_TYPES.has(row.discount_type)) return null;
    return {
      code: row.code,
      discount_type: row.discount_type,
      discount_value: String(row.discount_value ?? "0"),
      max_discount: row.max_discount == null ? null : String(row.max_discount),
    };
  } catch {
    return null;
  }
}

export function writeStoredCoupon(coupon: AppliedCoupon | null): void {
  try {
    if (!coupon) {
      sessionStorage.removeItem(COUPON_STORAGE_KEY);
      return;
    }
    sessionStorage.setItem(COUPON_STORAGE_KEY, JSON.stringify(coupon));
  } catch {
    /* Private mode/quota: the in-memory coupon still works this visit. */
  }
}

/** Short human label for the coupon chip, e.g. "20% off" or "Free delivery". */
export function couponLabel(coupon: AppliedCoupon): string {
  if (coupon.discount_type === "FREE_DELIVERY") return "Free delivery";
  if (coupon.discount_type === "FIXED") {
    return `₹${toNumber(coupon.discount_value).toLocaleString("en-IN")} off`;
  }
  const pct = toNumber(coupon.discount_value);
  const cap = coupon.max_discount == null ? 0 : toNumber(coupon.max_discount);
  return `${pct}% off${cap > 0 ? ` up to ₹${cap.toLocaleString("en-IN")}` : ""}`;
}
