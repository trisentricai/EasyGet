import { useEffect, useRef, useState, type ReactNode } from "react";
import { href } from "../hooks/useHashRoute";
import {
  addToWishlist,
  getTokens,
  img,
  removeFromWishlist,
  type Product,
} from "../services/api";
import { isWished, syncWishlistCache, toggleWishlist } from "../utils/history";
import { Icon, type IconName } from "./icons";

export function money(value: string | number | null | undefined): string {
  if (value === null || value === undefined || value === "") return "—";
  const n = typeof value === "string" ? Number(value) : value;
  if (Number.isNaN(n)) return String(value);
  return `₹${n.toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

/** First letters of a name, set in the display face — our no-image placeholder. */
export function Monogram({ text, className = "" }: { text: string; className?: string }) {
  const initials = text
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((w) => w[0]?.toUpperCase() ?? "")
    .join("");
  return <span className={`monogram ${className}`}>{initials || "·"}</span>;
}

export function Price({
  price,
  mrp,
  discount,
  size = "md",
}: {
  price: string | null | undefined;
  mrp?: string | null;
  discount?: number;
  size?: "sm" | "md" | "lg";
}) {
  return (
    <div className={`price price-${size}`}>
      <span className="price-now">{money(price)}</span>
      {mrp && Number(mrp) > Number(price ?? 0) ? <s className="price-mrp">{money(mrp)}</s> : null}
      {discount && discount > 0 ? <span className="price-off">{discount}% off</span> : null}
    </div>
  );
}

/** Flipkart-style green rating pill: ★ 4.3 (128) */
export function RatingPill({
  avg,
  count,
  size = "sm",
}: {
  avg: number | null | undefined;
  count: number | undefined;
  size?: "sm" | "lg";
}) {
  if (!avg || !count) return null;
  return (
    <span className={`rating-pill rating-pill-${size}`}>
      {avg.toFixed(1)}
      <svg width="9" height="9" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
        <path d="M12 2l2.9 6.6 7.1.7-5.4 4.8 1.6 7-6.2-3.7-6.2 3.7 1.6-7L2 9.3l7.1-.7z" />
      </svg>
      <em>({count > 999 ? `${(count / 1000).toFixed(1)}k` : count})</em>
    </span>
  );
}

export function WishButton({ slug, className = "" }: { slug: string; className?: string }) {
  const [wished, setWished] = useState(() => isWished(slug));
  const [busy, setBusy] = useState(false);

  const toggle = async (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (busy) return;
    const next = !wished;
    setWished(next);
    if (getTokens()) {
      // Signed in: server is the source of truth (optimistic, rolls back).
      setBusy(true);
      try {
        const res = next ? await addToWishlist(slug) : await removeFromWishlist(slug);
        setWished(next);
        // Keep the offline cache aligned with the server.
        syncWishlistCache(slug, next);
        void res;
      } catch {
        setWished(!next);
      } finally {
        setBusy(false);
      }
    } else {
      toggleWishlist(slug);
    }
  };

  return (
    <button
      type="button"
      className={`wish-btn ${wished ? "on" : ""} ${className}`}
      aria-label={wished ? "Remove from wishlist" : "Add to wishlist"}
      aria-pressed={wished}
      disabled={busy}
      onClick={toggle}
    >
      <Icon name="heart" size={16} />
    </button>
  );
}

export function ProductCard({ product }: { product: Product }) {
  const image = img(product.primary_image);
  const freeDelivery = Number(product.base_price ?? 0) >= 499;
  return (
    <a className="product-card" href={href(`product/${product.slug}`)}>
      <div className="product-thumb">
        {image ? <img src={image} alt={product.name} loading="lazy" /> : <Monogram text={product.name} />}
        {(product.discount_percent ?? 0) >= 50 ? (
          <span className="chip chip-deal">{product.discount_percent}% off</span>
        ) : product.is_featured ? (
          <span className="chip chip-featured">★ Featured</span>
        ) : null}
        <WishButton slug={product.slug} className="wish-card" />
      </div>
      <div className="product-body">
        <div className="product-brand">{product.brand || product.category?.name || ""}</div>
        <div className="product-name" title={product.name}>{product.name}</div>
        <div className="product-rate-row">
          <RatingPill avg={product.rating_avg} count={product.rating_count} />
        </div>
        <Price price={product.base_price} mrp={product.mrp} discount={product.discount_percent} size="sm" />
        {freeDelivery ? <div className="free-ship">Free delivery</div> : null}
      </div>
    </a>
  );
}

export function Section({ title, subtitle, children, action }: { title?: string; subtitle?: string; children: ReactNode; action?: ReactNode }) {
  return (
    <section className="section">
      {(title || action) && (
        <div className="section-head">
          <div>
            {title ? <h2>{title}</h2> : null}
            {subtitle ? <p className="muted">{subtitle}</p> : null}
          </div>
          {action}
        </div>
      )}
      {children}
    </section>
  );
}

export function Spinner() {
  return <div className="spinner" role="status" aria-label="Loading" />;
}

export function CardSkeletonGrid({ count = 8 }: { count?: number }) {
  return (
    <div className="grid grid-products">
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className="card-skeleton" />
      ))}
    </div>
  );
}

export function EmptyState({ icon = "box", title, text, action }: { icon?: IconName; title: string; text?: string; action?: ReactNode }) {
  return (
    <div className="empty-state">
      <div className="empty-ico">
        <Icon name={icon} size={26} />
      </div>
      <h3>{title}</h3>
      {text ? <p className="muted">{text}</p> : null}
      {action}
    </div>
  );
}

export function StatusChip({ status }: { status: string }) {
  const s = status.toLowerCase();
  const cls = ["pending", "confirmed", "preparing", "ready"].includes(s)
    ? "pending"
    : s === "delivered"
      ? "ok"
      : s === "cancelled"
        ? "err"
        : "info";
  return <span className={`chip chip-${cls}`}>{status.replaceAll("_", " ").toLowerCase()}</span>;
}

export function SignInGate({ title, text }: { title: string; text: string }) {
  return (
    <div className="auth-wrap">
      <div className="auth-card" style={{ textAlign: "center" }}>
        <div style={{ display: "grid", placeItems: "center", margin: "10px 0 12px", color: "var(--primary)" }}>
          <Icon name="lock" size={30} />
        </div>
        <h1>{title}</h1>
        <p className="sub">{text}</p>
        <button className="btn btn-block" onClick={() => (window.location.hash = "#/login")}>
          Sign in or create an account
        </button>
      </div>
    </div>
  );
}

/** One-shot "pop" trigger: flips a ref-driven class when `trigger` changes. */
export function usePopOnChange(value: number) {
  const ref = useRef<HTMLSpanElement | null>(null);
  const first = useRef(true);
  useEffect(() => {
    if (first.current) {
      first.current = false;
      return;
    }
    const el = ref.current;
    if (!el) return;
    el.classList.remove("pop");
    void el.offsetWidth; // restart the animation
    el.classList.add("pop");
  }, [value]);
  return ref;
}
