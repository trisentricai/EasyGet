/**
 * NEXT_UI ProductCard — DESIGN.md §4 PLP grid density + §3 component rules.
 *
 * Grid density, locked: 4:5 imagery, 3 per row desktop / 2 mobile, 16–20px
 * gaps (the grid itself lives at the call site). Serif appears only on
 * section headings — product names stay Inter, prices/ratings stay Geist
 * Mono. No discount theater: muted MRP strike, never a badge.
 *
 * State-driven prominence: at rest only a quiet wishlist ghost is visible
 * and price is the loudest element; Add to Bag surfaces filled on
 * hover/focus, and stays a quiet outline on touch devices (filled green is
 * reserved for PDP). Missing images get a category-tinted wash — the image
 * arriving, not a failure state.
 *
 * Gating: render only when `isNextUi()` is true (DESIGN.md §8).
 * Every static value below resolves to a DESIGN.md §1 token — no raw hex
 * except the decorative placeholder wash table (meaning-free by design).
 */
import { useEffect, useState } from "react";

export interface NextProductCardData {
  id: number | string;
  name: string;
  brand?: string | null;
  /** base_price — string ("97.00") or number; null renders a fallback line */
  price: string | number | null;
  mrp?: string | number | null;
  ratingAvg?: number | null;
  ratingCount?: number | null;
  /** absolute image URL (resolve with `img()` at the call site); null = category wash */
  image?: string | null;
  slug?: string;
  /** drives the placeholder wash when image is null */
  category?: { slug?: string | null; name?: string | null } | string | null;
}

export interface NextProductCardProps {
  product: NextProductCardData;
  /** omitted => no Add button (browse-only contexts) */
  onAdd?: (product: NextProductCardData) => void;
  /** omitted => name/image are not interactive */
  onOpen?: (product: NextProductCardData) => void;
  wishlisted?: boolean;
  /** omitted => no wishlist heart */
  onToggleWishlist?: (product: NextProductCardData) => void;
  disabled?: boolean;
  /** Add-button busy state (card stays interactive) */
  loading?: boolean;
}

const inrWhole = new Intl.NumberFormat("en-IN", {
  style: "currency",
  currency: "INR",
  maximumFractionDigits: 0,
});
const inrPaise = new Intl.NumberFormat("en-IN", {
  style: "currency",
  currency: "INR",
  minimumFractionDigits: 2,
  maximumFractionDigits: 2,
});

/** Real grocery copy needs real formatting: ₹97, not ₹97.00 — paise only when nonzero. */
export function formatINR(value: string | number | null | undefined): string | null {
  if (value === null || value === undefined || value === "") return null;
  const n = typeof value === "number" ? value : Number(value);
  if (!Number.isFinite(n)) return null;
  return (Math.abs(n % 1) > 1e-9 ? inrPaise : inrWhole).format(n);
}

/**
 * Placeholder wash per category — soft warm swatches that read as the image
 * arriving, not content pretending to load. Decorative only (carries no
 * meaning, never text), so contrast rules do not apply; revisit with real
 * per-product LQIP once the media pipeline lands.
 */
const CATEGORY_WASHES: ReadonlyArray<readonly [RegExp, string]> = [
  [/fresh|produce|fruit|vegetable|leafy|green/i, "#DCE3D2"], // sage
  [/dairy|milk|paneer|curd|ghee|cheese/i, "#F0E7D3"], // cream
  [/bakery|bread|bake|cake/i, "#EAD9B8"], // wheat
  [/beverage|drink|juice|tea|coffee|water/i, "#D8E2E4"], // mist
  [/care|beauty|skin|bath|personal|cosmetic/i, "#EAD9CF"], // blush
  [/baby|infant|kid/i, "#F2EDE4"], // milk
  [/home|house|clean|kitchen|utility|daily/i, "#E3DDD2"], // stone
  [/grocery|pantry|staple|food|snack|spice/i, "#E7DFD3"], // oat
];
const DEFAULT_WASH = "#E7DFD3"; // pantry default

function washFor(category: NextProductCardData["category"]): string {
  const hay = typeof category === "string" ? category : `${category?.name ?? ""} ${category?.slug ?? ""}`;
  for (const [re, wash] of CATEGORY_WASHES) {
    if (re.test(hay)) return wash;
  }
  return DEFAULT_WASH;
}

/** Tracks the app theme (data-theme attribute) so theme-agnostic washes can dim in dark. */
function useDarkTheme(): boolean {
  const [dark, setDark] = useState(
    () => typeof document !== "undefined" && document.documentElement.dataset.theme === "dark",
  );
  useEffect(() => {
    if (typeof document === "undefined") return;
    const el = document.documentElement;
    const update = () => setDark(el.dataset.theme === "dark");
    update();
    const mo = new MutationObserver(update);
    mo.observe(el, { attributes: true, attributeFilter: ["data-theme"] });
    return () => mo.disconnect();
  }, []);
  return dark;
}

/** Touch devices have no hover — the Add action must stay visible (quiet outline). */
function useCoarsePointer(): boolean {
  const [coarse, setCoarse] = useState(
    () =>
      typeof window !== "undefined" &&
      typeof window.matchMedia === "function" &&
      window.matchMedia("(hover: none)").matches,
  );
  useEffect(() => {
    if (typeof window === "undefined" || typeof window.matchMedia !== "function") return;
    const mq = window.matchMedia("(hover: none)");
    const onChange = () => setCoarse(mq.matches);
    mq.addEventListener("change", onChange);
    return () => mq.removeEventListener("change", onChange);
  }, []);
  return coarse;
}

function HeartIcon({ filled, size = 18 }: { filled: boolean; size?: number }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill={filled ? "currentColor" : "none"}
      stroke="currentColor"
      strokeWidth={1.8}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
    >
      <path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z" />
    </svg>
  );
}

const ADD_REVEAL =
  "action-block w-full opacity-0 transition-opacity duration-micro group-hover:opacity-100 group-focus-within:opacity-100 focus-visible:opacity-100 active:opacity-80 disabled:cursor-not-allowed disabled:opacity-50";
const ADD_QUIET =
  "inline-flex min-h-11 w-full items-center justify-center rounded-md bg-transparent font-ui text-sm font-bold text-cta shadow-elev-1 transition-opacity duration-micro active:opacity-70 disabled:cursor-not-allowed disabled:opacity-50";

export function ProductCard({
  product,
  onAdd,
  onOpen,
  wishlisted = false,
  onToggleWishlist,
  disabled = false,
  loading = false,
}: NextProductCardProps) {
  const { name, brand, ratingAvg, ratingCount } = product;
  const price = formatINR(product.price);
  const mrp = formatINR(product.mrp);
  const showRating = (ratingCount ?? 0) > 0 && ratingAvg !== null && ratingAvg !== undefined;
  const interactive = typeof onOpen === "function" && !disabled;
  const dark = useDarkTheme();
  const coarse = useCoarsePointer();
  const wash = washFor(product.category);

  const nameNode = interactive ? (
    <h3 className="min-h-12">
      <button
        type="button"
        onClick={() => onOpen?.(product)}
        aria-label={`View ${name}`}
        className="touch-target w-full justify-start bg-transparent p-0 text-left font-ui text-body font-normal text-ink-strong"
      >
        <span className="line-clamp-2">{name}</span>
      </button>
    </h3>
  ) : (
    <h3 className="line-clamp-2 min-h-12 font-ui text-body font-normal text-ink-strong">{name}</h3>
  );

  return (
    <article
      aria-label={name}
      aria-disabled={disabled || undefined}
      className="group flex flex-col overflow-hidden rounded-md bg-surface shadow-elev-1 transition-shadow duration-micro hover:shadow-elev-2"
    >
      <div className="relative aspect-[4/5] bg-sunken">
        {product.image ? (
          <img
            src={product.image}
            alt=""
            loading="lazy"
            decoding="async"
            draggable={false}
            className="h-full w-full object-cover"
          />
        ) : (
          <div
            aria-hidden="true"
            className="h-full w-full"
            style={{
              backgroundColor: dark ? `color-mix(in srgb, ${wash} 42%, var(--color-canvas))` : wash,
            }}
          />
        )}
        {interactive && (
          <button
            type="button"
            onClick={() => onOpen?.(product)}
            aria-label={`View ${name}`}
            className="absolute inset-0 h-full w-full cursor-pointer bg-transparent"
          />
        )}
        {onToggleWishlist ? (
          <button
            type="button"
            onClick={() => onToggleWishlist(product)}
            aria-pressed={wishlisted}
            aria-label={wishlisted ? `Remove ${name} from wishlist` : `Save ${name} to wishlist`}
            className="touch-target absolute right-2 top-2 z-10 rounded-full"
          >
            <span
              className={`grid h-9 w-9 place-items-center rounded-full bg-surface shadow-elev-1 ${
                wishlisted ? "text-state-alert" : "text-ink-muted"
              }`}
            >
              <HeartIcon filled={wishlisted} />
            </span>
          </button>
        ) : null}
      </div>

      <div className="flex flex-1 flex-col gap-1 p-3">
        {brand ? <p className="truncate font-ui text-xs text-ink-muted">{brand}</p> : null}
        {nameNode}

        {showRating ? (
          <p className="flex items-center gap-1 font-ui text-sm text-ink-muted">
            <span aria-hidden="true" className="text-cta">★</span>
            <span className="sr-only">Rated {Number(ratingAvg).toFixed(1)} out of 5,</span>
            <span className="font-mono tabular-nums">{Number(ratingAvg).toFixed(1)}</span>
            <span>({ratingCount})</span>
          </p>
        ) : null}

        <p className="flex flex-wrap items-baseline gap-x-2">
          {price ? (
            <span className="font-mono text-h3 text-ink-strong tabular-nums">{price}</span>
          ) : (
            <span className="font-ui text-sm text-ink-muted">Price unavailable</span>
          )}
          {mrp ? <s className="font-mono text-sm text-ink-muted tabular-nums">{mrp}</s> : null}
        </p>

        {onAdd ? (
          <div className="mt-auto pt-2">
            <button
              type="button"
              disabled={disabled || loading}
              aria-busy={loading || undefined}
              aria-label={`Add ${name} to bag`}
              onClick={() => onAdd(product)}
              className={coarse ? ADD_QUIET : ADD_REVEAL}
            >
              {loading ? "Adding…" : "Add to bag"}
            </button>
          </div>
        ) : null}
      </div>
    </article>
  );
}

/**
 * Loading twin of ProductCard — identical layout (§3: skeleton matches final
 * layout exactly). The collection renders these while fetching.
 */
export function ProductCardSkeleton() {
  return (
    <div aria-hidden="true" className="flex flex-col overflow-hidden rounded-md bg-surface shadow-elev-1">
      <div className="aspect-[4/5] animate-pulse bg-sunken" />
      <div className="flex flex-1 flex-col gap-2 p-3">
        <div className="h-3 w-2/5 animate-pulse rounded-sm bg-sunken" />
        <div className="min-h-12">
          <div className="h-4 w-full animate-pulse rounded-sm bg-sunken" />
          <div className="mt-1 h-4 w-3/4 animate-pulse rounded-sm bg-sunken" />
        </div>
        <div className="h-5 w-1/2 animate-pulse rounded-sm bg-sunken" />
        <div className="mt-auto pt-2">
          <div className="h-11 w-full animate-pulse rounded-md bg-sunken" />
        </div>
      </div>
    </div>
  );
}
