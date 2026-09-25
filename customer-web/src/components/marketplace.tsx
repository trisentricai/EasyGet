import { useEffect, useMemo, useState } from "react";
import {
  asArray,
  listCategories,
  listProductsPaged,
  type Product,
} from "../services/api";
import { href } from "../hooks/useHashRoute";
import { ProductCard, Section } from "./ui";
import {
  getRecentViews,
  toProductCard,
  topCategory,
} from "../utils/history";

/** Seconds left until local midnight (deal countdown). */
function useMidnightCountdown(): string {
  const [now, setNow] = useState(() => Date.now());
  useEffect(() => {
    const t = window.setInterval(() => setNow(Date.now()), 1000);
    return () => window.clearInterval(t);
  }, []);
  const end = new Date();
  end.setHours(24, 0, 0, 0);
  const s = Math.max(0, Math.floor((end.getTime() - now) / 1000));
  const hh = String(Math.floor(s / 3600)).padStart(2, "0");
  const mm = String(Math.floor((s % 3600) / 60)).padStart(2, "0");
  const ss = String(s % 60).padStart(2, "0");
  return `${hh}:${mm}:${ss}`;
}

function Rail({ children }: { children: React.ReactNode }) {
  return <div className="rail">{children}</div>;
}

/** Top-discount products across the catalog ("Deals of the Day"). */
export function DealsRail() {
  const [deals, setDeals] = useState<Product[] | null>(null);
  const countdown = useMidnightCountdown();

  useEffect(() => {
    let cancelled = false;
    listProductsPaged({ page_size: "60" })
      .then((d) => {
        if (cancelled) return;
        setDeals(
          [...d.results]
            .filter((p) => (p.discount_percent ?? 0) > 0)
            .sort((a, b) => (b.discount_percent ?? 0) - (a.discount_percent ?? 0))
            .slice(0, 12),
        );
      })
      .catch(() => {
        if (!cancelled) setDeals([]);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  if (!deals || deals.length === 0) return null;
  return (
    <Section
      title="Deals of the Day"
      subtitle={`Ends in ${countdown}`}
      action={<a className="link" href={href("browse")}>See all</a>}
    >
      <Rail>
        {deals.map((p) => (
          <div className="rail-item" key={p.id}>
            <ProductCard product={p} />
          </div>
        ))}
      </Rail>
    </Section>
  );
}

/** All categories as tappable cards. */
export function CategoryRail() {
  const [cats, setCats] = useState<{ name: string; slug: string }[]>([]);
  useEffect(() => {
    let cancelled = false;
    listCategories()
      .then((d) => {
        if (!cancelled) setCats(asArray(d));
      })
      .catch(() => undefined);
    return () => {
      cancelled = true;
    };
  }, []);
  if (!cats.length) return null;
  return (
    <Section title="Shop by Category">
      <Rail>
        {cats.map((c) => (
          <a className="cat-chip" key={c.slug} href={href(`browse?category=${c.slug}`)}>
            {c.name}
          </a>
        ))}
      </Rail>
    </Section>
  );
}

/** Products the shopper recently opened on this device. */
export function RecentlyViewedRail() {
  const items = useMemo(() => getRecentViews(), []);
  if (!items.length) return null;
  return (
    <Section title="Recently Viewed" subtitle="Pick up where you left off">
      <Rail>
        {items.map((v) => (
          <div className="rail-item" key={v.slug}>
            <ProductCard product={toProductCard(v)} />
          </div>
        ))}
      </Rail>
    </Section>
  );
}

/** Products from the shopper's most-viewed category. */
export function RecommendedRail() {
  const top = useMemo(() => topCategory(), []);
  const [items, setItems] = useState<Product[] | null>(null);

  useEffect(() => {
    if (!top) return;
    let cancelled = false;
    listProductsPaged({ category: top.slug, page_size: "12" })
      .then((d) => {
        if (!cancelled) setItems(d.results);
      })
      .catch(() => {
        if (!cancelled) setItems([]);
      });
    return () => {
      cancelled = true;
    };
  }, [top?.slug]); // eslint-disable-line react-hooks/exhaustive-deps

  if (!top || !items || items.length === 0) return null;
  return (
    <Section
      title={`More in ${top.name}`}
      subtitle="Based on what you've been browsing"
      action={<a className="link" href={href(`browse?category=${top.slug}`)}>See all</a>}
    >
      <Rail>
        {items.map((p) => (
          <div className="rail-item" key={p.id}>
            <ProductCard product={p} />
          </div>
        ))}
      </Rail>
    </Section>
  );
}
