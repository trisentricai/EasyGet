import { useEffect, useState } from "react";
import { useAuth } from "../context/AuthContext";
import { navigate } from "../hooks/useHashRoute";
import { asArray, errText, listWishlist, type Product } from "../services/api";
import { EmptyState, ProductCard, SignInGate, Spinner } from "../components/ui";
import { setWishlistCache } from "../utils/history";

export function WishlistPage() {
  const { user } = useAuth();
  const [items, setItems] = useState<Product[] | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!user) return;
    let cancelled = false;
    setItems(null);
    setError(null);
    listWishlist()
      .then((d) => {
        if (cancelled) return;
        const rows = asArray<Product>(d);
        setItems(rows);
        setWishlistCache(rows.map((p) => p.slug));
      })
      .catch((e) => {
        if (!cancelled) setError(errText(e));
      });
    return () => {
      cancelled = true;
    };
  }, [user]);

  if (!user) {
    return <SignInGate title="Your wishlist" text="Sign in to see the products you've saved." />;
  }

  return (
    <div className="page">
      <div className="pagehead">
        <h1>Your wishlist</h1>
        <p className="muted">Tap the heart on any product to keep it here for later.</p>
      </div>

      {error ? (
        <EmptyState icon="warning" title="Couldn't load wishlist" text={error} />
      ) : items === null ? (
        <Spinner />
      ) : items.length === 0 ? (
        <EmptyState
          icon="heart"
          title="Nothing saved yet"
          text="Products you heart show up here so you can find them quickly."
          action={
            <button className="btn" onClick={() => navigate("browse")}>
              Browse products
            </button>
          }
        />
      ) : (
        <div className="grid grid-products">
          {items.map((p) => (
            <ProductCard key={p.slug} product={p} />
          ))}
        </div>
      )}
    </div>
  );
}
