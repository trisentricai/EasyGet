import { useState } from "react";
import { useAuth } from "../context/AuthContext";
import { useToast } from "../context/ToastContext";
import { navigate } from "../hooks/useHashRoute";
import {
  errText,
  fieldErrors,
  login,
  register,
  resendOtp,
  verifyOtp,
  type LoginResponse,
} from "../services/api";

type Mode = "login" | "register" | "otp";

export function AuthPage() {
  const [mode, setMode] = useState<Mode>("login");
  const { signIn } = useAuth();
  const toast = useToast();

  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [firstName, setFirstName] = useState("");
  const [lastName, setLastName] = useState("");
  const [phone, setPhone] = useState("");
  const [code, setCode] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [info, setInfo] = useState<string | null>(null);

  const finishLogin = (res: LoginResponse) => {
    signIn({ access: res.access, refresh: res.refresh }, res.user);
    toast.push(`Welcome back, ${res.user.first_name || res.user.email}`);
    navigate("home", { replace: true });
  };

  const submitLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      finishLogin(await login(email, password));
    } catch (err) {
      setError(fieldErrors(err));
    } finally {
      setBusy(false);
    }
  };

  const submitRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const res = await register({
        email,
        password,
        first_name: firstName || undefined,
        last_name: lastName || undefined,
        phone: phone || undefined,
      });
      toast.push(res.message, "info");
      setInfo(res.message);
      setMode("otp");
    } catch (err) {
      setError(fieldErrors(err));
    } finally {
      setBusy(false);
    }
  };

  const submitOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      const res = await verifyOtp(email, code);
      toast.push(res.message);
      setMode("login");
      setInfo("Email verified — sign in to continue.");
    } catch (err) {
      setError(fieldErrors(err));
    } finally {
      setBusy(false);
    }
  };

  const doResend = async () => {
    setBusy(true);
    setError(null);
    try {
      const res = await resendOtp(email);
      toast.push(res.message, "info");
      setInfo(res.message);
    } catch (err) {
      setError(fieldErrors(err));
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="auth-wrap">
      <div className="auth-card">
        <div className="mode-tabs">
          <button className={mode === "login" ? "active" : ""} onClick={() => { setMode("login"); setError(null); }} type="button">
            Sign in
          </button>
          <button className={mode === "register" ? "active" : ""} onClick={() => { setMode("register"); setError(null); }} type="button">
            Create account
          </button>
        </div>

        {error ? <div className="error-box">{error}</div> : null}
        {info ? <div className="ok-box">{info}</div> : null}

        {mode === "login" && (
          <form onSubmit={submitLogin}>
            <h1>Welcome back</h1>
            <p className="sub">Sign in to shop, track orders and manage your cart.</p>
            <div className="field">
              <label>Email</label>
              <input type="email" required value={email} onChange={(e) => setEmail(e.target.value)} placeholder="you@example.com" />
            </div>
            <div className="field">
              <label>Password</label>
              <input type="password" required value={password} onChange={(e) => setPassword(e.target.value)} placeholder="••••••••" />
            </div>
            <button className="btn btn-block" disabled={busy} type="submit">
              {busy ? "Signing in…" : "Sign in"}
            </button>
            <p className="auth-alt">
              New here?{" "}
              <span className="link" onClick={() => setMode("register")}>Create an account</span>
            </p>
          </form>
        )}

        {mode === "register" && (
          <form onSubmit={submitRegister}>
            <h1>Create your account</h1>
            <p className="sub">We'll email you a 6-digit code to verify your address.</p>
            <div className="form-grid">
              <div className="field">
                <label>First name</label>
                <input value={firstName} onChange={(e) => setFirstName(e.target.value)} placeholder="Riya" />
              </div>
              <div className="field">
                <label>Last name</label>
                <input value={lastName} onChange={(e) => setLastName(e.target.value)} placeholder="Sharma" />
              </div>
              <div className="field full">
                <label>Email</label>
                <input type="email" required value={email} onChange={(e) => setEmail(e.target.value)} placeholder="you@example.com" />
              </div>
              <div className="field full">
                <label>Phone (optional)</label>
                <input value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="+91 98765 43210" />
              </div>
              <div className="field full">
                <label>Password</label>
                <input type="password" required minLength={8} value={password} onChange={(e) => setPassword(e.target.value)} placeholder="At least 8 characters" />
              </div>
            </div>
            <button className="btn btn-block" disabled={busy} type="submit">
              {busy ? "Creating…" : "Create account"}
            </button>
            <p className="auth-alt">
              Already registered? <span className="link" onClick={() => setMode("login")}>Sign in</span>
            </p>
          </form>
        )}

        {mode === "otp" && (
          <form onSubmit={submitOtp}>
            <h1>Verify your email</h1>
            <p className="sub">
              Enter the 6-digit code we emailed to <b>{email || "your address"}</b>.
            </p>
            <div className="field">
              <label>OTP code</label>
              <input
                className="otp-input"
                inputMode="numeric"
                pattern="\d{6}"
                maxLength={6}
                required
                value={code}
                onChange={(e) => setCode(e.target.value.replace(/\D/g, ""))}
                placeholder="••••••"
              />
            </div>
            <button className="btn btn-block" disabled={busy || code.length !== 6} type="submit">
              {busy ? "Verifying…" : "Verify email"}
            </button>
            <p className="auth-alt">
              Didn't get it? <span className="link" onClick={doResend}>Resend code</span> ·{" "}
              <span className="link" onClick={() => setMode("login")}>Back to sign in</span>
            </p>
          </form>
        )}
      </div>
    </div>
  );
}
