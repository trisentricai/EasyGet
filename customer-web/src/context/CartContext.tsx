import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useRef,
  useState,
  type ReactNode,
} from "react";
import {
  addToCart,
  clearCart as clearCartApi,
  getCart,
  removeCartItem,
  updateCartItem,
  validateCoupon,
  type Cart,
  type CartItem,
} from "../services/api";
import {
  clearGuestCart,
  guestCart,
  guestLine,
  MAX_CART_QTY,
  readGuestCart,
  readGuestCartItems,
  setGuestLineQuantity,
  writeGuestCartItems,
  type GuestVariantSnapshot,
} from "../utils/guestCart";
import { readStoredCoupon, writeStoredCoupon } from "../utils/coupon";
import type { AppliedCoupon } from "../utils/pricing";
import { useAuth } from "./AuthContext";
import { useToast } from "./ToastContext";

type CouponResult = { ok: boolean; message?: string };

type Ctx = {
  cart: Cart | null;
  count: number;
  loading: boolean;
  refresh: () => Promise<void>;
  add: (variantId: number, qty?: number, snapshot?: GuestVariantSnapshot) => Promise<void>;
  setQty: (itemId: number, qty: number) => Promise<void>;
  remove: (itemId: number) => Promise<void>;
  clear: () => Promise<void>;
  /** Coupon applied to the cart, persisted for the tab's session. */
  appliedCoupon: AppliedCoupon | null;
  couponBusy: boolean;
  applyCoupon: (code: string) => Promise<CouponResult>;
  removeCoupon: () => void;
};

const noop = async () => {};
const CartContext = createContext<Ctx>({
  cart: null,
  count: 0,
  loading: false,
  refresh: noop,
  add: noop,
  setQty: noop,
  remove: noop,
  clear: noop,
  appliedCoupon: null,
  couponBusy: false,
  applyCoupon: async () => ({ ok: false }),
  removeCoupon: () => {},
});

export function CartProvider({ children }: { children: ReactNode }) {
  const { user, ready } = useAuth();
  const toast = useToast();
  const [cart, setCart] = useState<Cart | null>(null);
  const [loading, setLoading] = useState(false);
  const [appliedCoupon, setAppliedCoupon] = useState<AppliedCoupon | null>(readStoredCoupon);
  const [couponBusy, setCouponBusy] = useState(false);
  /** Guards React StrictMode's double-effect from merging twice. */
  const syncedUser = useRef<number | null>(null);
  /** Last `code:subtotal` pair we validated, so cart refreshes stay quiet. */
  const lastCouponCheck = useRef<string>("");

  const refresh = useCallback(async () => {
    if (!user) {
      setCart(readGuestCart());
      return;
    }
    setLoading(true);
    try {
      setCart(await getCart());
    } catch {
      setCart(null);
    } finally {
      setLoading(false);
    }
  }, [user]);

  const storeCoupon = useCallback((coupon: AppliedCoupon | null) => {
    setAppliedCoupon(coupon);
    writeStoredCoupon(coupon);
  }, []);

  const removeCoupon = useCallback(() => {
    storeCoupon(null);
  }, [storeCoupon]);

  const applyCoupon = useCallback(
    async (code: string): Promise<CouponResult> => {
      const clean = code.trim();
      if (!clean) return { ok: false, message: "Enter a coupon code." };
      const subtotal = Number(cart?.subtotal ?? 0);
      if (!cart || subtotal <= 0) {
        return { ok: false, message: "Add items to your cart before applying a coupon." };
      }

      setCouponBusy(true);
      try {
        const res = await validateCoupon(clean, subtotal);
        if (!res.valid) {
          return { ok: false, message: res.message || "This coupon can't be applied." };
        }
        const next: AppliedCoupon = {
          code: res.coupon.code,
          discount_type: res.coupon.discount_type,
          discount_value: res.coupon.discount_value,
          max_discount: res.coupon.max_discount ?? null,
        };
        storeCoupon(next);
        // The effect below skips the pair we just validated.
        lastCouponCheck.current = `${next.code}:${subtotal.toFixed(2)}`;
        return { ok: true };
      } catch (e) {
        return {
          ok: false,
          message: e instanceof Error && e.message ? e.message : "Could not apply coupon.",
        };
      } finally {
        setCouponBusy(false);
      }
    },
    [cart, storeCoupon],
  );

  // Revalidate the coupon whenever the subtotal changes (quantity edits,
  // guest→user merge, items removed). Business failures clear the coupon with
  // a gentle toast; network failures keep it because the backend revalidates
  // authoritatively at order creation.
  useEffect(() => {
    if (!appliedCoupon || !cart) return;
    if (cart.items.length === 0) {
      storeCoupon(null);
      return;
    }

    const subtotal = Number(cart.subtotal ?? 0);
    if (subtotal <= 0) return;
    const key = `${appliedCoupon.code}:${subtotal.toFixed(2)}`;
    if (lastCouponCheck.current === key) return;

    const couponCode = appliedCoupon.code;
    const handle = window.setTimeout(() => {
      lastCouponCheck.current = key;
      void validateCoupon(couponCode, subtotal)
        .then((res) => {
          if (!res.valid) {
            storeCoupon(null);
            toast.push(`${couponCode} removed — ${res.message}`, "info");
            return;
          }
          const next: AppliedCoupon = {
            code: res.coupon.code,
            discount_type: res.coupon.discount_type,
            discount_value: res.coupon.discount_value,
            max_discount: res.coupon.max_discount ?? null,
          };
          setAppliedCoupon((prev) => {
            if (
              prev &&
              prev.code === next.code &&
              prev.discount_type === next.discount_type &&
              prev.discount_value === next.discount_value &&
              prev.max_discount === next.max_discount
            ) {
              return prev;
            }
            writeStoredCoupon(next);
            return next;
          });
        })
        .catch(() => {
          /* Network hiccup: keep it; order creation revalidates. */
        });
    }, 350);

    return () => window.clearTimeout(handle);
  }, [appliedCoupon, cart, storeCoupon, toast]);

  /**
   * On sign-in: merge a guest cart into the server cart.
   *
   * - Matching variants sum quantities, capped at MAX_CART_QTY.
   * - Guest-only lines are pushed up to the server.
   * - With no guest cart we simply adopt the server cart.
   *
   * Failed lines stay in localStorage so a transient API error can be retried
   * on the next sign-in instead of silently losing the shopper's picks.
   */
  const mergeGuestCart = useCallback(async () => {
    const guestItems = readGuestCartItems();

    if (guestItems.length === 0) {
      setLoading(true);
      try {
        setCart(await getCart());
      } catch {
        setCart(null);
      } finally {
        setLoading(false);
      }
      return;
    }

    setLoading(true);
    let merged = 0;
    const failed: CartItem[] = [];

    try {
      const server = await getCart();

      for (const item of guestItems) {
        const existing = server.items.find((line) => line.variant.id === item.variant.id);
        try {
          if (existing) {
            const target = Math.min(existing.quantity + item.quantity, MAX_CART_QTY);
            if (target > existing.quantity) {
              await updateCartItem(existing.id, target);
              merged += target - existing.quantity;
            }
          } else {
            await addToCart(item.variant.id, item.quantity);
            merged += item.quantity;
          }
        } catch {
          failed.push(item);
        }
      }

      if (failed.length > 0) writeGuestCartItems(failed);
      else clearGuestCart();

      try {
        setCart(await getCart());
      } catch {
        setCart(null);
      }

      if (merged > 0) {
        toast.push(
          `${merged} item${merged === 1 ? "" : "s"} merged from your guest cart.`,
        );
      }
    } catch {
      // The server cart could not be read at all — leave the guest cart intact.
      setCart(null);
    } finally {
      setLoading(false);
    }
  }, [toast]);

  useEffect(() => {
    if (!ready) return;

    if (!user) {
      syncedUser.current = null;
      setCart(readGuestCart());
      setLoading(false);
      return;
    }

    if (syncedUser.current === user.id) return;
    syncedUser.current = user.id;
    void mergeGuestCart();
  }, [ready, user, mergeGuestCart]);

  const add = useCallback(
    async (variantId: number, qty = 1, snapshot?: GuestVariantSnapshot) => {
      if (!user) {
        const items = readGuestCartItems();
        const existing = items.find((line) => line.variant.id === variantId);
        const next = existing
          ? items.map((line) =>
              line.variant.id === variantId
                ? setGuestLineQuantity(line, line.quantity + qty)
                : line,
            )
          : [...items, guestLine(variantId, qty, snapshot)];
        writeGuestCartItems(next);
        setCart(guestCart(next));
        return;
      }

      try {
        await addToCart(variantId, qty);
      } catch (e) {
        await refresh();
        throw e;
      }
      await refresh();
    },
    [user, refresh],
  );

  const setQty = useCallback(
    async (itemId: number, qty: number) => {
      if (!user) {
        const items = readGuestCartItems();
        const next =
          qty <= 0
            ? items.filter((line) => line.id !== itemId && line.variant.id !== itemId)
            : items.map((line) =>
                line.id === itemId || line.variant.id === itemId
                  ? setGuestLineQuantity(line, qty)
                  : line,
              );
        writeGuestCartItems(next);
        setCart(next.length > 0 ? guestCart(next) : null);
        return;
      }

      try {
        if (qty <= 0) {
          await removeCartItem(itemId);
        } else {
          await updateCartItem(itemId, qty);
        }
      } catch (e) {
        await refresh();
        throw e;
      }
      await refresh();
    },
    [user, refresh],
  );

  const remove = useCallback(
    async (itemId: number) => {
      if (!user) {
        const next = readGuestCartItems().filter(
          (line) => line.id !== itemId && line.variant.id !== itemId,
        );
        writeGuestCartItems(next);
        setCart(next.length > 0 ? guestCart(next) : null);
        return;
      }

      await removeCartItem(itemId);
      await refresh();
    },
    [user, refresh],
  );

  const clear = useCallback(async () => {
    storeCoupon(null);
    if (!user) {
      clearGuestCart();
      setCart(null);
      return;
    }

    await clearCartApi();
    await refresh();
  }, [user, refresh, storeCoupon]);

  return (
    <CartContext.Provider
      value={{
        cart,
        count: cart?.total_items ?? 0,
        loading,
        refresh,
        add,
        setQty,
        remove,
        clear,
        appliedCoupon,
        couponBusy,
        applyCoupon,
        removeCoupon,
      }}
    >
      {children}
    </CartContext.Provider>
  );
}

export const useCart = () => useContext(CartContext);
