import { useEffect, useMemo, useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { api, errText, getProduct, listAllProducts, listStores, type Product } from "../services/api";
import { useToast } from "../context/ToastContext";
import { Card, EmptyState, Modal, Spinner } from "../components/ui";

type StockItem = {
  id: number;
  store: { id: number; name: string; slug: string };
  variant: { id: number; name: string; sku: string; price: string };
  quantity: number;
  low_stock_threshold: number;
  is_available: boolean;
  is_low_stock: boolean;
  updated_at: string;
};

type ProductWithStock = Product & {
  stockItems: Array<{
    id: number;
    store: { id: number; name: string; slug: string };
    variant: { id: number; name: string; sku: string; price: string };
    quantity: number;
    low_stock_threshold: number;
    is_available: boolean;
    is_low_stock: boolean;
    updated_at: string;
  }>;
  totalQuantity: number;
  isLowStock: boolean;
  isOutOfStock: boolean;
};

function toArray<T>(res: { results: T[] } | T[]): T[] {
  return Array.isArray(res) ? res : res.results;
}

export function InventoryPage() {
  const { push } = useToast();
  const queryClient = useQueryClient();
  const [query, setQuery] = useState("");
  const [adjusting, setAdjusting] = useState<StockItem | null>(null);
  const [adding, setAdding] = useState<Product | null>(null);

  const itemsQuery = useQuery({
    queryKey: ["admin", "inventory"],
    queryFn: async () =>
      toArray(await api<{ results: StockItem[] } | StockItem[]>("/inventory/")),
  });

  const productsQuery = useQuery({
    queryKey: ["admin", "products"],
    queryFn: () => listAllProducts(),
  });

  // Merge products with their stock items
  const productsWithStock = useMemo(() => {
    const stockItems = itemsQuery.data ?? [];
    const products = productsQuery.data ?? [];
    const q = query.trim().toLowerCase();

    // Group stock items by variant ID
    const stockByVariant = new Map<number, StockItem[]>();
    for (const item of stockItems) {
      if (item.variant?.id) {
        const arr = stockByVariant.get(item.variant.id) ?? [];
        arr.push(item);
        stockByVariant.set(item.variant.id, arr);
      }
    }

    return products
      .filter((p) => {
        if (!q) return true;
        return (
          p.name.toLowerCase().includes(q) ||
          (p.category?.name ?? "").toLowerCase().includes(q) ||
          (p.slug ?? "").toLowerCase().includes(q)
        );
      })
      .map((p): ProductWithStock => {
        const variantIds = (p.variants ?? []).map((v: { id: number }) => v.id);
        const stockItemsForProduct = variantIds.flatMap((id: number) =>
          stockByVariant.get(id) ?? [],
        );
        const totalQuantity = stockItemsForProduct.reduce(
          (sum: number, i: StockItem) => sum + i.quantity,
          0,
        );
        const isLowStock = stockItemsForProduct.some(
          (i: StockItem) => i.is_low_stock && i.quantity > 0,
        );
        const isOutOfStock = totalQuantity === 0;

        return {
          ...p,
          stockItems: stockItemsForProduct,
          totalQuantity,
          isLowStock,
          isOutOfStock,
        };
      });
  }, [itemsQuery.data, productsQuery.data, query]);

  useEffect(() => {
    if (itemsQuery.error)
      push(itemsQuery.error?.message ?? "Failed to load inventory", "err");
  }, [itemsQuery.error, push]);

  useEffect(() => {
    if (productsQuery.error)
      push(productsQuery.error?.message ?? "Failed to load products", "err");
  }, [productsQuery.error, push]);

  const reload = () =>
    queryClient.invalidateQueries({ queryKey: ["admin", "inventory"] });

  const loading = itemsQuery.isLoading || productsQuery.isLoading;

  return (
    <div>
      <div className="toolbar">
        <input
          className="input"
          placeholder="Search by name, SKU, or category…"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
        <span className="muted" style={{ marginLeft: 12 }}>
          {productsWithStock.length} product{productsWithStock.length !== 1 ? "s" : ""}
        </span>
      </div>

      <Card>
        {loading ? (
          <Spinner />
        ) : productsWithStock.length === 0 ? (
          <EmptyState text="No products found." />
        ) : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Product</th>
                  <th>Category</th>
                  <th>SKU</th>
                  <th>Price</th>
                  <th>Total Stock</th>
                  <th>Status</th>
                  <th style={{ width: 180 }} />
                </tr>
              </thead>
              <tbody>
                {productsWithStock.map((p) => (
                  <tr key={p.id}>
                    <td>
                      <div style={{ fontWeight: 700 }}>
                        {p.name}
                        {p.is_demo && (
                          <span
                            className="badge"
                            style={{
                              marginLeft: 8,
                              background: "var(--c-accent)",
                              color: "#fff",
                              fontSize: 10.5,
                            }}
                          >
                            Demo
                          </span>
                        )}
                        {!p.is_demo && (
                          <span
                            className="badge"
                            style={{
                              marginLeft: 8,
                              background: "var(--c-primary)",
                              color: "#fff",
                              fontSize: 10.5,
                            }}
                          >
                            Manual
                          </span>
                        )}
                      </div>
                      <div className="muted" style={{ fontSize: 12.5 }}>
                        {p.slug}
                      </div>
                    </td>
                    <td>{p.category?.name ?? "—"}</td>
                    <td>
                      {p.variants?.map((v) => (
                        <div key={v.id} className="muted" style={{ fontSize: 12.5 }}>
                          {v.sku ?? v.name}
                        </div>
                      ))}
                    </td>
                    <td>
                      {p.variants?.map((v) => (
                        <div key={v.id} style={{ fontWeight: 600, fontSize: 13 }}>
                          ₹{v.price}
                        </div>
                      ))}
                    </td>
                    <td>
                      <strong style={{ fontSize: 16 }}>
                        {p.totalQuantity > 0 ? p.totalQuantity : "0"}
                      </strong>
                      {p.stockItems.length > 0 && (
                        <span className="muted" style={{ fontSize: 12.5 }}>
                          {" "}
                          across {p.stockItems.length} store{p.stockItems.length > 1 ? "s" : ""}
                        </span>
                      )}
                    </td>
                    <td>
                      {p.isOutOfStock ? (
                        <span className="badge err">Out of Stock</span>
                      ) : p.isLowStock ? (
                        <span className="badge warn">Low Stock</span>
                      ) : (
                        <span className="badge ok">In Stock</span>
                      )}
                    </td>
                    <td>
                      <div style={{ display: "flex", gap: 8, justifyContent: "flex-end" }}>
                        {p.stockItems.length > 0 && (
                          <button
                            className="btn btn-sm btn-primary"
                            onClick={() => setAdjusting(p.stockItems[0])}
                          >
                            Adjust stock
                          </button>
                        )}
                        <button
                          className="btn btn-sm btn-primary"
                          onClick={() => setAdding(p)}
                        >
                          {p.stockItems.length > 0 ? "Add more stock" : "Add stock"}
                        </button>
                        <button
                          className="btn btn-sm btn-ghost"
                          onClick={() => {
                            // Navigate to products page to edit
                            window.location.hash = `#/products`;
                            // Could also use navigate if we had router context
                          }}
                        >
                          Edit product
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {adjusting && (
        <AdjustModal
          item={adjusting}
          onClose={() => setAdjusting(null)}
          onDone={async () => {
            setAdjusting(null);
            await reload();
          }}
        />
      )}

      {adding && <AddStockModal product={adding} onClose={() => setAdding(null)} />}
    </div>
  );
}

function AdjustModal({
  item,
  onClose,
  onDone,
}: {
  item: StockItem;
  onClose: () => void;
  onDone: () => Promise<void> | void;
}) {
  const { push } = useToast();
  const [change, setChange] = useState<number>(10);
  const [reason, setReason] = useState("RESTOCK");
  const [note, setNote] = useState("");
  const [busy, setBusy] = useState(false);

  async function submit() {
    setBusy(true);
    try {
      await api(`/inventory/${item.id}/adjust/`, {
        method: "POST",
        body: { change, reason, note },
      });
      push(`Stock ${change > 0 ? "+" : ""}${change} saved for ${item.variant?.sku}`);
      await onDone();
    } catch (e) {
      push(errText(e, "Adjustment failed"), "err");
    } finally {
      setBusy(false);
    }
  }

  const quick: Array<{ label: string; delta: number }> = [
    { label: "−10", delta: -10 },
    { label: "−1", delta: -1 },
    { label: "+1", delta: 1 },
    { label: "+10", delta: 10 },
    { label: "+50", delta: 50 },
  ];

  return (
    <Modal title={`Adjust stock · ${item.variant?.sku}`} subtitle={`Current quantity: ${item.quantity}`} onClose={onClose}>
      <div className="form-grid">
        <div>
          <div className="muted" style={{ fontWeight: 700, marginBottom: 8 }}>
            Change
          </div>
          <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
            {quick.map((q) => (
              <button
                key={q.label}
                type="button"
                className={`effect-pill ${change === q.delta ? "on" : ""}`}
                onClick={() => setChange(q.delta)}
              >
                {q.label}
              </button>
            ))}
            <input
              className="input"
              type="number"
              style={{ maxWidth: 110 }}
              value={change}
              onChange={(e) => setChange(Number(e.target.value))}
            />
          </div>
        </div>
        <label>
          Reason
          <select className="input" value={reason} onChange={(e) => setReason(e.target.value)}>
            <option value="RESTOCK">Restock</option>
            <option value="SALE">Sale</option>
            <option value="ADJUSTMENT">Adjustment</option>
            <option value="DAMAGE">Damage</option>
            <option value="RETURN">Return</option>
          </select>
        </label>
        <label>
          Note
          <input
            className="input"
            value={note}
            onChange={(e) => setNote(e.target.value)}
            placeholder="Optional note for the audit trail"
          />
        </label>
        <p className="muted">
          Resulting quantity: <strong>{item.quantity + change}</strong>
          {item.quantity + change < 0 ? " — below zero is not allowed" : ""}
        </p>
      </div>
      <div className="modal-actions">
        <button className="btn btn-ghost" onClick={onClose} disabled={busy}>
          Cancel
        </button>
        <button
          className="btn btn-primary"
          onClick={submit}
          disabled={busy || change === 0 || item.quantity + change < 0}
        >
          {busy ? "Saving…" : "Apply adjustment"}
        </button>
      </div>
    </Modal>
  );
}

function AddStockModal({
  product,
  onClose,
}: {
  product: Product;
  onClose: () => void;
}) {
  const { push } = useToast();
  const queryClient = useQueryClient();
  const itemsQuery = useQuery({
    queryKey: ["admin", "inventory"],
    queryFn: async () =>
      toArray(await api<{ results: StockItem[] } | StockItem[]>("/inventory/")),
  });
  const storesQuery = useQuery({
    queryKey: ["admin", "stores"],
    queryFn: async () => toArray(await listStores()),
  });
  const [quantity, setQuantity] = useState(10);
  const [storeId, setStoreId] = useState<number | null>(null);
  const [busy, setBusy] = useState(false);
  const [variants, setVariants] = useState<
    Array<{ id: number; name: string; sku: string; price: string; is_active?: boolean }>
  >([]);

  // Resolve the product's variants (with ids)
  useEffect(() => {
    let alive = true;
    getProduct(product.slug)
      .then((d) => {
        if (!alive) return;
        setVariants(
          (d.variants ?? []).map((v) => ({
            id: v.id,
            name: v.name,
            sku: (v as { sku?: string }).sku ?? "",
            price: v.price,
            is_active: (v as { is_active?: boolean }).is_active ?? true,
          })),
        );
      })
      .catch(() => {
        if (alive) setVariants([]);
      });
    return () => {
      alive = false;
    };
  }, [product.slug]);

  const active = variants.find((v) => v.is_active) ?? variants[0];
  const stores = storesQuery.data ?? [];
  const platformStore =
    stores.find((s) => s.is_platform) ?? stores.find((s) => s.slug === "easyget") ?? null;
  const effectiveStoreId = storeId ?? platformStore?.id ?? null;
  const existing = active
    ? (itemsQuery.data ?? []).some((i) => i.variant?.id === active.id)
    : false;

  async function submit() {
    if (!active || busy || existing) return;
    const store = stores.find((s) => s.id === effectiveStoreId) ?? platformStore ?? null;
    if (!store) {
      push("Couldn't resolve a store for this product", "err");
      return;
    }
    setBusy(true);
    try {
      await api("/inventory/", {
        method: "POST",
        body: { store: store.id, variant: active.id, quantity },
      });
      await queryClient.invalidateQueries({ queryKey: ["admin", "inventory"] });
      await queryClient.invalidateQueries({ queryKey: ["admin", "products"] });
      push(`Stock added: ${active.sku} × ${quantity} — now "In stock".`);
      onClose();
    } catch (e) {
      push(errText(e, "Couldn't add stock"), "err");
    } finally {
      setBusy(false);
    }
  }

  return (
    <Modal
      title={`Add stock · ${product.name}`}
      subtitle={active ? `${active.name} · ${active.sku} · ₹${active.price}` : "Loading variant…"}
      onClose={onClose}
    >
      <div className="form-grid">
        <label>
          Variant
          <input className="input" value={active ? `${active.name} (${active.sku})` : "Loading…"} readOnly />
        </label>
        <label>
          Store
          <select
            className="input"
            value={effectiveStoreId ?? ""}
            onChange={(e) => setStoreId(Number(e.target.value))}
            disabled={busy || stores.length === 0}
          >
            {stores.length === 0 ? <option value="">No stores found</option> : null}
            {stores.map((s) => (
              <option key={s.id} value={s.id}>
                {s.name}
                {s.is_platform ? " (platform)" : ""}
              </option>
            ))}
          </select>
        </label>
        <label>
          Quantity
          <input
            className="input"
            type="number"
            min={1}
            value={quantity}
            onChange={(e) => setQuantity(Math.max(1, Number(e.target.value) || 1))}
          />
        </label>
        {existing ? (
          <p className="muted">
            This variant already has a stock row — use "Adjust stock" on the stock table instead.
          </p>
        ) : null}
      </div>
      <div className="modal-actions">
        <button className="btn btn-ghost" onClick={onClose} disabled={busy}>
          Cancel
        </button>
        <button className="btn btn-primary" onClick={submit} disabled={busy || !active || existing}>
          {busy ? "Saving…" : "Add stock"}
        </button>
      </div>
    </Modal>
  );
}

export type { Product };