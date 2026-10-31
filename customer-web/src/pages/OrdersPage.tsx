import { useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useAuth } from "../context/AuthContext";
import { useToast } from "../context/ToastContext";
import { navigate } from "../hooks/useHashRoute";
import {
  asArray,
  cancelOrder,
  errText,
  getOrder,
  listOrders,
  type Order,
} from "../services/api";
import { EmptyState, money, SignInGate, Spinner, StatusChip } from "../components/ui";

const CANCELLABLE = new Set(["PENDING", "CONFIRMED", "PREPARING"]);

export function OrdersPage() {
  const { user } = useAuth();
  const { data, error } = useQuery({
    queryKey: ["orders", user?.id ?? null],
    queryFn: listOrders,
    enabled: !!user,
  });
  const orders = data ? asArray<Order>(data) : null;
  const errorMsg = error ? errText(error) : null;

  if (!user) return <SignInGate title="Your orders" text="Sign in to track your orders." />;

  return (
    <div className="page">
      <div className="pagehead">
        <h1>Your orders</h1>
        <p className="muted">Track and manage everything you've ordered.</p>
      </div>

      {errorMsg ? (
        <EmptyState icon="warning" title="Couldn't load orders" text={errorMsg} />
      ) : orders === null ? (
        <Spinner />
      ) : orders.length === 0 ? (
        <EmptyState
          icon="box"
          title="No orders yet"
          text="When you place an order it will show up here."
          action={<button className="btn" onClick={() => navigate("browse")}>Start shopping</button>}
        />
      ) : (
        orders.map((o) => (
          <div className="order-card" key={o.id} onClick={() => navigate(`order/${o.id}`)} style={{ cursor: "pointer" }}>
            <div>
              <div className="num">{o.order_number}</div>
              <div className="meta">
                {new Date(o.created_at).toLocaleString()} · {o.item_count ?? "—"} item(s) · Seller: {o.store_name ?? "EASYGET"}
              </div>
            </div>
            <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
              <div style={{ fontWeight: 800 }}>{money(o.total)}</div>
              <StatusChip status={o.status} />
            </div>
          </div>
        ))
      )}
    </div>
  );
}

export function OrderDetailPage({ id }: { id: string }) {
  const { user } = useAuth();
  const toast = useToast();
  const queryClient = useQueryClient();
  const orderKey = ["order", id, user?.id ?? null];
  const { data: order, error } = useQuery({
    queryKey: orderKey,
    queryFn: () => getOrder(id),
    enabled: !!user,
  });
  const [cancelling, setCancelling] = useState(false);
  const [busy, setBusy] = useState(false);
  const errorMsg = error ? errText(error, "Order not found") : null;

  if (!user) return <SignInGate title="Order details" text="Sign in to view this order." />;
  if (errorMsg) return <div className="page"><EmptyState icon="warning" title="Order not found" text={errorMsg} /></div>;
  if (!order) return <Spinner />;

  const doCancel = async () => {
    const reason = window.prompt("Why are you cancelling this order?");
    if (reason === null) return;
    setBusy(true);
    setCancelling(false);
    try {
      const updated = await cancelOrder(order.id, reason || "No reason provided");
      queryClient.setQueryData(orderKey, updated);
      queryClient.invalidateQueries({ queryKey: ["orders"] });
      toast.push("Order cancelled", "info");
    } catch (e) {
      toast.push(errText(e, "Could not cancel order"), "err");
    } finally {
      setBusy(false);
    }
  };

  const canCancel = CANCELLABLE.has(order.status);

  return (
    <div className="page page-narrow">
      <div style={{ marginBottom: 14 }}>
        <span className="link" onClick={() => navigate("orders")}>← All orders</span>
      </div>
      <div className="pagehead">
        <h1 style={{ display: "flex", alignItems: "center", gap: 12 }}>
          {order.order_number} <StatusChip status={order.status} />
        </h1>
        <p className="muted">Placed {new Date(order.created_at).toLocaleString()}</p>
      </div>

      <div className="panel">
        <h2>Items</h2>
        {(order.items ?? []).map((item) => (
          <div key={item.id} className="summary-line">
            <span>
              {item.product_name}
              {item.variant_name ? <span className="muted"> · {item.variant_name}</span> : null}
              <span className="muted"> × {item.quantity}</span>
            </span>
            <span>{money(item.line_total)}</span>
          </div>
        ))}
        <div className="summary-line">
          <span className="muted">Seller: {order.store_name ?? "EASYGET"}</span>
          <span />
        </div>
        <div className="summary-line">
          <span className="muted">Subtotal</span>
          <span>{money(order.subtotal)}</span>
        </div>
        {Number(order.delivery_fee) > 0 ? (
          <div className="summary-line">
            <span className="muted">Delivery</span>
            <span>{money(order.delivery_fee)}</span>
          </div>
        ) : null}
        {Number(order.discount) > 0 ? (
          <div className="summary-line">
            <span className="muted">Discount</span>
            <span>−{money(order.discount)}</span>
          </div>
        ) : null}
        <div className="summary-line summary-total">
          <span>Total</span>
          <span>{money(order.total)}</span>
        </div>
        {canCancel ? (
          <div className="form-actions">
            <button className="btn btn-danger" disabled={busy} onClick={() => setCancelling(true)}>
              Cancel order
            </button>
          </div>
        ) : null}
      </div>

      <div className="panel">
        <h2>Delivery address</h2>
        <p style={{ margin: 0, fontSize: 14, lineHeight: 1.6 }}>
          {formatAddress(order.delivery_address)}
          {order.delivery_instructions ? <span className="muted"><br />Note: {order.delivery_instructions}</span> : null}
        </p>
      </div>

      <div className="panel">
        <h2>Status history</h2>
        {order.status_history.length ? (
          <ul className="timeline">
            {order.status_history.map((h) => (
              <li key={h.id}>
                <span className="dot" />
                <span>
                  <b>{h.to_status.replaceAll("_", " ").toLowerCase()}</b>
                  {h.note ? <span className="muted"> — {h.note}</span> : null}
                </span>
                <time>{new Date(h.created_at).toLocaleString()}</time>
              </li>
            ))}
          </ul>
        ) : (
          <p className="muted" style={{ margin: 0 }}>No status updates yet.</p>
        )}
      </div>

      {cancelling ? (
        <div className="overlay" onMouseDown={(e) => e.target === e.currentTarget && setCancelling(false)}>
          <div className="panel" role="dialog" style={{ maxWidth: 420, margin: "15vh auto" }}>
            <h2>Cancel this order?</h2>
            <p className="muted">This can't be undone once confirmed.</p>
            <div className="form-actions">
              <button className="btn btn-ghost" onClick={() => setCancelling(false)}>Keep order</button>
              <button className="btn btn-danger" disabled={busy} onClick={() => void doCancel()}>
                {busy ? "Cancelling…" : "Yes, cancel it"}
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}

function formatAddress(addr?: Record<string, unknown>): string {
  if (!addr) return "—";
  const parts = [addr.line1, addr.line2, addr.city, addr.state, addr.postal_code, addr.country].filter(Boolean);
  return parts.join(", ");
}
