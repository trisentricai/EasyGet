import { useEffect, useMemo, useState } from "react";
import { useAuth } from "../context/AuthContext";
import { useCart } from "../context/CartContext";
import { useToast } from "../context/ToastContext";
import { href, navigate } from "../hooks/useHashRoute";
import {
  errText,
  getProduct,
  img,
  listProductsPaged,
  listReviews,
  postReview,
  type Product,
  type ProductDetail,
  type Review,
} from "../services/api";
import { EmptyState, Monogram, RatingPill, SignInGate, Spinner } from "../components/ui";
import { Icon } from "../components/icons";
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
  const [qty, setQty] = useState(1);
  const [pincode, setPincode] = useState("");
  const [pinResult, setPinResult] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    setProduct(null);
    setError(null);
    setQty(1);
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

  const addToCart = async (thenCheckout = false) => {
    if (!variantId) return;
    setBusy(true);
    try {
      await add(variantId, qty);
      if (thenCheckout) navigate("checkout");
      else toast.push("Added to cart");
    } catch (e) {
      toast.push(errText(e, "Could not add to cart"), "err");
    } finally {
      setBusy(false);
    }
  };

  const checkPincode = () => {
    const code = pincode.trim();
    if (!/^\d{6}$/.test(code)) {
      setPinResult("Enter a valid 6-digit pincode");
      return;
    }
    const eta = new Date();
    eta.setDate(eta.getDate() + 3);
    setPinResult(
      `Delivery by ${eta.toLocaleDateString("en-IN", { weekday: "short", day: "numeric", month: "short" })} · ${Number(price ?? 0) >= 499 ? "Free delivery" : "₹29 delivery"}`,
    );
  };

  const discount = activeVariant?.discount_percent || product.discount_percent;

  return (
    <div className="page">
      <div style={{ marginBottom: 14 }}>
        <span className="link" onClick={() => history.back()}>← Back</span>
        {"  "}
        {product.category ? (
          <a className="muted" style={{ fontSize: 13 }} href={href(`browse?category=${product.category.slug}`)}>
            › {product.category.name}
          </a>
        ) : null}
      </div>

      <div className="product-detail">
        {/* gallery */}
        <div className="pdp-gallery">
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

        {/* info column */}
        <div>
          <div className="buybox-brand">{product.brand || product.category?.name || "EasyGet"}</div>
          <h1 className="detail-title">{product.name}</h1>
          <div style={{ display: "flex", gap: 10, alignItems: "center", flexWrap: "wrap" }}>
            <RatingPill avg={product.rating_avg} count={product.rating_count} size="lg" />
            {product.rating_count ? (
              <span className="muted" style={{ fontSize: 13 }}>
                {product.rating_count} ratings
              </span>
            ) : (
              <span className="muted" style={{ fontSize: 13 }}>No ratings yet</span>
            )}
          </div>

          <div className="buybox-price" style={{ marginTop: 14 }}>
            <span className="now">₹{Number(price ?? 0).toLocaleString("en-IN")}</span>
            {product.mrp && Number(product.mrp) > Number(price ?? 0) ? (
              <span className="mrp">₹{Number(product.mrp).toLocaleString("en-IN")}</span>
            ) : null}
            {discount > 0 ? <span className="off">{discount}% off</span> : null}
          </div>

          {product.variants.length > 1 ? (
            <div style={{ marginTop: 18 }}>
              <h3 className="detail-option-label">Variants</h3>
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

          {product.description ? (
            <div className="buybox-section" style={{ marginTop: 20 }}>
              <h4>Description</h4>
              <p className="detail-desc" style={{ marginTop: 0 }}>{product.description}</p>
            </div>
          ) : null}

          <div className="buybox-section" style={{ marginTop: 18 }}>
            <h4>Highlights</h4>
            <ul className="pdp-highlights">
              <li>7-day easy returns if something isn't right</li>
              <li>Cash on delivery available</li>
              <li>Free delivery on orders above ₹499</li>
              <li>{product.brand ? `${product.brand} · ` : ""}Quality checked before dispatch</li>
            </ul>
          </div>
        </div>

        {/* buy box */}
        <aside className="buybox">
          <div className="buybox-section">
            <h4>Delivery</h4>
            <div className="pincode-row">
              <input
                inputMode="numeric"
                maxLength={6}
                placeholder="Enter pincode"
                value={pincode}
                onChange={(e) => {
                  setPincode(e.target.value.replace(/\D/g, ""));
                  setPinResult(null);
                }}
                onKeyDown={(e) => {
                  if (e.key === "Enter") checkPincode();
                }}
                aria-label="Delivery pincode"
              />
              <button className="link" onClick={checkPincode} type="button">Check</button>
            </div>
            {pinResult ? (
              <div className={`pincode-eta ${/valid/i.test(pinResult) ? "muted" : ""}`}>{pinResult}</div>
            ) : (
              <div className="pincode-eta muted" style={{ marginTop: 6 }}>
                Pay on delivery · Usually delivered in 3–5 days
              </div>
            )}
          </div>

          <div className="buybox-section">
            <h4>Quantity</h4>
            <div className="qty-stepper">
              <button onClick={() => setQty((q) => Math.max(1, q - 1))} aria-label="Decrease quantity">−</button>
              <span>{qty}</span>
              <button onClick={() => setQty((q) => Math.min(10, q + 1))} aria-label="Increase quantity">+</button>
            </div>
          </div>

          <div className="buybox-actions">
            <button className="btn-cart" disabled={busy || !variantId} onClick={() => void addToCart(false)}>
              <Icon name="cart" size={17} />
              {busy ? "Adding…" : "Add to cart"}
            </button>
            <button className="btn-buy" disabled={busy || !variantId} onClick={() => void addToCart(true)}>
              Buy now
            </button>
          </div>

          <div className="seller-box">
            <div style={{ display: "flex", justifyContent: "space-between", gap: 8 }}>
              <span className="muted">Sold by</span>
              <b>EasyGet Retail</b>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", gap: 8, marginTop: 6 }}>
              <span className="muted">Returns</span>
              <span style={{ color: "var(--savings)", fontWeight: 700 }}>7 days</span>
            </div>
            <div style={{ display: "flex", justifyContent: "space-between", gap: 8, marginTop: 6 }}>
              <span className="muted">Payment</span>
              <span style={{ fontWeight: 700 }}>COD / UPI</span>
            </div>
          </div>
        </aside>
      </div>

      <SimilarRail slug={slug} categorySlug={product.category?.slug ?? null} />
      <ReviewsSection slug={slug} canReview={!!user} />
    </div>
  );
}

function SimilarRail({ slug, categorySlug }: { slug: string; categorySlug: string | null }) {
  const [items, setItems] = useState<Product[] | null>(null);
  useEffect(() => {
    if (!categorySlug) return;
    let cancelled = false;
    listProductsPaged({ category: categorySlug, page_size: "12" })
      .then((d) => {
        if (!cancelled) setItems(d.results.filter((p) => p.slug !== slug).slice(0, 10));
      })
      .catch(() => {
        if (!cancelled) setItems([]);
      });
    return () => {
      cancelled = true;
    };
  }, [categorySlug, slug]);

  if (!categorySlug || !items || items.length === 0) return null;
  return (
    <section className="section">
      <div className="section-head">
        <h2>Similar products</h2>
        <a className="link" href={href(`browse?category=${categorySlug}`)}>See all</a>
      </div>
      <div className="rail">
        {items.map((p) => (
          <div className="rail-item" key={p.id}>
            <SimilarCard product={p} />
          </div>
        ))}
      </div>
    </section>
  );
}

function SimilarCard({ product }: { product: Product }) {
  const image = img(product.primary_image);
  return (
    <a className="product-card" href={href(`product/${product.slug}`)}>
      <div className="product-thumb">
        {image ? <img src={image} alt={product.name} loading="lazy" /> : <Monogram text={product.name} />}
      </div>
      <div className="product-body">
        <div className="product-brand">{product.brand || ""}</div>
        <div className="product-name" title={product.name}>{product.name}</div>
        <div className="product-rate-row">
          <RatingPill avg={product.rating_avg} count={product.rating_count} />
        </div>
        <div className="price price-sm">
          <span className="price-now">₹{Number(product.base_price ?? 0).toLocaleString("en-IN")}</span>
          {product.mrp && Number(product.mrp) > Number(product.base_price ?? 0) ? (
            <s className="price-mrp">₹{Number(product.mrp).toLocaleString("en-IN")}</s>
          ) : null}
          {product.discount_percent > 0 ? (
            <span className="price-off">{product.discount_percent}% off</span>
          ) : null}
        </div>
      </div>
    </a>
  );
}

function ReviewsSection({ slug, canReview }: { slug: string; canReview: boolean }) {
  const toast = useToast();
  const [reviews, setReviews] = useState<Review[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [rating, setRating] = useState(5);
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [posting, setPosting] = useState(false);

  const load = () => {
    listReviews(slug, 1)
      .then((d) => setReviews(d.results))
      .catch((e) => setError(errText(e, "Could not load reviews")));
  };

  useEffect(() => {
    setReviews(null);
    setError(null);
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [slug]);

  const submit = async () => {
    setPosting(true);
    try {
      await postReview(slug, { rating, title: title.trim(), body: body.trim() });
      toast.push("Thanks! Your review is live.");
      setTitle("");
      setBody("");
      setRating(5);
      load();
    } catch (e) {
      const status = (e as { status?: number }).status;
      toast.push(
        status === 409
          ? "You've already reviewed this product."
          : errText(e, "Could not post review"),
        "err",
      );
    } finally {
      setPosting(false);
    }
  };

  const dist = useMemo(() => {
    const counts = [0, 0, 0, 0, 0];
    for (const r of reviews ?? []) {
      if (r.rating >= 1 && r.rating <= 5) counts[5 - r.rating] += 1;
    }
    return counts;
  }, [reviews]);

  const avg =
    reviews && reviews.length
      ? reviews.reduce((s, r) => s + r.rating, 0) / reviews.length
      : 0;
  const maxDist = Math.max(1, ...dist);

  return (
    <section className="section reviews-wrap" id="reviews">
      <div className="section-head" style={{ marginBottom: 12 }}>
        <h2>Ratings &amp; Reviews</h2>
      </div>

      {error ? (
        <p className="muted">{error}</p>
      ) : !reviews ? (
        <Spinner />
      ) : (
        <>
          <div className="ratings-summary">
            <div className="ratings-big">
              <div className="num">{avg ? avg.toFixed(1) : "—"}</div>
              <div className="outof">{reviews.length} {reviews.length === 1 ? "review" : "reviews"}</div>
            </div>
            <div className="ratings-bars">
              {[5, 4, 3, 2, 1].map((star, i) => (
                <div className="ratings-bar" key={star}>
                  <span style={{ width: 12, fontWeight: 700 }}>{star}★</span>
                  <span className="track">
                    <span className="fill" style={{ width: `${(dist[i] / maxDist) * 100}%` }} />
                  </span>
                  <span style={{ width: 24, textAlign: "right" }}>{dist[i]}</span>
                </div>
              ))}
            </div>
          </div>

          {reviews.length === 0 ? (
            <p className="muted" style={{ padding: "18px 0" }}>
              No reviews yet — be the first to review this product.
            </p>
          ) : (
            <div style={{ marginTop: 6 }}>
              {reviews.map((r) => (
                <article className="review-card" key={r.id}>
                  <div className="review-head">
                    <span className="rating-pill">{r.rating}.0 ★</span>
                    <span className="review-who">{r.reviewer_name}</span>
                    {r.is_verified_purchase ? (
                      <span className="verified-badge">✓ Verified Purchase</span>
                    ) : null}
                    <span className="review-when">
                      {new Date(r.created_at).toLocaleDateString("en-IN", {
                        day: "numeric",
                        month: "short",
                        year: "numeric",
                      })}
                    </span>
                  </div>
                  {r.title ? <div className="review-title">{r.title}</div> : null}
                  {r.body ? <p className="review-body">{r.body}</p> : null}
                </article>
              ))}
            </div>
          )}
        </>
      )}

      {canReview && (
        <div className="review-form">
          <h3>Write a review</h3>
          <div className="star-picker" role="radiogroup" aria-label="Rating">
            {[1, 2, 3, 4, 5].map((n) => (
              <button
                key={n}
                type="button"
                className={n <= rating ? "on" : ""}
                aria-label={`${n} star${n > 1 ? "s" : ""}`}
                onClick={() => setRating(n)}
              >
                <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                  <path d="M12 2l2.9 6.6 7.1.7-5.4 4.8 1.6 7-6.2-3.7-6.2 3.7 1.6-7L2 9.3l7.1-.7z" />
                </svg>
              </button>
            ))}
          </div>
          <div className="field" style={{ marginBottom: 10 }}>
            <label htmlFor="rv-title">Title</label>
            <input
              id="rv-title"
              value={title}
              maxLength={150}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Sum it up in a line"
            />
          </div>
          <div className="field" style={{ marginBottom: 12 }}>
            <label htmlFor="rv-body">Review</label>
            <textarea
              id="rv-body"
              value={body}
              rows={3}
              onChange={(e) => setBody(e.target.value)}
              placeholder="What did you like or dislike?"
            />
          </div>
          <button className="btn" disabled={posting} onClick={() => void submit()}>
            {posting ? "Posting…" : "Post review"}
          </button>
        </div>
      )}
    </section>
  );
}
