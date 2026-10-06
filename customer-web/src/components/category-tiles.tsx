/**
 * Category tiles — the four CATEGORY_GRID layouts (DESIGN.md §4 "Shop by
 * aisle"). Style comes from section.config.category_style, edited in the
 * admin storefront designer — no code change to re-skin a section.
 *
 *   avatars — circular faces in a horizontal rail (Instacart-style)
 *   cards   — classic grid cards (default; reuses legacy cat-card CSS)
 *   cover   — wide cover banners with overlaid names
 *   chips   — text pills (reuses legacy cat-chip CSS)
 *
 * Image resolution: the designer's per-item image first, then the category's
 * own icon (uploaded in admin Categories), then a monogram fallback.
 */
import { useQuery } from "@tanstack/react-query";
import { asArray, img, listCategories, type SectionItem } from "../services/api";
import { href } from "../hooks/useHashRoute";
import { Monogram } from "./ui";

export type CategoryTileStyle = "avatars" | "cards" | "cover" | "chips";

const STYLE_ORDER: CategoryTileStyle[] = ["avatars", "cards", "cover", "chips"];

export function normalizeTileStyle(value: unknown): CategoryTileStyle {
  return typeof value === "string" &&
    (STYLE_ORDER as string[]).includes(value)
    ? (value as CategoryTileStyle)
    : "cards";
}

function useCategoryIcons(): Map<string, string> {
  const { data } = useQuery({
    queryKey: ["categories"],
    queryFn: listCategories,
    staleTime: 5 * 60_000,
  });
  const map = new Map<string, string>();
  for (const c of asArray(data)) {
    if (c.slug && c.icon) map.set(c.slug, c.icon);
  }
  return map;
}

export interface TileItem {
  key: string | number;
  slug?: string | null;
  name: string;
  image?: string | null;
}

export function toTiles(items: SectionItem[], icons: Map<string, string>): TileItem[] {
  return items
    .filter((i) => i.item_type === "CATEGORY" || i.category_slug)
    .map((i) => ({
      key: i.id,
      slug: i.category_slug,
      name: i.category_name || i.caption || "Category",
      image: img(i.image) ?? (i.category_slug ? img(icons.get(i.category_slug) ?? null) : null),
    }));
}

export function CategoryTiles({ items, style }: { items: SectionItem[]; style: CategoryTileStyle }) {
  const icons = useCategoryIcons();
  const tiles = toTiles(items, icons);
  if (tiles.length === 0) return <p className="muted">No categories configured.</p>;

  if (style === "chips") {
    return (
      <div className="filter-chips" role="list">
        {tiles.map((t) => (
          <a key={t.key} role="listitem" className="cat-chip" href={href(`browse?category=${t.slug}`)}>
            {t.name}
          </a>
        ))}
      </div>
    );
  }

  if (style === "avatars") {
    return (
      <div className="cat-avatars" role="list">
        {tiles.map((t) => (
          <a key={t.key} role="listitem" className="cat-avatar" href={href(`browse?category=${t.slug}`)}>
            <span className="cat-avatar-img">
              {t.image ? (
                <img src={t.image} alt="" loading="lazy" decoding="async" width={128} height={128} />
              ) : (
                <Monogram text={t.name} />
              )}
            </span>
            <span className="cat-avatar-name">{t.name}</span>
          </a>
        ))}
      </div>
    );
  }

  if (style === "cover") {
    return (
      <div className="cat-covers" role="list">
        {tiles.map((t) => (
          <a key={t.key} role="listitem" className="cat-cover" href={href(`browse?category=${t.slug}`)}>
            {t.image ? (
              <img
                className="cat-cover-img"
                src={t.image}
                alt=""
                loading="lazy"
                decoding="async"
                width={640}
                height={280}
              />
            ) : (
              <span className="cat-cover-fallback" aria-hidden="true">
                <Monogram text={t.name} />
              </span>
            )}
            <span className="cat-cover-label">{t.name}</span>
          </a>
        ))}
      </div>
    );
  }

  // cards (default): the classic grid card.
  return (
    <div className="grid grid-categories">
      {tiles.map((t) => (
        <a key={t.key} className="cat-card" href={href(`browse?category=${t.slug}`)}>
          <span className="cat-ico">
            {t.image ? (
              <img src={t.image} alt="" loading="lazy" decoding="async" width={300} height={300} />
            ) : (
              <Monogram text={t.name} />
            )}
          </span>
          {t.name}
        </a>
      ))}
    </div>
  );
}
