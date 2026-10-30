import { useMemo } from "react";
import { useStorefront } from "../context/StorefrontContext";
import { href } from "../hooks/useHashRoute";
import { img, type SectionItem, type StoreSection } from "../services/api";
import { EmptyState, Price, ProductCard, Section, Spinner } from "../components/ui";
import { fxStyle } from "../utils/imageFx";
import { CategoryTiles, normalizeTileStyle } from "../components/category-tiles";
import {
  AllProductsGrid,
  DealsRail,
  RecentlyViewedRail,
  RecommendedRail,
} from "../components/marketplace";

/**
 * Home page — Shopify/Nike/Apple-inspired design:
 * - Full-bleed hero tile with giant headline + single pill CTA
 * - Shop by Category rail (icon cards in horizontal scroll)
 * - Deals of the Day
 * - 4 product cards per row (PDP-style cards)
 * - Left category sidebar on browse pages
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
  const hasContent = sections.length > 0;

  return (
    <div className="page home-page">
      {/* Full-width hero + category rail (replaces BannerCarousel for a cleaner look) */}
      {banners.length > 0 ? (
        <HeroTile sections={banners} />
      ) : (
        <WelcomeHero
          storeName={data.store.name}
          city={data.store.city}
          description={data.store.description}
        />
      )}

      {/* Shop by Category — horizontal icon rail */}
      <CategoryRail categories={data.sections.flatMap((s) => s.items).filter((i) => i.item_type === "CATEGORY" || i.category_slug)} />

      {/* Designed sections (admin-configured) */}
      {rest.map((s) => <SectionRenderer key={s.id} section={s} />)}

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

      {hasContent && (
        <>
          <DealsRail />
          <RecommendedRail />
          <RecentlyViewedRail />
          <AllProductsGrid />
        </>
      )}
    </div>
  );
}

function HeroTile({ sections }: { sections: StoreSection[] }) {
  const section = sections[0];
  const cfg = section?.config ?? {};
  const effects = (cfg.effects as Record<string, unknown>) ?? {};
  const heroImg = img(section?.image) ?? img((cfg.hero_image as string) ?? null);
  const cta = (cfg.cta_label as string) ?? "Shop now";
  const ctaLink = (cfg.cta_link as string) ?? "browse";
  const align = (cfg.align as string) === "right" ? "right" : "left";

  return (
    <section className="hero-tile" style={effects.hero_animation === "fade" ? { animation: "rise 0.6s ease" } : undefined}>
      {heroImg ? (
        <img
          className="hero-img"
          style={fxStyle(section)}
          src={heroImg}
          alt=""
          decoding="async"
          width={1600}
          height={800}
        />
      ) : null}
      <div className="hero-content" style={align === "right" ? { marginLeft: "auto", textAlign: "right" } : undefined}>
        {section?.subtitle ? <p className="hero-eyebrow">{section.subtitle}</p> : null}
        <h1 className="hero-headline">{section?.title || "Fresh groceries, fast"}</h1>
        <div className="hero-actions">
          <a
            className="btn btn-primary"
            href={ctaLink.startsWith("/") || ctaLink.startsWith("#") ? ctaLink : href(ctaLink)}
          >
            {cta}
          </a>
        </div>
      </div>
    </section>
  );
}

function WelcomeHero({ storeName, description }: { storeName: string; city: string; description: string }) {
  return (
    <section className="hero-tile hero-tile-dark">
      <div className="hero-content">
        <p className="hero-eyebrow">Welcome to {storeName}</p>
        <h1 className="hero-headline">{storeName}</h1>
        <p className="hero-lead">{description || "Essentials, delivered quickly."}</p>
        <div className="hero-actions">
          <a className="btn btn-primary" href={href("browse")}>
            Shop now
          </a>
        </div>
      </div>
    </section>
  );
}

function CategoryRail({ categories }: { categories: SectionItem[] }) {
  const items = categories.filter((i) => i.item_type === "CATEGORY" || i.category_slug);
  if (items.length === 0) return null;

  // Build tile items from section items
  const tiles = items.map((i) => ({
    key: i.id,
    slug: i.category_slug,
    name: i.category_name || i.caption || "Category",
    image: img(i.image),
  }));

  return (
    <section className="category-rail">
      <div className="rail-head">
        <h2 className="rail-title">Shop by category</h2>
        <a className="link" href={href("categories")}>
          See all →
        </a>
      </div>
      <div className="rail-scroll">
        {tiles.map((t) => (
          <a key={t.key} className="cat-icon-card" href={href(`browse?category=${t.slug}`)}>
            <div className="cat-icon-media">
              {t.image ? (
                <img src={t.image} alt="" loading="lazy" decoding="async" width={128} height={128} />
              ) : (
                <span className="cat-icon-monogram">{t.name.slice(0, 1).toUpperCase()}</span>
              )}
            </div>
            <span className="cat-icon-name">{t.name}</span>
          </a>
        ))}
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
  const size = section.config?.size ?? "md";

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
            gridTemplateColumns: `repeat(auto-fill, minmax(${size === "lg" ? 260 : size === "sm" ? 150 : 200}px, 1fr))`,
          }}
        >
          {products.map((p) => (
            <ProductCard
              key={p.id}
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
            <img className="gallery-img" src={img(i.image)!} alt={i.caption} loading="lazy" decoding="async" />
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
