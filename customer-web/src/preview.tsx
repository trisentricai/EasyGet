/**
 * NEXT_UI preview — renders the hybrid ProductCard against LIVE catalog data.
 * Flag-gated (DESIGN.md §8): without `?next_ui=1` this page only shows how
 * to enable the preview. Visual QA surface for the vertical slice.
 */
import { StrictMode, useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import { asArray, img, listProductsPaged } from "./services/api";
import { isNextUi } from "./flags";
import {
  ProductCard,
  ProductCardSkeleton,
  type NextProductCardData,
} from "./components/next/ProductCard";
import "./theme/index.css";

type Status = "loading" | "ready" | "empty" | "error";
type LooseRow = Record<string, unknown>;

const str = (v: unknown): string | null => (typeof v === "string" && v !== "" ? v : null);
const num = (v: unknown): number | null => (typeof v === "number" && Number.isFinite(v) ? v : null);

function pickRows(payload: unknown): LooseRow[] {
  const list: unknown[] = Array.isArray(payload)
    ? payload
    : typeof payload === "object" && payload !== null && Array.isArray((payload as { results?: unknown }).results)
      ? ((payload as { results: unknown }).results as unknown[])
      : [];
  return list.filter((r): r is LooseRow => typeof r === "object" && r !== null).slice(0, 6);
}

function toCategory(v: unknown): { slug?: string; name?: string } | null {
  if (typeof v === "string" && v !== "") return { name: v };
  if (typeof v === "object" && v !== null) {
    const o = v as Record<string, unknown>;
    const slug = typeof o.slug === "string" ? o.slug : undefined;
    const name = typeof o.name === "string" ? o.name : undefined;
    if (slug || name) return { slug, name };
  }
  return null;
}

function toCard(r: LooseRow, index: number): NextProductCardData {
  return {
    id: typeof r.id === "number" || typeof r.id === "string" ? r.id : `row-${index}`,
    name: str(r.name) ?? "Unnamed product",
    brand: str(r.brand),
    price: typeof r.base_price === "string" || typeof r.base_price === "number" ? r.base_price : null,
    mrp: typeof r.mrp === "string" || typeof r.mrp === "number" ? r.mrp : null,
    ratingAvg: num(r.rating_avg),
    ratingCount: num(r.rating_count) ?? 0,
    image: img(str(r.primary_image)),
    slug: str(r.slug) ?? undefined,
    category: toCategory(r.category),
  };
}

function PreviewApp() {
  const [enabled] = useState(isNextUi);
  const [items, setItems] = useState<NextProductCardData[]>([]);
  const [status, setStatus] = useState<Status>("loading");
  const [bag, setBag] = useState<Array<number | string>>([]);
  const [wished, setWished] = useState<Array<number | string>>([]);
  const toggleWish = (id: number | string) =>
    setWished((w) => (w.includes(id) ? w.filter((x) => x !== id) : [...w, id]));
  const [tick, setTick] = useState(0);

  useEffect(() => {
    if (!enabled) return;
    let dead = false;
    setStatus("loading");
    listProductsPaged({ page_size: "12" })
      .then((d: unknown) => {
        if (dead) return;
        const rows = pickRows(d);
        if (rows.length === 0) {
          setItems([]);
          setStatus("empty");
          return;
        }
        setItems(rows.map(toCard));
        setStatus("ready");
      })
      .catch(() => {
        if (!dead) setStatus("error");
      });
    return () => {
      dead = true;
    };
  }, [enabled, tick]);

  return (
    <div className="min-h-screen bg-canvas font-ui text-ink-strong">
      <div className="mx-auto max-w-5xl px-4 py-10">
        {!enabled ? (
          <div className="rounded-md bg-surface p-6 shadow-elev-1">
            <h1 className="font-display text-h2 text-ink-strong">NEXT_UI preview is off</h1>
            <p className="mt-2 font-ui text-body text-ink-muted">
              Append <code className="font-mono text-sm">?next_ui=1</code> to this URL to enable the
              hybrid preview. The choice persists on this device.
            </p>
            <p className="mt-4">
              <a className="action-block" href={`${window.location.pathname}?next_ui=1`}>
                Enable preview
              </a>
            </p>
          </div>
        ) : (
          <>
            <header className="mb-2 flex flex-wrap items-end justify-between gap-2">
              <div>
                <p className="font-ui text-sm text-ink-muted">Vertical slice · live catalog data</p>
                <h1 className="font-display text-h1 text-ink-strong">Fresh picks</h1>
              </div>
              <p aria-live="polite" className="font-mono text-sm text-ink-muted tabular-nums">
                Bag · {bag.length} · Saved · {wished.length}
              </p>
            </header>
            <p className="mb-6 font-ui text-body text-ink-muted">
              From nearby stores, restocked daily. Prices include all taxes.
            </p>

            {status === "loading" ? (
              <div className="grid grid-cols-2 gap-4 md:grid-cols-3" aria-label="Loading products">
                {Array.from({ length: 6 }, (_, i) => (
                  <ProductCardSkeleton key={i} />
                ))}
              </div>
            ) : null}

            {status === "error" ? (
              <div className="rounded-md bg-surface p-6 text-center shadow-elev-1">
                <h2 className="font-display text-h3 text-ink-strong">The shelf could not be loaded</h2>
                <p className="mt-2 font-ui text-body text-ink-muted">
                  Check your connection and try again.
                </p>
                <p className="mt-4">
                  <button type="button" className="action-block" onClick={() => setTick((t) => t + 1)}>
                    Retry
                  </button>
                </p>
              </div>
            ) : null}

            {status === "empty" ? (
              <div className="rounded-md bg-surface p-6 text-center shadow-elev-1">
                <h2 className="font-display text-h3 text-ink-strong">Nothing on this shelf yet</h2>
                <p className="mt-2 font-ui text-body text-ink-muted">
                  New picks land every morning.
                </p>
                <p className="mt-4">
                  <a className="action-block" href="/#/browse">
                    Browse the catalog
                  </a>
                </p>
              </div>
            ) : null}

            {status === "ready" ? (
              <div className="grid grid-cols-2 gap-4 md:grid-cols-3">
                {items.map((p) => (
                  <ProductCard
                    key={p.id}
                    product={p}
                    onAdd={(added) => setBag((b) => (b.includes(added.id) ? b : [...b, added.id]))}
                    wishlisted={wished.includes(p.id)}
                    onToggleWishlist={(toggled) => toggleWish(toggled.id)}
                  />
                ))}
              </div>
            ) : null}

            {status === "ready" && items.length > 0 ? (
              <section aria-label="State reference" className="mt-12">
                <h2 className="font-display text-h3 text-ink-strong">States</h2>
                <p className="mb-4 font-ui text-sm text-ink-muted">
                  Rest, hover, focus, active and loading live on the cards above — this one is disabled.
                </p>
                <div className="grid max-w-xs grid-cols-1 gap-4">
                  <ProductCard product={items[0]} onAdd={() => undefined} disabled />
                </div>
              </section>
            ) : null}

            <p className="mt-10 font-ui text-xs text-ink-faint">
              asArray sanity: {asArray(items).length} cards ·{" "}
              <a className="underline" href={`${window.location.pathname}?next_ui=0`}>
                disable preview
              </a>
            </p>
          </>
        )}
      </div>
    </div>
  );
}

createRoot(document.getElementById("preview-root")!).render(
  <StrictMode>
    <PreviewApp />
  </StrictMode>,
);
