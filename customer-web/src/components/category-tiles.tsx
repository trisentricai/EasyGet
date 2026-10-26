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
import { asArray, img, listCategories, type Category, type SectionItem } from "../services/api";
import { href } from "../hooks/useHashRoute";

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
  "#FDECEA", // danger wash
  "#FDF3E0", // warning wash
  "#E8F5E9", // success wash
  "#E3F2FD", // info wash
  "#F3E8FF", // purple wash
  "#FFE5E5", // rose wash
];

function categoryColorForSlug(slug: string): string {
  let hash = 0;
  for (let i = 0; i < slug.length; i++) {
    hash = ((hash << 5) - hash + slug.charCodeAt(i)) | 0;
  }
  return CATEGORY_WASHES[Math.abs(hash) % CATEGORY_WASHES.length];
}

function washTextColor(wash: string): string {
  // Pick dark or light text based on wash luminance for contrast.
  const r = parseInt(wash.slice(1, 3), 16);
  const g = parseInt(wash.slice(3, 5), 16);
  const b = parseInt(wash.slice(5, 7), 16);
  const luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
  return luminance > 0.6 ? "#1a1815" : "#ffffff";
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
      <div className="filter-chips" role="list">
        {shown.map((t) => (
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
        {shown.map((t) => {
          const wash = t.image ? null : categoryColorForSlug(t.slug ?? "");
          const textColor = wash ? washTextColor(wash) : "inherit";
          return (
            <a key={t.key} role="listitem" className="cat-avatar" href={href(`browse?category=${t.slug}`)}>
              <span className="cat-avatar-img" style={wash ? { backgroundColor: wash, color: textColor } : {}}>
                {t.image ? (
                  <img src={t.image} alt="" loading="lazy" decoding="async" width={128} height={128} />
                ) : (
                  <span className="cat-avatar-monogram">{t.name.slice(0, 1).toUpperCase()}</span>
                )}
              </span>
              <span className="cat-avatar-name">{t.name}</span>
            </a>
          );
        })}
      </div>
    );
  }

  if (style === "cover") {
    return (
      <>
        <div className="cat-covers" role="list">
          {shown.map((t) => {
            const wash = t.image ? null : categoryColorForSlug(t.slug ?? "");
            const textColor = wash ? washTextColor(wash) : "inherit";
            return (
              <a key={t.key} role="listitem" className="cat-cover" href={href(`browse?category=${t.slug}`)}>
                <div className="cat-cover-media" style={wash ? { backgroundColor: wash, color: textColor } : {}}>
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
                    <span className="cat-cover-monogram" aria-hidden="true">
                      {t.name.slice(0, 1).toUpperCase()}
                    </span>
                  )}
                </div>
                <span className="cat-cover-label">{t.name}</span>
              </a>
            );
          })}
        </div>
        {more ? (
          <div style={{ marginTop: 14 }}>
            <a className="link" href={href("categories")}>
              See all {tiles.length} categories →
            </a>
          </div>
        ) : null}
      </>
    );
  }

  // cards (default): the classic grid card with vibrant color backgrounds.
  return (
    <>
      <div className="grid grid-categories">
        {shown.map((t) => {
          const wash = t.image ? null : categoryColorForSlug(t.slug ?? "");
          const textColor = wash ? washTextColor(wash) : "inherit";
          return (
            <a key={t.key} className="cat-card" href={href(`browse?category=${t.slug}`)}>
              <span className="cat-ico" style={wash ? { backgroundColor: wash, color: textColor, borderColor: wash } : {}}>
                {t.image ? (
                  <img src={t.image} alt="" loading="lazy" decoding="async" width={300} height={300} />
                ) : (
                  <span className="cat-ico-monogram">{t.name.slice(0, 1).toUpperCase()}</span>
                )}
              </span>
              <span className="cat-name">{t.name}</span>
            </a>
          );
        })}
      </div>
      {more ? (
        <div style={{ marginTop: 14 }}>
          <a className="link" href={href("categories")}>
            See all {tiles.length} categories →
          </a>
        </div>
      ) : null}
    </>
  );
}
