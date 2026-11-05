import { useEffect, useMemo, useState } from "react";
import { useQuery, useQueryClient, useMutation } from "@tanstack/react-query";
import { api, errText, getProduct, listAllProducts, listStores, bulkUpdateProducts, exportProductsCsv, importProductsCsv, type Product } from "../services/api";
import { useToast } from "../context/ToastContext";
import { Card, EmptyState, Modal, Spinner } from "../components/ui";
import { motion, AnimatePresence } from "framer-motion";
import { Icon } from "../components/icons";
import { BulkDrawer, CsvImportModal } from "../components/BulkDrawer";

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

  // Bulk operations state
  const [selectedIds, setSelectedIds] = useState<Set<number>>(new Set());
  const [bulkDrawerOpen, setBulkDrawerOpen] = useState(false);
  const [bulkAction, setBulkAction] = useState<"price" | "stock">("price");
  const [bulkPriceAction, setBulkPriceAction] = useState<"increase_percent" | "decrease_percent" | "set_flat">("increase_percent");
  const [bulkValue, setBulkValue] = useState("");
  const [csvImportOpen, setCsvImportOpen] = useState(false);
  const [csvFile, setCsvFile] = useState<File | null>(null);
  const [csvImportResult, setCsvImportResult] = useState<{ created: number; updated: number; errors: string[] } | null>(null);

  const reload = async () => {
    await Promise.all([
      queryClient.invalidateQueries({ queryKey: ["admin", "inventory"] }),
      queryClient.invalidateQueries({ queryKey: ["admin", "products"] }),
    ]);
  };

  type BulkBody = {
    product_ids: number[];
    action: "increase_percent" | "decrease_percent" | "set_flat" | "set_stock";
    value: number;
  };

  const bulkUpdateMutation = useMutation<
    { updated: number; message: string },
    unknown,
    BulkBody,
    { previousProducts?: Product[]; previousItems?: StockItem[] }
  >({
    mutationFn: (body) => bulkUpdateProducts(body),
    onMutate: async (body) => {
      // Optimistically adjust the cached rows so the table reacts immediately.
      await queryClient.cancelQueries({ queryKey: ["admin", "products"] });
      await queryClient.cancelQueries({ queryKey: ["admin", "inventory"] });
      const previousProducts = queryClient.getQueryData<Product[]>(["admin", "products"]);
      const previousItems = queryClient.getQueryData<StockItem[]>(["admin", "inventory"]);
      const selected = new Set(body.product_ids);

      if (previousProducts) {
        if (body.action === "set_stock") {
          const variantIds = new Set<number>();
          for (const product of previousProducts) {
            if (!selected.has(product.id)) continue;
            for (const variant of product.variants ?? []) variantIds.add(variant.id);
          }
          if (previousItems) {
            queryClient.setQueryData<StockItem[]>(
              ["admin", "inventory"],
              previousItems.map((item) =>
                variantIds.has(item.variant.id)
                  ? { ...item, quantity: Math.max(0, Math.trunc(body.value)) }
                  : item,
              ),
            );
          }
        } else {
          queryClient.setQueryData<Product[]>(
            ["admin", "products"],
            previousProducts.map((product) => {
              if (!selected.has(product.id) || !product.variants) return product;
              return {
                ...product,
                variants: product.variants.map((variant) => {
                  const current = Number(variant.price) || 0;
                  let next = current;
                  if (body.action === "increase_percent") next = current * (1 + body.value / 100);
                  else if (body.action === "decrease_percent") next = current * (1 - body.value / 100);
                  else next = body.value;
                  return { ...variant, price: Math.max(0, next).toFixed(2) };
                }),
              };
            }),
          );
        }
      }

      return { previousProducts, previousItems };
    },
    onError: (e, _body, context) => {
      if (context?.previousProducts) {
        queryClient.setQueryData(["admin", "products"], context.previousProducts);
      }
      if (context?.previousItems) {
        queryClient.setQueryData(["admin", "inventory"], context.previousItems);
      }
      push(errText(e, "Bulk update failed"), "err");
    },
    onSuccess: (result) => {
      push(result.message || "Bulk update applied");
      setBulkDrawerOpen(false);
      setSelectedIds(new Set());
      setBulkValue("");
    },
    onSettled: () => {
      void reload();
    },
  });

  const csvImportMutation = useMutation<
    { created: number; updated: number; errors: string[] },
    unknown,
    File
  >({
    mutationFn: (file) => importProductsCsv(file),
    onSuccess: (result) => {
      setCsvImportResult(result);
      void reload();
      if (result.errors.length === 0) {
        push(`Imported: ${result.created} created, ${result.updated} updated`);
        setCsvImportOpen(false);
        setCsvFile(null);
      } else {
        push(`${result.errors.length} row(s) failed`, "err");
      }
    },
    onError: (e) => push(errText(e, "Import failed"), "err"),
  });

  const handleSelectAll = () => {
    const allSelected =
      productsWithStock.length > 0 && productsWithStock.every((p) => selectedIds.has(p.id));
    setSelectedIds(allSelected ? new Set() : new Set(productsWithStock.map((p) => p.id)));
  };

  const handleSelect = (id: number) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const handleBulkAction = () => {
    const numeric = Number(bulkValue);
    if (selectedIds.size === 0 || !bulkValue || !Number.isFinite(numeric) || numeric < 0) return;
    const action = bulkAction === "price" ? bulkPriceAction : "set_stock";
    bulkUpdateMutation.mutate({
      product_ids: Array.from(selectedIds),
      action,
      value: numeric,
    });
  };

  const handleCsvExport = async () => {
    try {
      const blob = await exportProductsCsv();
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = "products_export.csv";
      a.click();
      URL.revokeObjectURL(url);
      push("CSV exported successfully");
    } catch (e) {
      push(errText(e, "Export failed"), "err");
    }
  };

  const handleCsvImport = () => {
    if (!csvFile || csvImportMutation.isPending) return;
    csvImportMutation.mutate(csvFile);
  };

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
        <div style={{ display: "flex", gap: 8, marginLeft: "auto" }}>
          <button className="btn btn-sm btn-ghost" onClick={handleCsvExport}>
            <Icon name="download" size={14} /> Export CSV
          </button>
          <button className="btn btn-sm btn-primary" onClick={() => setCsvImportOpen(true)}>
            <Icon name="upload" size={14} /> Import CSV
          </button>
        </div>
      </div>

      {/* Floating action bar for bulk operations */}
      <AnimatePresence>
        {selectedIds.size > 0 && (
          <motion.div
            initial={{ y: 100, opacity: 0, x: "-50%" }}
            animate={{ y: 0, opacity: 1, x: "-50%" }}
            exit={{ y: 100, opacity: 0, x: "-50%" }}
            transition={{ type: "spring", stiffness: 300, damping: 30 }}
            className="bulk-action-bar"
            style={{
              position: "fixed",
              bottom: 24,
              left: "50%",
              zIndex: 100,
              display: "flex",
              alignItems: "center",
              gap: 12,
              padding: "12px 20px",
              background: "var(--bg-elevated)",
              border: "1px solid var(--border)",
              borderRadius: 12,
              boxShadow: "var(--shadow-lg)",
              maxWidth: "calc(100vw - 48px)",
            }}
          >
            <span className="muted" style={{ fontSize: 13.5, fontWeight: 500 }}>
              {selectedIds.size} product{selectedIds.size !== 1 ? "s" : ""} selected
            </span>
            <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
              <button className="btn btn-primary" onClick={() => setBulkDrawerOpen(true)}>
                Apply bulk update
              </button>
              <button className="btn btn-ghost btn-sm" onClick={() => setSelectedIds(new Set())}>
                Clear
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

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
                  <th style={{ width: 40 }}>
                    <input
                      type="checkbox"
                      checked={selectedIds.size === productsWithStock.length && productsWithStock.length > 0}
                      onChange={handleSelectAll}
                      aria-label="Select all"
                    />
                  </th>
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
                    <td style={{ textAlign: "center" }}>
                      <input
                        type="checkbox"
                        checked={selectedIds.has(p.id)}
                        onChange={() => handleSelect(p.id)}
                        aria-label={`Select ${p.name}`}
                      />
                    </td>
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

      {/* Bulk Operations Slide-out Drawer */}
      <BulkDrawer
        isOpen={bulkDrawerOpen}
        onClose={() => setBulkDrawerOpen(false)}
        onApply={handleBulkAction}
        action={bulkAction}
        setAction={setBulkAction}
        priceAction={bulkPriceAction}
        setPriceAction={setBulkPriceAction}
        value={bulkValue}
        setValue={setBulkValue}
        busy={bulkUpdateMutation.isPending}
        selectedCount={selectedIds.size}
      />

      {/* CSV Import Modal */}
      <CsvImportModal
        isOpen={csvImportOpen}
        onClose={() => {
          setCsvImportOpen(false);
          if (!csvImportMutation.isPending) {
            setCsvImportResult(null);
            setCsvFile(null);
          }
        }}
        onImport={handleCsvImport}
        file={csvFile}
        setFile={setCsvFile}
        busy={csvImportMutation.isPending}
        result={csvImportResult}
      />
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