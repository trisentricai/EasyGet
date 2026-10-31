import { useEffect, useRef, useState } from "react";
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
  type Address,
  type Order,
} from "../services/api";
import { money, SignInGate } from "../components/ui";

type PaymentMethod = "cod" | "upi" | "card";

export function CheckoutPage() {
  const { user } = useAuth();
  const { cart, refresh } = useCart();
  const toast = useToast();

  const [addresses, setAddresses] = useState<Address[]>([]);
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
  const [errors, setErrors] = useState<{ phone?: string; line1?: string; postal_code?: string }>({});
  const [pinLookup, setPinLookup] = useState(false);
  const [pinHint, setPinHint] = useState<string | null>(null);
  const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>("cod");
  const [upiId, setUpiId] = useState("");

  const phoneRef = useRef<HTMLInputElement>(null);
  const line1Ref = useRef<HTMLInputElement>(null);
  const pinRef = useRef<HTMLInputElement>(null);

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
  }, [user]);

  const lookupPin = async (pin: string) => {
    if (!/^\\d{6}$/.test(pin)) return;
    setPinLookup(true);
    setPinHint(null);
    try {
      const res = await fetch(`https://api.postalpincode.in/pincode/${pin}`);
      const data = await res.json();
      const info = Array.isArray(data) && data[0]?.PostOffice?.[0];
      if (info) {
        setForm((f) => ({ ...f, city: info.District || f.city, state: info.State || f.state }));
        setPinHint(`${info.District}, ${info.State}`);
      } else {
        setPinHint("PIN code not found — enter city/state manually.");
      }
    } catch {
      setPinHint("Couldn't look up PIN code — enter city/state manually.");
    } finally {
      setPinLookup(false);
    }
  };

  if (!user) return <SignInGate title="Checkout" text="Sign in to place your order." />;

  const items = cart?.items ?? [];

  // One group per seller; the backend splits checkout into one order each.
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

  const saveAddress = async (e: React.FormEvent) => {
    e.preventDefault();
    const next: { phone?: string; line1?: string; postal_code?: string } = {};
    if (!form.phone.trim()) next.phone = "Phone is required.";
    if (!form.line1.trim()) next.line1 = "Address line 1 is required.";
    if (!/^\\d{6}$/.test(form.postal_code)) next.postal_code = "Enter a valid 6-digit PIN code.";
    setErrors(next);
    if (Object.keys(next).length) {
      const first = next.phone ? phoneRef : next.line1 ? line1Ref : pinRef;
      first.current?.scrollIntoView({ behavior: "smooth", block: "center" });
      first.current?.focus();
      return;
    }
    setPlacing(true);
    setError(null);
    try {
      const created = await createAddress(form);
      setAddresses((l) => [...l, created]);
      setSelected(created.id);
      setShowForm(false);
      setErrors({});
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
      const created = await createOrder({
        cart_id: cart.id,
        delivery_address: { ...address },
        delivery_instructions: instructions || undefined,
      });
      await refresh();
      if (created.orders && created.orders.length > 0) {
        toast.push(`${created.orders.length} order${created.orders.length === 1 ? "" : "s"} placed! 🎉`);
        navigate("orders");
        return;
      }
      // Defensive fallback: legacy single-order response shape — resolve
      // the real order (id/number) from the user's order list (newest first).
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
    } catch (err) {
      setError(errText(err, "Could not place order"));
      setPlacing(false);
    }
  };

  const paymentLabel =
    paymentMethod === "cod"
      ? `Place order · ${money(cart?.subtotal)} (Cash on Delivery)`
      : paymentMethod === "upi"
        ? `Place order · ${money(cart?.subtotal)} (Pay via UPI)`
        : `Place order · ${money(cart?.subtotal)} (Pay by Card)`;

  return (
    <div className="page">
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

          <div className="checkout-layout">
            <div className="checkout-steps">
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
              <form onSubmit={saveAddress} noValidate>
                <div className="form-grid">
                  <div className="field">
                    <label>Label</label>
                    <input value={form.label} onChange={(e) => setForm({ ...form, label: e.target.value })} placeholder="Home / Work" />
                  </div>
                  <div className={`field ${errors.phone ? "field-error" : ""}`}>
                    <label>Phone *</label>
                    <input
                      ref={phoneRef}
                      value={form.phone}
                      onChange={(e) => {
                        setForm({ ...form, phone: e.target.value });
                        if (errors.phone) setErrors((x) => ({ ...x, phone: undefined }));
                      }}
                      placeholder="10-digit mobile"
                    />
                    {errors.phone ? <span className="field-err">{errors.phone}</span> : null}
                  </div>
                  <div className={`field full ${errors.line1 ? "field-error" : ""}`}>
                    <label>Address line 1 *</label>
                    <input
                      ref={line1Ref}
                      value={form.line1}
                      onChange={(e) => {
                        setForm({ ...form, line1: e.target.value });
                        if (errors.line1) setErrors((x) => ({ ...x, line1: undefined }));
                      }}
                      placeholder="Flat / House no, Street"
                    />
                    {errors.line1 ? <span className="field-err">{errors.line1}</span> : null}
                  </div>
                  <div className="field full">
                    <label>Address line 2</label>
                    <input value={form.line2} onChange={(e) => setForm({ ...form, line2: e.target.value })} placeholder="Area, Landmark (optional)" />
                  </div>
                  <div className="field">
                    <label>City</label>
                    <input value={form.city} onChange={(e) => setForm({ ...form, city: e.target.value })} />
                  </div>
                  <div className="field">
                    <label>State</label>
                    <input value={form.state} onChange={(e) => setForm({ ...form, state: e.target.value })} />
                  </div>
                  <div className={`field ${errors.postal_code ? "field-error" : ""}`}>
                    <label>PIN code *</label>
                    <div className="pin-input-wrap">
                      <input
                        ref={pinRef}
                        value={form.postal_code}
                        onChange={(e) => {
                          const v = e.target.value.replace(/\D/g, "").slice(0, 6);
                          setForm({ ...form, postal_code: v });
                          if (errors.postal_code) setErrors((x) => ({ ...x, postal_code: undefined }));
                          if (v.length === 6) void lookupPin(v);
                        }}
                        placeholder="6-digit PIN"
                        inputMode="numeric"
                      />
                      {pinLookup ? <span className="pin-spinner" aria-label="Looking up PIN code" /> : null}
                    </div>
                    {pinHint ? <span className="field-hint">{pinHint}</span> : null}
                    {errors.postal_code ? <span className="field-err">{errors.postal_code}</span> : null}
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
            {groups.length > 1 ? (
              <p className="muted" style={{ fontSize: 13, marginTop: 0 }}>
                This will be placed as {groups.length} orders — one per seller.
              </p>
            ) : null}
            {groups.map((group) => (
              <div key={group.key}>
                <div className="sub" style={{ fontWeight: 700, margin: "8px 0 4px" }}>
                  Sold by {group.seller}
                </div>
                {group.items.map((item) => (
                  <div key={item.id} className="summary-line">
                    <span>
                      {item.variant.name || item.variant.sku} <span className="muted">× {item.quantity}</span>
                    </span>
                    <span>{money(item.line_total)}</span>
                  </div>
                ))}
              </div>
            ))}
            <div className="summary-line summary-total">
              <span>Total (pay on delivery)</span>
              <span>{money(cart?.subtotal)}</span>
            </div>

            <div className="pay-methods">
              <div className="pay-methods-title">Payment method</div>
              {([
                { id: "cod", label: "Cash on Delivery", hint: "Pay with cash when your order arrives." },
                { id: "upi", label: "UPI (Google Pay / PhonePe / Paytm)", hint: "Pay instantly via UPI." },
                { id: "card", label: "Credit / Debit Card", hint: "Pay securely with your card." },
              ] as { id: PaymentMethod; label: string; hint: string }[]).map((m) => (
                <label key={m.id} className={`pay-option ${paymentMethod === m.id ? "selected" : ""}`}>
                  <input type="radio" name="payment" value={m.id} checked={paymentMethod === m.id} onChange={() => setPaymentMethod(m.id)} />
                  <div>
                    <div className="pay-option-label">{m.label}</div>
                    <div className="pay-option-hint">{m.hint}</div>
                  </div>
                </label>
              ))}
              {paymentMethod === "upi" ? (
                <div className="field" style={{ marginTop: 8 }}>
                  <label>UPI ID</label>
                  <input value={upiId} onChange={(e) => setUpiId(e.target.value)} placeholder="yourname@upi" />
                </div>
              ) : null}
            </div>

            <div className="form-actions">
              <button
                className="btn btn-primary cart-checkout"
                disabled={placing || !selected || items.length === 0}
                onClick={() => void placeOrder()}
              >
                {placing ? "Placing order…" : paymentLabel}
              </button>
            </div>
            <p className="muted" style={{ fontSize: 12.5, marginBottom: 0 }}>
              {paymentMethod === "cod"
                ? "Cash / UPI on delivery."
                : paymentMethod === "upi"
                  ? "UPI payment will be requested on place order."
                  : "Card payment will be requested on place order."}
            </p>
          </div>
            </div>

            <aside className="checkout-summary">
              <h2>Order summary</h2>
              {groups.map((group) => (
                <div key={group.key} className="checkout-summary-group">
                  <div className="checkout-summary-seller">Sold by {group.seller}</div>
                  {group.items.map((item) => (
                    <div key={item.id} className="checkout-summary-line">
                      <span>{item.variant.name || item.variant.sku} <span className="muted">× {item.quantity}</span></span>
                      <span>{money(item.line_total)}</span>
                    </div>
                  ))}
                </div>
              ))}
              <div className="checkout-summary-line">
                <span className="muted">Subtotal</span>
                <span>{money(cart?.subtotal)}</span>
              </div>
              <div className="checkout-summary-line">
                <span className="muted">Delivery</span>
                <span className="muted">calculated at checkout</span>
              </div>
              <div className="checkout-summary-total">
                <span>Total</span>
                <span>{money(cart?.subtotal)}</span>
              </div>
            </aside>
          </div>
        </>
      )}
    </div>
  );
}
