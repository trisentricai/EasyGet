import { useEffect, useMemo, useRef, useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useAuth } from "../context/AuthContext";
import { useCart } from "../context/CartContext";
import { useToast } from "../context/ToastContext";
import { href, navigate } from "../hooks/useHashRoute";
import { rememberPincode } from "../hooks/useDeliveryConfig";
import {
  errText,
  getProduct,
  resolveImageUrl,
  listProductsPaged,
  listReviews,
  postReview,
  ApiError,
  offerLine,
  type ImageDisplay,
} from "../services/api";
import { EmptyState, Monogram, ProductCard, RatingPill, Spinner, WishButton } from "../components/ui";
import { Icon } from "../components/icons";
import { SafeImage } from "../components/safe-image";
import { SuccessCheck } from "../components/animations";
import { trackEvent } from "../utils/analytics";
import { recordView } from "../utils/history";
import { fxClass, fxStyle } from "../utils/imageFx";
import { checkPincode as lookupPincode } from "../utils/pincode";

export function ProductPage({ slug }: { slug: string }) {
  const { user } = useAuth();
  const { add } = useCart();
  const toast = useToast();
  const { data: product, error } = useQuery({
    queryKey: ["product", slug],
    queryFn: () => getProduct(slug),
  });
  const [variantId, setVariantId] = useState<number | null>(null);
  const [activeImage, setActiveImage] = useState<string | null>(null);
  const [activeFx, setActiveFx] = useState<ImageDisplay | null>(null);
  const [busy, setBusy] = useState(false);
  const [justAdded, setJustAdded] = useState(false);
  const addedTimer = useRef<number | null>(null);
  const [qty, setQty] = useState(1);
  const [pincode, setPincode] = useState("");
  const [pinResult, setPinResult] = useState<string | null>(null);
  const [pinBusy, setPinBusy] = useState(false);
  const [copiedCode, setCopiedCode] = useState<string | null>(null);
  const copyTimer = useRef<number | null>(null);
  // StrictMode double-runs mount effects in development; one view per product.
  const viewedSlug = useRef<string | null>(null);
  const errorMsg = error ? errText(error, "Product not found") : null;

  useEffect(() => {
    setQty(1);
  }, [slug]);

  // Clear the "Added" confirmation and coupon-copy timers if the shopper
  // navigates away.
  useEffect(
    () => () => {
      if (addedTimer.current) window.clearTimeout(addedTimer.current);
      if (copyTimer.current) window.clearTimeout(copyTimer.current);
    },
    [],
  );

  useEffect(() => {
    if (!product) return;
    const firstActive =
      product.variants.find(
        (v) => v.is_active && v.in_stock !== false && v.stock_quantity !== 0,
      ) ??
      product.variants.find((v) => v.is_active) ??
      product.variants[0];
    setVariantId(firstActive?.id ?? null);
    setActiveImage(resolveImageUrl(product.primary_image));
    setActiveFx(product.primary_image_display ?? null);
    recordView(product);
    if (viewedSlug.current !== product.slug) {
      viewedSlug.current = product.slug;
      trackEvent("view_item", {
        item_id: product.id,
        item_name: product.name,
        price: Number(product.base_price ?? 0),
        currency: "INR",
      });
    }
  }, [product]);

  // Cap the stepper at the selected variant's stock (or the site max when
  // stock is unmanaged). Switching variants clamps an already-high quantity.
  const stockQuantity =
    product?.variants.find((v) => v.id === variantId)?.stock_quantity ?? null;
  const stockCap = Math.min(10, stockQuantity == null ? 10 : Math.max(0, stockQuantity));
  useEffect(() => {
    setQty((current) => Math.min(Math.max(1, current), Math.max(1, stockCap)));
  }, [variantId, stockCap]);

  if (errorMsg) {
    return (
      <div className="page">
        <EmptyState
          icon="search"
          title="Product not found"
          text={errorMsg}
          action={<a className="btn" href={href("home")}>Back to home</a>}
        />
      </div>
    );
  }
  if (!product) return <Spinner />;

  const activeVariant = product.variants.find((v) => v.id === variantId) ?? null;
  const price = activeVariant?.price ?? product.base_price;
  const variantOutOfStock =
    activeVariant?.in_stock === false || activeVariant?.stock_quantity === 0;
  const outOfStock = product.in_stock === false || variantOutOfStock;
  const maxQty =
    activeVariant?.stock_quantity == null
      ? 10
      : Math.min(10, Math.max(0, activeVariant.stock_quantity));
  const images = product.images.length
    ? product.images
    : product.primary_image
      ? [
          {
            id: 0,
            image: product.primary_image,
            caption: "",
            is_primary: true,
            sort_order: 0,
            ...(product.primary_image_display ?? {}),
          },
        ]
      : [];

  const addToCart = async (thenCheckout = false) => {
    if (!variantId) return;
    if (outOfStock) {
      toast.push("Out of stock", "err");
      return;
    }
    setBusy(true);
    try {
      // Guests get a localStorage cart; signing in later merges it into the
      // server cart. The snapshot keeps the local line readable until then.
      await add(variantId, qty, {
        name: product.name,
        sku: activeVariant?.sku ?? "",
        price: activeVariant?.price ?? product.base_price ?? "0",
        productName: product.name,
        productSlug: product.slug,
        image: resolveImageUrl(product.primary_image),
        tenantId: null,
        sellerName: "EASYGET",
        inStock: activeVariant?.in_stock ?? product.in_stock ?? null,
        stockQuantity: activeVariant?.stock_quantity ?? null,
      });
      trackEvent("add_to_cart", {
        item_id: product.id,
        item_name: product.name,
        variant_id: variantId,
        quantity: qty,
        value: Number(price ?? 0) * qty,
        currency: "INR",
      });
      if (thenCheckout) navigate("checkout");
      else {
        toast.push("Added to cart");
        setJustAdded(true);
        if (addedTimer.current) window.clearTimeout(addedTimer.current);
        addedTimer.current = window.setTimeout(() => setJustAdded(false), 1800);
      }
    } catch (e) {
      toast.push(errText(e, "Could not add to cart"), "err");
    } finally {
      setBusy(false);
    }
  };

  const checkPincode = async () => {
    const code = pincode.trim();
    if (!/^\d{6}$/.test(code)) {
      setPinResult("Enter a valid 6-digit pincode");
      return;
    }
    setPinBusy(true);
    setPinResult("Checking…");
    try {
      const res = await lookupPincode(code);
      if (!res.valid) {
        setPinResult(res.reason ?? "We do not deliver to this pincode yet.");
        return;
      }
      rememberPincode(code);
      const eta = new Date();
      eta.setDate(eta.getDate() + (res.eta_days ?? 4));
      const feeLimit = Number(res.free_delivery_over ?? 499);
      const fee = Number(res.delivery_fee ?? 29);
      const feeLabel =
        Number(price ?? 0) >= feeLimit
          ? "Free delivery"
          : `₹${fee.toLocaleString("en-IN")} delivery`;
      const where = res.city ? ` to ${res.city}` : "";
      setPinResult(
        `Delivery by ${eta.toLocaleDateString("en-IN", { weekday: "short", day: "numeric", month: "short" })}${where} · ${feeLabel}`,
      );
    } catch (e) {
      if (e instanceof ApiError && e.status === 404) {
        const reason = (e.payload as { reason?: string } | null)?.reason;
        setPinResult(reason ?? "We do not deliver to this pincode yet.");
      } else {
        setPinResult("Couldn't check this pincode — try again.");
      }
    } finally {
      setPinBusy(false);
    }
  };

  const copyCode = async (code: string) => {
    let copied = false;
    try {
      await navigator.clipboard.writeText(code);
      copied = true;
    } catch {
      /* Clipboard API can be blocked — fall back to a temporary textarea. */
    }
    if (!copied) {
      try {
        const field = document.createElement("textarea");
        field.value = code;
        field.setAttribute("readonly", "");
        field.style.position = "fixed";
        field.style.opacity = "0";
        document.body.appendChild(field);
        field.select();
        copied = document.execCommand("copy");
        document.body.removeChild(field);
      } catch {
        copied = false;
      }
    }
    if (!copied) {
      toast.push(`Could not copy — code: ${code}`, "err");
      return;
    }
    setCopiedCode(code);
    toast.push(`Coupon ${code} copied`);
    if (copyTimer.current) window.clearTimeout(copyTimer.current);
    copyTimer.current = window.setTimeout(() => setCopiedCode(null), 1800);
  };

  const discount = activeVariant?.discount_percent || product.discount_percent;

  return (
    <div className="page pdp-page">
      <nav className="pdp-breadcrumb" aria-label="Breadcrumb">
        <a className="pdp-crumb-link pdp-crumb-home" href={href("home")}>
          <Icon name="home" size={13} /> Home
        </a>
        {product.category ? (
          <>
            <span className="pdp-breadcrumb-sep" aria-hidden="true">›</span>
            <a className="pdp-breadcrumb-link" href={href(`browse?category=${product.category.slug}`)}>
              {product.category.name}
            </a>
          </>
        ) : null}
        <span className="pdp-breadcrumb-sep" aria-hidden="true">›</span>
        <span className="pdp-crumb-current" aria-current="page">{product.name}</span>
      </nav>

      <div className="product-detail">
        {/* gallery */}
        <div className="pdp-gallery">
          <div
            className={`pdp-stage ${fxClass(activeFx)}`}
            style={fxStyle(activeFx)}
          >
            <SafeImage
              className="pdp-stage-img"
              src={activeImage}
              alt={product.name}
              decoding="async"
              width={800}
              height={800}
              fallback={
                <div className="pdp-stage-fallback">
                  <div className="pdp-glass">
                    <Monogram text={product.name} />
                    <span className="pdp-glass-label">Image coming soon</span>
                  </div>
                </div>
              }
            />
          </div>
          {images.length > 1 ? (
            <div className="thumb-row">
              {images.map((im) => (
                <button
                  key={im.id}
                  onClick={() => {
                    setActiveImage(resolveImageUrl(im.image));
                    setActiveFx(im);
                  }}
                  aria-label={`Show image: ${im.caption || "product"}`}
                  className={`thumb-btn ${fxClass(im)} ${resolveImageUrl(im.image) === activeImage ? "active" : ""}`}
                  style={fxStyle(im)}
                >
                  <SafeImage
                    src={resolveImageUrl(im.image)}
                    alt={im.caption}
                    loading="lazy"
                    decoding="async"
                  />
                </button>
              ))}
            </div>
          ) : null}
        </div>

        {/* info column */}
        <div className="pdp-info">
          <div className="pdp-brand">{product.brand || product.category?.name || "EasyGet"}</div>
          <div className="pdp-title-row">
            <h1 className="detail-title">{product.name}</h1>
            <WishButton slug={product.slug} className="wish-pdp" />
          </div>
          <div className="pdp-rating-row">
            <RatingPill avg={product.rating_avg} count={product.rating_count} size="lg" />
            {product.rating_count ? (
              <span className="muted pdp-rating-count">
                {product.rating_count} ratings
              </span>
            ) : (
              <span className="muted pdp-rating-count">No ratings yet</span>
            )}
          </div>

          <div className="buybox-price pdp-price">
            <span className="now">₹{Number(price ?? 0).toLocaleString("en-IN")}</span>
            {product.mrp && Number(product.mrp) > Number(price ?? 0) ? (
              <span className="mrp">₹{Number(product.mrp).toLocaleString("en-IN")}</span>
            ) : null}
            {discount > 0 ? <span className="off">{discount}% off</span> : null}
          </div>

          {outOfStock ? (
            <div style={{ marginTop: 12 }}>
              <span className="chip chip-err">Out of stock</span>
              <p className="muted" style={{ fontSize: 13, marginTop: 8 }}>
                This item is not stocked right now — check back soon.
              </p>
            </div>
          ) : null}

          {product.offers?.length ? (
            <div className="buybox-section pdp-offer-section">
              <h4>Available offers</h4>
              <div className="pdp-offers">
                {product.offers.map((o) => {
                  const copied = copiedCode === o.code;
                  return (
                    <button
                      key={o.code}
                      type="button"
                      className={`offer-pill ${copied ? "is-copied" : ""}`.trim()}
                      onClick={() => void copyCode(o.code)}
                      aria-label={`Copy coupon code ${o.code}`}
                    >
                      <span className="offer-pill-ico" aria-hidden="true">
                        <Icon name={o.discount_type === "FREE_DELIVERY" ? "truck" : "tag"} size={15} />
                      </span>
                      <span className="offer-pill-copy">
                        <span className="offer-pill-title">{offerLine(o)}</span>
                        <span className="offer-pill-code">{copied ? "Copied!" : `CODE: ${o.code}`}</span>
                      </span>
                      <span className="offer-pill-action" aria-hidden="true">
                        <Icon name={copied ? "check" : "copy"} size={14} />
                      </span>
                    </button>
                  );
                })}
              </div>
            </div>
          ) : null}

          {product.variants.length > 1 ? (
            <div className="buybox-section pdp-variants">
              <h4>Variants</h4>
              <div className="pdp-variant-row">
                {product.variants.filter((v) => v.is_active).map((v) => {
                  const unavailable = v.in_stock === false || v.stock_quantity === 0;
                  return (
                    <button
                      key={v.id}
                      onClick={() => setVariantId(v.id)}
                      className={`variant-btn ${v.id === variantId ? "active" : ""} ${unavailable ? "is-oos" : ""}`.trim()}
                      title={unavailable ? "Out of stock" : undefined}
                    >
                      {v.name || v.sku} · ₹{v.price}
                      {unavailable ? " · Out of stock" : ""}
                    </button>
                  );
                })}
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
        <div className="pdp-aside">
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
                <button
                  className="link"
                  onClick={() => void checkPincode()}
                  type="button"
                  disabled={pinBusy}
                >
                  {pinBusy ? "Checking…" : "Check"}
                </button>
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
                <button
                  onClick={() => {
                    if (qty >= maxQty) {
                      toast.push(
                        activeVariant?.stock_quantity == null
                          ? "Maximum 10 per item"
                          : `Only ${maxQty} available`,
                        "info",
                      );
                      return;
                    }
                    setQty((q) => Math.min(maxQty || 1, q + 1));
                  }}
                  aria-label="Increase quantity"
                  disabled={outOfStock}
                  title={activeVariant?.stock_quantity != null ? `Only ${maxQty} available` : undefined}
                >
                  +
                </button>
              </div>
              {activeVariant?.stock_quantity != null &&
              activeVariant.stock_quantity > 0 &&
              activeVariant.stock_quantity <= 5 ? (
                <div className="field-hint">Only {activeVariant.stock_quantity} left</div>
              ) : null}
            </div>

            <div className="buybox-actions">
              <button
                className={`btn-cart ${justAdded ? "is-added" : ""}`.trim()}
                disabled={busy || !variantId || outOfStock}
                onClick={() => void addToCart(false)}
                aria-live="polite"
              >
                {justAdded ? <SuccessCheck size={22} /> : <Icon name="cart" size={20} />}
                {outOfStock ? "Out of stock" : busy ? "Adding…" : justAdded ? "Added" : "Add to cart"}
              </button>
              <button className="btn-buy" disabled={busy || !variantId || outOfStock} onClick={() => void addToCart(true)}>
                <Icon name="zap" size={20} />
                Buy now
              </button>
            </div>

            <div className="seller-box">
              <div style={{ display: "flex", justifyContent: "space-between", gap: 8 }}>
                <span className="muted">Sold by</span>
                <b>EASYGET</b>
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
      </div>

      {/* Mobile/tablet sticky purchase bar — desktop keeps the sticky buy box. */}
      <div className="pdp-stickybar" role="region" aria-label="Purchase actions">
        <div className="pdp-stickybar-price">
          <span className="now">₹{Number(price ?? 0).toLocaleString("en-IN")}</span>
          {product.mrp && Number(product.mrp) > Number(price ?? 0) ? (
            <s className="mrp">₹{Number(product.mrp).toLocaleString("en-IN")}</s>
          ) : null}
        </div>
        <div className="pdp-stickybar-actions">
          <button
            className={`btn-cart ${justAdded ? "is-added" : ""}`.trim()}
            disabled={busy || !variantId || outOfStock}
            onClick={() => void addToCart(false)}
            aria-live="polite"
          >
            {justAdded ? <SuccessCheck size={19} /> : <Icon name="cart" size={17} />}
            {outOfStock ? "Out of stock" : busy ? "Adding…" : justAdded ? "Added" : "Add to cart"}
          </button>
          <button className="btn-buy" disabled={busy || !variantId || outOfStock} onClick={() => void addToCart(true)}>
            <Icon name="zap" size={17} />
            Buy now
          </button>
        </div>
      </div>

      <SimilarRail slug={slug} categorySlug={product.category?.slug ?? null} />
      <ReviewsSection slug={slug} canReview={!!user} />
    </div>
  );
}

function SimilarRail({ slug, categorySlug }: { slug: string; categorySlug: string | null }) {
  const { data } = useQuery({
    queryKey: ["products", "related", slug, categorySlug],
    queryFn: () => listProductsPaged({ category: categorySlug!, page_size: "12" }),
    enabled: !!categorySlug,
  });
  const items = data ? data.results.filter((p) => p.slug !== slug).slice(0, 10) : null;

  if (!categorySlug || !items || items.length === 0) return null;
  return (
    <section className="section pdp-similar">
      <div className="section-head">
        <div>
          <h2>Similar products</h2>
          <p className="muted">More from this aisle, picked to go with your browse.</p>
        </div>
        <a className="link link-arrow" href={href(`browse?category=${categorySlug}`)}>
          See all <Icon name="arrowRight" size={14} />
        </a>
      </div>
      <div className="rail pdp-rail">
        {items.map((p) => (
          <div className="rail-item" key={p.id}>
            <ProductCard product={p} size="sm" />
          </div>
        ))}
      </div>
    </section>
  );
}

function ReviewsSection({ slug, canReview }: { slug: string; canReview: boolean }) {
  const toast = useToast();
  const queryClient = useQueryClient();
  const reviewsFormRef = useRef<HTMLDivElement | null>(null);
  const { data, error } = useQuery({
    queryKey: ["reviews", slug],
    queryFn: () => listReviews(slug, 1),
  });
  const reviews = data ? data.results : null;
  const errorMsg = error ? errText(error, "Could not load reviews") : null;
  const [rating, setRating] = useState(5);
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [posting, setPosting] = useState(false);

  const scrollToReview = () => {
    reviewsFormRef.current?.scrollIntoView({ behavior: "smooth", block: "start" });
  };

  const submit = async () => {
    setPosting(true);
    try {
      await postReview(slug, { rating, title: title.trim(), body: body.trim() });
      toast.push("Thanks! Your review is live.");
      setTitle("");
      setBody("");
      setRating(5);
      queryClient.invalidateQueries({ queryKey: ["reviews", slug] });
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

      {errorMsg ? (
        <p className="muted">{errorMsg}</p>
      ) : !reviews ? (
        <Spinner />
      ) : (
        <>
          {/* Two-column layout: rating score card left, reviews right */}
          <div className="reviews-grid">
            {/* Left: overall rating score card */}
            <div className="reviews-score-card">
              <div className="reviews-score">
                <span className="reviews-score-num">{avg ? avg.toFixed(1) : "—"}</span>
                <span className="reviews-score-max"> / 5</span>
              </div>
              <div className="reviews-score-stars">
                {[5, 4, 3, 2, 1].map((s) => (
                  <span key={s} className={`reviews-star ${avg >= s - 0.5 ? "on" : ""}`}>
                    <Icon name="starFilled" size={20} strokeWidth={0} />
                  </span>
                ))}
              </div>
              <div className="reviews-score-count">
                {reviews.length} {reviews.length === 1 ? "review" : "reviews"}
              </div>
              <div className="reviews-breakdown">
                {[5, 4, 3, 2, 1].map((star, i) => {
                  const pct = maxDist ? Math.round((dist[i] / maxDist) * 100) : 0;
                  return (
                    <div key={star} className="reviews-breakdown-row">
                      <span className="reviews-breakdown-label">{star}</span>
                      <div className="reviews-breakdown-track">
                        <span
                          className="reviews-breakdown-fill"
                          style={{ width: `${pct}%` }}
                        />
                      </div>
                      <span className="reviews-breakdown-count">{dist[i]}</span>
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Right: review list or add-review prompt */}
            <div className="reviews-list-wrap">
              {reviews.length === 0 ? (
                <div className="reviews-empty">
                  <span className="reviews-empty-ico"><Icon name="edit" size={26} /></span>
                  <h3 className="reviews-empty-title">No reviews yet</h3>
                  <p className="reviews-empty-text">Be the first to review this product.</p>
                  {canReview && (
                    <button className="btn btn-primary" onClick={scrollToReview}>
                      Write the first review
                    </button>
                  )}
                </div>
              ) : (
                <>
                  {reviews.map((r) => (
                    <article key={r.id} className="review-card">
                      <div className="review-head">
                        <div className="review-rating">{r.rating}.0</div>
                        <div className="review-meta">
                          <span className="review-who">{r.reviewer_name}</span>
                          {r.is_verified_purchase ? (
                            <span className="verified-badge">
                              <Icon name="shieldCheck" size={12} /> Verified Purchase
                            </span>
                          ) : null}
                          <span className="review-when">
                            {new Date(r.created_at).toLocaleDateString("en-IN", {
                              day: "numeric",
                              month: "short",
                              year: "numeric",
                            })}
                          </span>
                        </div>
                      </div>
                      {r.title ? <div className="review-title">{r.title}</div> : null}
                      {r.body ? <p className="review-body">{r.body}</p> : null}
                    </article>
                  ))}
                </>
              )}
            </div>
          </div>
        </>
      )}

      {canReview && (
        <div ref={reviewsFormRef} className="review-form">
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
                <Icon name="starFilled" size={24} strokeWidth={0} />
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
          <button className="btn btn-primary" disabled={posting} onClick={() => void submit()}>
            {posting ? "Posting…" : "Post review"}
          </button>
        </div>
      )}
    </section>
  );
}
