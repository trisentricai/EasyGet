import { useQuery } from "@tanstack/react-query";
import { errText, getSummary, getAnalytics, type AdminSummary, type AnalyticsResponse } from "../services/api";
import { Card, EmptyState, Spinner, StatCard } from "../components/ui";
import {
  LineChart,
  Line,
  AreaChart,
  Area,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Legend,
} from "recharts";

const REVENUE_COLOR = "#2874f0";
const ORDERS_COLOR = "#fb641b";
const POSITIVE_COLOR = "#2e7d32";
const NEGATIVE_COLOR = "#c62828";

export function DashboardPage() {
  const summaryQuery = useQuery({
    queryKey: ["admin", "dashboard"],
    queryFn: () => getSummary(),
  });

  const analyticsQuery = useQuery({
    queryKey: ["admin", "analytics"],
    queryFn: () => getAnalytics(),
    staleTime: 5 * 60 * 1000, // 5 minutes
  });

  const error = summaryQuery.error
    ? errText(summaryQuery.error, "Could not load summary")
    : "";
  const summary = summaryQuery.data ?? null;
  const analytics = analyticsQuery.data ?? null;
  const analyticsLoading = analyticsQuery.isLoading;
  const analyticsError = analyticsQuery.error ? errText(analyticsQuery.error, "Could not load analytics") : "";

  if (error) return <Card><EmptyState text={`⚠️ ${error}`} /></Card>;
  if (!summary) return <Spinner />;

  // Format number with Indian rupee notation
  const formatINR = (value: number) => {
    return new Intl.NumberFormat("en-IN", {
      style: "currency",
      currency: "INR",
      maximumFractionDigits: 0,
    }).format(value);
  };

  const formatCompactINR = (value: number) => {
    if (value >= 1e7) return `₹${(value / 1e7).toFixed(1)}Cr`;
    if (value >= 1e5) return `₹${(value / 1e5).toFixed(1)}L`;
    if (value >= 1e3) return `₹${(value / 1e3).toFixed(1)}K`;
    return `₹${value.toFixed(0)}`;
  };

  const toNumber = (value: string | number | undefined): number => {
    if (typeof value === "number") return value;
    if (typeof value === "string") return parseFloat(value) || 0;
    return 0;
  };

  const momGrowth = analytics?.mom_growth ?? 0;
  const isPositiveGrowth = momGrowth >= 0;

  const totalRevenue = toNumber(analytics?.total_revenue ?? summary.revenue.week);
  const totalOrders = analytics?.total_orders ?? summary.orders.total;
  const avgOrderValue = toNumber(analytics?.avg_order_value ?? 0);

  return (
    <div>
      <div className="stats-grid">
        <StatCard
          label="Total Revenue"
          value={formatCompactINR(totalRevenue)}
          sub={
            <>
              <span className={isPositiveGrowth ? "positive-growth" : "negative-growth"}>
                {isPositiveGrowth ? "↑" : "↓"} {Math.abs(momGrowth).toFixed(1)}% MoM
              </span>
            </>
          }
          icon="💰"
        />
        <StatCard
          label="Total Orders"
          value={totalOrders.toLocaleString()}
          sub={`${formatCompactINR(avgOrderValue)} AOV`}
          icon="📦"
        />
        <StatCard
          label="Avg Order Value"
          value={formatCompactINR(avgOrderValue)}
          sub={analytics ? `${analytics.total_orders} orders` : `₹${toNumber(summary.revenue.week)} this week`}
          icon="📊"
        />
        <StatCard
          label="Products"
          value={summary.products.total}
          sub={`${summary.products.low_stock} low on stock`}
          icon="🏷️"
        />
      </div>

      <div className="stats-grid" style={{ marginTop: 24 }}>
        <Card hoverable>
          <h3 style={{ marginTop: 0 }}>📈 Revenue Trend (30 Days)</h3>
          {analyticsError ? (
            <div className="error-state" style={{ padding: 24, textAlign: "center" }}>
              <p className="muted">{analyticsError}</p>
              <button className="btn btn-primary btn-sm" onClick={() => analyticsQuery.refetch()}>
                Retry
              </button>
            </div>
          ) : analyticsLoading ? (
            <div className="chart-skeleton" style={{ height: 300 }} />
          ) : analytics?.revenue_trend ? (
            <ResponsiveContainer width="100%" height={300}>
              <AreaChart data={analytics.revenue_trend} margin={{ top: 10, right: 20, left: 0, bottom: 0 }}>
                <defs>
                  <linearGradient id="revenueGradient" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor={REVENUE_COLOR} stopOpacity={0.3} />
                    <stop offset="95%" stopColor={REVENUE_COLOR} stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#e0e0e0" vertical={false} />
                <XAxis
                  dataKey="date"
                  tickFormatter={(value) => new Date(value).toLocaleDateString("en-IN", { month: "short", day: "numeric" })}
                  tick={{ fill: "#666", fontSize: 11 }}
                  interval="preserveStartEnd"
                />
                <YAxis
                  tickFormatter={(value) => formatCompactINR(value)}
                  tick={{ fill: "#666", fontSize: 11 }}
                  width={60}
                />
                <Tooltip
                  formatter={(value: unknown) => [formatINR(typeof value === "number" ? value : parseFloat(String(value ?? 0))), "Revenue"] as const}
                  labelFormatter={(value) => new Date(String(value)).toLocaleDateString("en-IN", { weekday: "short", month: "short", day: "numeric" })}
                  contentStyle={{ backgroundColor: "#fff", border: "1px solid #e0e0e0", borderRadius: 8, boxShadow: "0 4px 12px rgba(0,0,0,0.1)" }}
                />
                <Area
                  type="monotone"
                  dataKey="revenue"
                  stroke={REVENUE_COLOR}
                  strokeWidth={2}
                  fillOpacity={1}
                  fill="url(#revenueGradient)"
                />
              </AreaChart>
            </ResponsiveContainer>
          ) : null}
        </Card>

        <Card hoverable>
          <h3 style={{ marginTop: 0 }}>🏆 Top Categories (30 Days)</h3>
          {analyticsLoading ? (
            <div className="chart-skeleton" style={{ height: 300 }} />
          ) : analytics?.top_categories ? (
            <ResponsiveContainer width="100%" height={300}>
              <BarChart
                data={analytics.top_categories}
                layout="vertical"
                margin={{ top: 10, right: 20, left: 100, bottom: 20 }}
              >
                <CartesianGrid strokeDasharray="3 3" stroke="#e0e0e0" horizontal={false} />
                <XAxis
                  type="number"
                  tickFormatter={(value) => formatCompactINR(value)}
                  tick={{ fill: "#666", fontSize: 11 }}
                />
                <YAxis
                  dataKey="name"
                  type="category"
                  width={100}
                  tick={{ fill: "#666", fontSize: 11 }}
                />
                <Tooltip
                  formatter={(value: unknown) => [formatINR(typeof value === "number" ? value : parseFloat(String(value ?? 0))), "Revenue"] as const}
                  contentStyle={{ backgroundColor: "#fff", border: "1px solid #e0e0e0", borderRadius: 8, boxShadow: "0 4px 12px rgba(0,0,0,0.1)" }}
                />
                <Legend />
                <Bar
                  dataKey="revenue"
                  name="Revenue"
                  fill={REVENUE_COLOR}
                  radius={[0, 4, 4, 0]}
                />
              </BarChart>
            </ResponsiveContainer>
          ) : null}
        </Card>
      </div>

      <div className="stats-grid" style={{ marginTop: 24 }}>
        <Card hoverable>
          <h3 style={{ marginTop: 0 }}>🏆 Top Products (by Quantity)</h3>
          {analyticsLoading ? (
            <div className="chart-skeleton" style={{ height: 300 }} />
          ) : analytics?.top_products ? (
            <div style={{ display: "flex", flexDirection: "column", gap: 12 }}>
              {analytics.top_products.map((p, i) => (
                <div
                  key={`${p.name}-${p.sku}`}
                  style={{
                    display: "flex",
                    alignItems: "center",
                    gap: 12,
                    padding: "12px 16px",
                    background: i % 2 === 0 ? "#fafafa" : "transparent",
                    borderRadius: 8,
                    transition: "background 0.2s",
                  }}
                  onMouseEnter={(e) => { e.currentTarget.style.background = "#f0f4ff"; }}
                  onMouseLeave={(e) => { e.currentTarget.style.background = i % 2 === 0 ? "#fafafa" : "transparent"; }}
                >
                  <span style={{ fontWeight: 700, color: REVENUE_COLOR, minWidth: 28 }}>{i + 1}</span>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontWeight: 600, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                      {p.name} {p.variant && <span className="muted">· {p.variant}</span>}
                    </div>
                    <div className="muted" style={{ fontSize: 12, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>
                      SKU: {p.sku}
                    </div>
                  </div>
                  <div style={{ textAlign: "right" }}>
                    <div style={{ fontWeight: 700, color: POSITIVE_COLOR }}>{p.quantity} units</div>
                    <div className="muted" style={{ fontSize: 12 }}>{formatINR(p.revenue)}</div>
                  </div>
                </div>
              ))}
            </div>
          ) : null}
        </Card>
      </div>

      <div className="stats-grid" style={{ marginTop: 24 }}>
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