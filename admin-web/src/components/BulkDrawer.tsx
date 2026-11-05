import { useState, type ChangeEvent, type DragEvent } from "react";
import { motion, AnimatePresence } from "framer-motion";

type PriceAction = "increase_percent" | "decrease_percent" | "set_flat";
type BulkAction = "price" | "stock";

interface BulkDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  onApply: () => void;
  action: BulkAction;
  setAction: (v: BulkAction) => void;
  priceAction: PriceAction;
  setPriceAction: (v: PriceAction) => void;
  value: string;
  setValue: (v: string) => void;
  busy: boolean;
  selectedCount: number;
}

export function BulkDrawer({
  isOpen,
  onClose,
  onApply,
  action,
  setAction,
  priceAction,
  setPriceAction,
  value,
  setValue,
  busy,
  selectedCount,
}: BulkDrawerProps) {
  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div
            className="drawer-overlay"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            style={{
              position: "fixed",
              inset: 0,
              background: "rgba(0,0,0,0.3)",
              zIndex: 99,
            }}
          />
          <motion.div
            initial={{ x: "100%" }}
            animate={{ x: 0 }}
            exit={{ x: "100%" }}
            transition={{ type: "spring", stiffness: 300, damping: 30 }}
            className="bulk-drawer"
            style={{
              position: "fixed",
              top: 0,
              right: 0,
              bottom: 0,
              width: 420,
              maxWidth: "100vw",
              background: "var(--bg-elevated)",
              borderLeft: "1px solid var(--border)",
              zIndex: 100,
              display: "flex",
              flexDirection: "column",
              boxShadow: "var(--shadow-lg)",
            }}
            role="dialog"
            aria-modal="true"
            aria-labelledby="bulk-drawer-title"
          >
            <div
              style={{
                padding: 20,
                borderBottom: "1px solid var(--border)",
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
              }}
            >
              <h3 id="bulk-drawer-title" style={{ margin: 0, fontSize: 16, fontWeight: 700 }}>
                Bulk Actions
              </h3>
              <button className="btn btn-ghost btn-sm" onClick={onClose} style={{ padding: 4 }}>
                <span style={{ fontSize: 20 }}>×</span>
              </button>
            </div>

            <div style={{ padding: 20, overflowY: "auto", flex: 1 }}>
              <div style={{ marginBottom: 20 }}>
                <p className="muted" style={{ fontSize: 13, marginBottom: 12 }}>
                  {selectedCount} product{selectedCount !== 1 ? "s" : ""} selected
                </p>

                <label style={{ display: "block", marginBottom: 12 }}>
                  <span
                    className="muted"
                    style={{ fontSize: 12.5, fontWeight: 600, marginBottom: 6, display: "block" }}
                  >
                    Action
                  </span>
                  <select
                    className="input"
                    value={action}
                    onChange={(e) => setAction(e.target.value as BulkAction)}
                    style={{ width: "100%" }}
                  >
                    <option value="price">Bulk Price Update</option>
                    <option value="stock">Bulk Stock Update</option>
                  </select>
                </label>

                {action === "price" && (
                  <label style={{ display: "block", marginBottom: 12 }}>
                    <span
                      className="muted"
                      style={{ fontSize: 12.5, fontWeight: 600, marginBottom: 6, display: "block" }}
                    >
                      Price Operation
                    </span>
                    <select
                      className="input"
                      style={{ width: "100%" }}
                      value={priceAction}
                      onChange={(e) => setPriceAction(e.target.value as PriceAction)}
                    >
                      <option value="increase_percent">Increase by %</option>
                      <option value="decrease_percent">Decrease by %</option>
                      <option value="set_flat">Set flat price</option>
                    </select>
                  </label>
                )}

                <label style={{ display: "block", marginBottom: 20 }}>
                  <span
                    className="muted"
                    style={{ fontSize: 12.5, fontWeight: 600, marginBottom: 6, display: "block" }}
                  >
                    {action === "stock"
                      ? "Quantity"
                      : priceAction === "set_flat"
                        ? "Price (₹)"
                        : "Percentage (%)"}
                  </span>
                  <input
                    type="number"
                    step={action === "stock" ? "1" : "0.01"}
                    min={0}
                    className="input"
                    value={value}
                    onChange={(e) => setValue(e.target.value)}
                    placeholder={
                      action === "stock" ? "Qty" : priceAction === "set_flat" ? "₹" : "%"
                    }
                  />
                </label>

                <p className="muted" style={{ fontSize: 12.5, marginTop: 0 }}>
                  {action === "stock"
                    ? "Sets the stock quantity for every stock row of the selected products."
                    : priceAction === "set_flat"
                      ? "Sets every selected variant to this exact price."
                      : "Applies to every active variant of the selected products."}
                </p>

                <div style={{ display: "flex", gap: 8, marginTop: 8 }}>
                  <button
                    className="btn btn-primary"
                    style={{ flex: 1 }}
                    onClick={onApply}
                    disabled={busy || !value}
                  >
                    {busy ? "Applying…" : "Apply"}
                  </button>
                  <button className="btn btn-ghost" onClick={onClose} disabled={busy}>
                    Cancel
                  </button>
                </div>
              </div>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}

interface CsvImportResult {
  created: number;
  updated: number;
  errors: string[];
}

interface CsvImportModalProps {
  isOpen: boolean;
  onClose: () => void;
  onImport: () => void;
  file: File | null;
  setFile: (f: File | null) => void;
  busy: boolean;
  result: CsvImportResult | null;
}

export function CsvImportModal({
  isOpen,
  onClose,
  onImport,
  file,
  setFile,
  busy,
  result,
}: CsvImportModalProps) {
  const [dragActive, setDragActive] = useState(false);

  const handleDrag = (e: DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.type === "dragenter" || e.type === "dragover") setDragActive(true);
    else if (e.type === "dragleave") setDragActive(false);
  };

  const handleDrop = (e: DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setDragActive(false);
    if (e.dataTransfer.files.length > 0) {
      setFile(e.dataTransfer.files[0]);
    }
  };

  const handleFileSelect = (e: ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      setFile(e.target.files[0]);
    }
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div
            className="modal-overlay"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            style={{ position: "fixed", inset: 0, background: "rgba(0,0,0,0.4)", zIndex: 99 }}
          />
          <div
            style={{
              position: "fixed",
              inset: 0,
              zIndex: 100,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              padding: 16,
              pointerEvents: "none",
            }}
          >
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 20 }}
              transition={{ type: "spring", stiffness: 300, damping: 30 }}
              className="modal"
              style={{
                width: "100%",
                maxWidth: 480,
                maxHeight: "85vh",
                background: "var(--bg-elevated)",
                border: "1px solid var(--border)",
                borderRadius: 16,
                overflow: "hidden",
                display: "flex",
                flexDirection: "column",
                boxShadow: "var(--shadow-lg)",
                pointerEvents: "auto",
              }}
              role="dialog"
              aria-modal="true"
              aria-labelledby="csv-import-title"
            >
              <div
                style={{
                  padding: "20px 24px",
                  borderBottom: "1px solid var(--border)",
                  display: "flex",
                  justifyContent: "space-between",
                  alignItems: "center",
                }}
              >
                <h2 id="csv-import-title" style={{ margin: 0, fontSize: 16, fontWeight: 700 }}>
                  Import Products from CSV
                </h2>
                <button className="btn btn-ghost btn-sm" onClick={onClose} style={{ padding: 4 }}>
                  <span style={{ fontSize: 20 }}>×</span>
                </button>
              </div>

              <div style={{ padding: 24, overflowY: "auto", flex: 1 }}>
                {result ? (
                  <div style={{ textAlign: "center" }}>
                    <div style={{ fontSize: 48, marginBottom: 12 }}>✅</div>
                    <h3 style={{ margin: "0 0 8px", fontSize: 18, fontWeight: 700 }}>
                      Import Complete
                    </h3>
                    <p className="muted" style={{ marginBottom: 8 }}>
                      {result.created} created, {result.updated} updated
                      {result.errors.length > 0 && (
                        <span style={{ color: "var(--c-danger)" }}>
                          {" "}
                          · {result.errors.length} failed
                        </span>
                      )}
                    </p>
                    {result.errors.length > 0 && (
                      <div
                        style={{
                          marginTop: 16,
                          textAlign: "left",
                          maxHeight: 200,
                          overflow: "auto",
                          padding: 12,
                          background: "var(--bg-sunken)",
                          borderRadius: 8,
                        }}
                      >
                        <div className="muted" style={{ fontWeight: 600, marginBottom: 8 }}>
                          Errors:
                        </div>
                        <ul style={{ margin: 0, paddingLeft: 20, fontSize: 13 }}>
                          {result.errors.map((err, i) => (
                            <li key={i} style={{ color: "var(--c-danger)", marginBottom: 4 }}>
                              {err}
                            </li>
                          ))}
                        </ul>
                      </div>
                    )}
                    <button
                      className="btn btn-primary"
                      style={{ width: "100%", marginTop: 16 }}
                      onClick={onClose}
                    >
                      Done
                    </button>
                  </div>
                ) : (
                  <>
                    <p className="muted" style={{ marginBottom: 16, fontSize: 13.5 }}>
                      Upload a CSV file with columns:{" "}
                      <code style={{ fontSize: 12 }}>
                        id (optional), name, sku, price, stock, category, brand, is_active,
                        is_demo, mrp, description
                      </code>
                    </p>
                    <div
                      onDragEnter={handleDrag}
                      onDragLeave={handleDrag}
                      onDragOver={handleDrag}
                      onDrop={handleDrop}
                      style={{
                        border: `2px dashed ${dragActive ? "var(--c-primary)" : "var(--border)"}`,
                        borderRadius: 12,
                        padding: 40,
                        textAlign: "center",
                        background: dragActive ? "var(--bg-hover)" : "transparent",
                        transition: "all 0.2s",
                        cursor: "pointer",
                      }}
                      onClick={() => document.getElementById("csv-file-input")?.click()}
                    >
                      <input
                        id="csv-file-input"
                        type="file"
                        accept=".csv"
                        style={{ display: "none" }}
                        onChange={handleFileSelect}
                      />
                      <div
                        style={{
                          fontSize: 32,
                          color: dragActive ? "var(--c-primary)" : "var(--text-faint)",
                          marginBottom: 12,
                        }}
                      >
                        📁
                      </div>
                      <div style={{ fontWeight: 600, marginBottom: 4 }}>
                        {file ? file.name : "Drag & drop a CSV file or click to browse"}
                      </div>
                      <div className="muted" style={{ fontSize: 12 }}>
                        Max 1000 rows recommended
                      </div>
                    </div>
                    <div style={{ marginTop: 16, display: "flex", gap: 8 }}>
                      <button
                        className="btn btn-ghost"
                        style={{ flex: 1 }}
                        onClick={onClose}
                        disabled={busy}
                      >
                        Cancel
                      </button>
                      <button
                        className="btn btn-primary"
                        style={{ flex: 1 }}
                        onClick={onImport}
                        disabled={busy || !file}
                      >
                        {busy ? "Importing…" : "Import"}
                      </button>
                    </div>
                  </>
                )}
              </div>
            </motion.div>
          </div>
        </>
      )}
    </AnimatePresence>
  );
}
