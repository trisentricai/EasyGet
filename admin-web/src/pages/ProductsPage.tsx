import { useCallback, useEffect, useMemo, useState } from "react";
import {
  createProduct,
  deleteProduct,
  errText,
  listCategories,
  listProducts,
  updateProduct,
  type Category,
  type Product,
} from "../services/api";
import { useToast } from "../context/ToastContext";
import { Card, ConfirmDialog, EmptyState, Modal, Spinner } from "../components/ui";

type Draft = {
  name: string;
  category: number | "";
  description: string;
  brand: string;
  mrp: string;
  price: string;
  is_active: boolean;
  is_featured: boolean;
};

const emptyDraft: Draft = {
  name: "",
  category: "",
  description: "",
  brand: "",
  mrp: "",
  price: "",
  is_active: true,
  is_featured: false,
};

function toArray<T>(res: { results: T[] } | T[]): T[] {
  return Array.isArray(res) ? res : res.results;
}

export function ProductsPage() {
  const { push } = useToast();
  const [products, setProducts] = useState<Product[] | null>(null);
  const [categories, setCategories] = useState<Category[]>([]);
  const [query, setQuery] = useState("");
  const [filterCategory, setFilterCategory] = useState("");
  const [editing, setEditing] = useState<Product | null>(null);
  const [creating, setCreating] = useState(false);
  const [draft, setDraft] = useState<Draft>(emptyDraft);
  const [busy, setBusy] = useState(false);
  const [deleting, setDeleting] = useState<Product | null>(null);

  const load = useCallback(async () => {
    const [p, c] = await Promise.all([listProducts(), listCategories()]);
    setProducts(toArray(p));
    setCategories(toArray(c));
  }, []);

  useEffect(() => {
    load().catch((e) => push(e?.message ?? "Failed to load products", "err"));
  }, [load, push]);

  const categoryById = useMemo(
    () => new Map(categories.map((c) => [c.id, c])),
    [categories],
  );

  function openCreate() {
    setDraft({ ...emptyDraft, category: categories[0]?.id ?? "" });
    setCreating(true);
  }

  function openEdit(p: Product) {
    setEditing(p);
    setDraft({
      name: p.name,
      category: p.category?.id ?? "",
      description: "",
      brand: p.brand ?? "",
      mrp: p.mrp ?? "",
      price: p.base_price ?? "",
      is_active: p.is_active,
      is_featured: p.is_featured,
    });
  }

  function buildBody() {
    const body: Record<string, unknown> = {
      name: draft.name.trim(),
      category: Number(draft.category),
      is_active: draft.is_active,
      is_featured: draft.is_featured,
    };
    if (draft.description) body.description = draft.description;
    if (draft.brand) body.brand = draft.brand;
    if (draft.mrp) body.mrp = draft.mrp;
    // Keep existing variants on edit; on create add one default variant.
    if (creating && draft.price) {
      body.variants = [{ name: "1 unit", price: draft.price, is_active: true }];
    }
    return body;
  }

  async function save() {
    if (!draft.name.trim() || !draft.category) return;
    setBusy(true);
    try {
      if (editing) {
        await updateProduct(editing.slug, buildBody());
        push(`“${draft.name}” updated`);
      } else {
        await createProduct(buildBody());
        push(`“${draft.name}” created`);
      }
      setCreating(false);
      setEditing(null);
      await load();
    } catch (e) {
      push(errText(e, "Save failed"), "err");
    } finally {
      setBusy(false);
    }
  }

  async function confirmDelete() {
    if (!deleting) return;
    setBusy(true);
    try {
      await deleteProduct(deleting.slug);
      push(`“${deleting.name}” deleted`);
      setDeleting(null);
      await load();
    } catch (e) {
      push(errText(e, "Delete failed"), "err");
      setDeleting(null);
    } finally {
      setBusy(false);
    }
  }

  const filtered = (products ?? []).filter((p) => {
    const matchesQuery = p.name.toLowerCase().includes(query.toLowerCase());
    const matchesCategory = !filterCategory || p.category?.slug === filterCategory;
    return matchesQuery && matchesCategory;
  });

  return (
    <div>
      <div className="toolbar">
        <input
          className="input"
          placeholder="Search products…"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
        <select
          className="input"
          style={{ maxWidth: 220 }}
          value={filterCategory}
          onChange={(e) => setFilterCategory(e.target.value)}
        >
          <option value="">All categories</option>
          {categories.map((c) => (
            <option key={c.id} value={c.slug}>
              {c.name}
            </option>
          ))}
        </select>
        <div className="spacer" />
        <button className="btn btn-primary" onClick={openCreate} disabled={categories.length === 0}>
          + New product
        </button>
      </div>

      <Card>
        {products === null ? (
          <Spinner />
        ) : filtered.length === 0 ? (
          <EmptyState text="No products found — create one or adjust filters." />
        ) : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Product</th>
                  <th>Category</th>
                  <th>MRP</th>
                  <th>Selling price</th>
                  <th>Flags</th>
                  <th style={{ width: 180 }} />
                </tr>
              </thead>
              <tbody>
                {filtered.map((p) => (
                  <tr key={p.id}>
                    <td>
                      <div style={{ fontWeight: 700 }}>{p.name}</div>
                      <div className="muted" style={{ fontSize: 12.5 }}>
                        {p.slug}
                      </div>
                    </td>
                    <td>{p.category?.name}</td>
                    <td>{p.mrp ? `₹${p.mrp}` : "—"}</td>
                    <td style={{ fontWeight: 700 }}>{p.base_price ? `₹${p.base_price}` : "—"}</td>
                    <td>
                      <div style={{ display: "flex", gap: 6, flexWrap: "wrap" }}>
                        {!p.is_active && <span className="badge err">Hidden</span>}
                        {p.is_featured && <span className="badge warn">Featured</span>}
                        {p.is_active && !p.is_featured && <span className="badge ok">Live</span>}
                      </div>
                    </td>
                    <td>
                      <div style={{ display: "flex", gap: 8, justifyContent: "flex-end" }}>
                        <button className="btn btn-sm btn-ghost" onClick={() => openEdit(p)}>
                          Edit
                        </button>
                        <button className="btn btn-sm btn-danger" onClick={() => setDeleting(p)}>
                          Delete
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

      {(creating || editing) && (
        <Modal
          title={editing ? `Edit “${editing.name}”` : "New product"}
          subtitle={
            creating
              ? "A default “1 unit” variant is created with your selling price."
              : "Price/variant editing refines stock items automatically on the storefront."
          }
          onClose={() => {
            setCreating(false);
            setEditing(null);
          }}
        >
          <div className="form-grid">
            <label>
              Name
              <input
                className="input"
                autoFocus
                value={draft.name}
                onChange={(e) => setDraft({ ...draft, name: e.target.value })}
                placeholder="e.g. Basmati Rice 5kg"
              />
            </label>
            <label>
              Category
              <select
                className="input"
                value={draft.category}
                onChange={(e) => setDraft({ ...draft, category: e.target.value ? Number(e.target.value) : "" })}
              >
                <option value="">Choose…</option>
                {categories.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                  </option>
                ))}
              </select>
            </label>
            <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14 }}>
              <label>
                MRP (₹)
                <input
                  className="input"
                  type="number"
                  min="0"
                  step="0.01"
                  value={draft.mrp}
                  onChange={(e) => setDraft({ ...draft, mrp: e.target.value })}
                />
              </label>
              <label>
                Selling price (₹)
                <input
                  className="input"
                  type="number"
                  min="0"
                  step="0.01"
                  value={draft.price}
                  disabled={!creating}
                  onChange={(e) => setDraft({ ...draft, price: e.target.value })}
                />
              </label>
            </div>
            <label>
              Brand
              <input
                className="input"
                value={draft.brand}
                onChange={(e) => setDraft({ ...draft, brand: e.target.value })}
                placeholder="Optional"
              />
            </label>
            <label>
              Description
              <input
                className="input"
                value={draft.description}
                onChange={(e) => setDraft({ ...draft, description: e.target.value })}
                placeholder="Shown on the product page (optional)"
              />
            </label>
            <div style={{ display: "flex", gap: 22 }}>
              <label style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <input
                  type="checkbox"
                  checked={draft.is_active}
                  onChange={(e) => setDraft({ ...draft, is_active: e.target.checked })}
                />
                Active
              </label>
              <label style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <input
                  type="checkbox"
                  checked={draft.is_featured}
                  onChange={(e) => setDraft({ ...draft, is_featured: e.target.checked })}
                />
                Featured
              </label>
            </div>
          </div>
          <div className="modal-actions">
            <button
              className="btn btn-ghost"
              onClick={() => {
                setCreating(false);
                setEditing(null);
              }}
              disabled={busy}
            >
              Cancel
            </button>
            <button
              className="btn btn-primary"
              onClick={save}
              disabled={busy || !draft.name.trim() || !draft.category}
            >
              {busy ? "Saving…" : "Save"}
            </button>
          </div>
        </Modal>
      )}

      {deleting && (
        <ConfirmDialog
          title={`Delete “${deleting.name}”?`}
          message="This removes the product everywhere on the storefront. This cannot be undone."
          onCancel={() => setDeleting(null)}
          onConfirm={confirmDelete}
          busy={busy}
        />
      )}
    </div>
  );
}
