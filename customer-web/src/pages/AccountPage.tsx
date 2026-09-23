import { useEffect, useState } from "react";
import { useAuth } from "../context/AuthContext";
import { useToast } from "../context/ToastContext";
import { navigate } from "../hooks/useHashRoute";
import {
  asArray,
  createAddress,
  deleteAddress,
  errText,
  listAddresses,
  logout,
  setDefaultAddress,
  type Address,
} from "../services/api";
import { SignInGate, Spinner } from "../components/ui";
import { Icon } from "../components/icons";

export function AccountPage() {
  const { user, ready, signOut } = useAuth();
  const toast = useToast();
  const [addresses, setAddresses] = useState<Address[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [busy, setBusy] = useState(false);
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
      .then((d) => setAddresses(asArray<Address>(d)))
      .catch(() => setAddresses([]));
  }, [user]);

  if (!ready) return <Spinner />;
  if (!user) return <SignInGate title="Your account" text="Sign in to manage your profile and addresses." />;

  const saveAddress = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    try {
      const created = await createAddress(form);
      setAddresses((l) => [...l, created]);
      setShowForm(false);
      setForm({ label: "Home", line1: "", line2: "", city: "", state: "", postal_code: "", country: "India", phone: "" });
      toast.push("Address saved");
    } catch (e2) {
      toast.push(errText(e2, "Could not save address"), "err");
    } finally {
      setBusy(false);
    }
  };

  const makeDefault = async (id: Address["id"]) => {
    try {
      await setDefaultAddress(id);
      setAddresses((list) => list.map((a) => ({ ...a, is_default: a.id === id })));
      toast.push("Default address updated");
    } catch (e) {
      toast.push(errText(e), "err");
    }
  };

  const removeAddress = async (id: Address["id"]) => {
    try {
      await deleteAddress(id);
      setAddresses((list) => list.filter((a) => a.id !== id));
      toast.push("Address removed", "info");
    } catch (e) {
      toast.push(errText(e), "err");
    }
  };

  const doSignOut = async () => {
    try {
      const tokens = localStorage.getItem("eg-cust-tokens");
      if (tokens) {
        const parsed = JSON.parse(tokens) as { refresh?: string };
        if (parsed.refresh) await logout(parsed.refresh);
      }
    } catch {
      /* best effort */
    }
    signOut();
    toast.push("Signed out", "info");
    navigate("home", { replace: true });
  };

  return (
    <div className="page page-narrow">
      <div className="pagehead">
        <h1>Your account</h1>
        <p className="muted">{user.email}</p>
      </div>

      <div className="panel">
        <h2>Profile</h2>
        <div className="form-grid">
          <div className="field">
            <label>Name</label>
            <input value={[user.first_name, user.last_name].filter(Boolean).join(" ") || "—"} readOnly />
          </div>
          <div className="field">
            <label>Phone</label>
            <input value={user.phone || "—"} readOnly />
          </div>
          <div className="field">
            <label>Email</label>
            <input value={user.email} readOnly />
          </div>
          <div className="field">
            <label>Status</label>
            <input
              value={user.is_email_verified ? "Verified" : "Not verified"}
              readOnly
              style={{ color: user.is_email_verified ? "var(--ok)" : "var(--secondary)" }}
            />
          </div>
        </div>
        <div className="form-actions">
          <button className="btn btn-danger" onClick={() => void doSignOut()}>Sign out</button>
        </div>
      </div>

      <div className="panel">
        <h2>Saved addresses</h2>
        {addresses.length ? (
          <div style={{ display: "grid", gap: 10 }}>
            {addresses.map((a) => (
              <div key={a.id} className="addr-option" style={{ cursor: "default" }}>
                <div style={{ flex: 1 }}>
                  <div className="t">
                    {a.label} {a.is_default ? <span className="chip chip-info">default</span> : null}
                  </div>
                  <div className="d">
                    {a.line1}{a.line2 ? `, ${a.line2}` : ""}, {a.city}, {a.state} {a.postal_code} · {a.phone}
                  </div>
                </div>
                <div style={{ display: "flex", gap: 6 }}>
                  {!a.is_default ? (
                    <button className="btn btn-ghost btn-sm" onClick={() => void makeDefault(a.id)}>Make default</button>
                  ) : null}
                  <button className="trash" title="Delete" aria-label="Delete address" onClick={() => void removeAddress(a.id)}>
                    <Icon name="trash" size={17} />
                  </button>
                </div>
              </div>
            ))}
          </div>
        ) : (
          <p className="muted">No saved addresses yet.</p>
        )}

        {showForm ? (
          <form onSubmit={saveAddress} style={{ marginTop: 14 }}>
            <div className="form-grid">
              <div className="field">
                <label>Label</label>
                <input value={form.label} onChange={(e) => setForm({ ...form, label: e.target.value })} />
              </div>
              <div className="field">
                <label>Phone</label>
                <input required value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} />
              </div>
              <div className="field full">
                <label>Address line 1</label>
                <input required value={form.line1} onChange={(e) => setForm({ ...form, line1: e.target.value })} />
              </div>
              <div className="field full">
                <label>Address line 2</label>
                <input value={form.line2} onChange={(e) => setForm({ ...form, line2: e.target.value })} />
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
              <button className="btn" type="submit" disabled={busy}>{busy ? "Saving…" : "Save address"}</button>
              <button className="btn btn-ghost" type="button" onClick={() => setShowForm(false)}>Cancel</button>
            </div>
          </form>
        ) : (
          <div className="form-actions">
            <button className="btn btn-ghost" onClick={() => setShowForm(true)}>+ Add address</button>
          </div>
        )}
      </div>
    </div>
  );
}
