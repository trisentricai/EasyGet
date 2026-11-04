import type { Cart, CartItem } from "../services/api";

/**
 * Guest cart storage.
 *
 * The cart is a signed-in feature on the API, so while the shopper is a guest
 * we keep the exact same `CartItem` shape locally. `id` is the variant id:
 * a guest cart is keyed by variant, so one line per variant and the existing
 * CartPage quantity/remove handlers keep working unchanged.
 */
export const GUEST_CART_KEY = "eg-guest-cart";
export const MAX_CART_QTY = 10;

export type GuestVariantSnapshot = {
  /** Display title for the cart line (ProductPage sends the product name). */
  name?: string;
  sku?: string;
  price?: string;
  tenantId?: number | null;
  sellerName?: string;
  productName?: string;
  productSlug?: string;
  image?: string | null;
  /** Stock snapshot so a guest cart can enforce the same caps before merge. */
  inStock?: boolean | null;
  stockQuantity?: number | null;
};

function clampQuantity(value: number): number {
  const n = Math.floor(Number(value));
  if (!Number.isFinite(n) || n < 1) return 1;
  return Math.min(n, MAX_CART_QTY);
}

function money(value: number): string {
  return (Number.isFinite(value) ? value : 0).toFixed(2);
}

function lineTotal(price: string, quantity: number): string {
  return money(Number(price) * quantity);
}

function normalizeLine(raw: unknown): CartItem | null {
  if (!raw || typeof raw !== "object") return null;
  const row = raw as {
    variant?: {
      id?: unknown;
      name?: unknown;
      sku?: unknown;
      price?: unknown;
      attributes?: unknown;
      in_stock?: unknown;
      stock_quantity?: unknown;
    };
    quantity?: unknown;
    tenant_id?: unknown;
    seller_name?: unknown;
  };
  const variant = row.variant;
  if (!variant || typeof variant.id !== "number" || !Number.isFinite(variant.id)) {
    return null;
  }

  const quantity = clampQuantity(Number(row.quantity));
  const price = String(variant.price ?? "0");
  const attributes =
    variant.attributes &&
    typeof variant.attributes === "object" &&
    !Array.isArray(variant.attributes)
      ? (variant.attributes as Record<string, unknown>)
      : undefined;

  const stockQuantity =
    typeof variant.stock_quantity === "number" && Number.isFinite(variant.stock_quantity)
      ? variant.stock_quantity
      : null;
  const inStock =
    typeof variant.in_stock === "boolean" ? variant.in_stock : null;

  return {
    id: variant.id,
    variant: {
      id: variant.id,
      name: String(variant.name ?? ""),
      sku: String(variant.sku ?? ""),
      price,
      ...(attributes ? { attributes } : {}),
      in_stock: inStock,
      stock_quantity: stockQuantity,
    },
    quantity,
    line_total: lineTotal(price, quantity),
    tenant_id: typeof row.tenant_id === "number" ? row.tenant_id : null,
    seller_name: String(row.seller_name ?? "EASYGET"),
  };
}

export function setGuestLineQuantity(item: CartItem, quantity: number): CartItem {
  const qty = clampQuantity(quantity);
  return {
    ...item,
    id: item.variant.id,
    quantity: qty,
    line_total: lineTotal(item.variant.price, qty),
  };
}

/** Read and repair the guest cart (legacy/corrupt rows are ignored). */
export function readGuestCartItems(): CartItem[] {
  try {
    const raw = localStorage.getItem(GUEST_CART_KEY);
    if (!raw) return [];

    const parsed: unknown = JSON.parse(raw);
    const rows = Array.isArray(parsed)
      ? parsed
      : parsed &&
          typeof parsed === "object" &&
          Array.isArray((parsed as { items?: unknown }).items)
        ? (parsed as { items: unknown[] }).items
        : [];

    const byVariant = new Map<number, CartItem>();
    for (const row of rows) {
      const line = normalizeLine(row);
      if (!line) continue;
      const existing = byVariant.get(line.variant.id);
      if (existing) {
        byVariant.set(
          line.variant.id,
          setGuestLineQuantity(existing, existing.quantity + line.quantity),
        );
      } else {
        byVariant.set(line.variant.id, line);
      }
    }
    return [...byVariant.values()];
  } catch {
    return [];
  }
}

export function writeGuestCartItems(items: CartItem[]): void {
  try {
    if (items.length === 0) {
      localStorage.removeItem(GUEST_CART_KEY);
      return;
    }
    localStorage.setItem(GUEST_CART_KEY, JSON.stringify(items));
  } catch {
    /* Private mode / quota: the in-memory cart still works for this page. */
  }
}

export function clearGuestCart(): void {
  try {
    localStorage.removeItem(GUEST_CART_KEY);
  } catch {
    /* storage unavailable */
  }
}

export function guestCart(items: CartItem[]): Cart {
  const subtotal = items.reduce((sum, item) => sum + Number(item.line_total), 0);
  return {
    id: "guest",
    items,
    total_items: items.reduce((sum, item) => sum + item.quantity, 0),
    subtotal: money(subtotal),
  };
}

export function readGuestCart(): Cart | null {
  const items = readGuestCartItems();
  return items.length > 0 ? guestCart(items) : null;
}

export function guestLine(
  variantId: number,
  quantity: number,
  snapshot?: GuestVariantSnapshot,
): CartItem {
  const price = snapshot?.price ?? "0";
  const qty = clampQuantity(quantity);
  const attributes: Record<string, unknown> = {};
  if (snapshot?.productName) attributes.product_name = snapshot.productName;
  if (snapshot?.productSlug) attributes.product_slug = snapshot.productSlug;
  if (snapshot?.image) attributes.image = snapshot.image;

  return {
    id: variantId,
    variant: {
      id: variantId,
      name: snapshot?.name ?? snapshot?.productName ?? `Item ${variantId}`,
      sku: snapshot?.sku ?? "",
      price,
      ...(Object.keys(attributes).length > 0 ? { attributes } : {}),
      in_stock: snapshot?.inStock ?? null,
      stock_quantity: snapshot?.stockQuantity ?? null,
    },
    quantity: qty,
    line_total: lineTotal(price, qty),
    tenant_id: snapshot?.tenantId ?? null,
    seller_name: snapshot?.sellerName ?? "EASYGET",
  };
}
