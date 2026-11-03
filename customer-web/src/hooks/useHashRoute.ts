import { useSyncExternalStore } from "react";
import { flushSync } from "react-dom";

export type RouteInfo = {
  /** e.g. "product" from "#/product/foo" */
  name: string;
  /** remaining segments, e.g. ["foo"] */
  params: string[];
  /** query in the hash, e.g. {category: "drinks"} for "#/browse?category=drinks" */
  query: URLSearchParams;
};

type ViewTransitionDocument = Document & {
  startViewTransition?: (callback: () => void) => unknown;
};

function parse(): RouteInfo {
  const raw = window.location.hash.replace(/^#\/?/, "");
  const [pathPart, queryPart = ""] = raw.split("?");
  const segments = pathPart.split("/").filter(Boolean);
  return {
    name: (segments[0] || "home").toLowerCase(),
    params: segments.slice(1),
    query: new URLSearchParams(queryPart),
  };
}

/* ------------------------------------------------------------------ *
 * Router store
 *
 * `useHashRoute` is called by the shell and by pages that own filter
 * state. Keeping one module-level snapshot means every subscriber sees
 * the same object, and — importantly — a navigation runs a single
 * View Transition instead of one per hook instance.
 * ------------------------------------------------------------------ */

let current: RouteInfo = parse();
let currentHash = window.location.hash;
const listeners = new Set<() => void>();
let listening = false;

function emit() {
  for (const listener of listeners) listener();
}

/**
 * Run a DOM update inside the browser's native View Transition when
 * available (Chrome/Edge 111+, Safari 18+). This is the "free CSS page
 * transition" path: no animation library, and the cross-fade is defined in
 * styles.css via `::view-transition-old/new(root)`.
 *
 * Falls back to an immediate update when the API is missing or the shopper
 * asked for reduced motion, so navigation never waits on an unavailable
 * feature.
 */
export function withViewTransition(update: () => void) {
  const doc = document as unknown as ViewTransitionDocument;
  const reduce = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches ?? false;
  if (!doc.startViewTransition || reduce) {
    update();
    return;
  }
  try {
    doc.startViewTransition(() => {
      // flushSync makes React commit before the browser snapshots the new
      // page — without it the transition captures the old tree twice.
      flushSync(update);
    });
  } catch {
    update();
  }
}

function onHashChange() {
  if (window.location.hash === currentHash) return;
  const prev = current;
  const next = parse();
  currentHash = window.location.hash;
  const pageChanged = prev.name !== next.name || prev.params.join("/") !== next.params.join("/");

  withViewTransition(() => {
    current = next;
    emit();
    // Page-level navigations start at the top; filter updates on the same
    // page (browse sort/price) keep the shopper's scroll position.
    if (pageChanged) window.scrollTo({ top: 0, left: 0, behavior: "auto" });
  });
}

function subscribe(listener: () => void) {
  listeners.add(listener);
  if (!listening) {
    listening = true;
    window.addEventListener("hashchange", onHashChange);
  }
  return () => {
    listeners.delete(listener);
    if (listeners.size === 0) {
      listening = false;
      window.removeEventListener("hashchange", onHashChange);
    }
  };
}

function getSnapshot(): RouteInfo {
  return current;
}

export function useHashRoute(): RouteInfo {
  return useSyncExternalStore(subscribe, getSnapshot, getSnapshot);
}

export function navigate(path: string, opts: { replace?: boolean } = {}) {
  const hash = `#/${path.replace(/^\/+/, "")}`;
  if (opts.replace) {
    history.replaceState(null, "", hash);
    window.dispatchEvent(new Event("hashchange"));
  } else {
    window.location.hash = hash;
  }
}

export function href(path: string): string {
  return `#/${path.replace(/^\/+/, "")}`;
}
