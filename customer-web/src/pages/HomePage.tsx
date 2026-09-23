import { useMemo } from "react";
import { useStorefront } from "../context/StorefrontContext";
import { href } from "../hooks/useHashRoute";
import { img, type SectionItem, type StoreSection } from "../services/api";
import { EmptyState, Monogram, Price, ProductCard, Section, Spinner } from "../components/ui";

/**
 * Home page = the store's designed storefront. The backend returns an ordered
 * list of sections; each section type maps to a renderer here, so a rebrand
 * or layout change made in the admin dashboard shows up with no code change.
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

  const sections = [...data.sections].sort((a, b) => a.position - b.position);
  const hasContent = sections.length > 0;

  return (
    <div className="page">
      {hasContent ? (
        sections.map((s) => <SectionRenderer key={s.id} section={s} />)
      ) : (
        <WelcomeFallback storeName={data.store.name} city={data.store.city} description={data.store.description} />
      )}
    </div>
  );
}

function WelcomeFallback({ storeName, city, description }: { storeName: string; city: string; description: string }) {
  return (
    <>
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
      <Section title="Nothing designed yet">
        <p className="muted">
          This store has no active storefront sections{city ? ` (${city})` : ""}. Open the admin
          dashboard → Storefront designer to compose the page — it renders here instantly.
        </p>
      </Section>
    </>
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
      {heroImg ? <img className="hero-img" src={heroImg} alt="" /> : null}
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
  const columns = section.config?.columns ?? 4;
  const cats = section.items.filter((i) => i.item_type === "CATEGORY" || i.category_slug);
  return (
    <Section title={section.title || undefined} subtitle={section.subtitle || undefined}>
      {cats.length ? (
        <div className="grid grid-categories" style={{ gridTemplateColumns: `repeat(auto-fill, minmax(${Math.round(560 / columns)}px, 1fr))` }}>
          {cats.map((item) => (
            <a key={item.id} className="cat-card" href={href(`browse?category=${item.category_slug}`)}>
              <span className="cat-ico">
                {item.image ? <img src={img(item.image)!} alt="" /> : <Monogram text={item.category_name || item.caption || "·"} />}
              </span>
              {item.category_name || item.caption}
            </a>
          ))}
        </div>
      ) : (
        <p className="muted">No categories configured.</p>
      )}
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
            <img className="gallery-img" src={img(i.image)!} alt={i.caption} loading="lazy" />
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
