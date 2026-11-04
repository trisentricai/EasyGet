import { memo, useEffect, useRef, useState, type ReactNode } from "react";
import { useNetwork } from "../context/NetworkContext";
import { useToast } from "../context/ToastContext";
import { href } from "../hooks/useHashRoute";
import {
  addToWishlist,
  getTokens,
  resolveImageUrl,
  removeFromWishlist,
  type Product,
} from "../services/api";
import { isWished, syncWishlistCache, toggleWishlist } from "../utils/history";
import { queueWishlistAction } from "../utils/wishlistQueue";
import { fxClass, fxStyle } from "../utils/imageFx";
import { Icon, type IconName } from "./icons";
import { SafeImage } from "./safe-image";
import { AnimatedArt, type ArtKind } from "./animations";

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
      <Icon name="starFilled" size={9} strokeWidth={0} />
      <em>({count > 999 ? `${(count / 1000).toFixed(1)}k` : count})</em>
    </span>
  );
}

export function WishButton({ slug, className = "" }: { slug: string; className?: string }) {
  const [wished, setWished] = useState(() => isWished(slug));
  const [busy, setBusy] = useState(false);
  const { online } = useNetwork();
  const toast = useToast();

  const toggle = async (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (busy) return;
    const next = !wished;
    setWished(next);
    if (getTokens()) {
      if (!online) {
        // Signed in but disconnected: keep the optimistic heart, persist the
        // desired state, and let NetworkProvider replay it on reconnect.
        syncWishlistCache(slug, next);
        queueWishlistAction(slug, next);
        toast.push("Action saved locally. Will sync when online", "info");
        return;
      }
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
      <Icon name={wished ? "heartFilled" : "heart"} size={16} />
      <span className="wish-burst" aria-hidden="true" />
    </button>
  );
}

function ProductCardComponent({
  product,
  size = "sm",
  effects,
}: {
  product: Product;
  size?: "sm" | "md" | "lg";
  effects?: string[];
}) {
  const fx = Array.isArray(effects) ? effects : [];
  const fadeClass = fx.includes("fade_in") ? "fx-fade-in" : "";
  const image = resolveImageUrl(product.primary_image);

  // Optional multi-image gallery: activates only when the backend exposes
  // additional images; otherwise renders the single primary_image.
  const gallery = Array.isArray((product as { images?: string[] }).images)
    ? ((product as { images?: string[] }).images as string[])
        .map((u) => resolveImageUrl(u))
        .filter((u): u is string => Boolean(u))
    : [];
  const slides = gallery.length ? gallery : image ? [image] : [];
  const [active, setActive] = useState(0);
  const slide = slides[active] ?? image;
  const [imageFailed, setImageFailed] = useState(false);
  useEffect(() => setImageFailed(false), [slide]);

  const out = product.in_stock === false;
  const discount = product.discount_percent ?? 0;

  return (
    <a
      className={`product-card product-card--${size} ${fadeClass}`.trim()}
      href={href(`product/${product.slug}`)}
      onMouseEnter={() => {
        if (slides.length > 1) setActive((i) => (i + 1) % slides.length);
      }}
      onMouseLeave={() => setActive(0)}
    >
      <div className="product-thumb-wrap">
        <div
          className={`product-thumb ${fxClass(product.primary_image_display)} ${slide && !imageFailed ? "" : "is-placeholder"}`.trim()}
          style={fxStyle(product.primary_image_display)}
        >
          <SafeImage
            key={slide ?? "placeholder"}
            src={slide}
            alt={product.name}
            loading="lazy"
            decoding="async"
            width={600}
            height={600}
            onError={() => setImageFailed(true)}
            fallback={
              <span className="ph-badge">
                <Monogram text={product.name} />
              </span>
            }
          />
        </div>
        {out ? (
          <span className="product-chip chip chip-out">Out of stock</span>
        ) : discount >= 5 ? (
          <span className="product-chip chip chip-deal">{discount}% off</span>
        ) : product.is_featured ? (
          <span className="product-chip chip chip-featured">★ Featured</span>
        ) : null}
        <WishButton slug={product.slug} className="wish-card" />
      </div>
      <div className="product-body">
        <div className="product-brand">{product.category?.name || product.brand || ""}</div>
        <div className="product-name" title={product.name}>{product.name}</div>
        {product.rating_count > 0 ? (
          <div className="product-rate-row">
            <RatingPill avg={product.rating_avg} count={product.rating_count} />
          </div>
        ) : null}
        <div className="product-price-row">
          <Price price={product.base_price} mrp={product.mrp} discount={discount} size="md" />
        </div>
      </div>
    </a>
  );
}

function sameEffects(prev?: string[], next?: string[]): boolean {
  if (prev === next) return true;
  if (!prev || !next || prev.length !== next.length) return false;
  return prev.every((value, index) => value === next[index]);
}

/**
 * Cards are pure once rendered; parent filter/typing state should not force
 * every tile in a long grid to re-render. Compare the fields that actually
 * affect the card plus the wishlist/stock flags supplied by list payloads.
 */
function sameProductCard(
  prev: { product: Product; size?: "sm" | "md" | "lg"; effects?: string[] },
  next: { product: Product; size?: "sm" | "md" | "lg"; effects?: string[] },
): boolean {
  if (prev.size !== next.size || !sameEffects(prev.effects, next.effects)) return false;
  const a = prev.product;
  const b = next.product;
  if (a === b) return true;
  const aw = a as Product & { is_wished?: boolean };
  const bw = b as Product & { is_wished?: boolean };
  return (
    a.id === b.id &&
    a.slug === b.slug &&
    a.name === b.name &&
    a.brand === b.brand &&
    a.category?.name === b.category?.name &&
    a.base_price === b.base_price &&
    a.mrp === b.mrp &&
    a.discount_percent === b.discount_percent &&
    a.is_featured === b.is_featured &&
    a.in_stock === b.in_stock &&
    a.primary_image === b.primary_image &&
    a.primary_image_display === b.primary_image_display &&
    a.rating_avg === b.rating_avg &&
    a.rating_count === b.rating_count &&
    aw.is_wished === bw.is_wished
  );
}

export const ProductCard = memo(ProductCardComponent, sameProductCard);

/** Compact "Home / current" breadcrumb used on every inner page. */
export function PageCrumbs({ current }: { current: string }) {
  return (
    <nav className="page-crumbs" aria-label="Breadcrumb">
      <a className="page-crumbs-home" href={href("home")}>
        <Icon name="home" size={13} />
        Home
      </a>
      <span className="page-crumbs-sep" aria-hidden="true">/</span>
      <span className="page-crumbs-current" aria-current="page">{current}</span>
    </nav>
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

const ICON_ART: Partial<Record<IconName, ArtKind>> = {
  cart: "cart",
  bag: "cart",
  bagCheck: "cart",
  heart: "heart",
  heartFilled: "heart",
  search: "search",
  box: "box",
  receipt: "orders",
  warning: "error",
  alertCircle: "error",
  checkCircle: "success",
  leaf: "leaf",
};

export function EmptyState({
  icon = "box",
  title,
  text,
  action,
  art,
}: {
  icon?: IconName;
  title: string;
  text?: string;
  action?: ReactNode;
  /** Optional illustration override; otherwise inferred from the icon. */
  art?: ArtKind;
}) {
  const illustration = art ?? ICON_ART[icon];
  return (
    <div className="empty-state">
      {illustration ? (
        <AnimatedArt kind={illustration} />
      ) : (
        <div className="empty-ico">
          <Icon name={icon} size={26} />
        </div>
      )}
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
