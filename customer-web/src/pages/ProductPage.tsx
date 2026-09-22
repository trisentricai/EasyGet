import { useEffect, useState } from "react";
import { useAuth } from "../context/AuthContext";
import { useCart } from "../context/CartContext";
import { useToast } from "../context/ToastContext";
import { navigate } from "../hooks/useHashRoute";
import { errText, getProduct, img, type ProductDetail } from "../services/api";
import { Price, SignInGate, Spinner } from "../components/ui";

export function ProductPage({ slug }: { slug: string }) {
  const { user } = useAuth();
  const { add } = useCart();
  const toast = useToast();
  const [product, setProduct] = useState<ProductDetail | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [variantId, setVariantId] = useState<number | null>(null);
  const [activeImage, setActiveImage] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    let cancelled = false;
    setProduct(null);
    setError(null);
    getProduct(slug)
      .then((p) => {
        if (cancelled) return;
        setProduct(p);
        const firstActive = p.variants.find((v) => v.is_active) ?? p.variants[0];
        setVariantId(firstActive?.id ?? null);
        setActiveImage(img(p.primary_image));
      })
      .catch((e) => {
        if (!cancelled) setError(errText(e, "Product not found"));
      });
    return () => {
      cancelled = true;
    };
  }, [slug]);

  if (!user) return <SignInGate title="View product" text="Sign in to see details and add to cart." />;
  if (error) {
    return (
      <div className="page">
        <div className="empty-state">
          <div className="empty-ico">🔎</div>
          <h3>Product not found</h3>
          <p className="muted">{error}</p>
        </div>
      </div>
    );
  }
  if (!product) return <Spinner />;

  const activeVariant = product.variants.find((v) => v.id === variantId) ?? null;
  const price = activeVariant?.price ?? product.base_price;
  const images = product.images.length
    ? product.images
    : product.primary_image
      ? [{ id: 0, image: product.primary_image, caption: "", is_primary: true, sort_order: 0 }]
      : [];

  const addToCart = async () => {
    if (!variantId) return;
    setBusy(true);
    try {
      await add(variantId, 1);
      toast.push("Added to cart 🛒");
    } catch (e) {
      toast.push(errText(e, "Could not add to cart"), "err");
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="page">
      <div style={{ marginBottom: 14 }}>
        <span className="link" onClick={() => history.back()}>← Back</span>
      </div>
      <div style={{ display: "grid", gridTemplateColumns: "minmax(280px, 460px) 1fr", gap: 34, alignItems: "start" }}>
        <div>
          <div className="product-thumb" style={{ aspectRatio: "1/0.9", borderRadius: 18, border: "1px solid var(--border)" }}>
            {activeImage ? (
              <img src={activeImage} alt={product.name} style={{ borderRadius: 18 }} />
            ) : (
              <span className="ph" style={{ fontSize: 64 }}>🛒</span>
            )}
          </div>
          {images.length > 1 ? (
            <div style={{ display: "flex", gap: 8, marginTop: 10, flexWrap: "wrap" }}>
              {images.map((im) => (
                <button
                  key={im.id}
                  onClick={() => setActiveImage(img(im.image))}
                  style={{
                    width: 58,
                    height: 58,
                    padding: 0,
                    borderRadius: 10,
                    overflow: "hidden",
                    border: img(im.image) === activeImage ? "2px solid var(--primary)" : "1px solid var(--border)",
                    background: "var(--surface)",
                    cursor: "pointer",
                  }}
                >
                  <img src={img(im.image)!} alt={im.caption} style={{ width: "100%", height: "100%", objectFit: "cover" }} />
                </button>
              ))}
            </div>
          ) : null}
        </div>

        <div>
          {product.category ? (
            <a className="link" href={`#/browse?category=${product.category.slug}`}>{product.category.name}</a>
          ) : null}
          <h1 style={{ margin: "6px 0 6px", fontSize: 27 }}>{product.name}</h1>
          {product.brand ? <p className="muted" style={{ margin: "0 0 10px" }}>by {product.brand}</p> : null}
          <Price price={price} mrp={product.mrp} discount={activeVariant?.discount_percent || product.discount_percent} size="lg" />

          {product.description ? (
            <p style={{ marginTop: 16, lineHeight: 1.65, fontSize: 14.5 }}>{product.description}</p>
          ) : null}

          {product.variants.length > 1 ? (
            <div style={{ marginTop: 18 }}>
              <h3 style={{ margin: "0 0 8px", fontSize: 14 }}>Choose option</h3>
              <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
                {product.variants.filter((v) => v.is_active).map((v) => (
                  <button
                    key={v.id}
                    onClick={() => setVariantId(v.id)}
                    className="btn btn-sm"
                    style={
                      v.id === variantId
                        ? {}
                        : { background: "var(--surface)", color: "var(--text)", borderColor: "var(--border)" }
                    }
                  >
                    {v.name || v.sku} · ₹{v.price}
                  </button>
                ))}
              </div>
            </div>
          ) : null}

          <div className="form-actions" style={{ marginTop: 24 }}>
            <button className="btn" style={{ minWidth: 200 }} disabled={busy || !variantId} onClick={addToCart}>
              {busy ? "Adding…" : "Add to cart 🛒"}
            </button>
            <button
              className="btn btn-ghost"
              onClick={() => {
                if (variantId) void add(variantId, 1).then(() => navigate("cart"));
              }}
              disabled={busy || !variantId}
            >
              Buy now
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
