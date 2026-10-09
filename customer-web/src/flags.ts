/**
 * EASYGET — NEXT_UI feature flag (DESIGN.md §8).
 *
 * The hybrid redesign ships behind this flag until the client approves:
 * new-look components render only when it is on; everything else keeps the
 * current UI untouched.
 *
 * Precedence: `?next_ui=1|0` query param (persisted to localStorage) >
 * `VITE_NEXT_UI=1` build env > off.
 */
const STORAGE_KEY = "eg-next-ui";

export function isNextUi(): boolean {
  if (typeof window === "undefined") {
    return import.meta.env.VITE_NEXT_UI === "1";
  }
  try {
    const q = new URLSearchParams(window.location.search);
    const param = q.get("next_ui");
    if (param === "1") {
      window.localStorage.setItem(STORAGE_KEY, "1");
      return true;
    }
    if (param === "0") {
      window.localStorage.removeItem(STORAGE_KEY);
      return false;
    }
    if (window.localStorage.getItem(STORAGE_KEY) === "1") return true;
  } catch {
    /* storage/blocked-context safe: fall through to the build flag */
  }
  return import.meta.env.VITE_NEXT_UI === "1";
}
