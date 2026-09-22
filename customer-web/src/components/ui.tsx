import { useEffect, type ReactNode } from "react";
import { href } from "../hooks/useHashRoute";
import { img, type Product } from "../services/api";

export function money(value: string | number | null | undefined): string {
  if (value === null || value === undefined || value === "") return "—";
  const n = typeof value === "string" ? Number(value) : value;
  if (Number.isNaN(n)) return String(value);
  return `₹${n.toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
}

export function Price({
  price,
  mrp,
  discount,
  size = "md",
}: {
  price: string | null | undefined;
  mrp?: string | null;
  discount?: number;
  size?: "sm" | "md" | "lg";
}) {
  return (
    <div className={`price price-${size}`}>
      <span className="price-now">{money(price)}</span>
      {mrp && Number(mrp) > Number(price ?? 0) ? <s className="price-mrp">{money(mrp)}</s> : null}
      {discount && discount > 0 ? <span className="price-off">{discount}% off</span> : null}
    </div>
  );
}

export function ProductCard({ product, delay = 0 }: { product: Product; delay?: number }) {
  const image = img(product.primary_image);
  return (
    <a className="product-card" style={delay ? { animationDelay: `${delay}ms` } : undefined} href={href(`product/${product.slug}`)}>
      <div className="product-thumb">
        {image ? <img src={image} alt={product.name} loading="lazy" /> : <span className="ph">🛒</span>}
        {product.is_featured ? <span className="chip chip-featured">★ Featured</span> : null}
      </div>
      <div className="product-body">
        <div className="product-name" title={product.name}>{product.name}</div>
        <div className="product-meta">
          {product.brand ? <span className="brand">{product.brand}</span> : null}
          {product.category ? <span className="cat">{product.category.name}</span> : null}
        </div>
        <Price price={product.base_price} mrp={product.mrp} discount={product.discount_percent} size="sm" />
      </div>
    </a>
  );
}

export function Section({ title, subtitle, children, action }: { title?: string; subtitle?: string; children: ReactNode; action?: ReactNode }) {
  return (
    <section className="section">
      {(title || action) && (
        <div className="section-head">
          <div>
            {title ? <h2>{title}</h2> : null}
            {subtitle ? <p className="muted">{subtitle}</p> : null}
          </div>
          {action}
        </div>
      )}
      {children}
    </section>
  );
}

export function Spinner() {
  return <div className="spinner" role="status" aria-label="Loading" />;
}

export function CardSkeletonGrid({ count = 8 }: { count?: number }) {
  return (
    <div className="grid grid-products">
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className="card-skeleton" />
      ))}
    </div>
  );
}

export function EmptyState({ icon = "🛒", title, text, action }: { icon?: string; title: string; text?: string; action?: ReactNode }) {
  return (
    <div className="empty-state">
      <div className="empty-ico">{icon}</div>
      <h3>{title}</h3>
      {text ? <p className="muted">{text}</p> : null}
      {action}
    </div>
  );
}

export function StatusChip({ status }: { status: string }) {
  const s = status.toLowerCase();
  const cls = ["pending", "confirmed", "preparing", "ready"].includes(s)
    ? "pending"
    : s === "delivered"
      ? "ok"
      : s === "cancelled"
        ? "err"
        : "info";
  return <span className={`chip chip-${cls}`}>{status.replaceAll("_", " ").toLowerCase()}</span>;
}

export function SignInGate({ title, text }: { title: string; text: string }) {
  return (
    <div className="auth-wrap">
      <div className="auth-card" style={{ textAlign: "center" }}>
        <div style={{ fontSize: 40, marginBottom: 8 }}>🔐</div>
        <h1>{title}</h1>
        <p className="sub">{text}</p>
        <button className="btn btn-block" onClick={() => (window.location.hash = "#/login")}>
          Sign in / Create account
        </button>
      </div>
    </div>
  );
}
