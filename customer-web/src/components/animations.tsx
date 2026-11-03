/**
 * Micro-illustrations & success motion, built as SVG + CSS rather than a
 * Lottie runtime: they weigh a few hundred bytes, inherit tokens, and obey
 * `prefers-reduced-motion` automatically. The visual language follows the
 * LottieFiles / Flaticon e-commerce sets — a soft halo, one floating object,
 * and three orbiting sparks — so empty states feel alive without a player.
 */
import { Icon, type IconName } from "./icons";

export type ArtKind =
  | "cart"
  | "heart"
  | "search"
  | "box"
  | "orders"
  | "error"
  | "success"
  | "leaf";

const ART_ICON: Record<ArtKind, IconName> = {
  cart: "bag",
  heart: "heart",
  search: "search",
  box: "box",
  orders: "receipt",
  error: "alertCircle",
  success: "checkCircle",
  leaf: "leaf",
};

/** Animated empty-state illustration. */
export function AnimatedArt({
  kind = "box",
  size = 132,
  label,
}: {
  kind?: ArtKind;
  size?: number;
  label?: string;
}) {
  return (
    <div
      className={`art art-${kind}`}
      style={{ width: size, height: size }}
      role={label ? "img" : undefined}
      aria-label={label}
      aria-hidden={label ? undefined : true}
    >
      <span className="art-halo" />
      <span className="art-ring art-ring-1" />
      <span className="art-ring art-ring-2" />
      <span className="art-core">
        <Icon name={ART_ICON[kind]} size={Math.round(size * 0.36)} strokeWidth={1.4} />
      </span>
      <span className="art-dot art-dot-1" />
      <span className="art-dot art-dot-2" />
      <span className="art-dot art-dot-3" />
    </div>
  );
}

/** Draw-on success tick — used for add-to-cart and order confirmation. */
export function SuccessCheck({ size = 44, className = "" }: { size?: number; className?: string }) {
  return (
    <svg
      className={`success-check ${className}`.trim()}
      width={size}
      height={size}
      viewBox="0 0 48 48"
      role="img"
      aria-label="Success"
    >
      <circle className="success-check-ring" cx="24" cy="24" r="20" />
      <path className="success-check-tick" d="m14 24.5 7 7L34 17" />
    </svg>
  );
}
