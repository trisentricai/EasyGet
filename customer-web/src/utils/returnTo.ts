const RETURN_TO_KEY = "eg-return-to";
const MAX_LENGTH = 2048;

/**
 * Remember the hash path a guest was trying to reach before the auth guard
 * sent them to `#/login`. Stored in sessionStorage so it dies with the tab and
 * never leaks between browser sessions.
 */
export function rememberReturnTo(path: string): void {
  const clean = path.replace(/^#\/?/, "").trim();
  if (!clean || clean.startsWith("login")) return;
  try {
    sessionStorage.setItem(RETURN_TO_KEY, clean.slice(0, MAX_LENGTH));
  } catch {
    /* storage unavailable — login will fall back to home */
  }
}

/** Read and consume the remembered path (one-shot). */
export function takeReturnTo(): string | null {
  try {
    const value = sessionStorage.getItem(RETURN_TO_KEY);
    if (value) sessionStorage.removeItem(RETURN_TO_KEY);
    if (!value || value.length > MAX_LENGTH) return null;
    return value;
  } catch {
    return null;
  }
}
