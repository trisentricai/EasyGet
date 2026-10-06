import { useEffect, useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import {
  createCategory,
  deleteCategory,
  errText,
  listCategories,
  mediaSrc,
  updateCategory,
  uploadCategoryIcon,
  type Category,
} from "../services/api";
import { useToast } from "../context/ToastContext";
import { Card, ConfirmDialog, EmptyState, Modal, Spinner } from "../components/ui";

type Draft = { name: string; description: string; is_active: boolean };

const emptyDraft: Draft = { name: "", description: "", is_active: true };

export function CategoriesPage() {
  const { push } = useToast();
  const queryClient = useQueryClient();
  const [query, setQuery] = useState("");
  const [editing, setEditing] = useState<Category | null>(null);
  const [creating, setCreating] = useState(false);
  const [draft, setDraft] = useState<Draft>(emptyDraft);
  const [busy, setBusy] = useState(false);
  const [deleting, setDeleting] = useState<Category | null>(null);
  const [imgBusy, setImgBusy] = useState(false);

  const categoriesQuery = useQuery({
    queryKey: ["admin", "categories"],
    queryFn: async () => {
      const res = await listCategories();
      return Array.isArray(res) ? res : res.results;
    },
  });

  const categories = categoriesQuery.data ?? null;

  useEffect(() => {
    if (categoriesQuery.error)
      push(errText(categoriesQuery.error, "Failed to load categories"), "err");
  }, [categoriesQuery.error, push]);

  function openCreate() {
    setDraft(emptyDraft);
    setCreating(true);
  }

  function openEdit(category: Category) {
    setEditing(category);
    setDraft({ name: category.name, description: category.description ?? "", is_active: category.is_active });
  }

  async function save() {
    if (!draft.name.trim()) return;
    setBusy(true);
    try {
      if (editing) {
        await updateCategory(editing.slug, draft);
        push(`Renamed/updated “${draft.name}”`);
      } else {
        await createCategory(draft);
        push(`Category “${draft.name}” created`);
      }
      setCreating(false);
      setEditing(null);
      await queryClient.invalidateQueries({ queryKey: ["admin", "categories"] });
    } catch (e) {
      push(errText(e, "Save failed"), "err");
    } finally {
      setBusy(false);
    }
  }

  async function uploadIcon(file: File | null) {
    if (!editing || imgBusy) return;
    setImgBusy(true);
    try {
      const updated = await uploadCategoryIcon(editing.slug, file);
      setEditing(updated);
      await queryClient.invalidateQueries({ queryKey: ["admin", "categories"] });
      push(file ? "Category image updated" : "Category image removed");
    } catch (e) {
      push(errText(e, "Image upload failed"), "err");
    } finally {
      setImgBusy(false);
    }
  }

  async function confirmDelete() {
    if (!deleting) return;
    setBusy(true);
    try {
      await deleteCategory(deleting.slug);
      push(`“${deleting.name}” deleted`);
      setDeleting(null);
      await queryClient.invalidateQueries({ queryKey: ["admin", "categories"] });
    } catch (e) {
      push(errText(e, "Delete failed (category may have products)"), "err");
      setDeleting(null);
    } finally {
      setBusy(false);
    }
  }

  const filtered = (categories ?? []).filter((c) =>
    c.name.toLowerCase().includes(query.toLowerCase()),
  );

  return (
    <div>
      <div className="toolbar">
        <input
          className="input"
          placeholder="Search categories…"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
        />
        <div className="spacer" />
        <button className="btn btn-primary" onClick={openCreate}>
          + New category
        </button>
      </div>

      <Card>
        {categories === null ? (
          <Spinner />
        ) : filtered.length === 0 ? (
          <EmptyState text="No categories yet — create the first one." />
        ) : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th style={{ width: 56 }}>Image</th>
                  <th>Name</th>
                  <th>Slug</th>
                  <th>Products</th>
                  <th>Status</th>
                  <th style={{ width: 180 }} />
                </tr>
              </thead>
              <tbody>
                {filtered.map((c) => {
                  const icon = mediaSrc(c.icon);
                  return (
                  <tr key={c.id}>
                    <td>
                      {icon ? (
                        <img
                          src={icon}
                          alt=""
                          width={32}
                          height={32}
                          style={{ width: 32, height: 32, borderRadius: "50%", objectFit: "cover", display: "block" }}
                        />
                      ) : (
                        <span className="muted">—</span>
                      )}
                    </td>
                    <td style={{ fontWeight: 700 }}>{c.name}</td>
                    <td className="muted">{c.slug}</td>
                    <td>{c.product_count}</td>
                    <td>
                      <span className={`badge ${c.is_active ? "ok" : "err"}`}>
                        {c.is_active ? "Active" : "Hidden"}
                      </span>
                    </td>
                    <td>
                      <div style={{ display: "flex", gap: 8, justifyContent: "flex-end" }}>
                        <button className="btn btn-sm btn-ghost" onClick={() => openEdit(c)}>
                          Edit
                        </button>
                        <button className="btn btn-sm btn-danger" onClick={() => setDeleting(c)}>
                          Delete
                        </button>
                      </div>
                    </td>
                  </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {(creating || editing) && (
        <Modal
          title={editing ? "Edit category" : "New category"}
          subtitle="Changes go live for customers immediately."
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
                placeholder="e.g. Grocery"
              />
            </label>
            <label>
              Description
              <input
                className="input"
                value={draft.description}
                onChange={(e) => setDraft({ ...draft, description: e.target.value })}
                placeholder="Shown on the storefront (optional)"
              />
            </label>
            <label style={{ display: "flex", alignItems: "center", gap: 10 }}>
              <input
                type="checkbox"
                checked={draft.is_active}
                onChange={(e) => setDraft({ ...draft, is_active: e.target.checked })}
              />
              Active (visible to customers)
            </label>
            {editing && (
              <div style={{ gridColumn: "1 / -1" }}>
                <div className="muted" style={{ fontWeight: 700, marginBottom: 8 }}>
                  Category image (avatar + cover)
                </div>
                <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
                  {mediaSrc(editing.icon) ? (
                    <img
                      src={mediaSrc(editing.icon)!}
                      alt=""
                      width={56}
                      height={56}
                      style={{ width: 56, height: 56, borderRadius: "50%", objectFit: "cover" }}
                    />
                  ) : (
                    <span className="muted">No image yet</span>
                  )}
                  <label className="btn btn-sm btn-ghost" style={{ cursor: "pointer" }}>
                    {imgBusy ? "Uploading…" : mediaSrc(editing.icon) ? "Replace image" : "Upload image"}
                    <input
                      type="file"
                      accept="image/*"
                      style={{ display: "none" }}
                      disabled={imgBusy}
                      onChange={(e) => {
                        const file = e.target.files?.[0] ?? null;
                        e.target.value = "";
                        if (file) void uploadIcon(file);
                      }}
                    />
                  </label>
                  {mediaSrc(editing.icon) && !imgBusy && (
                    <button type="button" className="btn btn-sm btn-danger" onClick={() => void uploadIcon(null)}>
                      Remove
                    </button>
                  )}
                </div>
                <p className="muted" style={{ margin: "8px 0 0", fontSize: 12.5 }}>
                  Shown as the avatar circle and cover art wherever this category appears.
                </p>
              </div>
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
            <button className="btn btn-primary" onClick={save} disabled={busy || !draft.name.trim()}>
              {busy ? "Saving…" : "Save"}
            </button>
          </div>
        </Modal>
      )}

      {deleting && (
        <ConfirmDialog
          title={`Delete “${deleting.name}”?`}
          message="Categories with products or subcategories cannot be deleted. This cannot be undone."
          onCancel={() => setDeleting(null)}
          onConfirm={confirmDelete}
          busy={busy}
        />
      )}
    </div>
  );
}
