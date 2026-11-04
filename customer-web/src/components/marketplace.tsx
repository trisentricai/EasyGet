import { useEffect, useMemo, useRef, useState } from "react";
import { useInfiniteQuery, useQuery } from "@tanstack/react-query";
import {
  asArray,
  errText,
  resolveImageUrl,
  listCategories,
  listProductsPaged,
  type StoreSection,
} from "../services/api";
import { href } from "../hooks/useHashRoute";
import { fxClass, fxStyle } from "../utils/imageFx";
import { Icon } from "./icons";
import { SafeImage } from "./safe-image";
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
  const [paused, setPaused] = useState(false);
  const [dragging, setDragging] = useState(false);
  const [dragX, setDragX] = useState(0);
  const drag = useRef<{
    pointerId: number;
    startX: number;
    startY: number;
    dx: number;
    horizontal: boolean;
    moved: boolean;
  } | null>(null);
  const suppressClickUntil = useRef(0);

  // Full dwell after every slide (including manual navigation). Hover,
  // keyboard focus, or a touch drag pauses the rotation.
  useEffect(() => {
    if (count < 2 || paused || dragging) return;
    const timer = window.setTimeout(() => setIdx((i) => (i + 1) % count), 4800);
    return () => window.clearTimeout(timer);
  }, [count, paused, idx, dragging]);

  if (count === 0) return null;

  const go = (next: number) => {
    setDragX(0);
    setIdx(((next % count) + count) % count);
  };

  // Touch/pen swipe. Mouse is intentionally excluded so desktop arrows,
  // hover-pause, and CTA clicks keep their existing behaviour.
  const onPointerDown = (e: React.PointerEvent<HTMLDivElement>) => {
    if (count < 2 || e.pointerType === "mouse" || !e.isPrimary) return;
    if ((e.target as HTMLElement).closest(".carousel-arrow, .carousel-dots")) return;
    drag.current = {
      pointerId: e.pointerId,
      startX: e.clientX,
      startY: e.clientY,
      dx: 0,
      horizontal: false,
      moved: false,
    };
    setDragging(true);
    try {
      e.currentTarget.setPointerCapture(e.pointerId);
    } catch {
      /* Synthetic/test pointers may not support capture. */
    }
  };

  const onPointerMove = (e: React.PointerEvent<HTMLDivElement>) => {
    const d = drag.current;
    if (!d || d.pointerId !== e.pointerId) return;
    const dx = e.clientX - d.startX;
    const dy = e.clientY - d.startY;

    if (!d.horizontal) {
      if (Math.abs(dx) < 6 && Math.abs(dy) < 6) return;
      // Vertical intent belongs to the page scroller; let it take over.
      if (Math.abs(dy) > Math.abs(dx)) {
        drag.current = null;
        setDragging(false);
        setDragX(0);
        try {
          if (e.currentTarget.hasPointerCapture(e.pointerId)) {
            e.currentTarget.releasePointerCapture(e.pointerId);
          }
        } catch {
          /* Pointer capture is best-effort. */
        }
        return;
      }
      d.horizontal = true;
    }

    if (Math.abs(dx) > 6) d.moved = true;
    d.dx = dx;
    setDragX(dx);
  };

  const finishDrag = (e: React.PointerEvent<HTMLDivElement>, cancelled = false) => {
    const d = drag.current;
    if (!d || d.pointerId !== e.pointerId) return;
    drag.current = null;
    setDragging(false);
    try {
      if (e.currentTarget.hasPointerCapture(e.pointerId)) {
        e.currentTarget.releasePointerCapture(e.pointerId);
      }
    } catch {
      /* Pointer capture is best-effort. */
    }

    if (d.moved) suppressClickUntil.current = Date.now() + 400;
    if (!cancelled && d.horizontal && Math.abs(d.dx) >= 50) {
      go(d.dx < 0 ? idx + 1 : idx - 1);
    } else {
      // Below the threshold: snap back to the current slide.
      setDragX(0);
    }
  };

  return (
    <div
      className="carousel"
      role="region"
      aria-roledescription="carousel"
      aria-label="Featured offers"
      onMouseEnter={() => setPaused(true)}
      onMouseLeave={() => setPaused(false)}
      onFocusCapture={() => setPaused(true)}
      onBlurCapture={(e) => {
        if (!e.currentTarget.contains(e.relatedTarget as Node | null)) setPaused(false);
      }}
      onKeyDown={(e) => {
        if (e.key === "ArrowLeft") {
          e.preventDefault();
          go(idx - 1);
        } else if (e.key === "ArrowRight") {
          e.preventDefault();
          go(idx + 1);
        }
      }}
      onPointerDown={onPointerDown}
      onPointerMove={onPointerMove}
      onPointerUp={(e) => finishDrag(e)}
      onPointerCancel={(e) => finishDrag(e, true)}
      onDragStart={(e) => e.preventDefault()}
      onClickCapture={(e) => {
        // A swipe ends with a synthetic click on whatever is under the
        // finger; swallow it so dragging never opens a CTA link.
        if (Date.now() < suppressClickUntil.current) {
          e.preventDefault();
          e.stopPropagation();
          suppressClickUntil.current = 0;
        }
      }}
      style={{ touchAction: "pan-y" }}
    >
      <div
        className="carousel-track"
        style={{
          transform: `translateX(${dragX}px)`,
          transition: dragging ? "none" : "transform 220ms cubic-bezier(0.2, 0.8, 0.2, 1)",
          touchAction: "pan-y",
          userSelect: dragging ? "none" : undefined,
        }}
      >
        {slides.map((s, i) => (
          <div
            key={s.id}
            className={`carousel-slide ${i === idx ? "on" : ""}`}
            aria-hidden={i !== idx}
            aria-roledescription="slide"
            aria-label={`${i + 1} of ${count}`}
          >
            <HeroSlide section={s} />
          </div>
        ))}
      </div>
      {count > 1 && (
        <>
          <button
            className="carousel-arrow prev"
            aria-label="Previous banner"
            onClick={() => go(idx - 1)}
          >
            <Icon name="chevronLeft" size={18} />
          </button>
          <button
            className="carousel-arrow next"
            aria-label="Next banner"
            onClick={() => go(idx + 1)}
          >
            <Icon name="chevronRight" size={18} />
          </button>
          <div className="carousel-dots" role="tablist" aria-label="Choose banner">
            {slides.map((s, i) => (
              <button
                key={s.id}
                className={`carousel-dot ${i === idx ? "on" : ""}`}
                role="tab"
                aria-selected={i === idx}
                aria-label={`Go to slide ${i + 1}`}
                onClick={() => go(i)}
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
  const image = resolveImageUrl(section.image) ?? resolveImageUrl((cfg.hero_image as string) ?? null);
  const [imageFailed, setImageFailed] = useState(false);
  useEffect(() => setImageFailed(false), [image]);
  const showImage = Boolean(image) && !imageFailed;
  const cta = (cfg.cta_label as string) ?? "Shop now";
  const ctaLink = (cfg.cta_link as string) ?? "browse";
  const link = ctaLink.startsWith("/") || ctaLink.startsWith("#") ? ctaLink : href(ctaLink);
  // Admin-designed variants (section config hero_layout/hero_overlay).
  // Pure class hooks — all visuals live in showcase.css.
  const layout = (cfg.hero_layout as string) === "split" ? "split" : (cfg.hero_layout as string) === "minimal" ? "minimal" : "feature";
  const overlay = (cfg.hero_overlay as string) === "light" ? "light" : (cfg.hero_overlay as string) === "none" ? "none" : "dark";
  return (
    <div className={`hero hero-slide hero-${layout} hero-overlay-${overlay} ${showImage ? "" : "hero-gradient"}`.trim()}>
      {showImage ? (
        <SafeImage
          className={`hero-img ${fxClass(section)}`}
          style={fxStyle(section)}
          src={image}
          alt=""
          decoding="async"
          width={1200}
          height={675}
          draggable={false}
          onError={() => setImageFailed(true)}
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
      action={<a className="link link-arrow" href={href("browse")}>See all <Icon name="arrowRight" size={14} /></a>}
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
    <Section
      title="Shop by Category"
      action={
        <a className="link link-arrow" href={href("categories")}>
          See all <Icon name="arrowRight" size={14} />
        </a>
      }
    >
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
      action={
        <a className="link link-arrow" href={href(`browse?category=${top.slug}`)}>
          See all <Icon name="arrowRight" size={14} />
        </a>
      }
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
      action={<a className="link link-arrow" href={href("browse")}>See all <Icon name="arrowRight" size={14} /></a>}
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
