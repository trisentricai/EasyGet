import { useQuery } from "@tanstack/react-query";
import { useAuth } from "../context/AuthContext";
import { href } from "../hooks/useHashRoute";
import { errText, getOrder } from "../services/api";
import { EmptyState, money, PageCrumbs, SignInGate, Spinner } from "../components/ui";
import { SuccessCheck } from "../components/animations";
import { Icon } from "../components/icons";
import { TotalsBreakdown } from "../components/TotalsBreakdown";
import { orderTotals } from "../utils/pricing";

/**
 * Post-checkout trust screen (#/order/:id/confirmation).
 *
 * The order detail remains the tracking page; this page only exists to make
 * the placement moment unambiguous: big success state, order number, ETA,
 * a compact item recap, totals, and two clear next actions.
 */
export function OrderConfirmationPage({ id }: { id: string }) {
  const { user, ready } = useAuth();
  const { data: order, error } = useQuery({
    queryKey: ["order", id, user?.id ?? null],
    queryFn: () => getOrder(id),
    enabled: !!user,
  });

  if (!ready) return <Spinner />;
  if (!user) {
    return <SignInGate title="Order confirmation" text="Sign in to view this order." />;
  }
  if (error) {
    return (
      <div className="page page-narrow">
        <EmptyState
          icon="warning"
          title="Couldn't load this order"
          text={errText(error, "Order not found")}
          action={<a className="btn" href={href("orders")}>View your orders</a>}
        />
      </div>
    );
  }
  if (!order) return <Spinner />;

  const totals = orderTotals(order);
  const eta = formatEta(order.estimated_delivery_at);
  const payment =
    order.payment_method === "cod"
      ? "Cash on Delivery"
      : order.payment_method === "upi"
        ? "UPI"
        : order.payment_method === "card"
          ? "Card"
          : "—";

  return (
    <div className="page page-narrow">
      <PageCrumbs current="Order confirmed" />

      <section className="panel" style={{ textAlign: "center", padding: "36px 24px 28px" }}>
        <div
          style={{
            display: "grid",
            placeItems: "center",
            color: "var(--ok)",
            marginBottom: 6,
          }}
        >
          <SuccessCheck size={76} />
        </div>
        <h1 style={{ margin: "8px 0 4px" }}>Order Placed Successfully!</h1>
        <p className="muted" style={{ marginTop: 0 }}>
          Thank you{user.first_name ? `, ${user.first_name}` : ""}. We're getting your order ready.
        </p>

        <div
          style={{
            display: "inline-flex",
            flexDirection: "column",
            gap: 3,
            margin: "10px 0 14px",
            padding: "12px 22px",
            borderRadius: "var(--radius-md)",
            border: "1px solid var(--border)",
            background: "var(--surface-2, var(--surface))",
          }}
        >
          <span className="muted" style={{ fontSize: 12, letterSpacing: "0.04em", textTransform: "uppercase" }}>
            Order number
          </span>
          <b style={{ fontFamily: "var(--display)", fontSize: 23, letterSpacing: "0.01em" }}>
            {order.order_number}
          </b>
        </div>

        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: 10,
            margin: "0 auto 18px",
            maxWidth: 440,
            padding: "12px 16px",
            borderRadius: "var(--radius-md)",
            border: "1px solid color-mix(in srgb, var(--ok) 28%, var(--border))",
            background: "color-mix(in srgb, var(--ok) 8%, transparent)",
          }}
        >
          <span style={{ color: "var(--ok)", display: "grid", placeItems: "center" }}>
            <Icon name="truck" size={22} />
          </span>
          <div style={{ textAlign: "left" }}>
            <b style={{ display: "block", fontSize: 14 }}>
              {eta ? `Estimated delivery: ${eta}` : "Estimated delivery: 2–4 business days"}
            </b>
            <span className="muted" style={{ fontSize: 12.5 }}>
              We'll update the status as your order moves.
            </span>
          </div>
        </div>

        <div
          style={{
            display: "flex",
            flexWrap: "wrap",
            justifyContent: "center",
            gap: 10,
          }}
        >
          <a className="btn btn-primary" href={href(`order/${order.id}`)}>
            Track order <Icon name="arrowRight" size={15} />
          </a>
          <a className="btn btn-ghost" href={href("home")}>
            Continue shopping
          </a>
        </div>
      </section>

      <section className="panel">
        <h2>Items in this order</h2>
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
          <span className="muted">Sold by {order.store_name ?? "EASYGET"}</span>
          <span className="muted">{payment}</span>
        </div>
        <TotalsBreakdown
          totals={totals}
          showCod={order.payment_method === "cod" || Number(order.cod_fee ?? 0) > 0}
        />
      </section>

      <section className="panel">
        <h2>Delivery address</h2>
        <p style={{ margin: 0, fontSize: 14, lineHeight: 1.6 }}>
          {formatAddress(order.delivery_address)}
          {order.delivery_instructions ? (
            <span className="muted">
              <br />
              Note: {order.delivery_instructions}
            </span>
          ) : null}
        </p>
        <div className="form-actions">
          <a className="link" href={href("orders")}>
            View all orders
          </a>
        </div>
      </section>
    </div>
  );
}

function formatEta(value?: string | null): string | null {
  if (!value) return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  return date.toLocaleDateString("en-IN", {
    weekday: "short",
    day: "numeric",
    month: "short",
  });
}

function formatAddress(addr?: Record<string, unknown>): string {
  if (!addr) return "—";
  const parts = [addr.line1, addr.line2, addr.city, addr.state, addr.postal_code, addr.country].filter(Boolean);
  return parts.join(", ");
}
