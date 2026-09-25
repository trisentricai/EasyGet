import { useEffect, useState } from "react";
import { useAuth } from "../context/AuthContext";
import { useCart } from "../context/CartContext";
import { useToast } from "../context/ToastContext";
import { navigate } from "../hooks/useHashRoute";
import { errText, getProduct, img, type ProductDetail } from "../services/api";
import { EmptyState, Monogram, Price, SignInGate, Spinner } from "../components/ui";
import { recordView } from "../utils/history";

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
        recordView(p);
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
        <EmptyState icon="search" title="Product not found" text={error} />
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
      toast.push("Added to cart");
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
      <div className="product-detail">
        <div>
          <div className="product-thumb detail-thumb">
            {activeImage ? <img src={activeImage} alt={product.name} /> : <Monogram text={product.name} />}
          </div>
          {images.length > 1 ? (
            <div className="thumb-row">
              {images.map((im) => (
                <button
                  key={im.id}
                  onClick={() => setActiveImage(img(im.image))}
                  aria-label={`Show image: ${im.caption || "product"}`}
                  className={`thumb-btn ${img(im.image) === activeImage ? "active" : ""}`}
                >
                  <img src={img(im.image)!} alt={im.caption} />
                </button>
              ))}
            </div>
          ) : null}
        </div>

        <div>
          {product.category ? (
            <a className="link" href={`#/browse?category=${product.category.slug}`}>{product.category.name}</a>
          ) : null}
          <h1 className="detail-title">{product.name}</h1>
          {product.brand ? <p className="muted" style={{ margin: "0 0 10px" }}>by {product.brand}</p> : null}
          <Price price={price} mrp={product.mrp} discount={activeVariant?.discount_percent || product.discount_percent} size="lg" />

          {product.description ? (
            <p className="detail-desc">{product.description}</p>
          ) : null}

          {product.variants.length > 1 ? (
            <div style={{ marginTop: 18 }}>
              <h3 className="detail-option-label">Choose option</h3>
              <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
                {product.variants.filter((v) => v.is_active).map((v) => (
                  <button
                    key={v.id}
                    onClick={() => setVariantId(v.id)}
                    className={`variant-btn ${v.id === variantId ? "active" : ""}`}
                  >
                    {v.name || v.sku} · ₹{v.price}
                  </button>
                ))}
              </div>
            </div>
          ) : null}

          <div className="form-actions" style={{ marginTop: 24 }}>
            <button className="btn" style={{ minWidth: 200 }} disabled={busy || !variantId} onClick={addToCart}>
              {busy ? "Adding…" : "Add to cart"}
            </button>
            <button
              className="btn btn-dark"
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
