const BASE = "http://127.0.0.1:8000/api/v1";

export type Tokens = { access: string; refresh: string };

export type AdminUser = {
  id: number;
  email: string;
  first_name?: string;
  last_name?: string;
  role: string;
  is_staff?: boolean;
};

let on401: (() => void) | null = null;
export function setUnauthorizedHandler(fn: () => void) {
  on401 = fn;
}

export function getTokens(): Tokens | null {
  try {
    const raw = localStorage.getItem("eg-tokens");
    return raw ? (JSON.parse(raw) as Tokens) : null;
  } catch {
    return null;
  }
}

export function setTokens(t: Tokens | null) {
  if (t) localStorage.setItem("eg-tokens", JSON.stringify(t));
  else localStorage.removeItem("eg-tokens");
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
  options: { method?: string; body?: unknown; form?: FormData } = {},
): Promise<T> {
  const doFetch = async () => {
    const tokens = getTokens();
    const headers: Record<string, string> = {};
    if (tokens?.access) headers.Authorization = `Bearer ${tokens.access}`;
    let body: BodyInit | undefined;
    if (options.form) {
      body = options.form;
    } else if (options.body !== undefined) {
      headers["Content-Type"] = "application/json";
      body = JSON.stringify(options.body);
    }
    return fetch(`${BASE}${path}`, {
      method: options.method ?? "GET",
      headers,
      body,
    });
  };

  let res = await doFetch();
  if (res.status === 401 && (await refreshTokens())) {
    res = await doFetch();
  }
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

/* ---------------- Auth ---------------- */

export type LoginResponse = {
  access: string;
  refresh: string;
  user: AdminUser;
};

export async function login(email: string, password: string) {
  return api<LoginResponse>("/auth/login/", {
    method: "POST",
    body: { email, password },
  });
}

export async function logout(refresh: string) {
  return api("/auth/logout/", { method: "POST", body: { refresh } });
}

/* ---------------- Dashboard ---------------- */

export type AdminSummary = {
  users: { total: number; today: number; week: number };
  orders: { total: number; today: number; week: number; pending: number };
  revenue: { today: string | number; week: string | number };
  products: { total: number; low_stock: number };
};

export const getSummary = () => api<AdminSummary>("/admin/dashboard/");

/* ---------------- Categories ---------------- */

export type Category = {
  id: number;
  name: string;
  slug: string;
  description: string;
  is_active: boolean;
  sort_order: number;
  product_count: number;
  is_subcategory: boolean;
};

export const listCategories = () => api<{ results: Category[] } | Category[]>("/categories/");

export async function createCategory(body: Partial<Category>) {
  return api<Category>("/categories/", { method: "POST", body });
}

export async function updateCategory(slug: string, body: Partial<Category>) {
  return api<Category>(`/categories/${slug}/`, { method: "PATCH", body });
}

export async function deleteCategory(slug: string) {
  return api<void>(`/categories/${slug}/`, { method: "DELETE" });
}

/* ---------------- Products ---------------- */

export type Product = {
  id: number;
  name: string;
  slug: string;
  category: { id: number; name: string; slug: string };
  brand: string;
  mrp: string | null;
  base_price: string | null;
  is_featured: boolean;
  is_active: boolean;
};

export function listProducts(params: Record<string, string> = {}) {
  const qs = new URLSearchParams(params).toString();
  return api<{ results: Product[] } | Product[]>(`/products/${qs ? `?${qs}` : ""}`);
}

export async function createProduct(body: Record<string, unknown>) {
  return api<Product>("/products/", { method: "POST", body });
}

export async function updateProduct(slug: string, body: Record<string, unknown>) {
  return api<Product>(`/products/${slug}/`, { method: "PATCH", body });
}

export async function deleteProduct(slug: string) {
  return api<void>(`/products/${slug}/`, { method: "DELETE" });
}

/* ---------------- Storefront ---------------- */

export type SectionItem = {
  id: number;
  item_type: "PRODUCT" | "CATEGORY" | "CUSTOM";
  product: number | null;
  product_name: string | null;
  product_price: string | null;
  category: number | null;
  category_name: string | null;
  caption: string;
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
  config: { columns?: number; size?: "sm" | "md" | "lg"; effects?: Record<string, unknown>; placeholder?: string } & Record<string, unknown>;
  position: number;
  is_active: boolean;
  items: SectionItem[];
};

export type Theme = {
  primary_color: string;
  secondary_color: string;
  background_color: string;
  font_family: string;
  button_style: "ROUNDED" | "SQUARE" | "PILL";
  effects: Record<string, unknown>;
};

export function getStoreSlug(): string {
  return localStorage.getItem("eg-store") || "rahuls-store";
}

export function setStoreSlug(slug: string) {
  localStorage.setItem("eg-store", slug);
}

export const getStorefront = (slug: string) =>
  api<{ store: Record<string, string>; theme: Theme | null; sections: StoreSection[] }>(
    `/storefront/${slug}/`,
  );

export const getSections = (slug: string) => api<StoreSection[]>(`/storefront/${slug}/sections/`);

export const createSection = (slug: string, body: Record<string, unknown>) =>
  api<StoreSection>(`/storefront/${slug}/sections/`, { method: "POST", body });

export const updateSection = (id: number, body: Record<string, unknown>) =>
  api<StoreSection>(`/storefront/sections/${id}/`, { method: "PATCH", body });

export const deleteSection = (id: number) =>
  api<void>(`/storefront/sections/${id}/`, { method: "DELETE" });

export const reorderSections = (slug: string, order: number[]) =>
  api<StoreSection[]>(`/storefront/${slug}/sections/reorder/`, {
    method: "POST",
    body: { order },
  });

export const createItem = (sectionId: number, body: Record<string, unknown>) =>
  api<SectionItem>(`/storefront/sections/${sectionId}/items/`, { method: "POST", body });

export const updateItem = (id: number, body: Record<string, unknown>) =>
  api<SectionItem>(`/storefront/items/${id}/`, { method: "PATCH", body });

export const deleteItem = (id: number) =>
  api<void>(`/storefront/items/${id}/`, { method: "DELETE" });

export const reorderItems = (sectionId: number, order: number[]) =>
  api<SectionItem[]>(`/storefront/sections/${sectionId}/items/reorder/`, {
    method: "POST",
    body: { order },
  });

export const updateTheme = (slug: string, body: Partial<Theme>) =>
  api<Theme>(`/storefront/${slug}/theme/`, { method: "PATCH", body });

export const listStores = () =>
  api<{ results: { id: number; name: string; slug: string; is_active: boolean }[] } | { id: number; name: string; slug: string; is_active: boolean }[]>("/stores/");

/* ---------------- Orders (fulfilment queue) ---------------- */

export type OrderItem = {
  id: number;
  product_name: string;
  variant_name: string;
  sku: string;
  unit_price: string;
  quantity: number;
  line_total: string;
};

export type OrderStatusEvent = {
  id: number;
  from_status: string;
  to_status: string;
  changed_by_email?: string;
  note: string;
  created_at: string;
};

export type Order = {
  id: string;
  order_number: string;
  store: string | null;
  store_name?: string;
  status: string;
  subtotal: string;
  delivery_fee: string;
  discount: string;
  total: string;
  item_count?: number;
  delivery_address?: Record<string, unknown>;
  delivery_instructions?: string;
  estimated_delivery_at?: string | null;
  created_at: string;
};

export type OrderDetail = Order & {
  items: OrderItem[];
  status_history: OrderStatusEvent[];
  cancelled_at?: string | null;
  cancellation_reason?: string;
};

/** Next states the fulfilment UI may offer for a given status. */
export const NEXT_STATUS: Record<string, string[]> = {
  PENDING: ["CONFIRMED"],
  CONFIRMED: ["PREPARING"],
  PREPARING: ["READY"],
  READY: ["OUT_FOR_DELIVERY"],
  OUT_FOR_DELIVERY: ["DELIVERED"],
  DELIVERED: ["REFUNDED"],
};

export function listOrders() {
  return api<{ results: Order[] } | Order[]>("/orders/");
}

export const getOrder = (id: string) => api<OrderDetail>(`/orders/${id}/`);

export const updateOrderStatus = (id: string, status: string, note = "") =>
  api<OrderDetail>(`/orders/${id}/`, { method: "PATCH", body: { status, note } });

export const cancelOrder = (id: string, reason: string) =>
  api<OrderDetail>(`/orders/${id}/cancel/`, { method: "POST", body: { reason } });
