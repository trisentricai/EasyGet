import { useEffect, useMemo, useRef, useState } from "react";
import { useInfiniteQuery, useQuery } from "@tanstack/react-query";
import {
  asArray,
  errText,
  img,
  listCategories,
  listProductsPaged,
  type StoreSection,
} from "../services/api";
import { href } from "../hooks/useHashRoute";
import { fxClass, fxStyle } from "../utils/imageFx";
import { Icon } from "./icons";
import { ProductCard, Section, CardSkeletonGrid, EmptyState } from "./ui";
import {
  getRecentViews,
  toProductCard,
  topCategory,
} from "../utils/history";

/** Auto-rotating hero carousel built from the store's HERO/BANNER sections. */
export function BannerCarousel({ sections }: { sections: StoreSection[] }) {
  const slides = useMemo(
    () => sections.filter((s) => s.is_active && (s.image || s.title)),
    [sections],
  );
  const count = slides.length;
  const [idx, setIdx] = useState(0);

  useEffect(() => {
    if (count < 2) return;
    const t = window.setInterval(() => setIdx((i) => (i + 1) % count), 4500);
    return () => window.clearInterval(t);
  }, [count]);

  if (count === 0) return null;

  return (
    <div className="carousel">
      <div className="carousel-track">
        {slides.map((s, i) => (
          <div key={s.id} className={`carousel-slide ${i === idx ? "on" : ""}`}>
            <HeroSlide section={s} />
          </div>
        ))}
      </div>
      {count > 1 && (
        <>
          <button
            className="carousel-arrow prev"
            aria-label="Previous banner"
            onClick={() => setIdx((i) => (i - 1 + count) % count)}
          >
            <Icon name="chevronLeft" size={18} />
          </button>
          <button
            className="carousel-arrow next"
            aria-label="Next banner"
            onClick={() => setIdx((i) => (i + 1) % count)}
          >
            <Icon name="chevronRight" size={18} />
          </button>
          <div className="carousel-dots">
            {slides.map((s, i) => (
              <button
                key={s.id}
                className={`carousel-dot ${i === idx ? "on" : ""}`}
                aria-label={`Go to slide ${i + 1}`}
                onClick={() => setIdx(i)}
              />
            ))}
          </div>
        </>
      )}
    </div>
  );
}

function HeroSlide({ section }: { section: StoreSection }) {
  const cfg = section.config ?? {};
  const image = img(section.image) ?? img((cfg.hero_image as string) ?? null);
  const cta = (cfg.cta_label as string) ?? "Shop now";
  const ctaLink = (cfg.cta_link as string) ?? "browse";
  const link = ctaLink.startsWith("/") || ctaLink.startsWith("#") ? ctaLink : href(ctaLink);
  // Admin-designed variants (section config hero_layout/hero_overlay).
  // Pure class hooks — all visuals live in showcase.css.
  const layout = (cfg.hero_layout as string) === "split" ? "split" : (cfg.hero_layout as string) === "minimal" ? "minimal" : "feature";
  const overlay = (cfg.hero_overlay as string) === "light" ? "light" : (cfg.hero_overlay as string) === "none" ? "none" : "dark";
  return (
    <div className={`hero hero-slide hero-${layout} hero-overlay-${overlay}`}>
      {image ? (
        <img
          className={`hero-img ${fxClass(section)}`}
          style={fxStyle(section)}
          src={image}
          alt=""
          decoding="async"
          width={1200}
          height={675}
        />
      ) : null}
      <div className="hero-content">
        {section.subtitle ? <p>{section.subtitle}</p> : null}
        <h1>{section.title}</h1>
        <div className="hero-actions">
          <a className="btn btn-secondary" href={link}>{cta}</a>
        </div>
      </div>
    </div>
  );
}

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
  const countdown = useMidnightCountdown();
  const { data } = useQuery({
    queryKey: ["products", "deals"],
    queryFn: () => listProductsPaged({ page_size: "60" }),
    staleTime: 2 * 60_000,
  });
  const deals = useMemo(
    () =>
      data
        ? [...data.results]
            .filter((p) => (p.discount_percent ?? 0) > 0)
            .sort((a, b) => (b.discount_percent ?? 0) - (a.discount_percent ?? 0))
            .slice(0, 12)
        : null,
    [data],
  );

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

/** All categories as tappable cards. Shares the ["categories"] cache with
 *  the header strip and browse filters — one fetch per session visit. */
export function CategoryRail() {
  const { data } = useQuery({
    queryKey: ["categories"],
    queryFn: listCategories,
    staleTime: 5 * 60_000,
  });
  const cats = asArray(data);
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
  const { data } = useQuery({
    queryKey: ["products", "recommended", top?.slug ?? null],
    queryFn: () => listProductsPaged({ category: top!.slug, page_size: "12" }),
    enabled: !!top,
    staleTime: 2 * 60_000,
  });
  const items = data?.results ?? null;

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

/**
 * Full catalog grid for the home page tail: every visible product,
 * paginated with infinite scroll until the end. Renders AFTER the
 * curated rails (Shop by category / Deals / Recommended / Recently
 * viewed) so shoppers can keep scrolling through everything.
 */
export function AllProductsGrid() {
  const {
    data,
    error,
    hasNextPage,
    isFetchingNextPage,
    fetchNextPage,
    isLoading,
  } = useInfiniteQuery({
    queryKey: ["products", "home-all"],
    queryFn: ({ pageParam }) =>
      listProductsPaged({ page: String(pageParam), page_size: "20" }),
    initialPageParam: 1,
    getNextPageParam: (lastPage, allPages) =>
      lastPage.next ? allPages.length + 1 : undefined,
    staleTime: 2 * 60_000,
  });

  const products = data ? data.pages.flatMap((p) => p.results) : null;
  const total = data?.pages[0]?.count ?? null;
  const errorMsg = error ? errText(error) : null;

  const sentinelRef = useRef<HTMLDivElement | null>(null);
  const [nearBottom, setNearBottom] = useState(false);

  useEffect(() => {
    const el = sentinelRef.current;
    if (!el || !hasNextPage) return;
    const io = new IntersectionObserver(([entry]) => setNearBottom(entry.isIntersecting), {
      rootMargin: "0px 0px 200px 0px",
    });
    io.observe(el);
    return () => io.disconnect();
  }, [hasNextPage, products?.length]);

  useEffect(() => {
    if (!data || !nearBottom || !hasNextPage || isFetchingNextPage) return;
    void fetchNextPage();
  }, [data, nearBottom, hasNextPage, isFetchingNextPage, fetchNextPage]);

  if (isLoading) {
    return (
      <Section
        title="Explore all products"
        subtitle="The full catalog — keep scrolling"
      >
        <CardSkeletonGrid />
      </Section>
    );
  }

  if (errorMsg) {
    return (
      <Section title="Explore all products">
        <EmptyState icon="warning" title="Couldn't load products" text={errorMsg} />
      </Section>
    );
  }

  if (!products || products.length === 0) return null;

  return (
    <Section
      title="Explore all products"
      subtitle={
        total !== null
          ? `${total} products — scroll for more`
          : "The full catalog — keep scrolling"
      }
      action={<a className="link" href={href("browse")}>See all</a>}
    >
      <div className="grid grid-products">
        {products.map((p) => (
          <ProductCard key={p.id} product={p} />
        ))}
      </div>
      {isFetchingNextPage ? (
        <div style={{ marginTop: 18 }}>
          <CardSkeletonGrid count={4} />
        </div>
      ) : null}
      {hasNextPage ? (
        <>
          <div ref={sentinelRef} style={{ height: 1 }} aria-hidden="true" />
          {!nearBottom ? (
            <div style={{ display: "flex", justifyContent: "center", marginTop: 18 }}>
              <button
                className="btn"
                onClick={() => void fetchNextPage()}
                disabled={isFetchingNextPage}
              >
                {isFetchingNextPage
                  ? "Loading…"
                  : total !== null
                    ? `Load more (${total - products.length} left)`
                    : "Load more"}
              </button>
            </div>
          ) : null}
        </>
      ) : null}
    </Section>
  );
}
