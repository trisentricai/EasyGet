import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useRef,
  useState,
  type ReactNode,
} from "react";
import { flushWishlistQueue } from "../utils/wishlistQueue";
import { useAuth } from "./AuthContext";
import { useToast } from "./ToastContext";

type NetworkValue = {
  online: boolean;
};

const NetworkContext = createContext<NetworkValue>({ online: true });

export const useNetwork = () => useContext(NetworkContext);

type Notice = "offline" | "online" | "hidden";

/**
 * Global connectivity state plus the two banners:
 *   offline -> amber status until the browser reconnects
 *   online  -> green "Back online" confirmation for 3s, then fades out
 *
 * Mounted inside AuthProvider/ToastProvider so reconnects can replay the
 * wishlist write-behind queue and report the result.
 */
export function NetworkProvider({ children }: { children: ReactNode }) {
  const { user, ready } = useAuth();
  const toast = useToast();
  const [online, setOnline] = useState(() =>
    typeof navigator === "undefined" ? true : navigator.onLine,
  );
  const [notice, setNotice] = useState<Notice>(() =>
    typeof navigator !== "undefined" && !navigator.onLine ? "offline" : "hidden",
  );
  const wasOffline = useRef(
    typeof navigator !== "undefined" ? !navigator.onLine : false,
  );
  const noticeTimer = useRef<number | null>(null);

  const syncWishlist = useCallback(async () => {
    try {
      const count = await flushWishlistQueue();
      if (count > 0) {
        toast.push(
          `Synced ${count} wishlist change${count === 1 ? "" : "s"}.`,
          "ok",
        );
      }
    } catch {
      /* Keep the queue for the next reconnect. */
    }
  }, [toast]);

  useEffect(() => {
    const clearNoticeTimer = () => {
      if (noticeTimer.current) {
        window.clearTimeout(noticeTimer.current);
        noticeTimer.current = null;
      }
    };

    const onOffline = () => {
      wasOffline.current = true;
      setOnline(false);
      setNotice("offline");
      clearNoticeTimer();
    };

    const onOnline = () => {
      const reconnected = wasOffline.current;
      wasOffline.current = false;
      setOnline(true);
      if (!reconnected) return;

      setNotice("online");
      clearNoticeTimer();
      noticeTimer.current = window.setTimeout(() => setNotice("hidden"), 3000);
      void syncWishlist();
    };

    window.addEventListener("offline", onOffline);
    window.addEventListener("online", onOnline);

    // Reconcile if connectivity changed while the tab was suspended.
    const current = navigator.onLine;
    setOnline(current);
    if (!current) {
      wasOffline.current = true;
      setNotice("offline");
    }

    return () => {
      window.removeEventListener("offline", onOffline);
      window.removeEventListener("online", onOnline);
      clearNoticeTimer();
    };
  }, [syncWishlist]);

  // A fresh sign-in (or a reload with queued changes) should sync even when
  // no offline -> online event fired in this tab.
  useEffect(() => {
    if (!ready || !user || !online) return;
    void syncWishlist();
  }, [ready, user, online, syncWishlist]);

  return (
    <NetworkContext.Provider value={{ online }}>
      {children}
      <NetworkBanner notice={notice} />
    </NetworkContext.Provider>
  );
}

function NetworkBanner({ notice }: { notice: Notice }) {
  const [mounted, setMounted] = useState(notice !== "hidden");
  const [fading, setFading] = useState(false);
  const [compact, setCompact] = useState(() =>
    typeof window === "undefined"
      ? false
      : window.matchMedia("(max-width: 700px)").matches,
  );

  useEffect(() => {
    const mq = window.matchMedia("(max-width: 700px)");
    const onChange = () => setCompact(mq.matches);
    mq.addEventListener("change", onChange);
    return () => mq.removeEventListener("change", onChange);
  }, []);

  useEffect(() => {
    if (notice === "hidden") {
      if (!mounted) return;
      setFading(true);
      const timer = window.setTimeout(() => {
        setMounted(false);
        setFading(false);
      }, 320);
      return () => window.clearTimeout(timer);
    }
    setMounted(true);
    setFading(false);
  }, [notice, mounted]);

  if (!mounted) return null;

  const offline = notice === "offline";
  return (
    <div
      role="status"
      aria-live="polite"
      aria-atomic="true"
      style={{
        position: "fixed",
        left: "50%",
        top: compact ? undefined : 12,
        bottom: compact ? 84 : undefined,
        zIndex: 1800,
        maxWidth: "calc(100vw - 32px)",
        padding: "9px 16px",
        borderRadius: 999,
        background: offline ? "#8a4b12" : "#166534",
        color: "#fff",
        border: "1px solid rgb(255 255 255 / 0.24)",
        boxShadow: "0 8px 28px rgb(0 0 0 / 0.2)",
        fontSize: 13.5,
        fontWeight: 600,
        lineHeight: 1.35,
        textAlign: "center",
        pointerEvents: "none",
        opacity: fading ? 0 : 1,
        transform: `translate(-50%, ${fading ? -8 : 0}px)`,
        transition: "opacity 300ms ease, transform 300ms ease",
      }}
    >
      {offline
        ? "⚠️ You are offline. Some features may be unavailable."
        : "✅ Back online. Syncing..."}
    </div>
  );
}
