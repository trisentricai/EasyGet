import React from 'react';
import { Plus, Minus, Heart } from 'lucide-react';
import { Product } from '../../types';
import { useApp } from '../../context/AppContext';
import { PriceBlock } from './PriceBlock';
import { RatingPill } from './RatingPill';

interface ProductCardProps {
  product: Product;
  variant?: 'rail' | 'grid' | 'line';
  quantity?: number;
  onRemove?: () => void;
}

export const ProductCard: React.FC<ProductCardProps> = ({
  product,
  variant = 'grid',
  quantity = 0,
  onRemove,
}) => {
  const { cart, addToCart, navigate, toggleWishlist, isWishlisted } = useApp();

  const cartItem = cart.find(i => i.product.id === product.id);
  const currentQty = quantity > 0 ? quantity : cartItem ? cartItem.quantity : 0;
  const wishlisted = isWishlisted(product.id);

  const handleOpenPdp = () => {
    navigate('pdp', { slug: product.slug });
  };

  // Line Card variant (Cart and Order items)
  if (variant === 'line') {
    return (
      <div className="flex items-center gap-3 p-3 bg-[var(--surface)] border border-[var(--border)] rounded-2xl">
        <div
          onClick={handleOpenPdp}
          className="relative w-19 h-19 shrink-0 bg-[var(--sunken)] rounded-xl overflow-hidden cursor-pointer"
        >
          <img
            src={product.image}
            alt={product.name}
            className="w-full h-full object-cover"
            loading="lazy"
          />
          {product.isVeg && (
            <div className="absolute top-1 left-1 w-3.5 h-3.5 bg-white/90 border border-green-600 rounded-xs flex items-center justify-center">
              <div className="w-1.5 h-1.5 rounded-full bg-green-600" />
            </div>
          )}
        </div>

        <div className="flex-1 min-w-0">
          <div className="flex items-start justify-between gap-1">
            <h4
              onClick={handleOpenPdp}
              className="text-sm font-semibold text-[var(--ink)] line-clamp-1 cursor-pointer hover:underline"
            >
              {product.name}
            </h4>
          </div>
          <p className="text-[12px] text-[var(--muted)] line-clamp-1 mb-1">{product.weight}</p>
          <PriceBlock price={product.price} mrp={product.mrp} size="sm" />
        </div>

        {/* Stepper */}
        <div className="shrink-0 flex items-center bg-[var(--primary-tint)] rounded-xl p-0.5 border border-[var(--primary)]/20">
          <button
            onClick={() => {
              if (currentQty === 1 && onRemove) {
                onRemove();
              } else {
                addToCart(product, -1);
              }
            }}
            aria-label="Decrease quantity"
            className="w-8 h-8 flex items-center justify-center text-[var(--primary)] hover:bg-black/5 rounded-lg active:scale-95 transition-transform"
          >
            <Minus className="w-3.5 h-3.5 stroke-[2.5]" />
          </button>
          <span className="w-6 text-center text-xs font-bold text-[var(--brand)] tnum">
            {currentQty}
          </span>
          <button
            disabled={currentQty >= product.stockQty}
            onClick={() => addToCart(product, 1)}
            aria-label="Increase quantity"
            className="w-8 h-8 flex items-center justify-center text-[var(--primary)] hover:bg-black/5 rounded-lg active:scale-95 transition-transform disabled:opacity-40"
          >
            <Plus className="w-3.5 h-3.5 stroke-[2.5]" />
          </button>
        </div>
      </div>
    );
  }

  // Rail Card variant (148dp horizontal carousel on Home / Recommendations)
  if (variant === 'rail') {
    return (
      <div className="w-[148px] shrink-0 flex flex-col justify-between bg-[var(--surface)] border border-[var(--border)] rounded-[18px] p-2.5 transition-all">
        <div>
          {/* 1:1 Image Well */}
          <div className="relative w-full aspect-square bg-[var(--sunken)] rounded-[14px] overflow-hidden mb-2">
            <img
              src={product.image}
              alt={product.name}
              onClick={handleOpenPdp}
              className="w-full h-full object-cover cursor-pointer hover:scale-105 transition-transform duration-300"
              loading="lazy"
            />
            {/* Rating pill top-left */}
            <div className="absolute top-1.5 left-1.5">
              <RatingPill rating={product.rating} />
            </div>

            {/* Wishlist button */}
            <button
              onClick={e => {
                e.stopPropagation();
                toggleWishlist(product.id);
              }}
              aria-label="Wishlist"
              className="absolute top-1.5 right-1.5 w-7 h-7 rounded-full bg-[var(--surface)]/90 backdrop-blur-xs flex items-center justify-center text-[var(--ink)] shadow-xs"
            >
              <Heart
                className={`w-3.5 h-3.5 ${
                  wishlisted ? 'fill-[var(--danger)] text-[var(--danger)]' : 'text-[var(--muted)]'
                }`}
              />
            </button>
          </div>

          {/* Veg dot */}
          <div className="flex items-center gap-1.5 mb-1">
            {product.isVeg && (
              <div className="w-3 h-3 bg-white border border-green-600 rounded-[2px] flex items-center justify-center shrink-0">
                <div className="w-1.5 h-1.5 rounded-full bg-green-600" />
              </div>
            )}
            <span className="text-[11px] text-[var(--muted)] truncate">{product.weight}</span>
          </div>

          {/* Name */}
          <h3
            onClick={handleOpenPdp}
            className="text-[13px] font-semibold text-[var(--ink)] leading-snug line-clamp-2 h-9 cursor-pointer hover:text-[var(--primary)]"
          >
            {product.name}
          </h3>
        </div>

        {/* Footer: Price & Add Stepper */}
        <div className="mt-2 pt-2 border-t border-[var(--border)]/60">
          <div className="mb-2">
            <PriceBlock price={product.price} mrp={product.mrp} size="sm" stacked />
          </div>

          {/* Add Stepper Morph */}
          {currentQty === 0 ? (
            <button
              onClick={() => addToCart(product, 1)}
              className="w-full h-[36px] rounded-xl border border-[var(--primary)] text-[var(--primary)] font-semibold text-xs flex items-center justify-center gap-1 hover:bg-[var(--primary-tint)]/40 active:scale-95 transition-all"
            >
              <Plus className="w-3.5 h-3.5 stroke-[2.5]" />
              ADD
            </button>
          ) : (
            <div className="w-full h-[36px] flex items-center justify-between bg-[var(--primary-tint)] border border-[var(--primary)]/30 rounded-xl px-1">
              <button
                onClick={() => addToCart(product, -1)}
                className="w-7 h-7 flex items-center justify-center text-[var(--primary)] active:scale-90"
              >
                <Minus className="w-3 h-3 stroke-[2.5]" />
              </button>
              <span className="text-xs font-bold text-[var(--brand)] tnum">{currentQty}</span>
              <button
                disabled={currentQty >= product.stockQty}
                onClick={() => addToCart(product, 1)}
                className="w-7 h-7 flex items-center justify-center text-[var(--primary)] active:scale-90 disabled:opacity-40"
              >
                <Plus className="w-3 h-3 stroke-[2.5]" />
              </button>
            </div>
          )}
        </div>
      </div>
    );
  }

  // Grid Card variant (Browse & Search PLP 2-column)
  return (
    <div className="flex flex-col justify-between bg-[var(--surface)] border border-[var(--border)] rounded-[18px] p-3 transition-all hover:border-[var(--border-strong)]">
      <div>
        {/* 4:5 Image Well */}
        <div className="relative w-full aspect-[4/5] bg-[var(--sunken)] rounded-[14px] overflow-hidden mb-2.5">
          <img
            src={product.image}
            alt={product.name}
            onClick={handleOpenPdp}
            className="w-full h-full object-cover cursor-pointer hover:scale-105 transition-transform duration-300"
            loading="lazy"
          />

          {/* Top-left Rating */}
          <div className="absolute top-2 left-2">
            <RatingPill rating={product.rating} reviewCount={product.reviewCount} />
          </div>

          {/* Top-right Wishlist */}
          <button
            onClick={e => {
              e.stopPropagation();
              toggleWishlist(product.id);
            }}
            aria-label="Wishlist"
            className="absolute top-2 right-2 w-8 h-8 rounded-full bg-[var(--surface)]/90 backdrop-blur-xs flex items-center justify-center text-[var(--ink)] shadow-xs active:scale-90 transition-transform"
          >
            <Heart
              className={`w-4 h-4 ${
                wishlisted ? 'fill-[var(--danger)] text-[var(--danger)]' : 'text-[var(--muted)]'
              }`}
            />
          </button>
        </div>

        {/* Veg Dot + Weight */}
        <div className="flex items-center gap-1.5 mb-1">
          {product.isVeg && (
            <div className="w-3 h-3 bg-white border border-green-600 rounded-[2px] flex items-center justify-center shrink-0">
              <div className="w-1.5 h-1.5 rounded-full bg-green-600" />
            </div>
          )}
          <span className="text-xs text-[var(--muted)] truncate">{product.weight}</span>
        </div>

        {/* Product Name */}
        <h3
          onClick={handleOpenPdp}
          className="text-sm font-semibold text-[var(--ink)] leading-snug line-clamp-2 h-10 cursor-pointer hover:text-[var(--primary)]"
        >
          {product.name}
        </h3>
      </div>

      {/* Bottom Block */}
      <div className="mt-2.5 pt-2 border-t border-[var(--border)]/60">
        <div className="mb-2.5">
          <PriceBlock
            price={product.price}
            mrp={product.mrp}
            savingsText={product.savingsText}
            size="md"
            stacked
          />
        </div>

        {/* Stepper Morph */}
        {currentQty === 0 ? (
          <button
            onClick={() => addToCart(product, 1)}
            className="w-full h-[40px] rounded-[14px] border border-[var(--primary)] text-[var(--primary)] font-bold text-xs tracking-wider flex items-center justify-center gap-1.5 hover:bg-[var(--primary-tint)]/40 active:scale-95 transition-all shadow-2xs"
          >
            <Plus className="w-4 h-4 stroke-[2.5]" />
            ADD
          </button>
        ) : (
          <div className="w-full h-[40px] flex items-center justify-between bg-[var(--primary-tint)] border border-[var(--primary)]/30 rounded-[14px] px-2 shadow-2xs">
            <button
              onClick={() => addToCart(product, -1)}
              className="w-8 h-8 flex items-center justify-center text-[var(--primary)] hover:bg-black/5 rounded-lg active:scale-90"
              aria-label="Decrease"
            >
              <Minus className="w-3.5 h-3.5 stroke-[2.5]" />
            </button>
            <span className="text-xs font-bold text-[var(--brand)] tnum">{currentQty}</span>
            <button
              disabled={currentQty >= product.stockQty}
              onClick={() => addToCart(product, 1)}
              className="w-8 h-8 flex items-center justify-center text-[var(--primary)] hover:bg-black/5 rounded-lg active:scale-90 disabled:opacity-40"
              aria-label="Increase"
            >
              <Plus className="w-3.5 h-3.5 stroke-[2.5]" />
            </button>
          </div>
        )}
      </div>
    </div>
  );
};
