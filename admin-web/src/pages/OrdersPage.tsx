import { useCallback, useEffect, useMemo, useState } from "react";
import {
  NEXT_STATUS,
  cancelOrder,
  errText,
  getOrder,
  listOrders,
  updateOrderStatus,
  type Order,
  type OrderDetail,
} from "../services/api";
import { useToast } from "../context/ToastContext";
import { Card, EmptyState, Modal, Spinner } from "../components/ui";

const FILTERS = [
  "ALL",
  "PENDING",
  "CONFIRMED",
  "PREPARING",
  "READY",
  "OUT_FOR_DELIVERY",
  "DELIVERED",
  "CANCELLED",
  "REFUNDED",
] as const;

function toArray<T>(res: { results: T[] } | T[]): T[] {
  return Array.isArray(res) ? res : res.results;
}

function statusClass(s: string): string {
  if (s === "DELIVERED" || s === "CONFIRMED") return "ok";
  if (s === "CANCELLED" || s === "REFUNDED") return "err";
  if (s === "PENDING" || s === "READY" || s === "OUT_FOR_DELIVERY") return "warn";
  return "";
}

export function OrdersPage() {
  const { push } = useToast();
  const [orders, setOrders] = useState<Order[] | null>(null);
  const [filter, setFilter] = useState<(typeof FILTERS)[number]>("ALL");
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const load = useCallback(async () => {
    const res = await listOrders();
    setOrders(toArray(res));
  }, []);

  useEffect(() => {
    load().catch((e) => push(errText(e, "Failed to load orders"), "err"));
  }, [load, push]);

  const filtered = useMemo(
    () => (orders ?? []).filter((o) => filter === "ALL" || o.status === filter),
    [orders, filter],
  );

  const counts = useMemo(() => {
    const m: Record<string, number> = { ALL: orders?.length ?? 0 };
    for (const o of orders ?? []) m[o.status] = (m[o.status] ?? 0) + 1;
    return m;
  }, [orders]);

  return (
    <div>
      <div className="toolbar">
        {FILTERS.map((f) => (
          <button
            key={f}
            type="button"
            className={`effect-pill ${filter === f ? "on" : ""}`}
            onClick={() => setFilter(f)}
          >
            {f.replace(/_/g, " ")}{(counts[f] ?? 0) > 0 ? ` · ${counts[f]}` : ""}
          </button>
        ))}
        <div className="spacer" />
        <button className="btn btn-sm btn-ghost" onClick={() => load()}>
          ↻ Refresh
        </button>
      </div>

      <Card>
        {orders === null ? (
          <Spinner />
        ) : filtered.length === 0 ? (
          <EmptyState text={filter === "ALL" ? "No orders yet." : `No ${filter} orders.`} />
        ) : (
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Order</th>
                  <th>Store</th>
                  <th>Items</th>
                  <th>Total</th>
                  <th>Status</th>
                  <th>Placed</th>
                  <th style={{ width: 90 }} />
                </tr>
              </thead>
              <tbody>
                {filtered.map((o) => (
                  <tr key={o.id}>
                    <td style={{ fontWeight: 700 }}>{o.order_number}</td>
                    <td>{o.store_name ?? "—"}</td>
                    <td>{o.item_count ?? "—"}</td>
                    <td>₹{o.total}</td>
                    <td>
                      <span className={`badge ${statusClass(o.status)}`}>
                        {o.status.replace(/_/g, " ")}
                      </span>
                    </td>
                    <td className="muted">{new Date(o.created_at).toLocaleString()}</td>
                    <td>
                      <div style={{ display: "flex", justifyContent: "flex-end" }}>
                        <button className="btn btn-sm btn-primary" onClick={() => setSelectedId(o.id)}>
                          Open
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

      {selectedId && (
        <OrderDetailModal
          id={selectedId}
          onClose={() => setSelectedId(null)}
          onChanged={load}
        />
      )}
    </div>
  );
}

function OrderDetailModal({
  id,
  onClose,
  onChanged,
}: {
  id: string;
  onClose: () => void;
  onChanged: () => Promise<void>;
}) {
  const { push } = useToast();
  const [order, setOrder] = useState<OrderDetail | null>(null);
  const [busy, setBusy] = useState(false);
  const [reason, setReason] = useState("");
  const [cancelling, setCancelling] = useState(false);

  const load = useCallback(async () => {
    setOrder(await getOrder(id));
  }, [id]);

  useEffect(() => {
    load().catch((e) => push(errText(e, "Failed to load order"), "err"));
  }, [load, push]);

  async function advance(next: string) {
    setBusy(true);
    try {
      const updated = await updateOrderStatus(id, next);
      setOrder(updated);
      await onChanged();
      push(`Order → ${next.replace(/_/g, " ")}`);
    } catch (e) {
      push(errText(e, "Status update failed"), "err");
    } finally {
      setBusy(false);
    }
  }

  async function doCancel() {
    if (!reason.trim()) {
      push("Give a cancellation reason", "err");
      return;
    }
    setBusy(true);
    try {
      const updated = await cancelOrder(id, reason.trim());
      setOrder(updated);
      setCancelling(false);
      await onChanged();
      push("Order cancelled");
    } catch (e) {
      push(errText(e, "Cancel failed"), "err");
    } finally {
      setBusy(false);
    }
  }

  const next = order ? NEXT_STATUS[order.status] ?? [] : [];
  const cancellable = order?.status === "PENDING" || order?.status === "CONFIRMED";

  return (
    <Modal
      title={order ? `Order ${order.order_number}` : "Order"}
      subtitle={order ? `${order.store_name ?? ""} · ₹${order.total} · ${order.status.replace(/_/g, " ")}` : undefined}
      onClose={onClose}
    >
      {!order ? (
        <Spinner />
      ) : (
        <>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Item</th>
                  <th>SKU</th>
                  <th>Qty</th>
                  <th>Line total</th>
                </tr>
              </thead>
              <tbody>
                {order.items.map((i) => (
                  <tr key={i.id}>
                    <td style={{ fontWeight: 700 }}>
                      {i.product_name}
                      {i.variant_name ? <span className="muted"> · {i.variant_name}</span> : null}
                    </td>
                    <td className="muted">{i.sku}</td>
                    <td>{i.quantity}</td>
                    <td>₹{i.line_total}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {order.status_history.length > 0 && (
            <div style={{ marginTop: 16 }}>
              <div className="muted" style={{ fontWeight: 700, marginBottom: 8 }}>
                Status timeline
              </div>
              {order.status_history.map((h) => (
                <div key={h.id} className="muted" style={{ fontSize: 13 }}>
                  {(h.from_status || "—").replace(/_/g, " ")} →{" "}
                  <strong>{h.to_status.replace(/_/g, " ")}</strong>
                  {h.changed_by_email ? ` · ${h.changed_by_email}` : ""}
                  {h.note ? ` · ${h.note}` : ""} ·{" "}
                  {new Date(h.created_at).toLocaleString()}
                </div>
              ))}
            </div>
          )}

          {cancelling ? (
            <div className="form-grid" style={{ marginTop: 16 }}>
              <label>
                Cancellation reason
                <input
                  className="input"
                  value={reason}
                  onChange={(e) => setReason(e.target.value)}
                  placeholder="e.g. customer asked to cancel, item out of stock"
                />
              </label>
            </div>
          ) : null}

          <div className="modal-actions">
            <button className="btn btn-ghost" onClick={onClose} disabled={busy}>
              Close
            </button>
            {cancelling ? (
              <button className="btn btn-danger" onClick={doCancel} disabled={busy}>
                {busy ? "Working…" : "Confirm cancel"}
              </button>
            ) : (
              <>
                {cancellable && (
                  <button
                    className="btn btn-danger"
                    onClick={() => setCancelling(true)}
                    disabled={busy}
                  >
                    Cancel order
                  </button>
                )}
                {next.map((s) => (
                  <button
                    key={s}
                    className="btn btn-primary"
                    onClick={() => advance(s)}
                    disabled={busy}
                  >
                    {busy ? "Saving…" : `Mark ${s.replace(/_/g, " ").toLowerCase()}`}
                  </button>
                ))}
              </>
            )}
          </div>
        </>
      )}
    </Modal>
  );
}
