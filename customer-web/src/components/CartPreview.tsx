import { useEffect, useRef, useState, type ReactNode } from "react";
import { useCart } from "../context/CartContext";
import { useDeliveryConfig } from "../hooks/useDeliveryConfig";
import { href } from "../hooks/useHashRoute";
import { money, Monogram } from "./ui";
import { Icon } from "./icons";
import { FreeShippingProgress } from "./FreeShippingProgress";

/**
 * Header mini-cart: opens on hover or keyboard focus under the cart link.
 * Hidden on small screens (CSS) where the bottom nav and CartPage take over.
 */
export function CartPreview({
  active,
  bubble,
}: {
  active?: boolean;
  bubble?: ReactNode;
}) {
  const { cart, count } = useCart();
  const { config } = useDeliveryConfig();
  const [open, setOpen] = useState(false);
  const closeTimer = useRef<number | null>(null);
  const wrapRef = useRef<HTMLDivElement>(null);

  useEffect(
    () => () => {
      if (closeTimer.current) window.clearTimeout(closeTimer.current);
    },
    [],
  );

  const openPanel = () => {
    if (closeTimer.current) window.clearTimeout(closeTimer.current);
    setOpen(true);
  };

  const closeSoon = () => {
    if (closeTimer.current) window.clearTimeout(closeTimer.current);
    closeTimer.current = window.setTimeout(() => setOpen(false), 140);
  };

  const items = cart?.items ?? [];
  const preview = items.slice(0, 3);
  const hiddenCount = items.length - preview.length;

  return (
    <div
      className="nav-cart-wrap"
      ref={wrapRef}
      onMouseEnter={openPanel}
      onMouseLeave={closeSoon}
      onFocus={openPanel}
      onBlur={(e) => {
        if (!e.currentTarget.contains(e.relatedTarget as Node | null)) setOpen(false);
      }}
      onKeyDown={(e) => {
        if (e.key !== "Escape") return;
        setOpen(false);
        wrapRef.current?.querySelector<HTMLAnchorElement>(".nav-cart")?.focus();
      }}
    >
      <a
        className="nav-cart"
        href={href("cart")}
        aria-label={`Cart${count > 0 ? `, ${count} items` : ""}`}
        aria-current={active ? "page" : undefined}
        aria-haspopup={count > 0 ? "true" : undefined}
        aria-expanded={count > 0 ? open : undefined}
        onClick={() => setOpen(false)}
      >
        <span className="nav-cart-ico">
          <Icon name="cart" size={20} />
          {bubble}
        </span>
        <span>
          <b>Cart</b>
        </span>
      </a>

      {open && count > 0 ? (
        <div className="mini-cart" role="region" aria-label="Cart preview">
          <div className="mini-cart-head">
            <span>
              {count} item{count === 1 ? "" : "s"}
            </span>
            <a className="link" href={href("cart")} onClick={() => setOpen(false)}>
              View cart
            </a>
          </div>

          <div className="mini-cart-items">
            {preview.map((item) => {
              const title = item.variant.name || item.variant.sku || `Item ${item.variant.id}`;
              return (
                <a
                  key={item.id}
                  className="mini-cart-item"
                  href={href("cart")}
                  onClick={() => setOpen(false)}
                >
                  <span className="mini-cart-thumb">
                    <Monogram text={title} />
                  </span>
                  <span className="mini-cart-copy">
                    <b>{title}</b>
                    <small>
                      {item.variant.sku ? `${item.variant.sku} · ` : ""}Qty {item.quantity}
                    </small>
                  </span>
                  <span className="mini-cart-line">{money(item.line_total)}</span>
                </a>
              );
            })}
          </div>

          {hiddenCount > 0 ? (
            <div className="mini-cart-more">
              + {hiddenCount} more item{hiddenCount === 1 ? "" : "s"} in cart
            </div>
          ) : null}

          <FreeShippingProgress
            subtotal={cart?.subtotal}
            config={config}
            className="mini-cart-ship"
          />

          <div className="mini-cart-foot">
            <span>Subtotal</span>
            <b>{money(cart?.subtotal)}</b>
          </div>
          <a
            className="btn btn-primary mini-cart-cta"
            href={href("cart")}
            onClick={() => setOpen(false)}
          >
            View cart &amp; checkout
          </a>
        </div>
      ) : null}
    </div>
  );
}
