import { useCallback, useEffect, useMemo, useState } from "react";
import {
  createItem,
  createSection,
  deleteItem,
  deleteSection,
  errText,
  getSections,
  getStoreSlug,
  listAllProducts,
  listCategories,
  listStores,
  reorderItems,
  reorderSections,
  setStoreSlug,
  updateItem,
  updateSection,
  updateTheme,
  type Category,
  type Product,
  type SectionItem,
  type StoreSection,
  type Theme,
} from "../services/api";
import { useToast } from "../context/ToastContext";
import { Card, ConfirmDialog, Modal, Spinner } from "../components/ui";

const TYPE_META: Record<string, { icon: string; label: string }> = {
  HERO: { icon: "🖼️", label: "Hero banner" },
  BANNER: { icon: "🎞️", label: "Banner strip" },
  CATEGORY_GRID: { icon: "🧩", label: "Category grid" },
  PRODUCT_ROW: { icon: "🛍️", label: "Product row" },
  IMAGE_GALLERY: { icon: "📸", label: "Image gallery" },
  RICH_TEXT: { icon: "📝", label: "Text block" },
};

const EFFECTS = ["hover_zoom", "fade_in", "shadow_on_hover"] as const;

function itemLabel(item: SectionItem): string {
  return (
    item.caption ||
    item.product_name ||
    item.category_name ||
    `#${item.id}`
  );
}

export function StorefrontPage() {
  const { push } = useToast();
  const [stores, setStores] = useState<{ id: number; name: string; slug: string }[]>([]);
  const [slug, setSlug] = useState(getStoreSlug());
  const [sections, setSections] = useState<StoreSection[] | null>(null);
  const [theme, setTheme] = useState<Theme | null>(null);
  const [products, setProducts] = useState<Product[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [editSection, setEditSection] = useState<StoreSection | null>(null);
  const [deleting, setDeleting] = useState<StoreSection | null>(null);
  const [addItemFor, setAddItemFor] = useState<StoreSection | null>(null);

  const load = useCallback(async () => {
    const [s, sec] = await Promise.all([listStores(), getSections(slug)]);
    const storeList = Array.isArray(s) ? s : s.results;
    setStores(storeList);
    if (!storeList.some((st) => st.slug === slug) && storeList[0]) {
      setSlug(storeList[0].slug);
      setStoreSlug(storeList[0].slug);
    }
    setSections(sec);
  }, [slug]);

  useEffect(() => {
    Promise.all([load(), listAllProducts(), listCategories()])
      .then(([, p, c]) => {
        setProducts(p);
        setCategories(Array.isArray(c) ? c : c.results);
      })
      .catch((e) => push(e?.message ?? "Failed to load storefront", "err"));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [slug]);

  /* -------------------- drag & drop (sections) -------------------- */

  const [dragId, setDragId] = useState<number | null>(null);
  const [overId, setOverId] = useState<number | null>(null);

  async function onDropSections(targetId: number) {
    if (dragId === null || dragId === targetId) return resetDnd();
    const from = sections!.findIndex((s) => s.id === dragId);
    const to = sections!.findIndex((s) => s.id === targetId);
    if (from < 0 || to < 0) return resetDnd();
    const next = [...sections!];
    const [moved] = next.splice(from, 1);
    next.splice(to, 0, moved);
    setSections(next);
    resetDnd();
    try {
      await reorderSections(slug, next.map((s) => s.id));
      push("Section order saved");
    } catch (e) {
      push(errText(e, "Reorder failed"), "err");
      await load();
    }
  }

  function resetDnd() {
    setDragId(null);
    setOverId(null);
  }

  /* -------------------- drag & drop (items) -------------------- */

  const [dragItem, setDragItem] = useState<{ sectionId: number; id: number } | null>(null);
  const [overItem, setOverItem] = useState<number | null>(null);

  async function onDropItems(section: StoreSection, targetId: number) {
    if (!dragItem || dragItem.sectionId !== section.id || dragItem.id === targetId)
      return resetItemDnd();
    const from = section.items.findIndex((i) => i.id === dragItem.id);
    const to = section.items.findIndex((i) => i.id === targetId);
    if (from < 0 || to < 0) return resetItemDnd();
    const nextItems = [...section.items];
    const [moved] = nextItems.splice(from, 1);
    nextItems.splice(to, 0, moved);
    setSections((list) =>
      (list ?? []).map((s) => (s.id === section.id ? { ...s, items: nextItems } : s)),
    );
    resetItemDnd();
    try {
      await reorderItems(section.id, nextItems.map((i) => i.id));
      push("Item order saved");
    } catch (e) {
      push(errText(e, "Reorder failed"), "err");
      await load();
    }
  }

  function resetItemDnd() {
    setDragItem(null);
    setOverItem(null);
  }

  /* -------------------- section CRUD -------------------- */

  async function saveSection(id: number, body: Record<string, unknown>) {
    try {
      const updated = await updateSection(id, body);
      setSections((list) => (list ?? []).map((s) => (s.id === id ? updated : s)));
      setEditSection(null);
      push("Section updated");
    } catch (e) {
      push(errText(e, "Update failed"), "err");
    }
  }

  async function toggleSection(section: StoreSection) {
    try {
      const updated = await updateSection(section.id, { is_active: !section.is_active });
      setSections((list) => (list ?? []).map((s) => (s.id === section.id ? updated : s)));
    } catch (e) {
      push(errText(e, "Toggle failed"), "err");
    }
  }

  async function addSection(type: string) {
    try {
      const created = await createSection(slug, {
        section_type: type,
        title: TYPE_META[type]?.label ?? type,
        config: { columns: 4, size: "md", placeholder: "Edit me from the dashboard" },
      });
      setSections((list) => [...(list ?? []), created]);
      push(`${TYPE_META[type]?.label ?? type} added to the bottom — drag to place it`);
    } catch (e) {
      push(errText(e, "Create failed"), "err");
    }
  }

  async function confirmDeleteSection() {
    if (!deleting) return;
    try {
      await deleteSection(deleting.id);
      setSections((list) => (list ?? []).filter((s) => s.id !== deleting.id));
      setDeleting(null);
      push("Section deleted");
    } catch (e) {
      push(errText(e, "Delete failed"), "err");
      setDeleting(null);
    }
  }

  /* -------------------- item CRUD -------------------- */

  async function removeItem(sectionId: number, item: SectionItem) {
    try {
      await deleteItem(item.id);
      setSections((list) =>
        (list ?? []).map((s) =>
          s.id === sectionId ? { ...s, items: s.items.filter((i) => i.id !== item.id) } : s,
        ),
      );
      push("Item removed");
    } catch (e) {
      push(errText(e, "Remove failed"), "err");
    }
  }

  async function renameItem(sectionId: number, item: SectionItem, caption: string) {
    try {
      const updated = await updateItem(item.id, { caption });
      setSections((list) =>
        (list ?? []).map((s) =>
          s.id === sectionId
            ? { ...s, items: s.items.map((i) => (i.id === item.id ? updated : i)) }
            : s,
        ),
      );
      push("Item renamed");
    } catch (e) {
      push(errText(e, "Rename failed"), "err");
    }
  }

  /* -------------------- theme -------------------- */

  async function saveTheme(patch: Partial<Theme>) {
    try {
      const saved = await updateTheme(slug, patch);
      setTheme(saved);
      push("Theme saved");
    } catch (e) {
      push(errText(e, "Theme save failed"), "err");
    }
  }

  const themeValue = useMemo(
    () =>
      theme ?? {
        primary_color: "#4f46e5",
        secondary_color: "#f59e0b",
        background_color: "#ffffff",
        font_family: "system-ui",
        button_style: "ROUNDED" as const,
        effects: {},
      },
    [theme],
  );

  if (sections === null) return <Spinner />;

  return (
    <div>
      <div className="toolbar">
        <select
          className="input"
          style={{ maxWidth: 240 }}
          value={slug}
          onChange={(e) => {
            setSlug(e.target.value);
            setStoreSlug(e.target.value);
          }}
        >
          {stores.map((s) => (
            <option key={s.id} value={s.slug}>
              {s.name}
            </option>
          ))}
        </select>
        <div className="spacer" />
        <select
          className="input"
          style={{ maxWidth: 210 }}
          value=""
          onChange={(e) => e.target.value && addSection(e.target.value)}
        >
          <option value="">+ Add a section…</option>
          {Object.entries(TYPE_META).map(([value, meta]) => (
            <option key={value} value={value}>
              {meta.icon} {meta.label}
            </option>
          ))}
        </select>
      </div>

      <div className="sf-layout">
        {/* -------- board -------- */}
        <div className="section-board">
          {sections.length === 0 && (
            <Card>
              <p className="empty">No sections yet — add your first section from the toolbar.</p>
            </Card>
          )}
          {sections.map((s) => (
            <Card
              key={s.id}
              className={`section-row ${dragId === s.id ? "dragging" : ""} ${
                overId === s.id ? "drop-target" : ""
              }`}
            >
              <div
                className="drag-handle"
                title="Drag to reorder"
                draggable
                onDragStart={() => setDragId(s.id)}
                onDragEnd={resetDnd}
                onDragOver={(e) => {
                  e.preventDefault();
                  setOverId(s.id);
                }}
                onDrop={() => onDropSections(s.id)}
              >
                ⠿
              </div>
              <div className="section-body">
                <div className="section-head">
                  <span style={{ fontSize: 20 }}>{TYPE_META[s.section_type]?.icon ?? "🧱"}</span>
                  <input
                    className="title"
                    style={{
                      border: "none",
                      background: "transparent",
                      fontWeight: 800,
                      fontSize: 15.5,
                      color: "var(--text)",
                      outline: "none",
                    }}
                    defaultValue={s.title}
                    onBlur={(e) => {
                      if (e.target.value !== s.title) saveSection(s.id, { title: e.target.value });
                    }}
                    placeholder="Section title"
                  />
                  <span className="badge">{TYPE_META[s.section_type]?.label}</span>
                  <div className="section-actions">
                    <button className="btn btn-sm btn-ghost" onClick={() => toggleSection(s)}>
                      {s.is_active ? "👁 Visible" : "🚫 Hidden"}
                    </button>
                    <button className="btn btn-sm btn-ghost" onClick={() => setEditSection(s)}>
                      ⚙️ Design
                    </button>
                    <button className="btn btn-sm btn-danger" onClick={() => setDeleting(s)}>
                      Delete
                    </button>
                  </div>
                </div>

                <div className="item-strip">
                  {s.items.map((item) => (
                    <div
                      key={item.id}
                      className={`item-chip ${dragItem?.id === item.id ? "dragging" : ""} ${
                        overItem === item.id ? "drop-target" : ""
                      }`}
                      draggable
                      onDragStart={() => setDragItem({ sectionId: s.id, id: item.id })}
                      onDragEnd={resetItemDnd}
                      onDragOver={(e) => {
                        e.preventDefault();
                        setOverItem(item.id);
                      }}
                      onDrop={() => onDropItems(s, item.id)}
                    >
                      <div className="chip-type">
                        {item.item_type === "PRODUCT"
                          ? "🛍️ PRODUCT"
                          : item.item_type === "CATEGORY"
                            ? "🧩 CATEGORY"
                            : "✏️ CUSTOM"}
                      </div>
                      <div
                        className="chip-label"
                        contentEditable
                        suppressContentEditableWarning
                        onBlur={(e) => {
                          const v = e.target.textContent?.trim() ?? "";
                          if (v && v !== itemLabel(item)) renameItem(s.id, item, v);
                        }}
                        title="Click to rename"
                      >
                        {itemLabel(item)}
                      </div>
                      <button
                        className="btn btn-sm btn-danger"
                        style={{ marginTop: 8, width: "100%", padding: "3px 0" }}
                        onClick={() => removeItem(s.id, item)}
                      >
                        Remove
                      </button>
                    </div>
                  ))}
                  <button
                    className="item-chip"
                    style={{ display: "grid", placeItems: "center", color: "var(--c-primary)", fontWeight: 800 }}
                    onClick={() => setAddItemFor(s)}
                  >
                    + Add item
                  </button>
                </div>
              </div>
            </Card>
          ))}
        </div>

        {/* -------- theme panel -------- */}
        <Card>
          <h3 style={{ marginTop: 0 }}>🎨 Store theme</h3>
          <p className="muted" style={{ marginBottom: 14 }}>
            Applies to the customer website and app instantly.
          </p>
          <div className="form-grid">
            <label>
              Primary color
              <input
                type="color"
                value={themeValue.primary_color}
                onChange={(e) => setTheme({ ...(theme ?? themeValue), primary_color: e.target.value } as Theme)}
                onBlur={(e) => saveTheme({ primary_color: e.target.value })}
                style={{ width: "100%", height: 40, border: "none", background: "transparent", cursor: "pointer" }}
              />
            </label>
            <label>
              Accent color
              <input
                type="color"
                value={themeValue.secondary_color}
                onChange={(e) => setTheme({ ...(theme ?? themeValue), secondary_color: e.target.value } as Theme)}
                onBlur={(e) => saveTheme({ secondary_color: e.target.value })}
                style={{ width: "100%", height: 40, border: "none", background: "transparent", cursor: "pointer" }}
              />
            </label>
            <label>
              Button style
              <select
                className="input"
                value={themeValue.button_style}
                onChange={(e) => saveTheme({ button_style: e.target.value as Theme["button_style"] })}
              >
                <option value="ROUNDED">Rounded</option>
                <option value="SQUARE">Square</option>
                <option value="PILL">Pill</option>
              </select>
            </label>
            <label>
              Font
              <select
                className="input"
                value={themeValue.font_family}
                onChange={(e) => saveTheme({ font_family: e.target.value })}
              >
                <option value="system-ui">System</option>
                <option value="Georgia, serif">Georgia (serif)</option>
                <option value="'Courier New', monospace">Courier (mono)</option>
                <option value="Verdana, sans-serif">Verdana</option>
              </select>
            </label>
          </div>
        </Card>
      </div>

      {/* -------- section design modal -------- */}
      {editSection && (
        <SectionDesignModal
          section={editSection}
          onClose={() => setEditSection(null)}
          onSave={(body) => saveSection(editSection.id, body)}
        />
      )}

      {/* -------- add item modal -------- */}
      {addItemFor && (
        <AddItemModal
          section={addItemFor}
          products={products}
          categories={categories}
          onClose={() => setAddItemFor(null)}
          onCreated={(item) => {
            setSections((list) =>
              (list ?? []).map((s) =>
                s.id === addItemFor.id ? { ...s, items: [...s.items, item] } : s,
              ),
            );
            setAddItemFor(null);
          }}
        />
      )}

      {deleting && (
        <ConfirmDialog
          title={`Delete “${deleting.title || deleting.section_type}”?`}
          message="The section and its items will disappear from the storefront. This cannot be undone."
          onCancel={() => setDeleting(null)}
          onConfirm={confirmDeleteSection}
        />
      )}
    </div>
  );
}

/* ============================ Sub-components ============================ */

function SectionDesignModal({
  section,
  onClose,
  onSave,
}: {
  section: StoreSection;
  onClose: () => void;
  onSave: (body: Record<string, unknown>) => void;
}) {
  const cfg = section.config ?? {};
  const [title, setTitle] = useState(section.title);
  const [subtitle, setSubtitle] = useState(section.subtitle);
  const [placeholder, setPlaceholder] = useState(String(cfg.placeholder ?? ""));
  const [columns, setColumns] = useState(Number(cfg.columns ?? 4));
  const [size, setSize] = useState<"sm" | "md" | "lg">((cfg.size as "sm" | "md" | "lg") ?? "md");
  const [effects, setEffects] = useState<string[]>(
    Array.isArray(cfg.effects) ? [] : Object.keys(cfg.effects ?? {}).filter((k) => (cfg.effects as Record<string, unknown>)[k]),
  );

  function save() {
    const effectsObj: Record<string, unknown> = {};
    for (const key of effects) effectsObj[key] = true;
    onSave({
      title,
      subtitle,
      config: {
        ...cfg,
        columns,
        size,
        placeholder,
        effects: effectsObj,
      },
    });
  }

  return (
    <Modal title="Design this section" subtitle="Everything here is editable by you — no code." onClose={onClose}>
      <div className="form-grid">
        <label>
          Title
          <input className="input" value={title} onChange={(e) => setTitle(e.target.value)} />
        </label>
        <label>
          Subtitle
          <input className="input" value={subtitle} onChange={(e) => setSubtitle(e.target.value)} />
        </label>
        <label>
          Placeholder text
          <input
            className="input"
            value={placeholder}
            onChange={(e) => setPlaceholder(e.target.value)}
            placeholder="Shown until real content is added"
          />
        </label>
        <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14 }}>
          <label>
            Columns
            <select className="input" value={columns} onChange={(e) => setColumns(Number(e.target.value))}>
              {[1, 2, 3, 4, 5, 6].map((n) => (
                <option key={n} value={n}>
                  {n}
                </option>
              ))}
            </select>
          </label>
          <label>
            Card size
            <select className="input" value={size} onChange={(e) => setSize(e.target.value as "sm" | "md" | "lg")}>
              <option value="sm">Small</option>
              <option value="md">Medium</option>
              <option value="lg">Large</option>
            </select>
          </label>
        </div>
        <div>
          <div className="muted" style={{ fontWeight: 700, marginBottom: 8 }}>
            Effects
          </div>
          <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
            {EFFECTS.map((fx) => (
              <button
                key={fx}
                type="button"
                className={`effect-pill ${effects.includes(fx) ? "on" : ""}`}
                onClick={() =>
                  setEffects((list) => (list.includes(fx) ? list.filter((x) => x !== fx) : [...list, fx]))
                }
              >
                {fx.replace(/_/g, " ")}
              </button>
            ))}
          </div>
        </div>
      </div>
      <div className="modal-actions">
        <button className="btn btn-ghost" onClick={onClose}>
          Cancel
        </button>
        <button className="btn btn-primary" onClick={save}>
          Save design
        </button>
      </div>
    </Modal>
  );
}

function AddItemModal({
  section,
  products,
  categories,
  onClose,
  onCreated,
}: {
  section: StoreSection;
  products: Product[];
  categories: Category[];
  onClose: () => void;
  onCreated: (item: SectionItem) => void;
}) {
  const { push } = useToast();
  const [mode, setMode] = useState<"PRODUCT" | "CATEGORY" | "CUSTOM">(
    section.section_type === "CATEGORY_GRID" ? "CATEGORY" : section.section_type === "PRODUCT_ROW" ? "PRODUCT" : "CUSTOM",
  );
  const [productId, setProductId] = useState<number | "">("");
  const [categoryId, setCategoryId] = useState<number | "">("");
  const [caption, setCaption] = useState("");
  const [busy, setBusy] = useState(false);
  const [query, setQuery] = useState("");

  const pool = mode === "PRODUCT" ? products : categories;
  const filtered = pool.filter((x: { name: string }) =>
    x.name.toLowerCase().includes(query.toLowerCase()),
  );

  async function add() {
    setBusy(true);
    try {
      const body: Record<string, unknown> = { item_type: mode };
      if (mode === "PRODUCT") body.product = productId;
      if (mode === "CATEGORY") body.category = categoryId;
      if (mode === "CUSTOM") body.caption = caption;
      const item = await createItem(section.id, body);
      onCreated(item);
      push("Item added");
    } catch (e) {
      push(errText(e, "Add failed"), "err");
    } finally {
      setBusy(false);
    }
  }

  return (
    <Modal title="Add an item" subtitle={`Into “${section.title || section.section_type}”`} onClose={onClose}>
      <div style={{ display: "flex", gap: 8, marginBottom: 16 }}>
        {(["PRODUCT", "CATEGORY", "CUSTOM"] as const)
          .filter((m) => (m === "CATEGORY" ? categories.length > 0 : m === "PRODUCT" ? products.length > 0 : true))
          .map((m) => (
            <button
              key={m}
              className={`effect-pill ${mode === m ? "on" : ""}`}
              onClick={() => setMode(m)}
            >
              {m === "PRODUCT" ? "🛍️ Product" : m === "CATEGORY" ? "🧩 Category" : "✏️ Custom"}
            </button>
          ))}
      </div>

      {mode !== "CUSTOM" && (
        <>
          <input
            className="input"
            placeholder="Search…"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            style={{ marginBottom: 12 }}
          />
          <div style={{ maxHeight: 260, overflow: "auto", display: "grid", gap: 6 }}>
            {filtered.map((x: { id: number; name: string }) => {
              const selected = mode === "PRODUCT" ? productId === x.id : categoryId === x.id;
              return (
                <button
                  key={x.id}
                  className={`btn ${selected ? "btn-primary" : "btn-ghost"}`}
                  style={{ justifyContent: "flex-start" }}
                  onClick={() => (mode === "PRODUCT" ? setProductId(x.id) : setCategoryId(x.id))}
                >
                  {x.name}
                </button>
              );
            })}
            {filtered.length === 0 && <p className="empty">Nothing matches.</p>}
          </div>
        </>
      )}

      {mode === "CUSTOM" && (
        <label className="form-grid">
          Caption
          <input
            className="input"
            value={caption}
            onChange={(e) => setCaption(e.target.value)}
            placeholder="e.g. Free delivery today!"
            autoFocus
          />
        </label>
      )}

      <div className="modal-actions">
        <button className="btn btn-ghost" onClick={onClose}>
          Cancel
        </button>
        <button
          className="btn btn-primary"
          onClick={add}
          disabled={busy || (mode === "PRODUCT" && !productId) || (mode === "CATEGORY" && !categoryId) || (mode === "CUSTOM" && !caption.trim())}
        >
          {busy ? "Adding…" : "Add item"}
        </button>
      </div>
    </Modal>
  );
}
