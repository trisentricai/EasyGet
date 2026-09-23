import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from "react";
import {
  addToCart,
  clearCart as clearCartApi,
  getCart,
  removeCartItem,
  updateCartItem,
  type Cart,
} from "../services/api";
import { useAuth } from "./AuthContext";

type Ctx = {
  cart: Cart | null;
  count: number;
  loading: boolean;
  refresh: () => Promise<void>;
  add: (variantId: number, qty?: number) => Promise<void>;
  setQty: (itemId: number, qty: number) => Promise<void>;
  remove: (itemId: number) => Promise<void>;
  clear: () => Promise<void>;
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
});

export function CartProvider({ children }: { children: ReactNode }) {
  const { user, ready } = useAuth();
  const [cart, setCart] = useState<Cart | null>(null);
  const [loading, setLoading] = useState(false);

  const refresh = useCallback(async () => {
    setLoading(true);
    try {
      setCart(await getCart());
    } catch {
      setCart(null);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (ready && user) void refresh();
    if (ready && !user) setCart(null);
  }, [ready, user, refresh]);

  const add = useCallback(
    async (variantId: number, qty = 1) => {
      await addToCart(variantId, qty);
      await refresh();
    },
    [refresh],
  );

  const setQty = useCallback(
    async (itemId: number, qty: number) => {
      if (qty <= 0) {
        await removeCartItem(itemId);
      } else {
        await updateCartItem(itemId, qty);
      }
      await refresh();
    },
    [refresh],
  );

  const remove = useCallback(
    async (itemId: number) => {
      await removeCartItem(itemId);
      await refresh();
    },
    [refresh],
  );

  const clear = useCallback(async () => {
    await clearCartApi();
    await refresh();
  }, [refresh]);

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
      }}
    >
      {children}
    </CartContext.Provider>
  );
}

export const useCart = () => useContext(CartContext);
