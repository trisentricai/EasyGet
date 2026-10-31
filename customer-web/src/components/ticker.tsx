/**
 * Announcement bar under the header, merchant-edited in admin
 * (Storefront > Announcement bar) and served inside the platform
 * storefront payload — no code change to reword it, ever.
 *
 * Without config it renders the classic four messages with legacy CSS, so
 * first paint is byte-identical to the old hardcoded strip.
 */
import type { ReactNode } from "react";
import { useStorefront } from "../context/StorefrontContext";

const FALLBACK_ITEMS = [
  "Free delivery over ₹499",
  "7-day easy returns",
  "Cash on delivery available",
  "Everyday low prices",
];
const FALLBACK_SYMBOL = "✦";

export function Ticker() {
  const { data } = useStorefront();
  const t = data?.ticker;
  const items = t && t.items.length ? t.items : FALLBACK_ITEMS;
  const symbol = t?.symbol || FALLBACK_SYMBOL;
  const cells: ReactNode[] = [];
  [...items, ...items].forEach((text, i) => {
    cells.push(<span key={`t${i}`}>{text}</span>);
    cells.push(<i key={`s${i}`}>{symbol}</i>);
  });
  return (
    <div
      className="offer-strip"
      aria-hidden="true"
      style={
        t
          ? {
              background: t.bg,
              color: t.color,
              fontSize: t.fontSize,
              borderRadius: t.radius,
            }
          : undefined
      }
    >
      <div
        className="offer-track"
        style={t ? { animationDuration: `${t.speed}s` } : undefined}
      >
        {cells}
      </div>
    </div>
  );
}
