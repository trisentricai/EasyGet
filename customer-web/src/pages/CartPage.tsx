import { useEffect, useRef } from "react";
import { useAuth } from "../context/AuthContext";
import { useCart } from "../context/CartContext";
import { useToast } from "../context/ToastContext";
import { navigate } from "../hooks/useHashRoute";
import { useDeliveryConfig } from "../hooks/useDeliveryConfig";
import { errText } from "../services/api";
import { EmptyState, money, Monogram, PageCrumbs, Spinner } from "../components/ui";
import { Icon } from "../components/icons";
import { CouponInput } from "../components/CouponInput";
import { FreeShippingProgress } from "../components/FreeShippingProgress";
import { TotalsBreakdown } from "../components/TotalsBreakdown";
import { MAX_CART_QTY } from "../utils/guestCart";
import { computeTotals } from "../utils/pricing";

export function CartPage() {
  const { ready } = useAuth();
  const { cart, loading, setQty, remove, clear, appliedCoupon } = useCart();
  const toast = useToast();
  const delivery = useDeliveryConfig();
  const clamping = useRef(false);

  const items = cart?.items ?? [];

  // Repair stale quantities against the stock snapshot (for example a guest
  // line added before stock dropped). One bad line at a time; the cart refresh
  // then re-runs this check for the next one.
  useEffect(() => {
    if (!cart || clamping.current) return;
    const bad = cart.items.find((item) => {
      const stock = item.variant.stock_quantity;
      if (stock == null) return item.quantity > MAX_CART_QTY;
      return item.quantity > Math.min(MAX_CART_QTY, stock);
    });
    if (!bad) return;

    const stock = bad.variant.stock_quantity;
    const max = stock == null ? MAX_CART_QTY : Math.min(MAX_CART_QTY, stock);
    const title = bad.variant.name || bad.variant.sku || "This item";
    clamping.current = true;
    void (async () => {
      try {
        if (max <= 0) {
          await remove(bad.id);
          toast.push(`${title} is out of stock and was removed.`, "info");
        } else {
          await setQty(bad.id, Math.max(1, max));
          toast.push(`Only ${max} available for ${title}.`, "info");
        }
      } catch (e) {
        toast.push(errText(e, "Could not update quantity"), "err");
      } finally {
        clamping.current = false;
      }
    })();
  }, [cart, remove, setQty, toast]);

  if (!ready) return <Spinner />;

  // Group by seller so the customer sees each seller's lines together
  // (checkout will place one order per group).
  const groups: { key: string; seller: string; items: typeof items }[] = [];
  for (const item of items) {
    const key = item.tenant_id != null ? String(item.tenant_id) : "__none";
    let group = groups.find((g) => g.key === key);
    if (!group) {
      group = { key, seller: item.seller_name || "EASYGET", items: [] };
      groups.push(group);
    }
    group.items.push(item);
  }

  const subtotal = Number(cart?.subtotal ?? 0);
  const totals = computeTotals({
    subtotal,
    coupon: appliedCoupon,
    delivery: delivery.config,
  });
  const hasStockIssue = items.some(
    (item) => item.variant.in_stock === false || item.variant.stock_quantity === 0,
  );

  const doClear = async () => {
    try {
      await clear();
      toast.push("Cart cleared", "info");
    } catch (e) {
      toast.push(errText(e), "err");
    }
  };

  const increase = (item: (typeof items)[number]) => {
    const stock = item.variant.stock_quantity;
    const max = stock == null ? MAX_CART_QTY : Math.min(MAX_CART_QTY, stock);
    if (max <= 0) {
      toast.push("Out of stock", "err");
      return;
    }
    if (item.quantity >= max) {
      toast.push(
        stock == null ? `Maximum ${MAX_CART_QTY} per item` : `Only ${max} available`,
        "info",
      );
      return;
    }
    void setQty(item.id, item.quantity + 1).catch((e) =>
      toast.push(errText(e, "Could not update quantity"), "err"),
    );
  };

  return (
    <div className="page">
      <PageCrumbs current="Your cart" />
      <div className="pagehead">
        <h1>Your cart</h1>
        <p className="muted">{cart ? `${cart.total_items} item${cart.total_items === 1 ? "" : "s"}` : "—"}</p>
      </div>

      {loading && !cart ? (
        <Spinner />
      ) : items.length === 0 ? (
        <EmptyState
          icon="cart"
          title="Your cart is empty"
          text="Browse the catalog and add something you love."
          action={<button className="btn" onClick={() => navigate("browse")}>Browse products</button>}
        />
      ) : (
        <div className="cart-layout">
          <div className="cart-panel">
            {groups.map((group) => {
              const groupSubtotal = group.items.reduce(
                (sum, i) => sum + Number(i.line_total),
                0,
              );
              return (
                <div key={group.key}>
                  <div className="cart-seller">Sold by {group.seller}</div>
                  {group.items.map((item) => {
                    const variant = item.variant;
                    // The frozen cart contract carries only variant fields
                    // (name/sku/price) — no product title or image.
                    const lineTitle = variant.name || variant.sku;
                    const unitPrice = money(variant.price);
                    const lineTotal = money(item.line_total);
                    const stock = variant.stock_quantity;
                    const isOut = variant.in_stock === false || stock === 0;
                    return (
                      <div className="cart-item" key={item.id}>
                        <div className="cart-thumb">
                          <Monogram text={lineTitle} />
                        </div>
                        <div className="cart-item-info">
                          <div className="name">{lineTitle}</div>
                          <div className="sub">{variant.sku} · {unitPrice} each</div>
                          {isOut ? (
                            <div className="cart-stock-note is-out">Out of stock</div>
                          ) : stock != null && stock <= 5 ? (
                            <div className="cart-stock-note">
                              Only {stock} available
                            </div>
                          ) : null}
                        </div>
                        <div className="cart-qty">
                          <button
                            onClick={() => void setQty(item.id, item.quantity - 1).catch((e) => toast.push(errText(e, "Could not update quantity"), "err"))}
                            disabled={item.quantity <= 1}
                            aria-label="Decrease quantity"
                          >
                            −
                          </button>
                          <span>{item.quantity}</span>
                          <button
                            onClick={() => increase(item)}
                            disabled={isOut}
                            aria-label="Increase quantity"
                            title={stock != null ? `Only ${stock} available` : undefined}
                          >
                            +
                          </button>
                        </div>
                        <div className="cart-item-price">{lineTotal}</div>
                        <button
                          className="cart-trash"
                          title="Remove"
                          aria-label="Remove item"
                          onClick={() => void remove(item.id)}
                        >
                          <Icon name="trash" size={16} />
                        </button>
                      </div>
                    );
                  })}
                  <div className="cart-summary-line" style={{ paddingTop: 10 }}>
                    <span className="muted">{group.seller} subtotal</span>
                    <span>{money(groupSubtotal)}</span>
                  </div>
                </div>
              );
            })}
            <div className="cart-actions">
              <button className="btn btn-ghost btn-sm" onClick={() => navigate("browse")}>
                <Icon name="arrowLeft" size={14} /> Continue shopping
              </button>
              <button className="btn btn-danger btn-sm" onClick={() => void doClear()}>Clear cart</button>
            </div>
          </div>

          <div className="cart-summary">
            <h2>Summary</h2>
            <FreeShippingProgress subtotal={subtotal} config={delivery.config} />
            <CouponInput />
            <TotalsBreakdown totals={totals} />
            {hasStockIssue ? (
              <p className="cart-stock-warning">
                Remove out-of-stock items to continue.
              </p>
            ) : null}
            <button
              className="btn btn-primary cart-checkout"
              onClick={() => navigate("checkout")}
              disabled={hasStockIssue}
            >
              Proceed to checkout
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
