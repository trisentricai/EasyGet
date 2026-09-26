const BASE = "http://127.0.0.1:8000/api/v1";

export type Tokens = { access: string; refresh: string };

export type User = {
  id: number;
  email: string;
  role: string;
  first_name?: string;
  last_name?: string;
  phone?: string;
  is_email_verified?: boolean;
};

let on401: (() => void) | null = null;
export function setUnauthorizedHandler(fn: () => void) {
  on401 = fn;
}

export function getTokens(): Tokens | null {
  try {
    const raw = localStorage.getItem("eg-cust-tokens");
    return raw ? (JSON.parse(raw) as Tokens) : null;
  } catch {
    return null;
  }
}

export function setTokens(t: Tokens | null) {
  if (t) localStorage.setItem("eg-cust-tokens", JSON.stringify(t));
  else localStorage.removeItem("eg-cust-tokens");
}

export class ApiError extends Error {
  status: number;
  payload: unknown;
  constructor(status: number, payload: unknown) {
    super(errorMessage(payload));
    this.status = status;
    this.payload = payload;
  }
}

export function errText(e: unknown, fallback = "Request failed"): string {
  if (e instanceof ApiError) return e.message;
  if (e instanceof Error) return e.message;
  return fallback;
}

/** DRF field errors ({field: [msgs]}) → one readable string. */
export function fieldErrors(e: unknown): string {
  if (e instanceof ApiError && e.payload && typeof e.payload === "object") {
    const p = e.payload as Record<string, unknown>;
    if (!("detail" in p) && !("error" in p)) {
      const parts: string[] = [];
      for (const [key, value] of Object.entries(p)) {
        if (Array.isArray(value)) parts.push(`${key}: ${value.join(", ")}`);
        else if (typeof value === "string") parts.push(`${key}: ${value}`);
      }
      if (parts.length) return parts.join(" · ");
    }
  }
  return errText(e);
}

function errorMessage(payload: unknown): string {
  if (payload && typeof payload === "object") {
    const err = (payload as { error?: { message?: string } }).error;
    if (err?.message) return err.message;
    const detail = (payload as { detail?: string }).detail;
    if (detail) return detail;
  }
  return "Request failed";
}

async function refreshTokens(): Promise<boolean> {
  const tokens = getTokens();
  if (!tokens?.refresh) return false;
  try {
    const res = await fetch(`${BASE}/auth/refresh/`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ refresh: tokens.refresh }),
    });
    if (!res.ok) return false;
    const data = (await res.json()) as { access?: string };
    if (!data.access) return false;
    setTokens({ access: data.access, refresh: tokens.refresh });
    return true;
  } catch {
    return false;
  }
}

export async function api<T = unknown>(
  path: string,
  options: { method?: string; body?: unknown } = {},
): Promise<T> {
  const doFetch = async () => {
    const tokens = getTokens();
    const headers: Record<string, string> = {};
    if (tokens?.access) headers.Authorization = `Bearer ${tokens.access}`;
    let body: BodyInit | undefined;
    if (options.body !== undefined) {
      headers["Content-Type"] = "application/json";
      body = JSON.stringify(options.body);
    }
    return fetch(`${BASE}${path}`, { method: options.method ?? "GET", headers, body });
  };

  let res = await doFetch();
  if (res.status === 401 && (await refreshTokens())) res = await doFetch();
  if (res.status === 401 && on401) {
    setTokens(null);
    on401();
  }
  if (res.status === 204) return undefined as T;

  let payload: unknown = null;
  try {
    payload = await res.json();
  } catch {
    /* non-JSON */
  }
  if (!res.ok) throw new ApiError(res.status, payload);
  return payload as T;
}

/* ---------------- Storefront (public) ---------------- */

export type Theme = {
  primary_color: string;
  secondary_color: string;
  background_color: string;
  font_family: string;
  logo?: string | null;
  hero_image?: string | null;
  button_style: "ROUNDED" | "SQUARE" | "PILL";
  effects?: Record<string, unknown>;
};

export type SectionItem = {
  id: number;
  item_type: "PRODUCT" | "CATEGORY" | "CUSTOM";
  product: number | null;
  product_name: string | null;
  product_slug: string | null;
  product_price: string | null;
  category: number | null;
  category_name: string | null;
  category_slug: string | null;
  caption: string;
  image: string | null;
  link: string;
  config: Record<string, unknown>;
  position: number;
};

export type StoreSection = {
  id: number;
  section_type:
    | "HERO"
    | "BANNER"
    | "CATEGORY_GRID"
    | "PRODUCT_ROW"
    | "IMAGE_GALLERY"
    | "RICH_TEXT";
  title: string;
  subtitle: string;
  image: string | null;
  config: {
    columns?: number;
    size?: "sm" | "md" | "lg";
    effects?: Record<string, unknown>;
    [key: string]: unknown;
  };
  position: number;
  is_active: boolean;
  items: SectionItem[];
};

export type StorefrontPayload = {
  store: { name: string; slug: string; city: string; description: string };
  theme: Theme | null;
  sections: StoreSection[];
};

export const getPlatformStorefront = () => api<StorefrontPayload>("/storefront/platform/");

/* ---------------- Auth ---------------- */

export async function register(body: {
  email: string;
  password: string;
  first_name?: string;
  last_name?: string;
  phone?: string;
}) {
  return api<{ message: string; user: User }>("/auth/register/", { method: "POST", body });
}

export async function verifyOtp(email: string, code: string) {
  return api<{ message: string; user: User }>("/auth/verify-otp/", {
    method: "POST",
    body: { email, code },
  });
}

export async function resendOtp(email: string) {
  return api<{ message: string }>("/auth/resend-otp/", { method: "POST", body: { email } });
}

export type LoginResponse = { access: string; refresh: string; user: User };

export async function login(email: string, password: string) {
  return api<LoginResponse>("/auth/login/", { method: "POST", body: { email, password } });
}

export async function logout(refresh: string) {
  return api<{ message: string }>("/auth/logout/", { method: "POST", body: { refresh } });
}

export const getMe = () => api<User>("/users/me/");

/* ---------------- Addresses ---------------- */

export type Address = {
  id: number | string;
  label: string;
  line1: string;
  line2: string;
  city: string;
  state: string;
  postal_code: string;
  country: string;
  phone: string;
  is_default: boolean;
};

export const listAddresses = () => api<Address[] | { results: Address[] }>("/users/me/addresses/");

export async function createAddress(body: Partial<Address>) {
  return api<Address>("/users/me/addresses/", { method: "POST", body });
}

export async function deleteAddress(id: number | string) {
  return api<void>(`/users/me/addresses/${id}/`, { method: "DELETE" });
}

export async function setDefaultAddress(id: number | string) {
  return api<Address>(`/users/me/addresses/${id}/set-default/`, { method: "POST" });
}

/* ---------------- Products (authed) ---------------- */

export type Category = { id: number; name: string; slug: string; description: string };

export type Product = {
  id: number;
  name: string;
  slug: string;
  category: Category | null;
  brand: string;
  mrp: string | null;
  base_price: string | null;
  discount_percent: number;
  is_featured: boolean;
  primary_image: string | null;
  rating_avg: number | null;
  rating_count: number;
};

export type ProductDetail = Product & {
  description: string;
  offers: Offer[];
  variants: { id: number; name: string; sku: string; price: string; discount_percent: number; is_active: boolean }[];
  images: { id: number; image: string; caption: string; is_primary: boolean; sort_order: number }[];
};

export type Paged<T> = {
  count: number;
  next: string | null;
  previous: string | null;
  results: T[];
};

export function listProductsPaged(params: Record<string, string> = {}) {
  const qs = new URLSearchParams(params).toString();
  return api<Paged<Product>>(`/products/${qs ? `?${qs}` : ""}`);
}

/** Back-compat first-page call (shape fits existing asArray callers). */
export function listProducts(params: Record<string, string> = {}) {
  return listProductsPaged(params);
}

/** Fetch every page (page_size=100, follows `next`, capped) for flows that
 *  need the whole catalog client-side, e.g. the search fallback. */
export async function listAllProducts(
  params: Record<string, string> = {},
  maxPages = 10,
): Promise<Product[]> {
  const out: Product[] = [];
  let page = 1;
  for (;;) {
    const res = await listProductsPaged({ ...params, page: String(page), page_size: "100" });
    out.push(...res.results);
    if (!res.next || page >= maxPages) break;
    page += 1;
  }
  return out;
}

export const getProduct = (slug: string) => api<ProductDetail>(`/products/${slug}/`);

/* ---------------- Offers (active coupons shown on the PDP) ---------------- */

export type Offer = {
  code: string;
  name: string;
  description: string;
  discount_type: "PERCENTAGE" | "FIXED" | "FREE_DELIVERY";
  discount_value: string;
  max_discount: string | null;
};

/** One-line Flipkart-style offer text, e.g. "Flat ₹50 off (SAVE50)". */
export function offerLine(o: Offer): string {
  const cap = (s: string) => (s.length > 46 ? `${s.slice(0, 46)}…` : s);
  let head: string;
  if (o.discount_type === "PERCENTAGE") {
    const pct = Number(o.discount_value);
    head = `${pct}% off${o.max_discount ? ` up to ₹${Number(o.max_discount).toLocaleString("en-IN")}` : ""}`;
  } else if (o.discount_type === "FIXED") {
    head = `Flat ₹${Number(o.discount_value).toLocaleString("en-IN")} off`;
  } else {
    head = "Free delivery";
  }
  const body = cap(o.description || "");
  return body ? `${head} · ${body}` : head;
}

/* ---------------- Wishlist (server-backed heart) ---------------- */

export type WishlistAction = { added: boolean; slug: string; count: number };

export const listWishlist = (page = 1) =>
  api<Paged<Product>>(`/products/wishlist/?page=${page}`);

export const addToWishlist = (slug: string) =>
  api<WishlistAction>(`/products/wishlist/${slug}/`, { method: "POST" });

export const removeFromWishlist = (slug: string) =>
  api<WishlistAction>(`/products/wishlist/${slug}/`, { method: "DELETE" });

/* ---------------- Pincode (live delivery ETA) ---------------- */

export type PincodeResult = {
  valid: boolean;
  reason?: string;
  pincode: string;
  city?: string | null;
  state?: string | null;
  eta_days?: number;
  delivery_fee?: string;
  free_delivery_over?: string;
  source?: "api" | "fallback";
};

/** Throws ApiError(404) for undeliverable pins; payload carries `reason`. */
export const checkPincode = (pin: string) =>
  api<PincodeResult>(`/pincode/${pin}/`);

export type Brand = { name: string };

export const listBrands = () => api<Brand[] | { results: Brand[] }>("/products/brands/");

/* ---------------- Reviews (ratings & reviews) ---------------- */

export type Review = {
  id: number;
  rating: number;
  title: string;
  body: string;
  reviewer_name: string;
  is_verified_purchase: boolean;
  created_at: string;
};

export const listReviews = (slug: string, page = 1) =>
  api<Paged<Review>>(`/products/${slug}/reviews/?page=${page}`);

export const postReview = (
  slug: string,
  data: { rating: number; title?: string; body?: string },
) => api<Review>(`/products/${slug}/reviews/`, { method: "POST", body: data });

export function listCategories() {
  return api<{ results?: Category[] } | Category[]>("/categories/");
}

/* ---------------- Search (authed) ---------------- */

export type SearchResponse = {
  results: (Product & { score?: number })[];
  total: number;
  page: number;
  page_size: number;
  took_ms: number;
};

const searchProducts = (body: Record<string, unknown>) =>
  api<SearchResponse>("/search/", { method: "POST", body });

/**
 * Search with graceful degradation: the backend /search/ endpoint relies on
 * PostgreSQL full-text search (it 500s on the local SQLite dev DB), so on
 * failure fall back to the /products/ list filtered client-side.
 */
export async function searchWithFallback(body: {
  q?: string;
  sort?: string;
}): Promise<SearchResponse> {
  try {
    return await searchProducts(body);
  } catch {
    const params: Record<string, string> = {};
    if (body.sort && body.sort !== "relevance") params.sort = body.sort;
    const all = await listAllProducts(params);
    const q = (body.q ?? "").trim().toLowerCase();
    const matched = q
      ? all.filter(
          (p) =>
            p.name.toLowerCase().includes(q) ||
            p.brand.toLowerCase().includes(q) ||
            (p.category?.name.toLowerCase().includes(q) ?? false),
        )
      : all;
    return {
      results: matched.slice(0, 40),
      total: matched.length,
      page: 1,
      page_size: 40,
      took_ms: 0,
    };
  }
}

export const getSearchSuggestions = (q: string) =>
  api<string[]>(`/search/suggestions/?q=${encodeURIComponent(q)}`);

/* ---------------- Cart (authed) ---------------- */

export type CartVariant = {
  id: number;
  name: string;
  sku: string;
  price: string;
  attributes?: Record<string, unknown>;
};

export type CartItem = {
  id: number;
  variant: CartVariant;
  quantity: number;
  line_total: string;
  /** Seller split key: the variant's tenant (null = platform line). */
  tenant_id: number | null;
  seller_name: string;
};

export type Cart = {
  id: string;
  items: CartItem[];
  total_items: number;
  subtotal: string;
};

export const getCart = () => api<Cart>("/cart/");

export async function addToCart(variantId: number, quantity = 1) {
  return api<CartItem>("/cart/items/", { method: "POST", body: { variant_id: variantId, quantity } });
}

export async function updateCartItem(itemId: number, quantity: number) {
  return api<CartItem>(`/cart/items/${itemId}/`, { method: "PATCH", body: { quantity } });
}

export async function removeCartItem(itemId: number) {
  return api<void>(`/cart/items/${itemId}/`, { method: "DELETE" });
}

export const clearCart = () => api<void>("/cart/clear/", { method: "DELETE" });

/* ---------------- Orders (authed) ---------------- */

export type Order = {
  /** The orders API uses UUID primary keys. */
  id: string;
  order_number: string;
  store: number | null;
  store_name?: string;
  status: string;
  subtotal: string;
  delivery_fee: string;
  discount: string;
  total: string;
  item_count?: number;
  delivery_address?: Record<string, unknown>;
  delivery_instructions?: string;
  items?: {
    id: number;
    product_name: string;
    variant_name: string;
    sku: string;
    unit_price: string;
    quantity: number;
    line_total: string;
  }[];
  created_at: string;
};

export type OrderDetail = Order & {
  status_history: { id: number; from_status: string; to_status: string; note: string; created_at: string }[];
};

export type OrderCreateInput = {
  cart_id: string;
  /** Optional: omit to let the backend split the cart one order per seller. */
  store?: number;
  delivery_address: Record<string, unknown>;
  delivery_instructions?: string;
};

/** Split mode returns `{orders}`; the legacy path echoes a single order. */
export const createOrder = (body: OrderCreateInput) =>
  api<{ orders?: Order[] } & Partial<OrderDetail>>("/orders/", { method: "POST", body });

export const listOrders = () => api<{ results?: Order[] } | Order[]>("/orders/");

export const getOrder = (id: string | number) => api<OrderDetail>(`/orders/${id}/`);

export const cancelOrder = (id: string | number, reason: string) =>
  api<OrderDetail>(`/orders/${id}/cancel/`, { method: "POST", body: { reason } });

/* ---------------- Stores ---------------- */

export type Store = { id: number; name: string; slug: string; is_active: boolean; city?: string };

export function listStores() {
  return api<{ results?: Store[] } | Store[]>("/stores/");
}

/** DRF may return a bare array or a paginated {results} object. */
export function asArray<T>(data: { results?: T[] } | T[] | undefined | null): T[] {
  if (Array.isArray(data)) return data;
  if (data && Array.isArray(data.results)) return data.results;
  return [];
}

export function img(path: string | null | undefined): string | null {
  if (!path) return null;
  if (path.startsWith("http") || path.startsWith("data:")) return path;
  return `http://127.0.0.1:8000${path.startsWith("/") ? "" : "/media/"}${path}`;
}
