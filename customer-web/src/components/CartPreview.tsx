import { useCallback, useEffect, useRef, useState, type ReactNode } from "react";
import { createPortal } from "react-dom";
import { useCart } from "../context/CartContext";
import { useDeliveryConfig } from "../hooks/useDeliveryConfig";
import { href } from "../hooks/useHashRoute";
import { money, Monogram } from "./ui";
import { Icon } from "./icons";
import { FreeShippingProgress } from "./FreeShippingProgress";

/**
 * Header bag. Hover/keyboard focus keeps the compact preview for desktop;
 * the dedicated bag button opens a modal, scrim-backed sheet with the same
 * real cart lines. The Cart link still navigates to the full cart route.
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
  const [sheetOpen, setSheetOpen] = useState(false);
  const [closing, setClosing] = useState(false);
  const closeTimer = useRef<number | null>(null);
  const sheetTimer = useRef<number | null>(null);
  const wrapRef = useRef<HTMLDivElement>(null);
  const sheetTriggerRef = useRef<HTMLButtonElement>(null);
  const sheetCloseRef = useRef<HTMLButtonElement>(null);
  const sheetRef = useRef<HTMLElement>(null);

  useEffect(
    () => () => {
      if (closeTimer.current) window.clearTimeout(closeTimer.current);
      if (sheetTimer.current) window.clearTimeout(sheetTimer.current);
    },
    [],
  );

  useEffect(() => {
    if (active) setSheetOpen(false);
  }, [active]);

  const closeSheet = useCallback(() => {
    if (closing) return;
    const reduced = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches;
    if (reduced) {
      setSheetOpen(false);
      window.requestAnimationFrame(() => sheetTriggerRef.current?.focus());
      return;
    }
    setClosing(true);
    sheetTimer.current = window.setTimeout(() => {
      setSheetOpen(false);
      setClosing(false);
      window.requestAnimationFrame(() => sheetTriggerRef.current?.focus());
    }, 180);
  }, [closing]);

  useEffect(() => {
    if (!sheetOpen) return;
    const previouslyFocused = document.activeElement as HTMLElement | null;
    const previousOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    window.requestAnimationFrame(() => sheetCloseRef.current?.focus());

    const onKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        closeSheet();
        return;
      }
      if (event.key !== "Tab" || !sheetRef.current) return;
      const focusable = [
        ...sheetRef.current.querySelectorAll<HTMLElement>(
          'a[href], button:not([disabled]), input, select, textarea, [tabindex]:not([tabindex="-1"])',
        ),
      ].filter((el) => !el.hasAttribute("hidden"));
      if (!focusable.length) return;
      const first = focusable[0];
      const last = focusable[focusable.length - 1];
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault();
        last.focus();
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault();
        first.focus();
      }
    };
    document.addEventListener("keydown", onKeyDown);
    return () => {
      document.body.style.overflow = previousOverflow;
      document.removeEventListener("keydown", onKeyDown);
      previouslyFocused?.focus?.();
    };
  }, [sheetOpen, closeSheet]);

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
    <>
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
          sheetTriggerRef.current?.focus();
        }}
      >
        {/* Kept as a real route link for the full cart view; the visible bag
            control below opens the sheet. */}
        <a
          className="nav-cart"
          href={href("cart")}
          aria-hidden="true"
          tabIndex={-1}
        >
          <span className="nav-cart-ico">
            <Icon name="cart" size={20} />
          </span>
          <span>
            <b>Cart</b>
          </span>
        </a>
        <button
          ref={sheetTriggerRef}
          type="button"
          className="nav-bag-trigger"
          aria-label={`${active ? "Cart, current page. " : ""}Open bag${count > 0 ? `, ${count} items` : ""}`}
          aria-haspopup="dialog"
          aria-expanded={sheetOpen}
          onClick={() => {
            setOpen(false);
            setClosing(false);
            setSheetOpen(true);
          }}
        >
          <span className="nav-cart-ico">
            <Icon name="bag" size={20} />
            {bubble}
          </span>
        </button>

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

      {sheetOpen
        ? createPortal(
            <div className={`bag-layer ${closing ? "is-closing" : ""}`.trim()}>
              <button className="bag-scrim" type="button" aria-label="Close bag" onClick={closeSheet} />
              <aside ref={sheetRef} className="bag-sheet" role="dialog" aria-modal="true" aria-label="Your bag">
                <div className="bag-sheet-head">
                  <div>
                    <span className="bag-eyebrow">Your bag</span>
                    <h2>
                      {count} {count === 1 ? "item" : "items"}
                    </h2>
                  </div>
                  <button
                    ref={sheetCloseRef}
                    type="button"
                    className="bag-close icon-button"
                    aria-label="Close bag"
                    onClick={closeSheet}
                  >
                    <Icon name="x" size={18} />
                  </button>
                </div>

                {items.length ? (
                  <div className="bag-items">
                    {items.map((item) => {
                      const title = item.variant.name || item.variant.sku || `Item ${item.variant.id}`;
                      return (
                        <div className="cart-row" key={item.id}>
                          <span className="cart-thumb">
                            <Monogram text={title} />
                          </span>
                          <span className="cart-info">
                            <strong>{title}</strong>
                            <small>
                              {item.variant.sku ? `${item.variant.sku} · ` : ""}Qty {item.quantity}
                            </small>
                          </span>
                          <span className="cart-price">
                            <strong>{money(item.line_total)}</strong>
                          </span>
                        </div>
                      );
                    })}
                  </div>
                ) : (
                  <div className="cart-empty">
                    <strong>Your bag is empty</strong>
                    <span>Fresh finds are one tap away.</span>
                  </div>
                )}

                <div className="bag-sheet-foot">
                  <FreeShippingProgress subtotal={cart?.subtotal} config={config} />
                  <div className="summary-row">
                    <span>Subtotal</span>
                    <strong>{money(cart?.subtotal)}</strong>
                  </div>
                  <a className="btn btn-primary btn-block" href={href("cart")} onClick={closeSheet}>
                    View full bag
                  </a>
                  <a className="btn btn-secondary btn-block" href={href("checkout")} onClick={closeSheet}>
                    Checkout
                  </a>
                </div>
              </aside>
            </div>,
            document.body,
          )
        : null}
    </>
  );
}
