import { useEffect, useState } from "react";
import { AuthProvider, useAuth } from "./context/AuthContext";
import { CartProvider, useCart } from "./context/CartContext";
import { StorefrontProvider, useStorefront } from "./context/StorefrontContext";
import { ToastProvider } from "./context/ToastContext";
import { href, navigate, useHashRoute } from "./hooks/useHashRoute";
import { setUnauthorizedHandler } from "./services/api";
import { HomePage } from "./pages/HomePage";
import { AuthPage } from "./pages/AuthPage";
import { BrowsePage } from "./pages/BrowsePage";
import { ProductPage } from "./pages/ProductPage";
import { SearchPage } from "./pages/SearchPage";
import { CartPage } from "./pages/CartPage";
import { CheckoutPage } from "./pages/CheckoutPage";
import { OrderDetailPage, OrdersPage } from "./pages/OrdersPage";
import { AccountPage } from "./pages/AccountPage";
import { Icon } from "./components/icons";
import { Spinner, usePopOnChange } from "./components/ui";

export default function App() {
  return (
    <ToastProvider>
      <AuthProvider>
        <CartProvider>
          <StorefrontProvider>
            <Shell />
          </StorefrontProvider>
        </CartProvider>
      </AuthProvider>
    </ToastProvider>
  );
}

function Shell() {
  const route = useHashRoute();
  const { data, loading, error } = useStorefront();
  const { user, ready, signOut } = useAuth();
  const { count } = useCart();

  // Global 401 → sign out silently.
  useEffect(() => {
    setUnauthorizedHandler(() => signOut());
  }, [signOut]);

  // Apply the store's theme as CSS variables.
  useEffect(() => {
    const theme = data?.theme;
    const root = document.documentElement;
    if (theme) {
      root.style.setProperty("--primary", theme.primary_color);
      root.style.setProperty("--secondary", theme.secondary_color);
      root.style.setProperty("--bg", theme.background_color);
      root.style.setProperty("--font", theme.font_family);
      if (theme.button_style === "PILL") root.style.setProperty("--radius-btn", "999px");
      else if (theme.button_style === "SQUARE") root.style.setProperty("--radius-btn", "2px");
      else root.style.setProperty("--radius-btn", "10px");
    } else {
      root.style.removeProperty("--primary");
      root.style.removeProperty("--secondary");
      root.style.removeProperty("--bg");
      root.style.removeProperty("--font");
      root.style.removeProperty("--radius-btn");
    }
  }, [data]);

  const storeName = data?.store?.name ?? "EasyGet";
  const storeCity = data?.store?.city ?? "";
  const routeKey = `${route.name}:${route.params.join("/") ?? ""}`;

  const page = (() => {
    if (route.name === "login") return <AuthPage />;
    if (route.name === "home") return <HomePage />;
    if (route.name === "browse") return <BrowsePage key={route.query.get("category") ?? ""} initialCategory={route.query.get("category") ?? undefined} />;
    if (route.name === "product") return <ProductPage key={route.params[0]} slug={route.params[0] ?? ""} />;
    if (route.name === "search") return <SearchPage key={route.query.get("q") ?? ""} initialQuery={route.query.get("q") ?? undefined} />;
    if (route.name === "cart") return <CartPage />;
    if (route.name === "checkout") return <CheckoutPage />;
    if (route.name === "orders") return <OrdersPage />;
    if (route.name === "order") return <OrderDetailPage key={routeKey} id={route.params[0] ?? "0"} />;
    if (route.name === "account") return <AccountPage />;
    return <HomePage />;
  })();

  return (
    <>
      <header className="topnav">
        <div className="brand" onClick={() => navigate("home")}>
          <div className="brand-mark">EG</div>
          <div>
            <span className="brand-name">{loading ? "EasyGet" : storeName}</span>
            <span className="brand-city">{loading ? "" : storeCity || "store"}</span>
          </div>
        </div>

        <form
          className="searchform"
          onSubmit={(e) => {
            e.preventDefault();
            const input = (e.currentTarget.elements.namedItem("q") as HTMLInputElement) ?? null;
            if (input?.value.trim()) navigate(`search?q=${encodeURIComponent(input.value.trim())}`);
          }}
        >
          <input name="q" placeholder="Search products…" aria-label="Search products" />
          <button type="submit">Search</button>
        </form>

        <div className="nav-spacer" />

        <a className="icon-btn" title="Orders" aria-label="Orders" href={href("orders")}>
          <Icon name="box" size={19} />
        </a>
        <a className="icon-btn" title="Cart" aria-label={`Cart${count ? `, ${count} items` : ""}`} href={href("cart")}>
          <Icon name="cart" size={19} />
          {count > 0 ? <CartBubble count={count} /> : null}
        </a>
        {!ready ? null : user ? (
          <a className="icon-btn" title="Account" aria-label="Account" href={href("account")}>
            <Icon name="user" size={19} />
          </a>
        ) : (
          <button className="btn btn-sm" onClick={() => navigate("login")}>Sign in</button>
        )}
      </header>

      {page}

      <footer className="footer">
        <span className="brand-mark">EG</span>
        Powered by <b>EasyGet</b> — quick-commerce, beautifully simple.
      </footer>
    </>
  );
}

function CartBubble({ count }: { count: number }) {
  const ref = usePopOnChange(count);
  return <span className="bubble" ref={ref}>{count > 99 ? "99+" : count}</span>;
}
