/**
 * Announcement bar under the header, merchant-edited in admin
 * (Storefront > Announcement bar) and served inside the platform
 * storefront payload — no code change to reword it, ever.
 *
 * One message at a time, cross-fading every ~3.8s. The rotating text is
 * hidden from assistive tech (auto-rotating content is disruptive) and the
 * full list is exposed once in a visually-hidden block instead.
 */
import { useEffect, useState } from "react";
import { useStorefront } from "../context/StorefrontContext";
import { Icon, type IconName } from "./icons";

const FALLBACK_ITEMS = [
  "Free delivery over ₹499",
  "7-day easy returns",
  "Cash on delivery available",
  "Everyday low prices",
];

/** Pick a meaningful glyph for merchant-written copy. */
function iconFor(text: string): IconName {
  const t = text.toLowerCase();
  if (/deliver|ship|arrive/.test(t)) return "truck";
  if (/return|exchange|refund/.test(t)) return "refresh";
  if (/cod|cash|pay|payment|upi/.test(t)) return "wallet";
  if (/price|offer|deal|discount|save|off/.test(t)) return "tag";
  if (/quality|trust|verified|genuine/.test(t)) return "shieldCheck";
  return "sparkles";
}

/** Merchant speed is seconds-per-message; keep it in the requested 3–4s band. */
function dwellMs(speed: number | undefined): number {
  if (!speed || !Number.isFinite(speed) || speed > 6 || speed < 2) return 3800;
  return Math.round(speed * 1000);
}

export function Ticker() {
  const { data } = useStorefront();
  const t = data?.ticker;
  const items = t && t.items.length ? t.items : FALLBACK_ITEMS;
  const [idx, setIdx] = useState(0);
  const listKey = items.join("\u0001");
  const dwell = dwellMs(t?.speed);

  useEffect(() => {
    setIdx(0);
    if (items.length < 2) return;
    const timer = window.setInterval(() => {
      setIdx((i) => (i + 1) % items.length);
    }, dwell);
    return () => window.clearInterval(timer);
    // `listKey` captures item identity; `items.length` is the true bound.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [listKey, dwell]);

  const current = items[idx] ?? items[0] ?? "";

  return (
    <section
      className="announce-bar"
      aria-label="Store announcements"
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
      <div className="announce-inner">
        <span className="announce-mark" aria-hidden="true">
          <Icon name={iconFor(current)} size={14} />
        </span>

        <div className="announce-stage" aria-hidden="true">
          {items.map((text, i) => (
            <span
              key={`${text}-${i}`}
              className={`announce-item ${i === idx ? "on" : ""}`}
            >
              {text}
            </span>
          ))}
        </div>

        {items.length > 1 ? (
          <span className="announce-dots" aria-hidden="true">
            {items.map((text, i) => (
              <span key={`${text}-dot-${i}`} className={`announce-dot ${i === idx ? "on" : ""}`} />
            ))}
          </span>
        ) : null}

        <span className="sr-only">{items.join(". ")}</span>
      </div>
    </section>
  );
}
