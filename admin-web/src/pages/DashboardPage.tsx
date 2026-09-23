import { useEffect, useState } from "react";
import { errText, getSummary, type AdminSummary } from "../services/api";
import { Card, EmptyState, Spinner, StatCard } from "../components/ui";

export function DashboardPage() {
  const [summary, setSummary] = useState<AdminSummary | null>(null);
  const [error, setError] = useState("");

  useEffect(() => {
    getSummary()
      .then(setSummary)
      .catch((e) => setError(errText(e, "Could not load summary")));
  }, []);

  if (error) return <Card><EmptyState text={`⚠️ ${error}`} /></Card>;
  if (!summary) return <Spinner />;

  return (
    <div>
      <div className="stats-grid">
        <StatCard
          label="Customers"
          value={summary.users.total}
          sub={`+${summary.users.today} today · +${summary.users.week} this week`}
          icon="👥"
        />
        <StatCard
          label="Orders"
          value={summary.orders.total}
          sub={`${summary.orders.pending} pending · +${summary.orders.week} this week`}
          icon="📦"
        />
        <StatCard
          label="Revenue (week)"
          value={`₹${summary.revenue.week}`}
          sub={`₹${summary.revenue.today} today`}
          icon="💰"
        />
        <StatCard
          label="Products"
          value={summary.products.total}
          sub={`${summary.products.low_stock} low on stock`}
          icon="🏷️"
        />
      </div>

      <div className="stats-grid">
        <Card hoverable>
          <h3 style={{ marginTop: 0 }}>⚡ Quick actions</h3>
          <p className="muted">
            Everything on this dashboard writes straight to the live API — your customer
            website and Flutter app see the change instantly.
          </p>
          <div style={{ display: "flex", gap: 10, flexWrap: "wrap" }}>
            <a className="btn btn-primary btn-sm" href="#/categories">
              Manage categories
            </a>
            <a className="btn btn-ghost btn-sm" href="#/products">
              Manage products
            </a>
            <a className="btn btn-ghost btn-sm" href="#/storefront">
              Storefront designer
            </a>
          </div>
        </Card>
        <Card hoverable>
          <h3 style={{ marginTop: 0 }}>🛒 Fulfilment queue</h3>
          <p className="muted">
            {summary.orders.pending === 0
              ? "No pending orders — all caught up."
              : `${summary.orders.pending} order${summary.orders.pending === 1 ? "" : "s"} waiting to be confirmed.`}
          </p>
          <div style={{ display: "flex", gap: 10, flexWrap: "wrap", marginTop: 12 }}>
            <a className="btn btn-primary btn-sm" href="#/orders">
              Open fulfilment queue
            </a>
            <span className={`badge ${summary.orders.pending === 0 ? "ok" : "warn"}`}>
              {summary.orders.pending === 0 ? "All clear" : "Needs attention"}
            </span>
          </div>
        </Card>
      </div>
    </div>
  );
}
