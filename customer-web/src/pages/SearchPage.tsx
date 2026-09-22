import { useEffect, useRef, useState } from "react";
import { useAuth } from "../context/AuthContext";
import {
  errText,
  getSearchSuggestions,
  searchWithFallback,
  type Product,
} from "../services/api";
import { CardSkeletonGrid, EmptyState, ProductCard, Section } from "../components/ui";

export function SearchPage({ initialQuery }: { initialQuery?: string }) {
  const { user } = useAuth();
  const [q, setQ] = useState(initialQuery ?? "");
  const [category, setCategory] = useState("");
  const [sort, setSort] = useState("relevance");
  const [products, setProducts] = useState<Product[] | null>(null);
  const [total, setTotal] = useState(0);
  const [tookMs, setTookMs] = useState(0);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [suggestions, setSuggestions] = useState<string[]>([]);
  const [showSuggest, setShowSuggest] = useState(false);
  const debounceRef = useRef<number | null>(null);

  useEffect(() => {
    if (initialQuery !== undefined && initialQuery !== q) setQ(initialQuery);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [initialQuery]);

  const runSearch = async () => {
    if (!user) return;
    setBusy(true);
    setError(null);
    try {
      const body: Record<string, unknown> = { q, sort, page: 1, page_size: 40 };
      if (category) body.category = category;
      const res = await searchWithFallback({ q, sort });
      setProducts(res.results);
      setTotal(res.total);
      setTookMs(res.took_ms);
    } catch (e) {
      setError(errText(e, "Search failed"));
      setProducts([]);
    } finally {
      setBusy(false);
    }
  };

  useEffect(() => {
    if (!user) return;
    void runSearch();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [user, q, category, sort]);

  useEffect(() => {
    if (!user || q.trim().length < 2) {
      setSuggestions([]);
      return;
    }
    if (debounceRef.current) window.clearTimeout(debounceRef.current);
    debounceRef.current = window.setTimeout(() => {
      getSearchSuggestions(q.trim())
        .then(setSuggestions)
        .catch(() => setSuggestions([]));
    }, 220);
    return () => {
      if (debounceRef.current) window.clearTimeout(debounceRef.current);
    };
  }, [q, user]);

  if (!user) {
    return (
      <div className="auth-wrap">
        <div className="auth-card" style={{ textAlign: "center" }}>
          <div style={{ fontSize: 40, marginBottom: 8 }}>🔐</div>
          <h1>Search products</h1>
          <p className="sub">Sign in to search the catalog.</p>
          <button className="btn btn-block" onClick={() => (window.location.hash = "#/login")}>
            Sign in / Create account
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="page">
      <div className="pagehead">
        <h1>Search</h1>
        <p className="muted">
          {busy ? "Searching…" : products ? `${total} result${total === 1 ? "" : "s"}${tookMs ? ` · ${tookMs} ms` : ""}` : "Type to search the catalog"}
        </p>
      </div>

      <div className="toolbar" style={{ position: "relative" }}>
        <input
          autoFocus
          placeholder="Search products, brands, categories…"
          value={q}
          style={{ flex: 1, minWidth: 220 }}
          onChange={(e) => {
            setQ(e.target.value);
            setShowSuggest(true);
          }}
          onFocus={() => setShowSuggest(true)}
          onBlur={() => window.setTimeout(() => setShowSuggest(false), 150)}
          onKeyDown={(e) => {
            if (e.key === "Enter") {
              setShowSuggest(false);
              void runSearch();
            }
          }}
        />
        <select value={sort} onChange={(e) => setSort(e.target.value)} aria-label="Sort">
          <option value="relevance">Relevance</option>
          <option value="price_asc">Price: low → high</option>
          <option value="price_desc">Price: high → low</option>
          <option value="newest">Newest</option>
          <option value="popular">Popular</option>
        </select>
        {showSuggest && suggestions.length > 0 ? (
          <div
            style={{
              position: "absolute",
              top: "100%",
              left: 0,
              right: 0,
              zIndex: 30,
              background: "var(--surface)",
              border: "1px solid var(--border)",
              borderRadius: 12,
              boxShadow: "var(--shadow)",
              overflow: "hidden",
              maxWidth: 480,
            }}
          >
            {suggestions.map((s) => (
              <div
                key={s}
                onMouseDown={() => {
                  setQ(s);
                  setShowSuggest(false);
                }}
                style={{ padding: "9px 14px", fontSize: 14, cursor: "pointer" }}
                onMouseEnter={(e) => (e.currentTarget.style.background = "var(--bg)")}
                onMouseLeave={(e) => (e.currentTarget.style.background = "")}
              >
                🔍 {s}
              </div>
            ))}
          </div>
        ) : null}
      </div>

      {error ? (
        <EmptyState icon="⚠️" title="Search failed" text={error} />
      ) : busy && !products ? (
        <CardSkeletonGrid />
      ) : products && products.length === 0 ? (
        <EmptyState icon="🤔" title={`No results for "${q}"`} text="Check the spelling or try a broader term." />
      ) : products ? (
        <Section>
          <div className="grid grid-products">
            {products.map((p, i) => (
              <ProductCard key={p.id} product={p} delay={Math.min(i, 10) * 30} />
            ))}
          </div>
        </Section>
      ) : null}
    </div>
  );
}
