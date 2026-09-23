import { useEffect, useState } from "react";
import { useAuth } from "../context/AuthContext";
import { useCart } from "../context/CartContext";
import { useToast } from "../context/ToastContext";
import { navigate } from "../hooks/useHashRoute";
import {
  asArray,
  createAddress,
  createOrder,
  errText,
  listAddresses,
  listOrders,
  listStores,
  type Address,
  type Order,
  type Store,
} from "../services/api";
import { money, SignInGate, Spinner } from "../components/ui";

export function CheckoutPage() {
  const { user } = useAuth();
  const { cart, refresh } = useCart();
  const toast = useToast();

  const [addresses, setAddresses] = useState<Address[]>([]);
  const [stores, setStores] = useState<Store[]>([]);
  const [selected, setSelected] = useState<Address["id"] | null>(null);
  const [instructions, setInstructions] = useState("");
  const [showForm, setShowForm] = useState(false);
  const [placing, setPlacing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [form, setForm] = useState({
    label: "Home",
    line1: "",
    line2: "",
    city: "",
    state: "",
    postal_code: "",
    country: "India",
    phone: "",
  });

  useEffect(() => {
    if (!user) return;
    listAddresses()
      .then((d) => {
        const list = asArray<Address>(d);
        setAddresses(list);
        const def = list.find((a) => a.is_default) ?? list[0];
        if (def) setSelected(def.id);
        else setShowForm(true);
      })
      .catch((e) => {
        setError(errText(e, "Could not load addresses"));
        setShowForm(true);
      });
    // Orders are placed against a store; default to the first active one.
    listStores()
      .then((d) => {
        const list = asArray<Store>(d).filter((s) => s.is_active);
        setStores(list);
      })
      .catch(() => setStores([]));
  }, [user]);

  if (!user) return <SignInGate title="Checkout" text="Sign in to place your order." />;

  const items = cart?.items ?? [];

  const saveAddress = async (e: React.FormEvent) => {
    e.preventDefault();
    setPlacing(true);
    setError(null);
    try {
      const created = await createAddress(form);
      setAddresses((l) => [...l, created]);
      setSelected(created.id);
      setShowForm(false);
      toast.push("Address saved");
    } catch (err) {
      setError(errText(err, "Could not save address"));
    } finally {
      setPlacing(false);
    }
  };

  const placeOrder = async () => {
    if (!cart || !selected) return;
    setPlacing(true);
    setError(null);
    try {
      const address = addresses.find((a) => a.id === selected)!;
      if (stores.length === 0) {
        setError("No active store available to place the order against.");
        setPlacing(false);
        return;
      }
      const created = await createOrder({
        cart_id: cart.id,
        store: stores[0].id,
        delivery_address: { ...address },
        delivery_instructions: instructions || undefined,
      });
      await refresh();
      // The create endpoint echoes the input payload, so resolve the real
      // order (id/number) from the user's order list (newest first).
      let orderNumber = "";
      let orderId: string | null = null;
      try {
        const orders = asArray<Order>(await listOrders());
        const newest = orders[0];
        if (newest) {
          orderId = newest.id;
          orderNumber = newest.order_number;
        }
      } catch {
        /* fall through to success toast without navigation */
      }
      toast.push(`Order ${orderNumber || ""} placed! 🎉`.replace("  ", " "));
      if (orderId !== null) navigate(`order/${orderId}`);
      else navigate("orders");
      void created;
    } catch (err) {
      setError(errText(err, "Could not place order"));
      setPlacing(false);
    }
  };

  return (
    <div className="page page-narrow">
      <div className="pagehead">
        <h1>Checkout</h1>
        <p className="muted">{items.length ? `${cart?.total_items} item(s) · ${money(cart?.subtotal)}` : ""}</p>
      </div>

      {items.length === 0 ? (
        <div className="empty-state">
          <div className="empty-ico">🛒</div>
          <h3>Nothing to check out</h3>
          <p className="muted">Your cart is empty.</p>
          <button className="btn" onClick={() => navigate("browse")}>Browse products</button>
        </div>
      ) : (
        <>
          {error ? <div className="error-box">{error}</div> : null}

          <div className="panel">
            <h2>1 · Delivery address</h2>
            {addresses.length > 0 && !showForm ? (
              <div style={{ display: "grid", gap: 10 }}>
                {addresses.map((a) => (
                  <label key={a.id} className={`addr-option ${selected === a.id ? "selected" : ""}`}>
                    <input
                      type="radio"
                      name="addr"
                      checked={selected === a.id}
                      onChange={() => setSelected(a.id)}
                    />
                    <div>
                      <div className="t">
                        {a.label} {a.is_default ? <span className="chip chip-info">default</span> : null}
                      </div>
                      <div className="d">
                        {a.line1}{a.line2 ? `, ${a.line2}` : ""}, {a.city}, {a.state} {a.postal_code} · {a.phone}
                      </div>
                    </div>
                  </label>
                ))}
                <button className="btn btn-ghost btn-sm" onClick={() => setShowForm(true)}>+ Add new address</button>
              </div>
            ) : (
              <form onSubmit={saveAddress}>
                <div className="form-grid">
                  <div className="field">
                    <label>Label</label>
                    <input value={form.label} onChange={(e) => setForm({ ...form, label: e.target.value })} placeholder="Home / Work" />
                  </div>
                  <div className="field">
                    <label>Phone</label>
                    <input required value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} />
                  </div>
                  <div className="field full">
                    <label>Address line 1</label>
                    <input required value={form.line1} onChange={(e) => setForm({ ...form, line1: e.target.value })} placeholder="Flat / House no, Street" />
                  </div>
                  <div className="field full">
                    <label>Address line 2</label>
                    <input value={form.line2} onChange={(e) => setForm({ ...form, line2: e.target.value })} placeholder="Area, Landmark (optional)" />
                  </div>
                  <div className="field">
                    <label>City</label>
                    <input required value={form.city} onChange={(e) => setForm({ ...form, city: e.target.value })} />
                  </div>
                  <div className="field">
                    <label>State</label>
                    <input required value={form.state} onChange={(e) => setForm({ ...form, state: e.target.value })} />
                  </div>
                  <div className="field">
                    <label>PIN code</label>
                    <input required value={form.postal_code} onChange={(e) => setForm({ ...form, postal_code: e.target.value })} />
                  </div>
                  <div className="field">
                    <label>Country</label>
                    <input value={form.country} onChange={(e) => setForm({ ...form, country: e.target.value })} />
                  </div>
                </div>
                <div className="form-actions">
                  <button className="btn" type="submit" disabled={placing}>Save address</button>
                  {addresses.length > 0 ? (
                    <button className="btn btn-ghost" type="button" onClick={() => setShowForm(false)}>Cancel</button>
                  ) : null}
                </div>
              </form>
            )}
          </div>

          <div className="panel">
            <h2>2 · Delivery instructions (optional)</h2>
            <div className="field">
              <textarea
                rows={2}
                value={instructions}
                onChange={(e) => setInstructions(e.target.value)}
                placeholder="Leave at the door, ring the bell twice…"
              />
            </div>
          </div>

          <div className="panel">
            <h2>3 · Review & place order</h2>
            {items.map((item) => (
              <div key={item.id} className="summary-line">
                <span>
                  {item.variant.name || item.variant.sku} <span className="muted">× {item.quantity}</span>
                </span>
                <span>{money(item.line_total)}</span>
              </div>
            ))}
            <div className="summary-line summary-total">
              <span>Total (pay on delivery)</span>
              <span>{money(cart?.subtotal)}</span>
            </div>
            <div className="form-actions">
              <button
                className="btn btn-block"
                disabled={placing || !selected || items.length === 0}
                onClick={() => void placeOrder()}
              >
                {placing ? "Placing order…" : `Place order · ${money(cart?.subtotal)}`}
              </button>
            </div>
            <p className="muted" style={{ fontSize: 12.5, marginBottom: 0 }}>
              Cash / UPI on delivery. Online payment hooks land with the payments module.
            </p>
          </div>
        </>
      )}
    </div>
  );
}
