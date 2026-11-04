import {
  ApiError,
  addToWishlist,
  getTokens,
  removeFromWishlist,
} from "../services/api";
import { syncWishlistCache } from "./history";

/**
 * Offline wishlist write-behind queue.
 *
 * While offline the heart is optimistic and the desired final state is stored
 * per product (last write wins). On reconnect the queue replays against the
 * API, so toggling on/off/on offline results in one sync, not three.
 *
 * Non-retryable API responses (4xx except 429) drop the item: replaying a
 * deleted product or an expired account forever would wedge the queue.
 * Network failures and 5xx responses stay queued for the next reconnect.
 */

const QUEUE_KEY = "eg-wishlist-queue";

export type WishlistQueueItem = {
  slug: string;
  wished: boolean;
  at: number;
};

function readQueue(): WishlistQueueItem[] {
  try {
    const raw = localStorage.getItem(QUEUE_KEY);
    if (!raw) return [];
    const parsed: unknown = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    return parsed.filter(
      (item): item is WishlistQueueItem =>
        !!item &&
        typeof item === "object" &&
        typeof (item as WishlistQueueItem).slug === "string" &&
        typeof (item as WishlistQueueItem).wished === "boolean",
    );
  } catch {
    return [];
  }
}

function writeQueue(items: WishlistQueueItem[]): void {
  try {
    if (items.length === 0) localStorage.removeItem(QUEUE_KEY);
    else localStorage.setItem(QUEUE_KEY, JSON.stringify(items));
  } catch {
    /* Storage unavailable: the optimistic UI still works for this session. */
  }
}

/** Remember the final desired wishlist state for a product while offline. */
export function queueWishlistAction(slug: string, wished: boolean): void {
  const items = readQueue().filter((item) => item.slug !== slug);
  items.push({ slug, wished, at: Date.now() });
  writeQueue(items);
}

let flushing: Promise<number> | null = null;

/**
 * Replay queued wishlist intent. Returns how many products were synced.
 * Concurrent callers share one flush; the queue is only rewritten once the
 * pass finishes, so a new offline toggle mid-flush is preserved.
 */
export function flushWishlistQueue(): Promise<number> {
  if (flushing) return flushing;

  const task = (async () => {
    const items = readQueue();
    if (items.length === 0 || !getTokens()) return 0;

    const remaining: WishlistQueueItem[] = [];
    let synced = 0;

    for (const item of items) {
      try {
        if (item.wished) await addToWishlist(item.slug);
        else await removeFromWishlist(item.slug);
        syncWishlistCache(item.slug, item.wished);
        synced += 1;
      } catch (error) {
        const status = error instanceof ApiError ? error.status : null;
        const permanent = status != null && status >= 400 && status < 500 && status !== 429;
        if (!permanent) remaining.push(item);
      }
    }

    // Preserve newer intent added while this pass was in flight. A same-slug
    // toggle has a fresh timestamp and must win over the version we just
    // replayed; an untouched item keeps the original queue entry.
    const originalBySlug = new Map(items.map((item) => [item.slug, item]));
    const current = readQueue();
    const newer = current.filter((item) => {
      const original = originalBySlug.get(item.slug);
      return !original || item.at > original.at;
    });
    const superseded = new Set(newer.map((item) => item.slug));
    writeQueue([
      ...remaining.filter((item) => !superseded.has(item.slug)),
      ...newer,
    ]);
    return synced;
  })();

  const tracked = task.finally(() => {
    flushing = null;
  });
  flushing = tracked;
  return tracked;
}
