import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { errText, getMe, getTokens, setTokens, type User } from "../services/api";

type Ctx = {
  user: User | null;
  ready: boolean;
  signIn: (tokens: { access: string; refresh: string }, user: User) => void;
  signOut: () => void;
};

const AuthContext = createContext<Ctx>({
  user: null,
  ready: false,
  signIn: () => {},
  signOut: () => {},
});

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    let cancelled = false;
    const bootstrap = async () => {
      if (!getTokens()) {
        setReady(true);
        return;
      }
      try {
        const me = await getMe();
        if (!cancelled) setUser(me);
      } catch (e) {
        // 401 is already handled globally (tokens cleared); other errors: drop session.
        if (!cancelled) {
          console.warn("Session bootstrap failed:", errText(e));
          setUser(null);
        }
      } finally {
        if (!cancelled) setReady(true);
      }
    };
    void bootstrap();
    return () => {
      cancelled = true;
    };
  }, []);

  const signIn = useCallback((tokens: { access: string; refresh: string }, u: User) => {
    setTokens(tokens);
    setUser(u);
  }, []);

  const signOut = useCallback(() => {
    setTokens(null);
    setUser(null);
  }, []);

  const value = useMemo(() => ({ user, ready, signIn, signOut }), [user, ready, signIn, signOut]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export const useAuth = () => useContext(AuthContext);
