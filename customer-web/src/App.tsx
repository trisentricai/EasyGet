import { useCallback, useEffect, useRef, useState } from "react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
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

const queryClient = new QueryClient({
  defaultOptions: {
    queries: { staleTime: 30_000, refetchOnWindowFocus: false, retry: 1 },
  },
});

const THEME_KEY = "eg-theme";
type ThemeMode = "light" | "dark";

function applyTheme(next: ThemeMode) {
  const root = document.documentElement;
  root.setAttribute("data-theme-transition", "");
  root.dataset.theme = next;
  window.setTimeout(() => root.removeAttribute("data-theme-transition"), 260);
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <ToastProvider>
        <AuthProvider>
          <CartProvider>
            <StorefrontProvider>
              <Shell />
            </StorefrontProvider>
          </CartProvider>
        </AuthProvider>
      </ToastProvider>
    </QueryClientProvider>
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

  const [themeMode, setThemeMode] = useState<ThemeMode>(() =>
    document.documentElement.dataset.theme === "dark" ? "dark" : "light",
  );

  useEffect(() => {
    const mq = window.matchMedia?.("(prefers-color-scheme: dark)");
    if (!mq) return;
    const onSys = (e: MediaQueryListEvent) => {
      if (localStorage.getItem(THEME_KEY)) return;
      const next: ThemeMode = e.matches ? "dark" : "light";
      applyTheme(next);
      setThemeMode(next);
    };
    mq.addEventListener("change", onSys);
    return () => mq.removeEventListener("change", onSys);
  }, []);

  const toggleTheme = () => {
    const next: ThemeMode = themeMode === "dark" ? "light" : "dark";
    try {
      localStorage.setItem(THEME_KEY, next);
    } catch {
      /* storage unavailable — theme just won't persist */
    }
    applyTheme(next);
    setThemeMode(next);
  };

  useEffect(() => {
    if (ready && !user && personal) navigate("login", { replace: true });
  }, [ready, user, personal]);

  // Global 401 → sign out silently.
  useEffect(() => {
    setUnauthorizedHandler(() => signOut());
  }, [signOut]);

  // Category strip under the header (Flipkart-style nav row).
  // Public: guests browse too, so load it regardless of auth state.
  useEffect(() => {
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
  }, []);

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

  const storeName = data?.store?.name ?? "EASYGET";
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
            <span className="brand-name">{loading ? "EASYGET" : storeName}</span>
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
          <button
            className="nav-theme"
            type="button"
            onClick={toggleTheme}
            aria-label={themeMode === "dark" ? "Switch to light mode" : "Switch to dark mode"}
            aria-pressed={themeMode === "dark"}
            title={themeMode === "dark" ? "Light mode" : "Dark mode"}
          >
            {themeMode === "dark" ? <MoonIcon /> : <SunIcon />}
          </button>
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

      {categories.length > 0 && <CategoryStrip categories={categories} activeRoute={activeRoute} activeCategory={route.query.get("category") ?? undefined} />}

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
          <span className="footer-pay" aria-label="Accepted payment methods">
            <PayBadge label="UPI" mark={<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M3 6.5A3.5 3.5 0 0 1 6.5 3h11A3.5 3.5 0 0 1 21 6.5v11a3.5 3.5 0 0 1-3.5 3.5h-11A3.5 3.5 0 0 1 3 17.5v-11Zm7.4 1.6v7.8h1.7V8.1h-1.7Zm-4.2 7.8V8.1H4.6v7.8h1.6Zm11.3-7.8-3 3.9 3 3.9h-1.9l-3-3.9 3-3.9h1.9Z" /></svg>} />
            <PayBadge label="VISA" mark={<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M7.6 15.9 9.5 8h2l-1.9 7.9h-2Zm7.9-7.7c-.4-.2-1.1-.3-1.9-.3-2.1 0-3.6 1.1-3.6 2.7 0 1.2 1 1.8 1.8 2.2.9.4 1.2.7 1.2 1 0 .5-.6.8-1.2.8-.8 0-1.3-.1-2-.4l-.3 1.7c.6.3 1.5.5 2.4.5 2.3 0 3.8-1.1 3.8-2.8 0-.9-.6-1.6-1.7-2.2-.8-.4-1.2-.7-1.2-1 0-.4.4-.7 1.2-.7.6 0 1.1.1 1.5.3l.2-1.6-.2-.2Zm4.9 7.7-1.6-7.9h-1.8c-.4 0-.8.2-.9.6l-3 7.3h2.2l.4-1.2h2.7l.2 1.2h1.8Zm-4.1-2.8 1.1-3 .6 3h-1.7ZM7.1 8l-2.3 5.4-.2-1.2-.7-3.4C3.8 8.2 3.3 8 2.7 8H.9L.9 8c.7.1 1.4.4 1.9.9L4.5 16h2.3L10.2 8H7.1Z" transform="translate(2 0) scale(0.9)" /></svg>} />
            <PayBadge label="Mastercard" mark={
              <svg viewBox="0 0 24 24" aria-hidden="true">
                <circle cx="9" cy="12" r="5.2" fill="#EB001B" />
                <circle cx="15" cy="12" r="5.2" fill="#F79E1B" />
                <path d="M12 8.1a5.2 5.2 0 0 0 0 7.8 5.2 5.2 0 0 0 0-7.8Z" fill="#FF5F00" />
              </svg>
            } />
            <PayBadge label="RuPay" mark={
              <svg viewBox="0 0 24 24" aria-hidden="true">
                <path d="M3 5h11a4 4 0 0 1 4 4v10a0 0 0 0 1 0 0h-4a0 0 0 0 1 0 0V9.5A1.5 1.5 0 0 0 12.5 8H3V5Z" fill="#2f7c31" />
                <path d="M5 10h6.5A2.5 2.5 0 0 1 14 12.5V19h-3v-5.5a.5.5 0 0 0-.5-.5H5v-3Z" fill="#f97316" />
              </svg>
            } />
            <PayBadge label="Cash on Delivery" mark={<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20Zm1 15.7v1.2h-2v-1.2c-1.5-.2-2.7-1-3-2.4l1.9-.5c.2.8.9 1.3 2.1 1.3 1 0 1.6-.4 1.6-1 0-.5-.4-.8-1.9-1.1-2-.4-3.4-1.1-3.4-2.9 0-1.4 1-2.4 2.7-2.7V7.2h2v1.2c1.3.2 2.3 1 2.6 2.2l-1.9.5c-.2-.7-.8-1.1-1.8-1.1-.9 0-1.4.4-1.4.9 0 .6.5.8 2.1 1.1 2.1.4 3.3 1.2 3.3 3 0 1.5-1.1 2.5-2.9 2.7Z" /></svg>} />
          </span>
          <span className="footer-note">© {new Date().getFullYear()} <b>{storeName}</b> — quick-commerce, beautifully simple.</span>
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

function SunIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" aria-hidden="true">
      <circle cx="12" cy="12" r="4" />
      <path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4" />
    </svg>
  );
}

function MoonIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      <path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8Z" />
    </svg>
  );
}

/**
 * Flipkart-style category strip: single row that always scrolls horizontally
 * (touch/trackpad/wheel), plus arrow buttons + drag-to-scroll when the items
 * overflow, so nothing is ever clipped off-screen.
 */
function CategoryStrip({
  categories,
  activeRoute,
  activeCategory,
}: {
  categories: Category[];
  activeRoute: string;
  activeCategory?: string;
}) {
  const scrollerRef = useRef<HTMLDivElement | null>(null);
  const [canPrev, setCanPrev] = useState(false);
  const [canNext, setCanNext] = useState(false);
  const drag = useRef<{ startX: number; startScroll: number; moved: boolean } | null>(null);

  const updateArrows = useCallback(() => {
    const el = scrollerRef.current;
    if (!el) return;
    setCanPrev(el.scrollLeft > 4);
    setCanNext(el.scrollLeft + el.clientWidth < el.scrollWidth - 4);
  }, []);

  useEffect(() => {
    updateArrows();
    const el = scrollerRef.current;
    if (!el) return;
    el.addEventListener("scroll", updateArrows, { passive: true });
    const ro = new ResizeObserver(updateArrows);
    ro.observe(el);
    return () => {
      el.removeEventListener("scroll", updateArrows);
      ro.disconnect();
    };
  }, [updateArrows, categories.length]);

  const nudge = (dir: 1 | -1) => {
    const el = scrollerRef.current;
    if (!el) return;
    el.scrollBy({ left: dir * Math.max(200, el.clientWidth * 0.8), behavior: "smooth" });
  };

  const onMouseDown = (e: React.MouseEvent) => {
    if (e.button !== 0) return;
    const el = scrollerRef.current;
    if (!el || el.scrollWidth <= el.clientWidth) return;
    drag.current = { startX: e.pageX, startScroll: el.scrollLeft, moved: false };
  };
  const onMouseMove = (e: React.MouseEvent) => {
    const d = drag.current;
    const el = scrollerRef.current;
    if (!d || !el) return;
    const dx = e.pageX - d.startX;
    if (Math.abs(dx) > 4) d.moved = true;
    el.scrollLeft = d.startScroll - dx;
  };
  const endDrag = () => { drag.current = null; };

  const onClickCapture = (e: React.MouseEvent) => {
    // Swallow the click if it was actually a drag — prevents accidental nav.
    if (drag.current?.moved) {
      e.preventDefault();
      e.stopPropagation();
      drag.current = null;
    }
  };

  return (
    <nav className={`catstrip ${canPrev || canNext ? "has-arrows" : ""}`} aria-label="Categories">
      {canPrev && (
        <button className="catstrip-arrow prev" aria-label="Scroll categories left" onClick={() => nudge(-1)}>
          <Icon name="chevronLeft" size={16} />
        </button>
      )}
      <div
        className="catstrip-inner"
        ref={scrollerRef}
        onMouseDown={onMouseDown}
        onMouseMove={onMouseMove}
        onMouseUp={endDrag}
        onMouseLeave={endDrag}
        onClickCapture={onClickCapture}
      >
        {categories.map((c) => (
          <a
            key={c.slug}
            className="catstrip-item"
            href={href(`browse?category=${c.slug}`)}
            aria-current={activeRoute === "browse" && activeCategory === c.slug ? "page" : undefined}
          >
            <span className="catstrip-dot">{c.name.slice(0, 1).toUpperCase()}</span>
            <span>{c.name}</span>
          </a>
        ))}
      </div>
      {canNext && (
        <button className="catstrip-arrow next" aria-label="Scroll categories right" onClick={() => nudge(1)}>
          <Icon name="chevronRight" size={16} />
        </button>
      )}
    </nav>
  );
}

/** Payment-method badge with a brand mark + accessible label. */
function PayBadge({ label, mark }: { label: string; mark: React.ReactNode }) {
  return (
    <span className="pay-badge" title={label}>
      <span className="pay-badge-mark" aria-hidden="true">{mark}</span>
      <span className="pay-badge-label">{label}</span>
    </span>
  );
}
