import { useState } from "react";
import { useAuth } from "../context/AuthContext";
import { useToast } from "../context/ToastContext";
import { navigate } from "../hooks/useHashRoute";
import { isNextUi } from "../flags";
import {
  errText,
  fieldErrors,
  login,
  register,
  resendOtp,
  verifyOtp,
  type LoginResponse,
} from "../services/api";
import {
  firebaseErrorText,
  isFirebaseConfigured,
  loginWithFirebase,
  signInWithEmail,
  signInWithGoogle,
  signUpWithEmail,
} from "../services/firebase";

type Mode = "login" | "register" | "otp";

function GoogleButton({ disabled, onClick }: { disabled: boolean; onClick: () => void }) {
  return (
    <button
      type="button"
      className="btn btn-block"
      disabled={disabled}
      onClick={onClick}
      style={{
        background: "#fff",
        color: "#1f1f1f",
        border: "1px solid var(--border)",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        gap: 10,
      }}
    >
      <svg width="18" height="18" viewBox="0 0 24 24" aria-hidden="true">
        <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" />
        <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
        <path fill="#FBBC05" d="M5.84 14.1c-.22-.66-.35-1.36-.35-2.1s.13-1.44.35-2.1V7.06H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.94l3.66-2.84z" />
        <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.06l3.66 2.84c.87-2.6 3.3-4.52 6.16-4.52z" />
      </svg>
      Continue with Google
    </button>
  );
}

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
  // NEXT_UI Firebase paths (flag-gated): Google one-tap + Firebase-hosted
  // email auth. Off by default — the classic password/OTP flow is untouched.
  const firebaseOn = isNextUi() && isFirebaseConfigured();
  const [firebaseEmail, setFirebaseEmail] = useState(false);

  const finishLogin = (res: LoginResponse) => {
    signIn({ access: res.access, refresh: res.refresh }, res.user);
    toast.push(`Welcome back, ${res.user.first_name || res.user.email}`);
    navigate("home", { replace: true });
  };

  const failQuietly = (err: unknown) => {
    const msg = firebaseErrorText(err);
    if (msg !== null) setError(msg);
  };

  const submitGoogle = async () => {
    setBusy(true);
    setError(null);
    try {
      const token = await signInWithGoogle();
      if (token === null) return; // popup closed — stay silent
      finishLogin(await loginWithFirebase(token));
    } catch (err) {
      failQuietly(err);
    } finally {
      setBusy(false);
    }
  };

  const submitLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      if (firebaseEmail) {
        finishLogin(await loginWithFirebase(await signInWithEmail(email, password)));
      } else {
        finishLogin(await login(email, password));
      }
    } catch (err) {
      if (firebaseEmail) failQuietly(err);
      else setError(fieldErrors(err));
    } finally {
      setBusy(false);
    }
  };

  const submitRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      if (firebaseEmail) {
        // Firebase-hosted account: no OTP step — Firebase's own email
        // verification applies, enforced by the backend.
        finishLogin(await loginWithFirebase(await signUpWithEmail(email, password)));
        return;
      }
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
      if (firebaseEmail) failQuietly(err);
      else setError(fieldErrors(err));
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
            {firebaseOn && (
              <>
                <p className="auth-alt">or continue with</p>
                <GoogleButton disabled={busy} onClick={submitGoogle} />
                <p className="auth-alt">
                  {firebaseEmail ? (
                    <span className="link" onClick={() => { setFirebaseEmail(false); setError(null); }}>
                      Use password instead
                    </span>
                  ) : (
                    <span className="link" onClick={() => { setFirebaseEmail(true); setError(null); }}>
                      Use Firebase sign-in instead
                    </span>
                  )}
                </p>
              </>
            )}
          </form>
        )}

        {mode === "register" && (
          <form onSubmit={submitRegister}>
            <h1>Create your account</h1>
            <p className="sub">
              {firebaseEmail
                ? "No code needed — verify through the email Firebase sends."
                : "We'll email you a 6-digit code to verify your address."}
            </p>
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
                <input type="password" required minLength={10} value={password} onChange={(e) => setPassword(e.target.value)} placeholder="At least 10 characters" />
              </div>
            </div>
            <button className="btn btn-block" disabled={busy} type="submit">
              {busy ? "Creating…" : firebaseEmail ? "Create account instantly" : "Create account"}
            </button>
            <p className="auth-alt">
              Already registered? <span className="link" onClick={() => setMode("login")}>Sign in</span>
            </p>
            {firebaseOn && (
              <>
                <p className="auth-alt">or continue with</p>
                <GoogleButton disabled={busy} onClick={submitGoogle} />
                <p className="auth-alt">
                  {firebaseEmail ? (
                    <span className="link" onClick={() => { setFirebaseEmail(false); setError(null); }}>
                      Use classic signup instead
                    </span>
                  ) : (
                    <span className="link" onClick={() => { setFirebaseEmail(true); setError(null); }}>
                      Use Firebase signup instead
                    </span>
                  )}
                </p>
              </>
            )}
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
