import React, { useState } from 'react';
import {
  Heart,
  Share2,
  Clock,
  ShieldCheck,
  MapPin,
  ChevronRight,
  Plus,
  Minus,
  Star,
  CheckCircle2,
  Sparkles,
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { Header } from '../components/common/Header';
import { RatingPill } from '../components/common/RatingPill';
import { PriceBlock } from '../components/common/PriceBlock';
import { ProductCard } from '../components/common/ProductCard';
import { PRODUCTS } from '../data/mockData';

export const PdpScreen: React.FC = () => {
  const {
    selectedProductSlug,
    cart,
    addToCart,
    toggleWishlist,
    isWishlisted,
    navigate,
  } = useApp();

  const product =
    PRODUCTS.find(p => p.slug === selectedProductSlug) || PRODUCTS[0];

  const [activeImageIndex, setActiveImageIndex] = useState(0);
  const [pincode, setPincode] = useState('560102');
  const [pincodeChecked, setPincodeChecked] = useState(true);
  const [selectedVariant, setSelectedVariant] = useState(0);
  const [showReviews, setShowReviews] = useState(false);

  const cartItem = cart.find(i => i.product.id === product.id);
  const qty = cartItem ? cartItem.quantity : 0;
  const wishlisted = isWishlisted(product.id);

  const variants = [
    { label: product.weight, price: product.price, mrp: product.mrp },
    { label: 'Family Pack (2x)', price: Math.round(product.price * 1.85), mrp: Math.round(product.mrp * 2) },
  ];

  const currentPrice = variants[selectedVariant].price;
  const currentMrp = variants[selectedVariant].mrp;

  const related = PRODUCTS.filter(p => p.id !== product.id && p.category === product.category).slice(0, 4);

  return (
    <div className="pb-28 bg-[var(--canvas)] min-h-screen">
      <Header
        showBack
        title={product.name}
      />

      {/* 1:1 Image Gallery with dots */}
      <div className="relative bg-[var(--sunken)] border-b border-[var(--border)]">
        <div className="w-full aspect-square relative overflow-hidden">
          <img
            src={product.gallery[activeImageIndex] || product.image}
            alt={product.name}
            className="w-full h-full object-cover"
          />

          {/* Wishlist and Share floating buttons */}
          <div className="absolute top-3 right-3 flex flex-col gap-2">
            <button
              onClick={() => toggleWishlist(product.id)}
              aria-label="Wishlist"
              className="w-10 h-10 rounded-full bg-[var(--surface)]/90 backdrop-blur-xs flex items-center justify-center text-[var(--ink)] shadow-md active:scale-95 transition-transform"
            >
              <Heart
                className={`w-5 h-5 ${
                  wishlisted ? 'fill-[var(--danger)] text-[var(--danger)]' : 'text-[var(--muted)]'
                }`}
              />
            </button>
            <button
              onClick={() => {
                if (navigator.share) {
                  navigator.share({ title: product.name, text: product.description });
                }
              }}
              aria-label="Share"
              className="w-10 h-10 rounded-full bg-[var(--surface)]/90 backdrop-blur-xs flex items-center justify-center text-[var(--muted)] hover:text-[var(--ink)] shadow-md"
            >
              <Share2 className="w-4.5 h-4.5" />
            </button>
          </div>

          {/* Veg indicator badge */}
          {product.isVeg && (
            <div className="absolute top-3 left-3 bg-white/95 px-2 py-1 rounded-md border border-green-600 flex items-center gap-1.5 shadow-2xs">
              <div className="w-2.5 h-2.5 rounded-full bg-green-600" />
              <span className="text-[10px] font-bold text-green-700 tracking-wider">VEG</span>
            </div>
          )}
        </div>

        {/* Gallery Dots */}
        {product.gallery.length > 1 && (
          <div className="absolute bottom-3 left-0 right-0 flex justify-center gap-1.5">
            {product.gallery.map((_, i) => (
              <button
                key={i}
                onClick={() => setActiveImageIndex(i)}
                className={`h-2 rounded-full transition-all ${
                  activeImageIndex === i ? 'w-6 bg-[var(--primary)]' : 'w-2 bg-black/20'
                }`}
              />
            ))}
          </div>
        )}
      </div>

      {/* Main Details */}
      <div className="p-4 bg-[var(--surface)] border-b border-[var(--border)]">
        {/* Origin / Category subtitle */}
        <div className="flex items-center justify-between text-xs text-[var(--muted)] mb-1">
          <span className="font-semibold uppercase tracking-wider text-[var(--primary)]">
            {product.origin}
          </span>
          <span className="text-[11px] tnum">Shelf life: {product.shelfLife}</span>
        </div>

        {/* Product Title (Headline Inter 700 20sp) */}
        <h1 className="text-xl font-bold text-[var(--ink)] leading-snug mb-2">
          {product.name}
        </h1>

        {/* Rating and Weight row */}
        <div className="flex items-center gap-3 mb-3">
          <RatingPill
            rating={product.rating}
            reviewCount={product.reviewCount}
            size="md"
            onClick={() => setShowReviews(!showReviews)}
          />
          <span className="text-xs text-[var(--muted)] font-medium">·</span>
          <span className="text-xs text-[var(--ink)] font-semibold">{product.weight}</span>
        </div>

        {/* Price Block */}
        <div className="pt-2 border-t border-[var(--border)]/60">
          <PriceBlock
            price={currentPrice}
            mrp={currentMrp}
            savingsText={product.savingsText}
            size="lg"
          />
        </div>

        {/* Variant selector */}
        <div className="mt-4 pt-3 border-t border-[var(--border)]/60">
          <span className="text-xs font-bold text-[var(--ink)] block mb-2">
            Select Pack Option:
          </span>
          <div className="grid grid-cols-2 gap-2">
            {variants.map((v, i) => (
              <button
                key={i}
                onClick={() => setSelectedVariant(i)}
                className={`p-2.5 rounded-xl border text-left transition-all ${
                  selectedVariant === i
                    ? 'border-[var(--primary)] bg-[var(--primary-tint)]/40 shadow-xs'
                    : 'border-[var(--border)] bg-[var(--surface)] hover:bg-[var(--sunken)]'
                }`}
              >
                <div className="text-xs font-bold text-[var(--ink)] truncate">{v.label}</div>
                <div className="text-xs font-bold text-[var(--primary)] tnum mt-0.5">
                  ₹{v.price}{' '}
                  <span className="text-[10px] text-[var(--muted)] line-through">₹{v.mrp}</span>
                </div>
              </button>
            ))}
          </div>
        </div>

        {/* Quiet Delivery row with inline pincode check */}
        <div className="mt-4 p-3 rounded-2xl bg-[var(--sunken)]/70 border border-[var(--border)] flex items-center justify-between">
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-full bg-[var(--marigold-wash)] flex items-center justify-center text-[var(--marigold)]">
              <Clock className="w-4 h-4" />
            </div>
            <div>
              <div className="flex items-center gap-1.5">
                <span className="text-xs font-bold text-[var(--ink)]">12-Minute Delivery</span>
                <span className="text-[10px] font-bold text-[var(--primary)] bg-[var(--primary-tint)] px-1.5 py-0.2 rounded">
                  In Stock
                </span>
              </div>
              <p className="text-[11px] text-[var(--muted)]">Delivering to pincode {pincode}</p>
            </div>
          </div>

          <button
            onClick={() => {
              const code = prompt('Enter 6-digit delivery pincode:', pincode);
              if (code) setPincode(code);
            }}
            className="text-xs font-bold text-[var(--primary)] hover:underline"
          >
            Change
          </button>
        </div>
      </div>

      {/* "The Story" Block per §12 & §4 */}
      <section className="p-4 mt-3 bg-[var(--surface)] border-y border-[var(--border)]">
        <span className="text-[10px] font-extrabold uppercase tracking-widest text-[var(--primary)]">
          FARM PROVENANCE
        </span>
        <h3 className="font-display font-medium text-lg text-[var(--ink)] mt-1 mb-2">
          The Origin Story
        </h3>
        <p className="text-xs text-[var(--muted)] leading-relaxed mb-3">
          {product.story}
        </p>
        <p className="text-xs text-[var(--muted)] leading-relaxed">
          {product.description}
        </p>

        {/* Nutrition values grid */}
        {product.nutrition && (
          <div className="mt-4 pt-3 border-t border-[var(--border)]/60">
            <span className="text-xs font-bold text-[var(--ink)] block mb-2">
              Key Nutritional Values
            </span>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
              {product.nutrition.map((item, idx) => (
                <div key={idx} className="p-2 rounded-xl bg-[var(--sunken)] text-center">
                  <span className="text-[10px] text-[var(--muted)] block truncate">{item.label}</span>
                  <span className="text-xs font-bold text-[var(--ink)] tnum mt-0.5 block">{item.value}</span>
                </div>
              ))}
            </div>
          </div>
        )}
      </section>

      {/* Customer Trust Badges */}
      <section className="px-4 py-3 bg-[var(--canvas)] flex items-center justify-around text-center border-b border-[var(--border)]">
        <div className="flex flex-col items-center">
          <ShieldCheck className="w-5 h-5 text-[var(--primary)] mb-1" />
          <span className="text-[10px] font-bold text-[var(--ink)]">100% Traceable</span>
          <span className="text-[9px] text-[var(--muted)]">Direct cooperative</span>
        </div>
        <div className="w-px h-8 bg-[var(--border)]" />
        <div className="flex flex-col items-center">
          <CheckCircle2 className="w-5 h-5 text-[var(--primary)] mb-1" />
          <span className="text-[10px] font-bold text-[var(--ink)]">Quality Checked</span>
          <span className="text-[9px] text-[var(--muted)]">4°C cold chain</span>
        </div>
        <div className="w-px h-8 bg-[var(--border)]" />
        <div className="flex flex-col items-center">
          <Sparkles className="w-5 h-5 text-[var(--marigold)] mb-1" />
          <span className="text-[10px] font-bold text-[var(--ink)]">Zero Preservatives</span>
          <span className="text-[9px] text-[var(--muted)]">Natural harvesting</span>
        </div>
      </section>

      {/* Related Products Rail */}
      {related.length > 0 && (
        <section className="mt-4 pt-2">
          <div className="px-4 mb-2 flex items-center justify-between">
            <h3 className="text-sm font-bold text-[var(--ink)]">Frequently Bought Together</h3>
            <button
              onClick={() => navigate('browse')}
              className="text-xs font-bold text-[var(--primary)] hover:underline"
            >
              See more
            </button>
          </div>
          <div className="flex gap-3 overflow-x-auto px-4 pb-2 no-scrollbar">
            {related.map(p => (
              <ProductCard key={p.id} product={p} variant="rail" />
            ))}
          </div>
        </section>
      )}

      {/* Sticky Bottom Bar (Thumb Zone Action per §11.1 & §12 S7) */}
      <div className="fixed bottom-0 left-0 right-0 z-30 max-w-[440px] mx-auto bg-[var(--surface)]/95 backdrop-blur-md border-t border-[var(--border)] p-3">
        <div className="flex items-center justify-between gap-3">
          {/* Price Preview */}
          <div className="shrink-0">
            <span className="text-[10px] uppercase font-bold text-[var(--muted)] block">
              Total Price
            </span>
            <PriceBlock price={currentPrice} mrp={currentMrp} size="lg" />
          </div>

          {/* Add / Stepper CTA */}
          <div className="flex-1 max-w-[200px]">
            {qty === 0 ? (
              <button
                onClick={() => addToCart(product, 1)}
                className="w-full h-[52px] rounded-[16px] bg-[var(--primary)] hover:bg-[var(--primary-dark)] text-white font-bold text-sm flex items-center justify-center gap-1.5 transition-all active:scale-95 shadow-md cursor-pointer"
              >
                <Plus className="w-4 h-4 stroke-[2.5]" />
                ADD TO BASKET
              </button>
            ) : (
              <div className="w-full h-[52px] flex items-center justify-between bg-[var(--primary-tint)] border border-[var(--primary)]/30 rounded-[16px] px-3 shadow-2xs">
                <button
                  onClick={() => addToCart(product, -1)}
                  className="w-9 h-9 flex items-center justify-center text-[var(--primary)] active:scale-90"
                  aria-label="Decrease"
                >
                  <Minus className="w-4 h-4 stroke-[2.5]" />
                </button>
                <span className="text-sm font-extrabold text-[var(--brand)] tnum">{qty}</span>
                <button
                  disabled={qty >= product.stockQty}
                  onClick={() => addToCart(product, 1)}
                  className="w-9 h-9 flex items-center justify-center text-[var(--primary)] active:scale-90 disabled:opacity-40"
                  aria-label="Increase"
                >
                  <Plus className="w-4 h-4 stroke-[2.5]" />
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
