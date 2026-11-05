import { useCallback, useRef, useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useAuth } from "../context/AuthContext";
import { useCart } from "../context/CartContext";
import { useToast } from "../context/ToastContext";
import { href, navigate } from "../hooks/useHashRoute";
import { useFocusTrap } from "../hooks/useFocusTrap";
import {
  asArray,
  cancelOrder,
  errText,
  getOrder,
  listOrders,
  type Order,
} from "../services/api";
import { EmptyState, money, PageCrumbs, SignInGate, Spinner, StatusChip } from "../components/ui";
import { Icon } from "../components/icons";
import { TotalsBreakdown } from "../components/TotalsBreakdown";
import { orderTotals } from "../utils/pricing";

const CANCELLABLE = new Set(["PENDING", "CONFIRMED"]);

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
      <PageCrumbs current="Your orders" />
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
          <a className="order-card" key={o.id} href={href(`order/${o.id}`)}>
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
          </a>
        ))
      )}
    </div>
  );
}

export function OrderDetailPage({ id }: { id: string }) {
  const { user } = useAuth();
  const { add } = useCart();
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
  const [reordering, setReordering] = useState(false);
  const cancelTriggerRef = useRef<HTMLButtonElement | null>(null);
  const closeCancel = useCallback(() => setCancelling(false), []);
  const cancelDialogRef = useFocusTrap<HTMLDivElement>(
    cancelling,
    closeCancel,
    cancelTriggerRef,
  );
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
      const msg = errText(e, "");
      // Backend returns 400 with "Cannot cancel order in X status"
      if (msg.includes("Cannot cancel order in")) {
        toast.push(`Cannot cancel order: ${msg.replace("Cannot cancel order in ", "").replace(" status", "")}`, "err");
      } else {
        toast.push(msg || "Could not cancel order", "err");
      }
    } finally {
      setBusy(false);
    }
  };

  const doReorder = async () => {
    setReordering(true);
    const unavailable: string[] = [];
    let added = 0;
    for (const item of order.items ?? []) {
      const variant = item.variant;
      if (!variant || variant.in_stock === false) {
        unavailable.push(item.product_name);
        continue;
      }
      try {
        await add(variant.id, item.quantity);
        added += 1;
      } catch {
        unavailable.push(item.product_name);
      }
    }

    if (unavailable.length > 0) {
      toast.push(
        added > 0
          ? `Added ${added} item${added === 1 ? "" : "s"} to cart. ${unavailable.length} item${unavailable.length === 1 ? "" : "s"} unavailable.`
          : `No items were added. ${unavailable.length} item${unavailable.length === 1 ? "" : "s"} unavailable.`,
        added > 0 ? "info" : "err",
      );
      toast.push(`Unavailable: ${unavailable.join(", ")}`, "info");
    } else {
      toast.push("All items added to cart.");
    }

    setReordering(false);
    navigate("cart");
  };

  const canCancel = CANCELLABLE.has(order.status);
  const canReorder = order.status !== "CANCELLED" && (order.items?.length ?? 0) > 0;

  return (
    <div className="page page-narrow">
      <PageCrumbs current={order.order_number} />
      <div style={{ marginBottom: 14 }}>
        <a className="link" href={href("orders")}>
          <Icon name="arrowLeft" size={14} /> All orders
        </a>
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
        <TotalsBreakdown
          totals={orderTotals(order)}
          showCod={order.payment_method === "cod" || Number(order.cod_fee ?? 0) > 0}
        />
        {canReorder || canCancel ? (
          <div className="form-actions">
            {canReorder ? (
              <button
                className="btn btn-primary"
                disabled={reordering}
                onClick={() => void doReorder()}
              >
                {reordering ? "Adding to cart…" : "Reorder"}
              </button>
            ) : null}
            {canCancel ? (
              <button
                ref={cancelTriggerRef}
                className="btn btn-danger"
                disabled={busy}
                onClick={() => setCancelling(true)}
              >
                Cancel order
              </button>
            ) : (
              <button
                className="btn btn-danger"
                disabled
                title="This order can no longer be cancelled."
              >
                Cancel order
              </button>
            )}
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
        <div className="overlay" onMouseDown={(e) => e.target === e.currentTarget && closeCancel()}>
          <div
            ref={cancelDialogRef}
            className="panel"
            role="dialog"
            aria-modal="true"
            aria-labelledby="cancel-order-title"
            tabIndex={-1}
            style={{ maxWidth: 420, margin: "15vh auto" }}
          >
            <h2 id="cancel-order-title">Cancel this order?</h2>
            <p className="muted">This can't be undone once confirmed.</p>
            <div className="form-actions">
              <button className="btn btn-ghost" onClick={closeCancel}>Keep order</button>
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
