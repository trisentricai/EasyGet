import { money } from "./ui";
import {
  DEFAULT_DELIVERY_CONFIG,
  FREE_DELIVERY_OVER,
  round2,
  toNumber,
  type DeliveryConfig,
} from "../utils/pricing";

/**
 * Progress towards the free-delivery threshold. The threshold comes from the
 * pincode response when a serviceable pin is known; otherwise the site
 * fallback applies. Hidden for an empty cart.
 */
export function FreeShippingProgress({
  subtotal,
  config = DEFAULT_DELIVERY_CONFIG,
  className = "",
}: {
  subtotal: number | string | null | undefined;
  config?: DeliveryConfig;
  className?: string;
}) {
  const value = round2(toNumber(subtotal));
  if (value <= 0) return null;

  const threshold =
    config.freeDeliveryOver > 0 ? config.freeDeliveryOver : FREE_DELIVERY_OVER;
  const remaining = round2(Math.max(0, threshold - value));
  const unlocked = remaining <= 0;
  const percent = Math.max(0, Math.min(100, (value / threshold) * 100));

  return (
    <div className={`free-ship ${unlocked ? "is-unlocked" : ""} ${className}`.trim()}>
      <div className="free-ship-msg" aria-live="polite">
        {unlocked ? "🎉 You've unlocked free delivery" : `Add ${money(remaining)} more for FREE delivery`}
      </div>
      <div
        className="free-ship-bar"
        role="progressbar"
        aria-label="Progress towards free delivery"
        aria-valuemin={0}
        aria-valuemax={100}
        aria-valuenow={Math.round(percent)}
      >
        <span className="free-ship-fill" style={{ width: `${percent}%` }} />
      </div>
    </div>
  );
}
