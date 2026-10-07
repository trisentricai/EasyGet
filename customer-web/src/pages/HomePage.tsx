import { useMemo } from "react";
import { useStorefront } from "../context/StorefrontContext";
import { href } from "../hooks/useHashRoute";
import { img, type SectionItem, type StoreSection } from "../services/api";
import { EmptyState, Price, ProductCard, Section, Spinner } from "../components/ui";
import { CategoryTiles, normalizeTileStyle } from "../components/category-tiles";
import { fxClass, fxStyle } from "../utils/imageFx";
import {
  BannerCarousel,
  DealsRail,
  RecentlyViewedRail,
  RecommendedRail,
} from "../components/marketplace";

/**
 * Home page = the store's designed storefront, marketplace layout:
 * rotating banner carousel (HERO/BANNER sections), then the admin's
 * designed sections, then the discovery rails.
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

  // No designed sections yet? Shoppers still get a real storefront: the
  // welcome hero plus the live discovery rails (deals / categories /
  // recommendations). Setup guidance belongs in the admin dashboard —
  // never in front of customers.
  return (
    <div className="page">
      <BannerCarousel sections={banners} />
      {rest.map((s) => <SectionRenderer key={s.id} section={s} />)}
      {!hasContent && (
        <WelcomeHero
          storeName={data.store.name}
          city={data.store.city}
          description={data.store.description}
        />
      )}
      <DealsRail />
      <RecommendedRail />
      <RecentlyViewedRail />
    </div>
  );
}

function WelcomeHero({ storeName, description }: { storeName: string; city: string; description: string }) {
  return (
    <div className="hero">
      <div className="hero-content">
        <p className="eyebrow">Welcome to</p>
        <h1>{storeName}</h1>
        <p>{description || "Essentials, delivered quickly."}</p>
        <div className="hero-actions">
          <a className="btn btn-secondary" href={href("browse")}>Browse catalog</a>
          <a className="btn btn-ghost" style={{ color: "#fff", borderColor: "rgb(255 255 255 / 0.5)" }} href={href("account")}>
            Sign in
          </a>
        </div>
      </div>
    </div>
  );
}

function SectionRenderer({ section }: { section: StoreSection }) {
  switch (section.section_type) {
    case "HERO":
      return <HeroSection section={section} />;
    case "BANNER":
      return <BannerSection section={section} />;
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

function HeroSection({ section }: { section: StoreSection }) {
  const cfg = section.config ?? {};
  const effects = (cfg.effects as Record<string, unknown>) ?? {};
  const heroImg = img(section.image) ?? img((cfg.hero_image as string) ?? null);
  const cta = (cfg.cta_label as string) ?? "Shop now";
  const ctaLink = (cfg.cta_link as string) ?? "browse";
  const align = (cfg.align as string) === "right" ? "right" : "left";
  return (
    <section className="hero" style={effects.hero_animation === "fade" ? { animation: "rise 0.6s ease" } : undefined}>
      {heroImg ? (
        <img
          className={`hero-img ${fxClass(section)}`}
          style={fxStyle(section)}
          src={heroImg}
          alt=""
          decoding="async"
        />
      ) : null}
      <div className="hero-content" style={align === "right" ? { marginLeft: "auto", textAlign: "right" } : undefined}>
        {section.subtitle ? <p>{section.subtitle}</p> : null}
        <h1>{section.title || "Fresh groceries, fast"}</h1>
        <div className="hero-actions">
          <a className="btn btn-secondary" href={ctaLink.startsWith("/") || ctaLink.startsWith("#") ? ctaLink : href(ctaLink)}>
            {cta}
          </a>
        </div>
      </div>
    </section>
  );
}

function BannerSection({ section }: { section: StoreSection }) {
  const first = section.items[0];
  const link = first?.link || (first?.category_slug ? href(`browse?category=${first.category_slug}`) : null);
  const body = (
    <>
      <div>
        <h3>{section.title || "Limited-time offers"}</h3>
        <p>{section.subtitle || first?.caption || "Save more on your daily essentials."}</p>
      </div>
      {link ? <span className="link">View</span> : null}
    </>
  );
  return link ? (
    <a className="banner" href={link.startsWith("/") || link.startsWith("#") ? link : href(link)}>{body}</a>
  ) : (
    <div className="banner">{body}</div>
  );
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
  const columns = section.config?.columns ?? 5;
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
            ...(columns ? {} : null),
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
