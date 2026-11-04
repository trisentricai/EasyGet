/**
 * Category tiles — the four CATEGORY_GRID layouts (DESIGN.md §4 "Shop by
 * aisle"). Style comes from section.config.category_style, edited in the
 * admin storefront designer — no code change to re-skin a section.
 *
 *   avatars — compact rounded tiles (Instacart-style, no grey circles)
 *   cards   — gradient tile grid (default)
 *   cover   — wide cover banners with overlaid names
 *   chips   — tinted text pills
 *
 * Image resolution: the designer's per-item image first, then the category's
 * own icon (uploaded in admin Categories), then an initials fallback on a
 * stable pastel wash. The wash is exposed as `--wash`, so dark mode can
 * re-tone the same hue instead of flashing a bright pastel card.
 */
import type { CSSProperties } from "react";
import { useQuery } from "@tanstack/react-query";
import { asArray, img, listCategories, type Category, type SectionItem } from "../services/api";
import { href } from "../hooks/useHashRoute";
import { Icon } from "./icons";

export type CategoryTileStyle = "avatars" | "cards" | "cover" | "chips";

const STYLE_ORDER: CategoryTileStyle[] = ["avatars", "cards", "cover", "chips"];

export function normalizeTileStyle(value: unknown): CategoryTileStyle {
  return typeof value === "string" &&
    (STYLE_ORDER as string[]).includes(value)
    ? (value as CategoryTileStyle)
    : "cards";
}

/** Vibrant wash palette for category placeholders when no image is uploaded.
 *  Stable per-category color derived from the slug hash so the same category
 *  always renders the same hue — never a grey monogram box. */
const CATEGORY_WASHES: ReadonlyArray<string> = [
  "#FCEFD4", // marigold wash
  "#DDF0E4", // primary tint
  "#FDECEA", // blush wash
  "#FDF3E0", // warm cream
  "#E8F5E9", // mint wash
  "#F5EFE6", // oat
  "#EFE7DC", // sand
  "#FFE9D6", // peach
];

function categoryColorForSlug(slug: string): string {
  let hash = 0;
  for (let i = 0; i < slug.length; i++) {
    hash = ((hash << 5) - hash + slug.charCodeAt(i)) | 0;
  }
  return CATEGORY_WASHES[Math.abs(hash) % CATEGORY_WASHES.length];
}

function initialsFor(name: string): string {
  const letters = name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((word) => word[0]?.toUpperCase() ?? "")
    .join("");
  return letters || "·";
}

function washStyle(t: TileItem): CSSProperties {
  return {
    "--wash": categoryColorForSlug(t.slug || t.name),
  } as CSSProperties;
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
  return <TileLayout tiles={tiles} style={style} capped />;
}

/** Direct category list (categories hub page) — no section items needed. */
export function CategoryTilesFromCategories({
  categories,
  style,
}: {
  categories: Category[];
  style: CategoryTileStyle;
}) {
  const tiles: TileItem[] = categories.map((c) => ({
    key: c.slug,
    slug: c.slug,
    name: c.name,
    image: img(c.icon ?? null),
  }));
  if (tiles.length === 0) return <p className="muted">No categories configured.</p>;
  return <TileLayout tiles={tiles} style={style} />;
}

/** Home grid shows at most 8 tiles, then a See-all into the hub page. */
const HOME_TILE_CAP = 8;

export function TileLayout({
  tiles,
  style,
  capped = false,
}: {
  tiles: TileItem[];
  style: CategoryTileStyle;
  capped?: boolean;
}) {
  const cap = style === "cards" || style === "cover";
  const shown = capped && cap && tiles.length > HOME_TILE_CAP ? tiles.slice(0, HOME_TILE_CAP) : tiles;
  const more = shown.length < tiles.length;

  if (style === "chips") {
    return (
      <div className="cat-pills" role="list">
        {shown.map((t) => (
          <a key={t.key} role="listitem" className="cat-pill" style={washStyle(t)} href={href(`browse?category=${t.slug}`)}>
            <span className="cat-pill-dot" aria-hidden="true">{initialsFor(t.name)}</span>
            <span className="cat-pill-name">{t.name}</span>
          </a>
        ))}
      </div>
    );
  }

  if (style === "cover") {
    return (
      <>
        <div className="cat-banners" role="list">
          {shown.map((t) => (
            <a key={t.key} role="listitem" className="cat-banner" style={washStyle(t)} href={href(`browse?category=${t.slug}`)}>
              <span className="cat-banner-media">
                {t.image ? (
                  <img src={t.image} alt="" loading="lazy" decoding="async" width={640} height={280} />
                ) : (
                  <span className="cat-banner-initials" aria-hidden="true">{initialsFor(t.name)}</span>
                )}
              </span>
              <span className="cat-banner-scrim" aria-hidden="true" />
              <span className="cat-banner-body">
                <span className="cat-banner-name">{t.name}</span>
                <span className="cat-banner-cta">
                  Shop now <Icon name="arrowRight" size={14} />
                </span>
              </span>
            </a>
          ))}
        </div>
        {more ? <SeeAll total={tiles.length} /> : null}
      </>
    );
  }

  const compact = style === "avatars";

  return (
    <>
      <div className={`cat-tiles ${compact ? "cat-tiles--compact" : ""}`} role="list">
        {shown.map((t) => (
          <a key={t.key} role="listitem" className="cat-tile" style={washStyle(t)} href={href(`browse?category=${t.slug}`)}>
            <span className="cat-tile-media">
              {t.image ? (
                <img src={t.image} alt="" loading="lazy" decoding="async" width={300} height={300} />
              ) : (
                <span className="cat-tile-initials" aria-hidden="true">{initialsFor(t.name)}</span>
              )}
            </span>
            <span className="cat-tile-foot">
              <span className="cat-tile-name">{t.name}</span>
              <span className="cat-tile-arrow" aria-hidden="true">
                <Icon name="arrowUpRight" size={14} />
              </span>
            </span>
          </a>
        ))}
      </div>
      {more ? <SeeAll total={tiles.length} /> : null}
    </>
  );
}

function SeeAll({ total }: { total: number }) {
  return (
    <div className="cat-see-all">
      <a className="link link-arrow" href={href("categories")}>
        See all {total} categories <Icon name="arrowRight" size={14} />
      </a>
    </div>
  );
}
