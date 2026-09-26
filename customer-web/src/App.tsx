import { useEffect, useState } from "react";
import { AuthProvider, useAuth } from "./context/AuthContext";
import { CartProvider, useCart } from "./context/CartContext";
import { StorefrontProvider, useStorefront } from "./context/StorefrontContext";
import { ToastProvider } from "./context/ToastContext";
import { href, navigate, useHashRoute } from "./hooks/useHashRoute";
import { listCategories, setUnauthorizedHandler, type Category } from "./services/api";
import { HomePage } from "./pages/HomePage";
import { AuthPage } from "./pages/AuthPage";
import { BrowsePage } from "./pages/BrowsePage";
import { ProductPage } from "./pages/ProductPage";
import { SearchPage } from "./pages/SearchPage";
import { CartPage } from "./pages/CartPage";
import { CheckoutPage } from "./pages/CheckoutPage";
import { OrderDetailPage, OrdersPage } from "./pages/OrdersPage";
import { AccountPage } from "./pages/AccountPage";
import { WishlistPage } from "./pages/WishlistPage";
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
  const [categories, setCategories] = useState<Category[]>([]);

  // Routes that show personal data — guests are sent to login before
  // anything renders (no cached-viewing window).
  const personal = ["cart", "checkout", "orders", "order", "account", "wishlist"].includes(route.name);

  useEffect(() => {
    if (ready && !user && personal) navigate("login", { replace: true });
  }, [ready, user, personal]);

  // Global 401 → sign out silently.
  useEffect(() => {
    setUnauthorizedHandler(() => signOut());
  }, [signOut]);

  // Category strip under the header (Flipkart-style nav row).
  useEffect(() => {
    if (!user) {
      setCategories([]);
      return;
    }
    let cancelled = false;
    listCategories()
      .then((d) => {
        if (cancelled) return;
        const raw = Array.isArray(d) ? d : (d.results ?? []);
        setCategories(raw);
      })
      .catch(() => {
        if (!cancelled) setCategories([]);
      });
    return () => {
      cancelled = true;
    };
  }, [user]);

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
      else if (theme.button_style === "SQUARE") root.style.setProperty("--radius-btn", "3px");
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
  const activeRoute = route.name;

  const page = (() => {
    // Personal routes: hold rendering until auth resolves; guests are
    // redirected to login by the effect above.
    if (personal && (!ready || !user)) return <Spinner />;
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
    if (route.name === "wishlist") return <WishlistPage />;
    return <HomePage />;
  })();

  return (
    <>
      <header className="topnav">
        <div className="brand" onClick={() => navigate("home")}>
          <div className="brand-mark">EG</div>
          <div>
            <span className="brand-name">{loading ? "EasyGet" : storeName}</span>
            <span className="brand-city">{loading ? "explore" : `${storeCity || "online"} · delivery`}</span>
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
          <span className="search-ico"><Icon name="search" size={17} /></span>
          <input name="q" placeholder="Search for products, brands and more" aria-label="Search products" />
          <button type="submit">Search</button>
        </form>

        <div className="nav-actions">
          {!ready ? null : user ? (
            <a className="nav-login" href={href("account")}>
              <b>{(user.first_name || user.email.split("@")[0])}</b>
              <small>Account &amp; Orders</small>
            </a>
          ) : (
            <button className="nav-login" onClick={() => navigate("login")}>
              <b>Login</b>
              <small>Signup</small>
            </button>
          )}
          <a className="nav-wish" href={href("wishlist")} aria-label="Wishlist">
            <Icon name="heart" size={19} />
            <span>Wishlist</span>
          </a>
          <a className="nav-orders" href={href("orders")}>
            <Icon name="box" size={19} />
            <span>Orders</span>
          </a>
          <a className="nav-cart" href={href("cart")}>
            <span className="nav-cart-ico">
              <Icon name="cart" size={20} />
              {count > 0 ? <CartBubble count={count} /> : null}
            </span>
            <span>
              <b>Cart</b>
            </span>
          </a>
        </div>
      </header>

      {categories.length > 0 && (
        <nav className="catstrip" aria-label="Categories">
          <div className="catstrip-inner">
            {categories.map((c) => (
              <a
                key={c.slug}
                className="catstrip-item"
                href={href(`browse?category=${c.slug}`)}
                aria-current={activeRoute === "browse" && route.query.get("category") === c.slug ? "page" : undefined}
              >
                <span className="catstrip-dot">{c.name.slice(0, 1).toUpperCase()}</span>
                <span>{c.name}</span>
              </a>
            ))}
          </div>
        </nav>
      )}

      <div className="offer-strip" aria-hidden="true">
        <div className="offer-track">
          <span>Free delivery over ₹499</span><i>✦</i>
          <span>7-day easy returns</span><i>✦</i>
          <span>Cash on delivery available</span><i>✦</i>
          <span>Everyday low prices</span><i>✦</i>
          <span>Free delivery over ₹499</span><i>✦</i>
          <span>7-day easy returns</span><i>✦</i>
          <span>Cash on delivery available</span><i>✦</i>
          <span>Everyday low prices</span><i>✦</i>
        </div>
      </div>

      {page}

      <footer className="footer">
        <div className="footer-cols">
          <div className="footer-col">
            <h4>About</h4>
            <a href={href("home")}>Contact Us</a>
            <a href={href("home")}>About Us</a>
            <a href={href("home")}>Careers</a>
          </div>
          <div className="footer-col">
            <h4>Help</h4>
            <a href={href("orders")}>Track Order</a>
            <a href={href("home")}>Returns</a>
            <a href={href("home")}>FAQ</a>
          </div>
          <div className="footer-col">
            <h4>Consumer Policy</h4>
            <a href={href("home")}>Return Policy</a>
            <a href={href("home")}>Terms of Use</a>
            <a href={href("home")}>Privacy</a>
          </div>
          <div className="footer-col footer-col-contact">
            <h4>Mail Us</h4>
            <p>{storeName}{storeCity ? `, ${storeCity}` : ""}</p>
            <p className="footer-social">
              <span className="soc">f</span>
              <span className="soc">𝕏</span>
              <span className="soc">in</span>
            </p>
          </div>
        </div>
        <div className="footer-bar">
          <span className="footer-pay">
            <span className="pay-badge">UPI</span>
            <span className="pay-badge">VISA</span>
            <span className="pay-badge">MC</span>
            <span className="pay-badge">RuPay</span>
            <span className="pay-badge">COD</span>
          </span>
          <span className="footer-note">© {new Date().getFullYear()} <b>EasyGet</b> — quick-commerce, beautifully simple.</span>
        </div>
      </footer>

      <nav className="bottomnav" aria-label="Primary">
        <a className={activeRoute === "home" ? "on" : ""} href={href("home")}>
          <Icon name="home" size={20} /><span>Home</span>
        </a>
        <a className={activeRoute === "search" ? "on" : ""} href={href("search")}>
          <Icon name="search" size={20} /><span>Search</span>
        </a>
        <a className={activeRoute === "cart" || activeRoute === "checkout" ? "on" : ""} href={href("cart")}>
          <span className="nav-cart-ico">
            <Icon name="cart" size={20} />
            {count > 0 ? <CartBubble count={count} /> : null}
          </span>
          <span>Cart</span>
        </a>
        <a className={activeRoute === "account" || activeRoute === "orders" ? "on" : ""} href={href("account")}>
          <Icon name="user" size={20} /><span>Account</span>
        </a>
      </nav>
    </>
  );
}

function CartBubble({ count }: { count: number }) {
  const ref = usePopOnChange(count);
  return <span className="bubble" ref={ref}>{count > 99 ? "99+" : count}</span>;
}
