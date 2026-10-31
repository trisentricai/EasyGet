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

  // Catalog for the "Needs stock" section — unstocked products added via the
  // product panel have no StockItem yet, so they never appear in the stock
  // table above. Shares the ["admin","products"] cache key with ProductsPage,
  // so invalidating after a create refreshes this list automatically.
  const productsQuery = useQuery({
    queryKey: ["admin", "products"],
    queryFn: () => listAllProducts(),
  });

  const unstockedProducts = useMemo(() => {
    const rows = productsQuery.data ?? [];
    const q = query.trim().toLowerCase();
    return rows.filter(
      (p) =>
        p.in_stock === false &&
        (!q ||
          p.name.toLowerCase().includes(q) ||
          (p.category?.name ?? "").toLowerCase().includes(q)),
    );
  }, [productsQuery.data, query]);

  const items = itemsQuery.data ?? null;

  useEffect(() => {
    if (itemsQuery.error)
      push(itemsQuery.error?.message ?? "Failed to load inventory", "err");
  }, [itemsQuery.error, push]);

  const reload = () =>
    queryClient.invalidateQueries({ queryKey: ["admin", "inventory"] });

  const filtered = (items ?? []).filter((i) =>
    (i.variant?.sku ?? "").toLowerCase().includes(query.toLowerCase()) ||
    (i.store?.name ?? "").toLowerCase().includes(query.toLowerCase()),
  );

  return (
    <div>
      <div className="toolbar">
        <input
          className="input"
          placeholder="Search by SKU or store…"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
      </div>

      <Card>
        {items === null ? (
          <Spinner />
        ) : filtered.length === 0 ? (
          <EmptyState text="No stock items yet." />
        ) : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Product / SKU</th>
                  <th>Store</th>
                  <th>Price</th>
                  <th>In stock</th>
                  <th>Status</th>
                  <th style={{ width: 160 }} />
                </tr>
              </thead>
              <tbody>
                {filtered.map((i) => (
                  <tr key={i.id}>
                    <td style={{ fontWeight: 700 }}>{i.variant?.sku}</td>
                    <td>{i.store?.name}</td>
                    <td>₹{i.variant?.price}</td>
                    <td>
                      <strong style={{ fontSize: 16 }}>{i.quantity}</strong>
                      <span className="muted" style={{ fontSize: 12.5 }}> / {i.low_stock_threshold} min</span>
                    </td>
                    <td>
                      <span className={`badge ${i.quantity === 0 ? "err" : i.is_low_stock ? "warn" : "ok"}`}>
                        {i.quantity === 0 ? "Out of stock" : i.is_low_stock ? "Low stock" : "Healthy"}
                      </span>
                    </td>
                    <td>
                      <div style={{ display: "flex", justifyContent: "flex-end" }}>
                        <button className="btn btn-sm btn-primary" onClick={() => setAdjusting(i)}>
                          Adjust stock
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

      {unstockedProducts.length > 0 ? (
        <Card>
          <h3 style={{ marginTop: 0 }}>Needs stock</h3>
          <p className="muted" style={{ marginTop: -8 }}>
            Products with <strong>no stock row yet</strong> — added from the product
            panel but never stocked. Add stock and the storefront flips them to
            “In stock” immediately.
          </p>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Product</th>
                  <th>Category</th>
                  <th>Stock</th>
                  <th style={{ width: 160 }} />
                </tr>
              </thead>
              <tbody>
                {unstockedProducts.map((p) => (
                  <tr key={p.id}>
                    <td style={{ fontWeight: 700 }}>{p.name}</td>
                    <td>{p.category?.name ?? "—"}</td>
                    <td>
                      <span className="badge err">No stock</span>
                    </td>
                    <td>
                      <div style={{ display: "flex", justifyContent: "flex-end" }}>
                        <button className="btn btn-sm btn-primary" onClick={() => setAdding(p)}>
                          Add stock
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </Card>
      ) : null}

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

  // Resolve the product's variants (with ids) — list rows don't carry them,
  // detail does; the add-stock create endpoint needs the variant id.
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
  // Single source of truth for storefront stock: the EASYGET platform store.
  // (fallback to slug match for safety; never blindly take stores[0] — that
  // could resolve to the legacy demo store.)
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
      push(`Stock added: ${active.sku} × ${quantity} — now “In stock”.`);
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
            This variant already has a stock row — use “Adjust stock” on the stock table instead.
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
