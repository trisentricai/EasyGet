import { useMemo } from "react";
import { useStorefront } from "../context/StorefrontContext";
import { href } from "../hooks/useHashRoute";
import { img, type SectionItem, type StoreSection } from "../services/api";
import { EmptyState, Price, ProductCard, Section, Spinner } from "../components/ui";
import { CategoryTiles, normalizeTileStyle } from "../components/category-tiles";
import { CategorySidebar } from "./CategorySidebar";
import { fxClass, fxStyle } from "../utils/imageFx";
import {
  AllProductsGrid,
  BannerCarousel,
  DealsRail,
  RecentlyViewedRail,
  RecommendedRail,
} from "../components/marketplace";

/**
 * Home page — clean, professional e-commerce layout:
 * - Full-bleed hero tile with giant headline + single pill CTA
 * - Single "Shop by Category" section with proper category cards (image + colorful wash fallback)
 * - Deals of the Day
 * - 4 product cards per row (PDP-style cards)
 * - Recently Viewed
 */
export function HomePage() {
  const { data, loading, error } = useStorefront();

  if (loading) return <Spinner />;
  if (error || !data) {
    return (
      <div className="page">
        <EmptyState
          icon="store"
          title="Storefront not available"
          text={error ?? "This store does not exist or is inactive."}
        />
      </div>
    );
  }

  const sections = [...data.sections]
    .filter((s) => s.is_active)
    .sort((a, b) => a.position - b.position);
  const banners = sections.filter(
    (s) => s.section_type === "HERO" || s.section_type === "BANNER",
  );
  const rest = sections.filter(
    (s) => s.section_type !== "HERO" && s.section_type !== "BANNER",
  );
  // Fallback category rail when the designer has no CATEGORY_GRID section,
  // so categories always render (admin sections take precedence when present).
  const hasCategorySection = rest.some((s) => s.section_type === "CATEGORY_GRID");
  const categoryItems = hasCategorySection
    ? []
    : sections.flatMap((s) => s.items.filter((i) => i.item_type === "CATEGORY" || i.category_slug));
  const hasContent = sections.length > 0;

  return (
    <div className="page home-page">
      {/* Left category sidebar + home content — sidebar now on the home screen too */}
      <div className="browse-layout">
        <CategorySidebar
          activeCategory=""
          activeBrand=""
          activeDiscount=""
          onCategoryChange={(slug) => { if (slug) window.location.hash = `#/browse?category=${encodeURIComponent(slug)}`; }}
          onBrandChange={() => undefined}
          onDiscountChange={() => undefined}
        />
        <div className="browse-main">
          {/* Hero / banner carousel (admin-configured HERO/BANNER sections) */}
          {banners.length > 0 ? (
            <BannerCarousel sections={banners} />
          ) : (
            <WelcomeHero
              storeName={data.store.name}
              city={data.store.city}
              description={data.store.description}
            />
          )}

          {/* Fallback category rail (only when no admin CATEGORY_GRID section). */}
          {categoryItems.length > 0 && (
            <>
              {(() => {
                const categorySection: StoreSection = {
                  id: 0,
                  section_type: "CATEGORY_GRID",
                  title: "Shop by category",
                  subtitle: "Everything your home needs, delivered fast",
                  image: null,
                  config: { category_style: "cards" },
                  position: 0,
                  is_active: true,
                  items: categoryItems,
                } as unknown as StoreSection;
                return <CategoryGridSection section={categorySection} />;
              })()}
            </>
          )}

          {/* Designed sections (admin-configured) — categories render via
              CATEGORY_GRID sections with their saved category_style. */}
          {rest.map((s) => <SectionRenderer key={s.id} section={s} />)}

          {/* Curated rails (always available as baseline content). */}
          {hasContent && (
            <>
              <DealsRail />
              <RecommendedRail />
              <RecentlyViewedRail />
              <AllProductsGrid />
            </>
          )}

          {/* Fallback welcome content when no sections configured */}
          {!hasContent && (
            <>
              <WelcomeHero
                storeName={data.store.name}
                city={data.store.city}
                description={data.store.description}
              />
              <DealsRail />
              <RecommendedRail />
              <RecentlyViewedRail />
              <AllProductsGrid />
            </>
          )}

          {/* When sections exist, only admin-configured sections render
              (see rest.map above) — no hardcoded rails. */}
        </div>
      </div>
    </div>
  );
}

function WelcomeHero({ storeName, description }: { storeName: string; city: string; description: string }) {
  return (
    <section className="hero-tile hero-tile-dark">
      <div className="hero-content">
        <p className="hero-eyebrow">Welcome to {storeName}</p>
        <h1 className="hero-headline">{storeName}</h1>
        <p className="hero-lead">{description || "Everyday essentials — groceries, personal care, household items and more, delivered to your doorstep in Bengaluru. Free delivery on orders above ₹499, 7-day easy returns, cash on delivery available."}</p>
        <div className="hero-actions">
          <a className="btn btn-primary" href={href("browse")}>
            Shop now
          </a>
        </div>
      </div>
    </section>
  );
}

function SectionRenderer({ section }: { section: StoreSection }) {
  switch (section.section_type) {
    case "HERO":
    case "BANNER":
      return null; // handled by HeroTile above
    case "CATEGORY_GRID":
      return <CategoryGridSection section={section} />;
    case "PRODUCT_ROW":
      return <ProductRowSection section={section} />;
    case "IMAGE_GALLERY":
      return <GallerySection section={section} />;
    case "RICH_TEXT":
      return <RichTextSection section={section} />;
    default:
      return null;
  }
}

function CategoryGridSection({ section }: { section: StoreSection }) {
  const style = normalizeTileStyle((section.config as Record<string, unknown> | undefined)?.category_style);
  return (
    <Section title={section.title || undefined} subtitle={section.subtitle || undefined}>
      <CategoryTiles items={section.items} style={style} />
    </Section>
  );
}

function ProductRowSection({ section }: { section: StoreSection }) {
  const products = useMemo(
    () =>
      section.items
        .filter((i) => i.item_type === "PRODUCT" && i.product_slug)
        .map((i) => ({
          id: i.product ?? i.id,
          name: i.product_name ?? i.caption,
          slug: i.product_slug!,
          price: i.product_price,
          image: i.image,
          caption: i.caption,
        })),
    [section.items],
  );
  const size = (section.config?.size as "sm" | "md" | "lg") ?? "md";
  const columns = Number(section.config?.columns);
  const effects = Array.isArray(section.config?.effects)
    ? (section.config?.effects as string[])
    : (section.config?.effects && typeof section.config?.effects === "object"
        ? Object.keys(section.config?.effects as Record<string, unknown>).filter(
            (k) => (section.config?.effects as Record<string, unknown>)[k],
          )
        : []);

  return (
    <Section
      title={section.title || undefined}
      subtitle={section.subtitle || undefined}
      action={<a className="link" href={href("browse")}>See all</a>}
    >
      {products.length ? (
        <div
          className="grid grid-products"
          style={{
            gridTemplateColumns:
              Number.isInteger(columns) && columns >= 1 && columns <= 6
                ? `repeat(${columns}, 1fr)`
                : `repeat(auto-fill, minmax(${size === "lg" ? 260 : size === "sm" ? 150 : 200}px, 1fr))`,
          }}
        >
          {products.map((p) => (
            <ProductCard
              key={p.id}
              size={size}
              effects={effects}
              product={{
                id: p.id,
                name: p.name,
                slug: p.slug,
                category: null,
                brand: "",
                mrp: null,
                base_price: p.price,
                discount_percent: 0,
                is_featured: false,
                primary_image: p.image,
                rating_avg: null,
                rating_count: 0,
              }}
            />
          ))}
        </div>
      ) : (
        <p className="muted">No products in this row yet.</p>
      )}
    </Section>
  );
}

function GallerySection({ section }: { section: StoreSection }) {
  const images = section.items.filter((i) => i.image);
  if (!images.length) return null;
  return (
    <Section title={section.title || undefined} subtitle={section.subtitle || undefined}>
      <div className="grid grid-gallery">
        {images.map((i) => (
          <figure key={i.id} style={{ margin: 0 }}>
            <img
              className={`gallery-img ${fxClass(section)}`}
              style={fxStyle(section)}
              src={img(i.image)!}
              alt={i.caption}
              loading="lazy"
              decoding="async"
            />
            {i.caption ? <figcaption className="muted" style={{ fontSize: 12, marginTop: 6 }}>{i.caption}</figcaption> : null}
          </figure>
        ))}
      </div>
    </Section>
  );
}

function RichTextSection({ section }: { section: StoreSection }) {
  const first = section.items[0];
  return (
    <Section>
      <div className="richtext">
        {section.title ? <h2>{section.title}</h2> : null}
        {section.subtitle ? <p className="muted">{section.subtitle}</p> : null}
        <p>{first?.caption || ""}</p>
      </div>
    </Section>
  );
}

export type { SectionItem };
export { Price };
