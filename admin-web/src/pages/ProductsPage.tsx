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
  is_active: boolean;
  is_featured: boolean;
};

type VariantRow = {
  id: number | null;
  name: string;
  price: string;
  is_active: boolean;
};

const emptyDraft: Draft = {
  name: "",
  category: "",
  description: "",
  brand: "",
  mrp: "",
  is_active: true,
  is_featured: false,
};

/** Quick-add names, grouped the way grocery catalogs think: weight, volume, count. */
const VARIANT_PRESETS = ["250g", "500g", "1kg", "150ml", "300ml", "500ml", "1L", "Pack of 2"];

const blankVariant = (name = "1 unit"): VariantRow => ({ id: null, name, price: "", is_active: true });

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
  const [variants, setVariants] = useState<VariantRow[]>([blankVariant()]);
  const [stagedFiles, setStagedFiles] = useState<File[]>([]);
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
    setVariants([blankVariant()]);
    setStagedFiles([]);
    setCreating(true);
  }

  function openEdit(p: Product) {
    setEditing(p);
    setImages([]);
    setVariants([]);
    setDraft({
      name: p.name,
      category: p.category?.id ?? "",
      description: "",
      brand: p.brand ?? "",
      mrp: p.mrp ?? "",
      is_active: p.is_active,
      is_featured: p.is_featured,
    });
    getProduct(p.slug)
      .then((detail) => {
        setImages(detail.images ?? []);
        const rows = (detail.variants ?? []).map((v) => ({
          id: v.id as number,
          name: v.name,
          price: v.price ?? "",
          is_active: (v as { is_active?: boolean }).is_active ?? true,
        }));
        setVariants(rows.length ? rows : [blankVariant()]);
      })
      .catch((e) => push(errText(e, "Couldn't load details"), "err"));
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
    // Variants round-trip by id (update in place); rows without an id are
    // created. Empty-price rows are skipped, never sent.
    const priced = variants
      .filter((v) => v.price !== "")
      .map((v) => ({
        ...(v.id != null ? { id: v.id } : {}),
        name: v.name.trim() || "1 unit",
        price: v.price,
        is_active: v.is_active,
      }));
    if (priced.length) body.variants = priced;
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
        const created = await createProduct(buildBody());
        let uploaded = 0;
        let failed = 0;
        for (const file of stagedFiles) {
          try {
            await uploadProductImage(created.slug, file);
            uploaded += 1;
          } catch {
            failed += 1;
          }
        }
        push(
          `“${draft.name}” created` +
            (uploaded ? ` with ${uploaded} image${uploaded > 1 ? "s" : ""}` : "") +
            (failed ? ` (${failed} image${failed > 1 ? "s" : ""} failed to upload)` : ""),
        );
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
              ? "Add variants, then attach images — everything uploads on Save."
              : "Variants update in place by id; images save instantly below."
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
            </div>
            <div style={{ gridColumn: "1 / -1" }}>
              <div className="muted" style={{ fontWeight: 700, marginBottom: 8 }}>
                Variants — packs &amp; sizes (e.g. 250g, 500ml, 1L)
              </div>
              {variants.map((v, i) => (
                <div
                  key={v.id ?? `new-${i}`}
                  style={{ display: "grid", gridTemplateColumns: "1fr 130px auto auto", gap: 8, marginBottom: 8, alignItems: "center" }}
                >
                  <input
                    className="input"
                    value={v.name}
                    onChange={(e) =>
                      setVariants((list) => list.map((row, j) => (j === i ? { ...row, name: e.target.value } : row)))
                    }
                    placeholder="1 unit"
                    aria-label="Variant name"
                  />
                  <input
                    className="input"
                    type="number"
                    min="0"
                    step="0.01"
                    value={v.price}
                    onChange={(e) =>
                      setVariants((list) => list.map((row, j) => (j === i ? { ...row, price: e.target.value } : row)))
                    }
                    placeholder="₹ price"
                    aria-label="Variant price"
                  />
                  <label className="muted" style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 12.5 }}>
                    <input
                      type="checkbox"
                      checked={v.is_active}
                      onChange={(e) =>
                        setVariants((list) => list.map((row, j) => (j === i ? { ...row, is_active: e.target.checked } : row)))
                      }
                    />
                    Live
                  </label>
                  <button
                    type="button"
                    className="btn btn-sm btn-ghost"
                    onClick={() => setVariants((list) => list.filter((_, j) => j !== i))}
                    title="Remove row"
                  >
                    ✕
                  </button>
                </div>
              ))}
              <div style={{ display: "flex", gap: 6, flexWrap: "wrap", alignItems: "center" }}>
                <button
                  type="button"
                  className="btn btn-sm btn-ghost"
                  onClick={() => setVariants((list) => [...list, blankVariant()])}
                >
                  + Add variant
                </button>
                {VARIANT_PRESETS.map((preset) => (
                  <button
                    key={preset}
                    type="button"
                    className="btn btn-sm btn-ghost"
                    title={`Add ${preset} variant`}
                    onClick={() => setVariants((list) => [...list, blankVariant(preset)])}
                  >
                    {preset}
                  </button>
                ))}
              </div>
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
              <>
                <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
                  <label className="btn btn-sm btn-ghost" style={{ cursor: "pointer" }}>
                    + Attach images
                    <input
                      type="file"
                      accept="image/*"
                      multiple
                      style={{ display: "none" }}
                      onChange={(e) => {
                        const files = Array.from(e.target.files ?? []);
                        e.target.value = "";
                        if (files.length) setStagedFiles((list) => [...list, ...files]);
                      }}
                    />
                  </label>
                </div>
                {stagedFiles.length > 0 && (
                  <div style={{ display: "flex", gap: 6, flexWrap: "wrap", marginTop: 10 }}>
                    {stagedFiles.map((f, i) => (
                      <span key={`${f.name}-${i}`} className="badge">
                        {f.name}
                        <button
                          type="button"
                          className="link"
                          style={{ marginLeft: 6 }}
                          onClick={() => setStagedFiles((list) => list.filter((_, j) => j !== i))}
                          title="Remove file"
                        >
                          ✕
                        </button>
                      </span>
                    ))}
                  </div>
                )}
                <p className="muted" style={{ margin: "8px 0 0", fontSize: 13 }}>
                  Attached files upload automatically when you save the product.
                </p>
              </>
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
