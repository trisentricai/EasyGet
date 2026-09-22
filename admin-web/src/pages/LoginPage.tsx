import { useState } from "react";
import { useAuth } from "../context/AuthContext";
import { useTheme } from "../context/ThemeContext";
import { useToast } from "../context/ToastContext";
import { ApiError } from "../services/api";

export function LoginPage({ onDone }: { onDone: () => void }) {
  const { signIn } = useAuth();
  const { push } = useToast();
  const { theme, toggle } = useTheme();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError("");
    try {
      await signIn(email.trim(), password);
      push("Welcome back 👋");
      onDone();
    } catch (err) {
      const message =
        err instanceof ApiError ? err.message : "Login failed — check your connection.";
      setError(message);
      push(message, "err");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="login-wrap">
      <div className="login-theme">
        <ThemeToggle />
      </div>
      <form className="card login-card" onSubmit={submit}>
        <div className="login-logo">EG</div>
        <h1>EASYGET Admin</h1>
        <p className="muted" style={{ textAlign: "center", marginBottom: 22 }}>
          Sign in to manage your store
        </p>

        <div className="form-grid">
          <label>
            Email
            <input
              className="input"
              type="email"
              required
              autoComplete="username"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="admin@example.com"
            />
          </label>
          <label>
            Password
            <input
              className="input"
              type="password"
              required
              autoComplete="current-password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
            />
          </label>
        </div>

        {error ? (
          <p className="muted" style={{ color: "var(--c-danger)", marginTop: 14 }}>
            {error}
          </p>
        ) : null}

        <button
          className="btn btn-primary"
          style={{ width: "100%", marginTop: 22 }}
          disabled={busy}
        >
          {busy ? "Signing in…" : "Sign in"}
        </button>
        <p className="muted" style={{ marginTop: 16, textAlign: "center" }}>
          {theme === "light" ? "☀️" : "🌙"} Tip: toggle the theme — your choice is remembered.
        </p>
      </form>
    </div>
  );
}

export function ThemeToggle() {
  const { theme, toggle } = useTheme();
  return (
    <button
      className="theme-toggle"
      onClick={toggle}
      title={theme === "light" ? "Switch to dark" : "Switch to light"}
      aria-label="Toggle theme"
    >
      <span className="knob">{theme === "light" ? "🌙" : "☀️"}</span>
    </button>
  );
}
