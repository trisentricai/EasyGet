import { useCallback, useEffect, useState } from "react";
import { api, errText, type Product } from "../services/api";
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
  const [items, setItems] = useState<StockItem[] | null>(null);
  const [query, setQuery] = useState("");
  const [adjusting, setAdjusting] = useState<StockItem | null>(null);

  const load = useCallback(async () => {
    const res = await api<{ results: StockItem[] } | StockItem[]>("/inventory/");
    setItems(toArray(res));
  }, []);

  useEffect(() => {
    load().catch((e) => push(e?.message ?? "Failed to load inventory", "err"));
  }, [load, push]);

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

      {adjusting && (
        <AdjustModal
          item={adjusting}
          onClose={() => setAdjusting(null)}
          onDone={async () => {
            setAdjusting(null);
            await load();
          }}
        />
      )}
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

export type { Product };
