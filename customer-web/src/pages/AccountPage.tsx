import { useEffect, useState } from "react";
import { useAuth } from "../context/AuthContext";
import { useToast } from "../context/ToastContext";
import { navigate } from "../hooks/useHashRoute";
import {
  asArray,
  changePassword,
  createAddress,
  deleteAddress,
  errText,
  fieldErrors,
  listAddresses,
  logout,
  setDefaultAddress,
  updateMe,
  type Address,
} from "../services/api";
import { PageCrumbs, SignInGate, Spinner } from "../components/ui";
import { Icon } from "../components/icons";

/** Password strength for the change-password meter (0 = empty/too short). */
function passwordStrength(value: string): { score: number; label: string; color: string } {
  if (!value) return { score: 0, label: "", color: "var(--border)" };
  let score = 0;
  if (value.length >= 8) score += 1;
  if (value.length >= 12) score += 1;
  if (/[a-z]/.test(value) && /[A-Z]/.test(value)) score += 1;
  if (/\d/.test(value)) score += 1;
  if (/[^A-Za-z0-9]/.test(value)) score += 1;
  const capped = Math.min(score, 4);
  const label = capped <= 1 ? "Weak" : capped === 2 ? "Fair" : capped === 3 ? "Good" : "Strong";
  const color =
    capped <= 1 ? "var(--danger)" : capped === 2 ? "var(--secondary)" : "var(--ok)";
  return { score: capped, label, color };
}

export function AccountPage() {
  const { user, ready, signOut, updateUser } = useAuth();
  const toast = useToast();
  const [addresses, setAddresses] = useState<Address[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [busy, setBusy] = useState(false);
  const [profile, setProfile] = useState({ first_name: "", last_name: "", phone: "" });
  const [profileError, setProfileError] = useState("");
  const [savingProfile, setSavingProfile] = useState(false);
  const [pwd, setPwd] = useState({ current: "", next: "", confirm: "" });
  const [pwdError, setPwdError] = useState("");
  const [savingPwd, setSavingPwd] = useState(false);
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

  // Keep the editable form in sync with the session user (first load and
  // after a successful save). Typing does not touch `user`, so drafts survive.
  useEffect(() => {
    if (!user) return;
    setProfile({
      first_name: user.first_name ?? "",
      last_name: user.last_name ?? "",
      phone: user.phone ?? "",
    });
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

  const saveProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    const phone = profile.phone.replace(/\D/g, "");
    if (phone && phone.length !== 10) {
      setProfileError("Phone number must be exactly 10 digits.");
      return;
    }
    setProfileError("");
    setSavingProfile(true);
    try {
      const saved = await updateMe({
        first_name: profile.first_name.trim(),
        last_name: profile.last_name.trim(),
        phone,
      });
      updateUser(saved);
      setProfile({
        first_name: saved.first_name ?? "",
        last_name: saved.last_name ?? "",
        phone: saved.phone ?? "",
      });
      toast.push("Profile updated");
    } catch (err) {
      setProfileError(fieldErrors(err));
    } finally {
      setSavingProfile(false);
    }
  };

  const savePassword = async (e: React.FormEvent) => {
    e.preventDefault();
    setPwdError("");
    if (pwd.next.length < 8) {
      setPwdError("New password must be at least 8 characters.");
      return;
    }
    if (pwd.next !== pwd.confirm) {
      setPwdError("New password and confirmation do not match.");
      return;
    }
    if (pwd.next === pwd.current) {
      setPwdError("New password must be different from the current one.");
      return;
    }
    setSavingPwd(true);
    try {
      const res = await changePassword({
        current_password: pwd.current,
        new_password: pwd.next,
      });
      setPwd({ current: "", next: "", confirm: "" });
      toast.push(res.message || "Password updated");
    } catch (err) {
      setPwdError(fieldErrors(err));
    } finally {
      setSavingPwd(false);
    }
  };

  const strength = passwordStrength(pwd.next);

  return (
    <div className="page page-narrow">
      <PageCrumbs current="Your account" />
      <div className="pagehead">
        <h1>Your account</h1>
        <p className="muted">{user.email}</p>
      </div>

      <div className="panel">
        <h2>Profile</h2>
        <form onSubmit={saveProfile}>
          <div className="form-grid">
            <div className="field">
              <label htmlFor="account-first-name">First name</label>
              <input
                id="account-first-name"
                autoComplete="given-name"
                value={profile.first_name}
                onChange={(e) => setProfile({ ...profile, first_name: e.target.value })}
                placeholder="First name"
              />
            </div>
            <div className="field">
              <label htmlFor="account-last-name">Last name</label>
              <input
                id="account-last-name"
                autoComplete="family-name"
                value={profile.last_name}
                onChange={(e) => setProfile({ ...profile, last_name: e.target.value })}
                placeholder="Last name"
              />
            </div>
            <div className="field">
              <label htmlFor="account-phone">Phone</label>
              <input
                id="account-phone"
                inputMode="numeric"
                autoComplete="tel"
                maxLength={10}
                value={profile.phone}
                onChange={(e) =>
                  setProfile({ ...profile, phone: e.target.value.replace(/\D/g, "").slice(0, 10) })
                }
                placeholder="10-digit mobile number"
                aria-invalid={Boolean(profileError && profileError.toLowerCase().includes("phone"))}
              />
              <span className="field-hint">10 digits, no country code.</span>
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
          {profileError ? (
            <span className="field-err" role="alert">
              {profileError}
            </span>
          ) : null}
          <div className="form-actions">
            <button className="btn btn-primary" type="submit" disabled={savingProfile}>
              {savingProfile ? "Saving…" : "Save profile"}
            </button>
            <button className="btn btn-danger" type="button" onClick={() => void doSignOut()}>
              Sign out
            </button>
          </div>
        </form>
      </div>

      <div className="panel">
        <h2>Security</h2>
        <p className="muted" style={{ marginTop: 0, fontSize: 13.5 }}>
          Use at least 8 characters. A mix of upper/lowercase, numbers and symbols
          makes the password stronger.
        </p>
        <form onSubmit={savePassword}>
          <div className="form-grid">
            <div className="field full">
              <label htmlFor="account-current-password">Current password</label>
              <input
                id="account-current-password"
                type="password"
                required
                autoComplete="current-password"
                value={pwd.current}
                onChange={(e) => setPwd({ ...pwd, current: e.target.value })}
              />
            </div>
            <div className="field">
              <label htmlFor="account-new-password">New password</label>
              <input
                id="account-new-password"
                type="password"
                required
                minLength={8}
                autoComplete="new-password"
                value={pwd.next}
                onChange={(e) => setPwd({ ...pwd, next: e.target.value })}
              />
              {pwd.next ? (
                <div style={{ marginTop: 6 }}>
                  <div
                    style={{
                      height: 6,
                      borderRadius: 999,
                      background: "var(--border)",
                      overflow: "hidden",
                    }}
                    role="progressbar"
                    aria-label="Password strength"
                    aria-valuemin={0}
                    aria-valuemax={4}
                    aria-valuenow={strength.score}
                  >
                    <div
                      style={{
                        width: `${(strength.score / 4) * 100}%`,
                        height: "100%",
                        background: strength.color,
                        transition: "width 160ms ease, background 160ms ease",
                      }}
                    />
                  </div>
                  <span className="field-hint">
                    Strength: <b style={{ color: strength.color }}>{strength.label}</b>
                  </span>
                </div>
              ) : (
                <span className="field-hint">At least 8 characters.</span>
              )}
            </div>
            <div className="field">
              <label htmlFor="account-confirm-password">Confirm new password</label>
              <input
                id="account-confirm-password"
                type="password"
                required
                minLength={8}
                autoComplete="new-password"
                value={pwd.confirm}
                onChange={(e) => setPwd({ ...pwd, confirm: e.target.value })}
                aria-invalid={Boolean(pwd.confirm && pwd.confirm !== pwd.next)}
              />
              {pwd.confirm && pwd.confirm !== pwd.next ? (
                <span className="field-err">Passwords do not match.</span>
              ) : null}
            </div>
          </div>
          {pwdError ? (
            <span className="field-err" role="alert">
              {pwdError}
            </span>
          ) : null}
          <div className="form-actions">
            <button className="btn btn-primary" type="submit" disabled={savingPwd}>
              {savingPwd ? "Updating…" : "Update password"}
            </button>
          </div>
        </form>
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
