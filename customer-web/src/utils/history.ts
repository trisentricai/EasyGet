import type { Product } from "../services/api";

/**
 * Marketplace memory (localStorage): recently viewed products, category
 * affinity for recommendations, and recent search terms. All client-side —
 * no backend calls, survives reloads, capped to stay tiny.
 */

const RECENT_KEY = "eg-recent-views";
const SEARCH_KEY = "eg-recent-searches";
const MAX_RECENT = 12;
const MAX_SEARCHES = 8;

export type RecentView = {
  slug: string;
  name: string;
  brand: string;
  categorySlug: string;
  categoryName: string;
  image: string | null;
  price: string | null;
  mrp: string | null;
  discount: number;
  ratingAvg: number | null;
  ratingCount: number;
  at: number;
};

function read<T>(key: string, fallback: T): T {
  try {
    const raw = localStorage.getItem(key);
    return raw ? (JSON.parse(raw) as T) : fallback;
  } catch {
    return fallback;
  }
}

function write(key: string, value: unknown) {
  try {
    localStorage.setItem(key, JSON.stringify(value));
  } catch {
    /* private mode — memory silently disabled */
  }
}

/** Record a product detail view (call from ProductPage on load). */
export function recordView(p: {
  slug: string;
  name: string;
  brand?: string;
  category?: { slug: string; name: string } | null;
  primary_image?: string | null;
  base_price?: string | null;
  mrp?: string | null;
  discount_percent?: number;
  rating_avg?: number | null;
  rating_count?: number;
}): void {
  const list = read<RecentView[]>(RECENT_KEY, []).filter((v) => v.slug !== p.slug);
  list.unshift({
    slug: p.slug,
    name: p.name,
    brand: p.brand ?? "",
    categorySlug: p.category?.slug ?? "",
    categoryName: p.category?.name ?? "",
    image: p.primary_image ?? null,
    price: p.base_price ?? null,
    mrp: p.mrp ?? null,
    discount: p.discount_percent ?? 0,
    ratingAvg: p.rating_avg ?? null,
    ratingCount: p.rating_count ?? 0,
    at: Date.now(),
  });
  write(RECENT_KEY, list.slice(0, MAX_RECENT));
}

export function getRecentViews(): RecentView[] {
  return read<RecentView[]>(RECENT_KEY, []);
}

/** Category slug the shopper looks at most (for "Recommended for you"). */
export function topCategory(): { slug: string; name: string } | null {
  const counts = new Map<string, { n: number; name: string }>();
  for (const v of getRecentViews()) {
    if (!v.categorySlug) continue;
    const cur = counts.get(v.categorySlug) ?? { n: 0, name: v.categoryName };
    cur.n += 1;
    counts.set(v.categorySlug, cur);
  }
  let best: { slug: string; name: string } | null = null;
  let bestN = 0;
  for (const [slug, { n, name }] of counts) {
    if (n > bestN) {
      bestN = n;
      best = { slug, name };
    }
  }
  return bestN > 0 ? best : null;
}

export function toProductCard(v: RecentView): Product {
  return {
    id: -Math.abs(hash(v.slug)),
    name: v.name,
    slug: v.slug,
    category: v.categorySlug
      ? { id: 0, name: v.categoryName, slug: v.categorySlug, description: "" }
      : null,
    brand: v.brand,
    mrp: v.mrp,
    base_price: v.price,
    discount_percent: v.discount,
    is_featured: false,
    primary_image: v.image,
    rating_avg: v.ratingAvg,
    rating_count: v.ratingCount ?? 0,
  };
}

function hash(s: string): number {
  let h = 0;
  for (let i = 0; i < s.length; i++) h = (Math.imul(31, h) + s.charCodeAt(i)) | 0;
  return h;
}

export function recordSearch(term: string): void {
  const t = term.trim();
  if (!t) return;
  const list = read<string[]>(SEARCH_KEY, []).filter(
    (s) => s.toLowerCase() !== t.toLowerCase(),
  );
  write(SEARCH_KEY, [t, ...list].slice(0, MAX_SEARCHES));
}

export function getRecentSearches(): string[] {
  return read<string[]>(SEARCH_KEY, []);
}

/** Static trending terms until search analytics lands (Phase 11). */
export const TRENDING_SEARCHES = [
  "Rice",
  "Soap",
  "Tea",
  "Biscuits",
  "Shampoo",
  "Detergent",
];

/* ---------------- Wishlist (offline cache; server is truth) ---------------- */

const WISH_KEY = "eg-wishlist";

export function getWishlist(): string[] {
  return read<string[]>(WISH_KEY, []);
}

export function isWished(slug: string): boolean {
  return getWishlist().includes(slug);
}

/** Toggle a slug in the wishlist; returns the new state. */
export function toggleWishlist(slug: string): boolean {
  const list = getWishlist();
  const has = list.includes(slug);
  write(WISH_KEY, has ? list.filter((s) => s !== slug) : [slug, ...list]);
  return !has;
}

/** Align the local cache with a server response (add/remove succeeded). */
export function syncWishlistCache(slug: string, wished: boolean): void {
  const list = getWishlist();
  const has = list.includes(slug);
  if (wished && !has) write(WISH_KEY, [slug, ...list]);
  if (!wished && has) write(WISH_KEY, list.filter((s) => s !== slug));
}

/** Replace the cache wholesale (e.g. after loading the server wishlist). */
export function setWishlistCache(slugs: string[]): void {
  write(WISH_KEY, slugs);
}

/**
 * Remove EVERY piece of user data this app persisted (logout / global 401):
 * tokens, wishlist, recent views/searches (all `eg-*` keys), plus anything
 * a future feature stashes in sessionStorage.
 */
export function purgeLocalUserData(): void {
  const doomed: string[] = [];
  for (let i = 0; i < localStorage.length; i += 1) {
    const key = localStorage.key(i);
    if (key && key.startsWith("eg-")) doomed.push(key);
  }
  for (const key of doomed) localStorage.removeItem(key);
  sessionStorage.clear();
}
