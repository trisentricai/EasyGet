import { useCallback, useEffect, useState } from "react";
import {
  createCategory,
  deleteCategory,
  errText,
  listCategories,
  updateCategory,
  type Category,
} from "../services/api";
import { useToast } from "../context/ToastContext";
import { Card, ConfirmDialog, EmptyState, Modal, Spinner } from "../components/ui";

type Draft = { name: string; description: string; is_active: boolean };

const emptyDraft: Draft = { name: "", description: "", is_active: true };

export function CategoriesPage() {
  const { push } = useToast();
  const [categories, setCategories] = useState<Category[] | null>(null);
  const [query, setQuery] = useState("");
  const [editing, setEditing] = useState<Category | null>(null);
  const [creating, setCreating] = useState(false);
  const [draft, setDraft] = useState<Draft>(emptyDraft);
  const [busy, setBusy] = useState(false);
  const [deleting, setDeleting] = useState<Category | null>(null);

  const load = useCallback(async () => {
    const res = await listCategories();
    setCategories(Array.isArray(res) ? res : res.results);
  }, []);

  useEffect(() => {
    load().catch((e) => push(errText(e, "Failed to load categories"), "err"));
  }, [load, push]);

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
      await deleteCategory(deleting.slug);
      push(`“${deleting.name}” deleted`);
      setDeleting(null);
      await load();
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
                  <th>Name</th>
                  <th>Slug</th>
                  <th>Products</th>
                  <th>Status</th>
                  <th style={{ width: 180 }} />
                </tr>
              </thead>
              <tbody>
                {filtered.map((c) => (
                  <tr key={c.id}>
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
                ))}
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
