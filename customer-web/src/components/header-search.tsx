import { useEffect, useRef, useState, type RefObject } from "react";
import { getSearchSuggestions, searchWithFallback } from "../services/api";
import { navigate } from "../hooks/useHashRoute";
import { Icon } from "./icons";

/**
 * Header search with API-backed suggestions and a graceful catalogue fallback.
 * The existing `/` shortcut keeps working through [inputRef]; submitting always
 * routes to the real SearchPage so no query handling is duplicated here.
 */
export function HeaderSearch({ inputRef }: { inputRef?: RefObject<HTMLInputElement | null> }) {
  const [query, setQuery] = useState("");
  const [suggestions, setSuggestions] = useState<string[]>([]);
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState(-1);
  const wrapRef = useRef<HTMLDivElement>(null);
  const blurTimer = useRef<number | null>(null);

  useEffect(
    () => () => {
      if (blurTimer.current) window.clearTimeout(blurTimer.current);
    },
    [],
  );

  useEffect(() => {
    const term = query.trim();
    if (term.length < 2) {
      setSuggestions([]);
      setOpen(false);
      setActive(-1);
      return;
    }

    let cancelled = false;
    const timer = window.setTimeout(async () => {
      let items: string[] = [];
      try {
        items = await getSearchSuggestions(term);
      } catch {
        /* fall through to the catalogue-backed suggestion path */
      }
      if (!Array.isArray(items)) items = [];
      if (items.length === 0) {
        try {
          const result = await searchWithFallback({ q: term });
          items = result.results.slice(0, 6).map((product) => product.name);
        } catch {
          items = [];
        }
      }
      if (cancelled) return;
      const unique = [...new Set(items.filter(Boolean))].slice(0, 6);
      setSuggestions(unique);
      setOpen(unique.length > 0);
      setActive(-1);
    }, 180);

    return () => {
      cancelled = true;
      window.clearTimeout(timer);
    };
  }, [query]);

  useEffect(() => {
    const onPointerDown = (event: PointerEvent) => {
      if (!wrapRef.current?.contains(event.target as Node)) setOpen(false);
    };
    document.addEventListener("pointerdown", onPointerDown);
    return () => document.removeEventListener("pointerdown", onPointerDown);
  }, []);

  const go = (term: string) => {
    const value = term.trim();
    if (!value) return;
    setOpen(false);
    setSuggestions([]);
    setQuery(value);
    navigate(`search?q=${encodeURIComponent(value)}`);
  };

  return (
    <div className="search-shell" ref={wrapRef}>
      <form
        className="searchform"
        role="search"
        onSubmit={(event) => {
          event.preventDefault();
          go(active >= 0 && suggestions[active] ? suggestions[active] : query);
        }}
      >
        <span className="search-ico" aria-hidden="true">
          <Icon name="search" size={18} />
        </span>
        <input
          ref={inputRef}
          name="q"
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          onFocus={() => {
            if (blurTimer.current) window.clearTimeout(blurTimer.current);
            if (suggestions.length) setOpen(true);
          }}
          onBlur={() => {
            blurTimer.current = window.setTimeout(() => setOpen(false), 120);
          }}
          onKeyDown={(event) => {
            if (event.key === "ArrowDown" && suggestions.length) {
              event.preventDefault();
              setOpen(true);
              setActive((i) => (i + 1) % suggestions.length);
            } else if (event.key === "ArrowUp" && suggestions.length) {
              event.preventDefault();
              setActive((i) => (i <= 0 ? suggestions.length - 1 : i - 1));
            } else if (event.key === "Escape") {
              setOpen(false);
              setActive(-1);
            }
          }}
          placeholder="Search products, brands"
          aria-label="Search products"
          aria-autocomplete="list"
          aria-expanded={open}
          aria-controls="header-search-suggestions"
          autoComplete="off"
        />
        <kbd className="search-kbd" aria-hidden="true">/</kbd>
        <button type="submit" aria-label="Search">
          <Icon name="arrowRight" size={16} />
        </button>
      </form>

      {open && suggestions.length > 0 ? (
        <div className="suggestions" id="header-search-suggestions" role="listbox">
          {suggestions.map((suggestion, index) => (
            <button
              type="button"
              role="option"
              aria-selected={index === active}
              className={`suggestion ${index === active ? "is-active" : ""}`.trim()}
              key={suggestion}
              onMouseDown={(event) => event.preventDefault()}
              onMouseEnter={() => setActive(index)}
              onClick={() => go(suggestion)}
            >
              <span className="suggestion-art" aria-hidden="true">
                <Icon name="search" size={15} />
              </span>
              <span>
                <strong>{suggestion}</strong>
                <small>Search EasyGet</small>
              </span>
            </button>
          ))}
        </div>
      ) : null}
    </div>
  );
}
