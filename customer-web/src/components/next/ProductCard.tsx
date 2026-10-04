/**
 * NEXT_UI ProductCard — DESIGN.md §4 PLP grid density + §3 component rules.
 *
 * Grid density, locked: 4:5 imagery, 3 per row desktop / 2 mobile, 16–20px
 * gaps (the grid itself lives at the call site). Serif appears only on
 * section headings — product names stay Inter, prices/ratings stay Geist
 * Mono. No discount theater: muted MRP strike, never a badge.
 *
 * Gating: render only when `isNextUi()` is true (DESIGN.md §8).
 * Every value below resolves to a DESIGN.md §1 token — no raw hex, no px.
 */

export interface NextProductCardData {
  id: number | string;
  name: string;
  brand?: string | null;
  /** base_price — string ("97.00") or number; null renders a fallback line */
  price: string | number | null;
  mrp?: string | number | null;
  ratingAvg?: number | null;
  ratingCount?: number | null;
  /** absolute image URL (resolve with `img()` at the call site); null = monogram placeholder */
  image?: string | null;
  slug?: string;
}

export interface NextProductCardProps {
  product: NextProductCardData;
  /** omitted => no Add button (browse-only contexts) */
  onAdd?: (product: NextProductCardData) => void;
  /** omitted => name/image are not interactive */
  onOpen?: (product: NextProductCardData) => void;
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

function monogram(name: string): string {
  const words = name.trim().split(/\s+/).filter(Boolean);
  if (words.length === 0) return "·";
  if (words.length === 1) return words[0].slice(0, 2).toUpperCase();
  return (words[0][0] + words[1][0]).toUpperCase();
}

export function ProductCard({ product, onAdd, onOpen, disabled = false, loading = false }: NextProductCardProps) {
  const { name, brand, ratingAvg, ratingCount } = product;
  const price = formatINR(product.price);
  const mrp = formatINR(product.mrp);
  const showRating = (ratingCount ?? 0) > 0 && ratingAvg !== null && ratingAvg !== undefined;
  const interactive = typeof onOpen === "function" && !disabled;

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
      className="flex flex-col overflow-hidden rounded-md bg-surface shadow-elev-1 transition-shadow duration-micro hover:shadow-elev-2"
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
          <div aria-hidden="true" className="grid h-full w-full place-items-center">
            <span className="font-display text-display text-ink-faint">{monogram(name)}</span>
          </div>
        )}
        {interactive && (
          <button
            type="button"
            onClick={() => onOpen?.(product)}
            aria-label={`View ${name}`}
            className="absolute inset-0 h-full w-full cursor-pointer bg-transparent"
          />
        )}
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
              className="action-block w-full hover:opacity-90 active:opacity-80 disabled:cursor-not-allowed disabled:opacity-50"
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
