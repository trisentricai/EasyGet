import { useEffect, useRef, useState } from "react";
import { keepPreviousData, useQuery } from "@tanstack/react-query";
import {
  errText,
  getSearchSuggestions,
  searchWithFallback,
} from "../services/api";
import { CardSkeletonGrid, EmptyState, ProductCard, Section } from "../components/ui";
import {
  TRENDING_SEARCHES,
  getRecentSearches,
  recordSearch,
} from "../utils/history";

export function SearchPage({ initialQuery }: { initialQuery?: string }) {
  const [q, setQ] = useState(initialQuery ?? "");
  const [sort, setSort] = useState("relevance");
  const [showSuggest, setShowSuggest] = useState(false);
  const [suggestions, setSuggestions] = useState<string[]>([]);
  const debounceRef = useRef<number | null>(null);

  const { data, error, isFetching, refetch } = useQuery({
    queryKey: ["search", q, sort],
    queryFn: () => searchWithFallback({ q, sort }),
    placeholderData: keepPreviousData,
  });
  const products = data ? data.results : null;
  const total = data ? data.total : 0;
  const busy = isFetching;
  const errorMsg = error ? errText(error, "Search failed") : null;

  useEffect(() => {
    if (initialQuery !== undefined && initialQuery !== q) setQ(initialQuery);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [initialQuery]);

  useEffect(() => {
    if (q.trim().length < 2) {
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
  }, [q]);

  return (
    <div className="page">
      <div className="pagehead">
        <h1>Search</h1>
        <p className="muted">
          {busy ? "Searching…" : products ? `${total} result${total === 1 ? "" : "s"}` : "Type to search the catalog"}
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
              recordSearch(q);
              void refetch();
            }
          }}
        />
        <select value={sort} onChange={(e) => setSort(e.target.value)} aria-label="Sort">
          <option value="relevance">Relevance</option>
          <option value="price_asc">Price: low → high</option>
          <option value="price_desc">Price: high → low</option>
          <option value="newest">Newest</option>
          <option value="popular">Popular</option>
          <option value="rating">Avg. Customer Review</option>
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
                {s}
              </div>
            ))}
          </div>
        ) : null}
      </div>

      {errorMsg ? (
        <EmptyState icon="warning" title="Search failed" text={errorMsg} />
      ) : !products && !busy ? (
        <SearchStart
          onPick={(term) => {
            setQ(term);
            setShowSuggest(false);
            recordSearch(term);
          }}
        />
      ) : busy && !products ? (
        <CardSkeletonGrid />
      ) : products && products.length === 0 ? (
        <EmptyState icon="search" title={`No results for "${q}"`} text="Check the spelling or try a broader term." />
      ) : products ? (
        <Section>
          <div className="grid grid-products">
            {products.map((p) => (
              <ProductCard key={p.id} product={p} />
            ))}
          </div>
        </Section>
      ) : null}
    </div>
  );
}

function SearchStart({ onPick }: { onPick: (term: string) => void }) {
  const [recent] = useState(() => getRecentSearches());
  return (
    <div>
      {recent.length > 0 && (
        <Section title="Recent searches">
          <div className="term-chips">
            {recent.map((t) => (
              <button key={t} className="term-chip" onClick={() => onPick(t)}>
                🕘 {t}
              </button>
            ))}
          </div>
        </Section>
      )}
      <Section title="Trending now" subtitle="Popular across the store">
        <div className="term-chips">
          {TRENDING_SEARCHES.map((t) => (
            <button key={t} className="term-chip term-hot" onClick={() => onPick(t)}>
              🔥 {t}
            </button>
          ))}
        </div>
      </Section>
    </div>
  );
}
