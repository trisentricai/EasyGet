import { useAuth } from "../context/AuthContext";
import { useCart } from "../context/CartContext";
import { useToast } from "../context/ToastContext";
import { navigate } from "../hooks/useHashRoute";
import { errText } from "../services/api";
import { EmptyState, money, Monogram, SignInGate, Spinner } from "../components/ui";
import { Icon } from "../components/icons";

export function CartPage() {
  const { user, ready } = useAuth();
  const { cart, loading, setQty, remove, clear } = useCart();
  const toast = useToast();

  if (!ready) return <Spinner />;
  if (!user) return <SignInGate title="Your cart" text="Sign in to view and manage your cart." />;

  const items = cart?.items ?? [];

  const doClear = async () => {
    try {
      await clear();
      toast.push("Cart cleared", "info");
    } catch (e) {
      toast.push(errText(e), "err");
    }
  };

  return (
    <div className="page">
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
          <div className="panel">
            {items.map((item) => {
              const attrs = item.variant.attributes ?? {};
              const attrText = Object.entries(attrs)
                .map(([k, v]) => `${k}: ${v}`)
                .join(" · ");
              return (
                <div className="cart-line" key={item.id}>
                  <div className="thumb">
                    <Monogram text={item.variant.name || item.variant.sku} />
                  </div>
                  <div className="grow">
                    <div className="name">{item.variant.name || item.variant.sku}</div>
                    {attrText ? <div className="sub">{attrText}</div> : null}
                    <div className="sub">{money(item.variant.price)} each</div>
                  </div>
                  <div className="qty">
                    <button onClick={() => void setQty(item.id, item.quantity - 1)} aria-label="Decrease">−</button>
                    <span>{item.quantity}</span>
                    <button onClick={() => void setQty(item.id, item.quantity + 1)} aria-label="Increase">+</button>
                  </div>
                  <div style={{ fontWeight: 700, minWidth: 80, textAlign: "right" }}>{money(item.line_total)}</div>
                  <button className="trash" title="Remove" aria-label="Remove item" onClick={() => void remove(item.id)}>
                    <Icon name="trash" size={17} />
                  </button>
                </div>
              );
            })}
            <div className="form-actions" style={{ justifyContent: "space-between" }}>
              <button className="btn btn-ghost btn-sm" onClick={() => navigate("browse")}>← Continue shopping</button>
              <button className="btn btn-danger btn-sm" onClick={() => void doClear()}>Clear cart</button>
            </div>
          </div>

          <div className="panel">
            <h2>Summary</h2>
            <div className="summary-line">
              <span className="muted">Subtotal</span>
              <span>{money(cart?.subtotal)}</span>
            </div>
            <div className="summary-line">
              <span className="muted">Delivery</span>
              <span className="muted">calculated at checkout</span>
            </div>
            <div className="summary-line summary-total">
              <span>Total</span>
              <span>{money(cart?.subtotal)}</span>
            </div>
            <button className="btn btn-block" style={{ marginTop: 14 }} onClick={() => navigate("checkout")}>
              Proceed to checkout
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
