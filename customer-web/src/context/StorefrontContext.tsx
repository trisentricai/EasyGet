import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from "react";
import {
  errText,
  getPlatformStorefront,
  type StorefrontPayload,
} from "../services/api";

type Ctx = {
  data: StorefrontPayload | null;
  loading: boolean;
  error: string | null;
  reload: () => void;
};

const StorefrontContext = createContext<Ctx>({
  data: null,
  loading: true,
  error: null,
  reload: () => {},
});

export function StorefrontProvider({ children }: { children: ReactNode }) {
  const [data, setData] = useState<StorefrontPayload | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [tick, setTick] = useState(0);

  const reload = useCallback(() => setTick((t) => t + 1), []);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);
    getPlatformStorefront()
      .then((payload) => {
        if (!cancelled) setData(payload);
      })
      .catch((e) => {
        if (!cancelled) {
          setData(null);
          setError(errText(e, "Storefront not available"));
        }
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [tick]);

  return (
    <StorefrontContext.Provider value={{ data, loading, error, reload }}>
      {children}
    </StorefrontContext.Provider>
  );
}

export const useStorefront = () => useContext(StorefrontContext);
