import { useEffect, useMemo, useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import {
  createProduct,
  deleteProduct,
  deleteProductImage,
  errText,
  getProduct,
  listAllProducts,
  listCategories,
  mediaSrc,
  setPrimaryProductImage,
  toImageDisplay,
  updateProduct,
  updateProductImage,
  uploadProductImage,
  DEFAULT_IMAGE_DISPLAY,
  type ImageDisplay,
  type Product,
  type ProductImage,
} from "../services/api";
import ImageDisplayEditor, {
  imageFxClass,
  imageFxStyle,
} from "../components/ImageDisplayEditor";
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
  const queryClient = useQueryClient();
  const [query, setQuery] = useState("");
  const [filterCategory, setFilterCategory] = useState("");
  const [editing, setEditing] = useState<Product | null>(null);
  const [creating, setCreating] = useState(false);
  const [draft, setDraft] = useState<Draft>(emptyDraft);
  const [busy, setBusy] = useState(false);
  const [deleting, setDeleting] = useState<Product | null>(null);
  const [images, setImages] = useState<ProductImage[]>([]);
  const [variantId, setVariantId] = useState<number | null>(null);
  const [imgBusy, setImgBusy] = useState(false);
  const [editImage, setEditImage] = useState<ProductImage | null>(null);
  const [editDraft, setEditDraft] = useState<ImageDisplay>(DEFAULT_IMAGE_DISPLAY);
  const [editCaption, setEditCaption] = useState("");
  const [editSaving, setEditSaving] = useState(false);

  const productsQuery = useQuery({
    queryKey: ["admin", "products"],
    queryFn: () => listAllProducts(),
  });
  const categoriesQuery = useQuery({
    queryKey: ["admin", "categories"],
    queryFn: async () => toArray(await listCategories()),
  });

  const products = productsQuery.data ?? null;
  const categories = categoriesQuery.data ?? [];

  useEffect(() => {
    const e = productsQuery.error ?? categoriesQuery.error;
    if (e) push(e?.message ?? "Failed to load products", "err");
  }, [productsQuery.error, categoriesQuery.error, push]);

  const categoryById = useMemo(
    () => new Map(categories.map((c) => [c.id, c])),
    [categories],
  );

  function openCreate() {
    setDraft({ ...emptyDraft, category: categories[0]?.id ?? "" });
    setImages([]);
    setVariantId(null);
    setCreating(true);
  }

  function openEdit(p: Product) {
    setEditing(p);
    setImages([]);
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
    getProduct(p.slug)
      .then((detail) => {
        setImages(detail.images ?? []);
        setVariantId(detail.variants?.[0]?.id ?? null);
      })
      .catch((e) => push(errText(e, "Couldn't load images"), "err"));
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
    // On create add one default variant; on edit, route a price change to the
    // existing variant by id (the API updates in place instead of duplicating).
    // If the product was created without a price it has no variants yet — send
    // one without an id and the API creates it.
    if (creating && draft.price) {
      body.variants = [{ name: "1 unit", price: draft.price, is_active: true }];
    } else if (editing && draft.price) {
      body.variants =
        variantId != null
          ? [{ id: variantId, price: draft.price }]
          : [{ name: "1 unit", price: draft.price, is_active: true }];
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
      await queryClient.invalidateQueries({ queryKey: ["admin", "products"] });
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
      await queryClient.invalidateQueries({ queryKey: ["admin", "products"] });
    } catch (e) {
      push(errText(e, "Delete failed"), "err");
      setDeleting(null);
    } finally {
      setBusy(false);
    }
  }

  async function uploadImage(file: File) {
    if (!editing) return;
    setImgBusy(true);
    try {
      const img = await uploadProductImage(editing.slug, file);
      setImages((list) => [...list, img]);
      push("Image added");
      await queryClient.invalidateQueries({ queryKey: ["admin", "products"] });
    } catch (e) {
      push(errText(e, "Upload failed"), "err");
    } finally {
      setImgBusy(false);
    }
  }

  async function makePrimary(img: ProductImage) {
    if (img.is_primary || imgBusy) return;
    setImgBusy(true);
    try {
      await setPrimaryProductImage(img.id);
      setImages((list) => list.map((i) => ({ ...i, is_primary: i.id === img.id })));
      await queryClient.invalidateQueries({ queryKey: ["admin", "products"] });
    } catch (e) {
      push(errText(e, "Couldn't change primary"), "err");
    } finally {
      setImgBusy(false);
    }
  }

  async function removeImage(img: ProductImage) {
    if (imgBusy) return;
    setImgBusy(true);
    try {
      await deleteProductImage(img.id);
      setImages((list) => {
        const next = list.filter((i) => i.id !== img.id);
        if (img.is_primary && next.length) {
          const first = [...next].sort(
            (a, b) => a.sort_order - b.sort_order || a.id - b.id,
          )[0];
          return next.map((i) => ({ ...i, is_primary: i.id === first.id }));
        }
        return next;
      });
      push("Image removed");
      await queryClient.invalidateQueries({ queryKey: ["admin", "products"] });
    } catch (e) {
      push(errText(e, "Remove failed"), "err");
    } finally {
      setImgBusy(false);
    }
  }

  function openImageEditor(img: ProductImage) {
    setEditImage(img);
    setEditDraft(toImageDisplay(img));
    setEditCaption(img.caption ?? "");
  }

  async function saveImageEditor() {
    if (!editImage || editSaving) return;
    setEditSaving(true);
    try {
      const updated = await updateProductImage(editImage.id, {
        caption: editCaption,
        align_x: editDraft.align_x,
        align_y: editDraft.align_y,
        zoom: editDraft.zoom,
        effect: editDraft.effect,
        transition_ms: editDraft.transition_ms,
      });
      setImages((list) => list.map((i) => (i.id === updated.id ? updated : i)));
      setEditImage(null);
      push("Image updated");
      await queryClient.invalidateQueries({ queryKey: ["admin", "products"] });
    } catch (e) {
      push(errText(e, "Update failed"), "err");
    } finally {
      setEditSaving(false);
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
            <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(170px, 1fr))", gap: 14 }}>
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
          <div style={{ marginTop: 18 }}>
            <div className="muted" style={{ fontWeight: 700, marginBottom: 8 }}>
              Images
            </div>
            {!editing ? (
              <p className="muted" style={{ margin: 0, fontSize: 13 }}>
                Save the product first, then edit it to add images.
              </p>
            ) : (
              <>
                <div className="prod-gallery">
                  {images.map((img) => {
                    const src = mediaSrc(img.image);
                    return (
                      <div
                        key={img.id}
                        className={`prod-img-tile ${imageFxClass(img)} ${
                          img.is_primary ? "primary" : ""
                        }`}
                      >
                        {src ? (
                          <img
                            src={src}
                            alt=""
                            decoding="async"
                            style={imageFxStyle(img)}
                          />
                        ) : (
                          <div className="prod-img-empty">?</div>
                        )}
                        <div className="prod-img-overlay">
                          <button
                            type="button"
                            title="Edit align / zoom / effect"
                            onClick={() => openImageEditor(img)}
                            disabled={imgBusy}
                          >
                            ✎
                          </button>
                          <button
                            type="button"
                            title={img.is_primary ? "Primary image" : "Make primary"}
                            onClick={() => makePrimary(img)}
                            disabled={img.is_primary || imgBusy}
                          >
                            {img.is_primary ? "★" : "☆"}
                          </button>
                          <button
                            type="button"
                            title="Remove image"
                            onClick={() => removeImage(img)}
                            disabled={imgBusy}
                          >
                            ✕
                          </button>
                        </div>
                        {img.is_primary && <span className="prod-img-badge">Primary</span>}
                      </div>
                    );
                  })}
                  <label
                    className={`prod-img-tile prod-img-add ${imgBusy ? "busy" : ""}`}
                    title="Upload image"
                  >
                    {imgBusy ? "…" : "+"}
                    <input
                      type="file"
                      accept="image/*"
                      style={{ display: "none" }}
                      disabled={imgBusy}
                      onChange={(e) => {
                        const file = e.target.files?.[0] ?? null;
                        e.target.value = "";
                        if (file) void uploadImage(file);
                      }}
                    />
                  </label>
                </div>
                <p className="muted" style={{ margin: "8px 0 0", fontSize: 12.5 }}>
                  Uploads are compressed to WebP (max 800px). The starred image is
                  the one shown on product cards.
                </p>
                {editImage && (
                  <div className="ide-panel">
                    <div className="ide-panel-head">
                      <strong>Edit image</strong>
                      <button
                        type="button"
                        className="btn btn-sm btn-ghost"
                        onClick={() => setEditImage(null)}
                      >
                        Close
                      </button>
                    </div>
                    <ImageDisplayEditor
                      src={mediaSrc(editImage.image)}
                      value={editDraft}
                      onChange={(patch) =>
                        setEditDraft((d) => ({ ...d, ...patch }))
                      }
                    />
                    <label
                      style={{
                        display: "grid",
                        gap: 6,
                        fontSize: 12.5,
                        fontWeight: 700,
                        color: "var(--text-faint)",
                      }}
                    >
                      Caption
                      <input
                        className="input"
                        value={editCaption}
                        maxLength={200}
                        placeholder="Optional description for this angle"
                        onChange={(e) => setEditCaption(e.target.value)}
                      />
                    </label>
                    <div className="modal-actions">
                      <button
                        type="button"
                        className="btn btn-ghost"
                        onClick={() => setEditImage(null)}
                      >
                        Cancel
                      </button>
                      <button
                        type="button"
                        className="btn btn-primary"
                        disabled={editSaving}
                        onClick={() => void saveImageEditor()}
                      >
                        {editSaving ? "Saving…" : "Save image"}
                      </button>
                    </div>
                  </div>
                )}
              </>
            )}
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
