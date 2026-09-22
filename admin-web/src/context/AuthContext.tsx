import { createContext, useCallback, useContext, useEffect, useState, type ReactNode } from "react";
import { api, getTokens, login as apiLogin, logout as apiLogout, setTokens, setUnauthorizedHandler, type AdminUser } from "../services/api";

const AuthContext = createContext<{
  user: AdminUser | null;
  ready: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => void;
}>({
  user: null,
  ready: false,
  signIn: async () => {},
  signOut: () => {},
});

function decodeJwtPayload(token: string): Record<string, unknown> | null {
  try {
    const payload = token.split(".")[1];
    return JSON.parse(atob(payload.replace(/-/g, "+").replace(/_/g, "/")));
  } catch {
    return null;
  }
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AdminUser | null>(null);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    const tokens = getTokens();
    if (tokens?.access) {
      const cached = localStorage.getItem("eg-user");
      const payload = decodeJwtPayload(tokens.access);
      const exp = typeof payload?.exp === "number" ? payload.exp * 1000 : 0;
      if (exp > Date.now() && cached) {
        try {
          setUser(JSON.parse(cached) as AdminUser);
        } catch {
          /* fall through */
        }
      } else if (exp <= Date.now()) {
        setTokens(null);
      }
    }
    setReady(true);
  }, []);

  useEffect(() => {
    setUnauthorizedHandler(() => {
      setTokens(null);
      localStorage.removeItem("eg-user");
      setUser(null);
    });
  }, []);

  const signIn = useCallback(async (email: string, password: string) => {
    const res = await apiLogin(email, password);
    setTokens({ access: res.access, refresh: res.refresh });
    localStorage.setItem("eg-user", JSON.stringify(res.user));
    setUser(res.user);
  }, []);

  const signOut = useCallback(() => {
    const tokens = getTokens();
    if (tokens?.refresh) {
      apiLogout(tokens.refresh).catch(() => undefined);
    }
    setTokens(null);
    localStorage.removeItem("eg-user");
    setUser(null);
  }, []);

  const value = { user, ready, signIn, signOut };
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export const useAuth = () => useContext(AuthContext);

export { api };
