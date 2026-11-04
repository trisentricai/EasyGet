import { money } from "./ui";
import type { Totals } from "../utils/pricing";

/**
 * Shared totals breakdown for cart, checkout review, and order detail.
 * Tax is shown as included-at-zero until a real tax engine supplies a value.
 */
export function TotalsBreakdown({
  totals,
  showCod = false,
  className = "",
}: {
  totals: Totals;
  /** Checkout sets this when COD is selected; the ₹0 row is intentional. */
  showCod?: boolean;
  className?: string;
}) {
  const couponNote = totals.couponCode ? ` (${totals.couponCode})` : "";

  return (
    <div className={`totals ${className}`.trim()}>
      <div className="totals-row">
        <span className="muted">Subtotal</span>
        <span>{money(totals.subtotal)}</span>
      </div>

      {totals.discount > 0 ? (
        <div className="totals-row totals-discount">
          <span>Discount{couponNote}</span>
          <span>−{money(totals.discount)}</span>
        </div>
      ) : null}

      <div className="totals-row">
        <span className="muted">Delivery</span>
        {totals.deliveryFee <= 0 ? (
          <span className="totals-free">
            {totals.freeDelivery && totals.couponCode ? "FREE (coupon)" : "FREE"}
          </span>
        ) : (
          <span>{money(totals.deliveryFee)}</span>
        )}
      </div>

      {showCod ? (
        <div className="totals-row">
          <span className="muted">COD fee</span>
          <span>{money(totals.codFee)}</span>
        </div>
      ) : null}

      <div className="totals-row">
        <span className="muted">Tax (included)</span>
        <span>{money(totals.tax)}</span>
      </div>

      {totals.freeDelivery && totals.couponCode && totals.discount <= 0 ? (
        <div className="totals-row totals-coupon-note">
          <span>Coupon {totals.couponCode}</span>
          <span>Free delivery</span>
        </div>
      ) : null}

      <div className="totals-row totals-total">
        <span>Grand total</span>
        <span>{money(totals.total)}</span>
      </div>
    </div>
  );
}
