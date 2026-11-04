import type { Order, PaymentMethod } from "../services/api";

/**
 * Storefront pricing mirror of `backend/orders/pricing.py`.
 *
 * The backend stays authoritative when an order is placed; these helpers only
 * make the cart/checkout preview match it. Tax is a pass-through and stays
 * zero until the backend supplies a value — no tax rules live here.
 */

export const DELIVERY_FEE = 29;
export const FREE_DELIVERY_OVER = 499;
/** No COD fee is configured today; the row still renders when COD is chosen. */
export const COD_FEE = 0;

export type CouponType = "PERCENTAGE" | "FIXED" | "FREE_DELIVERY";

export type AppliedCoupon = {
  code: string;
  discount_type: CouponType;
  discount_value: string;
  max_discount: string | null;
};

export type DeliveryConfig = {
  deliveryFee: number;
  freeDeliveryOver: number;
};

export const DEFAULT_DELIVERY_CONFIG: DeliveryConfig = {
  deliveryFee: DELIVERY_FEE,
  freeDeliveryOver: FREE_DELIVERY_OVER,
};

export type Totals = {
  subtotal: number;
  /** Coupon discount against the item subtotal. */
  productDiscount: number;
  /** Gross delivery fee before a free-delivery coupon waives it. */
  deliveryFee: number;
  /** Free-delivery coupon waiver (shown as part of Discount). */
  deliveryDiscount: number;
  /** Total discount = productDiscount + deliveryDiscount. */
  discount: number;
  codFee: number;
  tax: number;
  total: number;
  freeDelivery: boolean;
  couponCode: string | null;
};

export type TotalsInput = {
  subtotal: number | string | null | undefined;
  coupon?: AppliedCoupon | null;
  delivery?: DeliveryConfig;
  paymentMethod?: PaymentMethod | null;
  tax?: number;
};

/** Round to paise without float drift (e.g. 25.199999 → 25.2). */
export function round2(value: number): number {
  if (!Number.isFinite(value)) return 0;
  return Math.round((value + Number.EPSILON) * 100) / 100;
}

export function toNumber(value: number | string | null | undefined): number {
  if (value === null || value === undefined || value === "") return 0;
  const n = typeof value === "number" ? value : Number(value);
  return Number.isFinite(n) ? n : 0;
}

export function productDiscount(coupon: AppliedCoupon | null | undefined, subtotal: number): number {
  if (!coupon || subtotal <= 0) return 0;
  if (coupon.discount_type === "PERCENTAGE") {
    let discount = round2((subtotal * toNumber(coupon.discount_value)) / 100);
    const cap = coupon.max_discount === null ? 0 : toNumber(coupon.max_discount);
    if (cap > 0) discount = Math.min(discount, cap);
    return round2(Math.min(discount, subtotal));
  }
  if (coupon.discount_type === "FIXED") {
    return round2(Math.min(toNumber(coupon.discount_value), subtotal));
  }
  return 0;
}

export function computeTotals({
  subtotal: rawSubtotal,
  coupon,
  delivery = DEFAULT_DELIVERY_CONFIG,
  paymentMethod = null,
  tax = 0,
}: TotalsInput): Totals {
  const subtotal = round2(toNumber(rawSubtotal));
  const threshold = delivery.freeDeliveryOver > 0 ? delivery.freeDeliveryOver : FREE_DELIVERY_OVER;
  const deliveryFee = subtotal <= 0 || subtotal >= threshold ? 0 : round2(delivery.deliveryFee);
  const freeDelivery = coupon?.discount_type === "FREE_DELIVERY";
  const deliveryDiscount = freeDelivery ? deliveryFee : 0;
  const itemDiscount = productDiscount(coupon, subtotal);
  const discount = round2(itemDiscount + deliveryDiscount);
  const codFee = paymentMethod === "cod" ? COD_FEE : 0;
  const taxValue = round2(tax);
  const total = round2(subtotal - discount + deliveryFee + codFee + taxValue);

  return {
    subtotal,
    productDiscount: itemDiscount,
    deliveryFee,
    deliveryDiscount,
    discount,
    codFee,
    tax: taxValue,
    total,
    freeDelivery,
    couponCode: coupon?.code ?? null,
  };
}

/** Totals from an already-placed order's stored amounts (no re-derivation). */
export function orderTotals(order: Order): Totals {
  const subtotal = round2(toNumber(order.subtotal));
  const deliveryFee = round2(toNumber(order.delivery_fee));
  const discount = round2(toNumber(order.discount));
  const tax = round2(toNumber(order.tax));
  const codFee = round2(toNumber(order.cod_fee));
  const total = round2(toNumber(order.total));
  const freeDelivery = order.coupon_type === "FREE_DELIVERY";
  const deliveryDiscount = freeDelivery ? Math.min(deliveryFee, discount) : 0;

  return {
    subtotal,
    productDiscount: round2(discount - deliveryDiscount),
    deliveryFee,
    deliveryDiscount,
    discount,
    codFee,
    tax,
    total,
    freeDelivery,
    couponCode: order.coupon_code || null,
  };
}
