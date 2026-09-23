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
  getStorefront,
  type StorefrontPayload,
} from "../services/api";

type Ctx = {
  slug: string;
  setSlug: (s: string) => void;
  data: StorefrontPayload | null;
  loading: boolean;
  error: string | null;
  reload: () => void;
};

const StorefrontContext = createContext<Ctx>({
  slug: "",
  setSlug: () => {},
  data: null,
  loading: true,
  error: null,
  reload: () => {},
});

export function slugFromHash(): string {
  const hash = window.location.hash.replace(/^#\/?/, "");
  const m = hash.match(/(?:^|\/)shop\/([^/?#]+)/);
  return m ? decodeURIComponent(m[1]) : "";
}

export function StorefrontProvider({ children }: { children: ReactNode }) {
  const [slug, setSlugState] = useState(
    () => localStorage.getItem("eg-cust-store") || slugFromHash() || "rahuls-store",
  );
  const [data, setData] = useState<StorefrontPayload | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [tick, setTick] = useState(0);

  const reload = useCallback(() => setTick((t) => t + 1), []);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);
    getStorefront(slug)
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
  }, [slug, tick]);

  // Follow ?shop=slug in the hash (deep links from the dashboard preview).
  useEffect(() => {
    const fromHash = slugFromHash();
    if (fromHash && fromHash !== slug) setSlugState(fromHash);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [window.location.hash]);

  const setSlug = useCallback((s: string) => {
    localStorage.setItem("eg-cust-store", s);
    setSlugState(s);
  }, []);

  return (
    <StorefrontContext.Provider value={{ slug, setSlug, data, loading, error, reload }}>
      {children}
    </StorefrontContext.Provider>
  );
}

export const useStorefront = () => useContext(StorefrontContext);
