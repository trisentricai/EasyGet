import { useEffect, useState } from "react";
import { useAuth } from "./context/AuthContext";
import { useTheme } from "./context/ThemeContext";
import { navigate, useHashRoute } from "./hooks/useHashRoute";
import { LoginPage, ThemeToggle } from "./pages/LoginPage";
import { DashboardPage } from "./pages/DashboardPage";
import { CategoriesPage } from "./pages/CategoriesPage";
import { ProductsPage } from "./pages/ProductsPage";
import { InventoryPage } from "./pages/InventoryPage";
import { StorefrontPage } from "./pages/StorefrontPage";
import { Spinner } from "./components/ui";

const NAV: Array<{ route: string; icon: string; label: string }> = [
  { route: "dashboard", icon: "📊", label: "Dashboard" },
  { route: "categories", icon: "🧩", label: "Categories" },
  { route: "products", icon: "🛍️", label: "Products" },
  { route: "inventory", icon: "📦", label: "Inventory" },
  { route: "storefront", icon: "🎨", label: "Storefront designer" },
];

const TITLES: Record<string, string> = {
  dashboard: "Overview",
  categories: "Categories",
  products: "Products",
  inventory: "Inventory",
  storefront: "Storefront designer",
};

export default function App() {
  const { user, ready, signOut } = useAuth();
  const route = useHashRoute();

  if (!ready) {
    return (
      <div className="login-wrap">
        <Spinner />
      </div>
    );
  }

  if (!user) return <LoginPage onDone={() => navigate("dashboard")} />;

  return (
    <Shell route={route} email={user.email} role={user.role} onSignOut={signOut}>
      {route === "dashboard" && <DashboardPage />}
      {route === "categories" && <CategoriesPage />}
      {route === "products" && <ProductsPage />}
      {route === "inventory" && <InventoryPage />}
      {route === "storefront" && <StorefrontPage />}
      {!TITLES[route] && <DashboardPage />}
    </Shell>
  );
}

function Shell({
  route,
  email,
  role,
  onSignOut,
  children,
}: {
  route: string;
  email: string;
  role: string;
  onSignOut: () => void;
  children: React.ReactNode;
}) {
  const { theme } = useTheme();
  const [collapsed, setCollapsed] = useState(false);
  const [now, setNow] = useState(new Date());

  useEffect(() => {
    const t = window.setInterval(() => setNow(new Date()), 30_000);
    return () => window.clearInterval(t);
  }, []);

  return (
    <div className={`shell ${collapsed ? "sidebar-collapsed" : ""}`}>
      <aside className="sidebar">
        <div className="brand">
          <div className="brand-mark">EG</div>
          <div className="brand-name">
            EASYGET
            <small>ADMIN</small>
          </div>
        </div>
        {NAV.map((item) => (
          <button
            key={item.route}
            className={`nav-item ${route === item.route ? "active" : ""}`}
            onClick={() => navigate(item.route)}
            title={item.label}
          >
            <span className="ico">{item.icon}</span>
            <span>{item.label}</span>
          </button>
        ))}
        <div className="sidebar-footer">
          <button
            className="nav-item"
            onClick={() => setCollapsed((c) => !c)}
            title="Collapse sidebar"
          >
            <span className="ico">{collapsed ? "»" : "«"}</span>
            <span>Collapse</span>
          </button>
          <button className="nav-item" onClick={onSignOut} title="Sign out">
            <span className="ico">🚪</span>
            <span>Sign out</span>
          </button>
        </div>
      </aside>

      <div className="main">
        <header className="topbar">
          <h1>{TITLES[route] ?? "Overview"}</h1>
          <span className="badge">
            {now.toLocaleDateString(undefined, { weekday: "short", day: "numeric", month: "short" })} ·{" "}
            {now.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}
          </span>
          <span className="badge ok" title={email}>
            {role === "ADMIN" ? "🛡️" : "👤"} {email}
          </span>
          <ThemeToggle />
        </header>
        <main className="content" key={route}>
          {children}
        </main>
      </div>
    </div>
  );
}
