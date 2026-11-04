import React, { useState } from 'react';
import {
  Clock,
  Ticket,
  ChevronRight,
  ShieldCheck,
  Trash2,
  ArrowRight,
  ShoppingBag,
  Sparkles,
  X,
  Check,
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { Header } from '../components/common/Header';
import { ProductCard } from '../components/common/ProductCard';
import { StickyBottomCta } from '../components/common/StickyBottomCta';

export const CartScreen: React.FC = () => {
  const {
    cart,
    cartCount,
    cartSubtotal,
    cartDiscount,
    deliveryFee,
    riderTip,
    substitutionPreference,
    setSubstitutionPreference,
    cartTotal,
    removeFromCart,
    clearCart,
    coupons,
    appliedCoupon,
    applyCoupon,
    removeCoupon,
    navigate,
  } = useApp();

  const [isCouponSheetOpen, setIsCouponSheetOpen] = useState(false);
  const [customCoupon, setCustomCoupon] = useState('');
  const [couponError, setCouponError] = useState('');

  const freeDeliveryGap = Math.max(0, 300 - cartSubtotal);

  const handleApplyCoupon = (code: string) => {
    const res = applyCoupon(code);
    if (!res.success) {
      setCouponError(res.message);
    } else {
      setCouponError('');
      setIsCouponSheetOpen(false);
    }
  };

  if (cart.length === 0) {
    return (
      <div className="pb-24 bg-[var(--canvas)] min-h-screen">
        <Header title="Your Basket" />
        <div className="py-20 px-6 text-center max-w-sm mx-auto">
          <div className="w-20 h-20 rounded-full bg-[var(--sunken)] flex items-center justify-center mx-auto text-[var(--muted)] mb-4">
            <ShoppingBag className="w-10 h-10 stroke-[1.5]" />
          </div>
          <h2 className="font-display font-semibold text-2xl text-[var(--ink)]">
            Your basket is empty
          </h2>
          <p className="text-xs text-[var(--muted)] mt-2 mb-6 leading-relaxed">
            Fill your morning with tree-ripened avocados, fresh farm milk, and artisanal bakery staples.
          </p>
          <button
            onClick={() => navigate('browse')}
            className="w-full h-12 rounded-[16px] bg-[var(--primary)] text-white text-sm font-bold flex items-center justify-center gap-2 shadow-md active:scale-95"
          >
            Start Shopping Farm Picks
            <ArrowRight className="w-4 h-4" />
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="pb-32 bg-[var(--canvas)] min-h-screen">
      <Header title={`Your Basket (${cartCount})`} />

      {/* ETA Pill Header Row */}
      <div className="px-4 py-2.5 bg-[var(--marigold-wash)]/60 border-b border-[var(--border)] flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Clock className="w-4 h-4 text-[var(--marigold)] animate-pulse" />
          <span className="text-xs font-bold text-[var(--ink)]">
            Guaranteed 12-Minute Delivery
          </span>
        </div>
        <span className="text-[11px] font-bold text-[var(--primary)] bg-white px-2 py-0.5 rounded-full border border-[var(--border)]">
          Free over ₹300
        </span>
      </div>

      {/* Free Delivery Threshold Meter */}
      <div className="px-4 py-2 bg-[var(--sunken)]/40 border-b border-[var(--border)]">
        <div className="flex justify-between items-center text-[11px] mb-1 font-semibold text-[var(--ink)]">
          <span>
            {freeDeliveryGap > 0
              ? `Add ₹${freeDeliveryGap} more for FREE Delivery`
              : '🎉 You have unlocked FREE Express Delivery!'}
          </span>
          <span className="tnum font-bold text-[var(--primary)]">₹{cartSubtotal}/₹300</span>
        </div>
        <div className="w-full h-1.5 rounded-full bg-[var(--sunken)] overflow-hidden">
          <div
            className="h-full bg-[var(--primary)] transition-all duration-300 rounded-full"
            style={{ width: `${Math.min(100, (cartSubtotal / 300) * 100)}%` }}
          />
        </div>
      </div>

      <div className="p-4 space-y-4">
        {/* Cart Item Cards (Line Card Variant per §11.2) */}
        <div className="space-y-2.5">
          <div className="flex items-center justify-between text-xs font-bold text-[var(--muted)] px-1">
            <span>Review Items ({cart.length})</span>
            <button
              onClick={clearCart}
              className="text-[var(--danger)] hover:underline flex items-center gap-1"
            >
              <Trash2 className="w-3.5 h-3.5" /> Clear All
            </button>
          </div>

          {cart.map(item => (
            <ProductCard
              key={item.product.id}
              product={item.product}
              variant="line"
              quantity={item.quantity}
              onRemove={() => removeFromCart(item.product.id)}
            />
          ))}
        </div>

        {/* Coupon Row */}
        <div className="p-3.5 bg-[var(--surface)] border border-[var(--border)] rounded-2xl">
          {appliedCoupon ? (
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2.5">
                <div className="w-8 h-8 rounded-full bg-[var(--primary-tint)] flex items-center justify-center text-[var(--primary)]">
                  <Ticket className="w-4 h-4" />
                </div>
                <div>
                  <div className="flex items-center gap-1.5">
                    <span className="text-xs font-bold text-[var(--primary)] font-mono">
                      {appliedCoupon.code}
                    </span>
                    <span className="text-[10px] bg-green-100 text-green-800 font-bold px-1.5 py-0.2 rounded">
                      APPLIED
                    </span>
                  </div>
                  <p className="text-[11px] text-[var(--muted)]">
                    Saved ₹{appliedCoupon.discountAmount} on this order
                  </p>
                </div>
              </div>
              <button
                onClick={removeCoupon}
                className="text-xs font-bold text-[var(--danger)] hover:underline"
              >
                Remove
              </button>
            </div>
          ) : (
            <button
              onClick={() => setIsCouponSheetOpen(true)}
              className="w-full flex items-center justify-between text-left"
            >
              <div className="flex items-center gap-2.5">
                <div className="w-8 h-8 rounded-full bg-[var(--sunken)] flex items-center justify-center text-[var(--muted)]">
                  <Ticket className="w-4 h-4" />
                </div>
                <div>
                  <span className="text-xs font-bold text-[var(--ink)] block">
                    Apply Coupon or Voucher
                  </span>
                  <span className="text-[11px] text-[var(--muted)]">
                    Use FRESH20 for ₹50 off
                  </span>
                </div>
              </div>
              <ChevronRight className="w-4 h-4 text-[var(--muted)]" />
            </button>
          )}
        </div>

        {/* Out-of-Stock Substitution Preference */}
        <div className="p-3.5 bg-[var(--surface)] border border-[var(--border)] rounded-2xl">
          <span className="text-xs font-bold text-[var(--ink)] block mb-1">
            If any item is out of stock at dark store:
          </span>
          <div className="grid grid-cols-3 gap-1.5 pt-1">
            {[
              { id: 'call', label: '📞 Call me' },
              { id: 'best_match', label: '🔄 Best match' },
              { id: 'refund', label: '💵 Refund directly' },
            ].map(opt => {
              const isSelected = substitutionPreference === opt.id;
              return (
                <button
                  key={opt.id}
                  type="button"
                  onClick={() => setSubstitutionPreference(opt.id as any)}
                  className={`py-2 px-1 rounded-xl text-[11px] font-bold border transition-all text-center truncate ${
                    isSelected
                      ? 'bg-[var(--primary-tint)] border-[var(--primary)] text-[var(--primary)]'
                      : 'bg-[var(--sunken)] border-[var(--border)] text-[var(--muted)] hover:text-[var(--ink)]'
                  }`}
                >
                  {opt.label}
                </button>
              );
            })}
          </div>
        </div>

        {/* Bill Summary Block (Tabular Figures per §12 S8) */}
        <div className="p-4 bg-[var(--surface)] border border-[var(--border)] rounded-2xl space-y-2.5">
          <h3 className="text-xs font-bold text-[var(--ink)] uppercase tracking-wider mb-2">
            Bill Summary
          </h3>

          <div className="flex items-center justify-between text-xs text-[var(--muted)]">
            <span>Item Subtotal</span>
            <span className="text-[var(--ink)] font-semibold tnum">₹{cartSubtotal}</span>
          </div>

          {cartDiscount > 0 && (
            <div className="flex items-center justify-between text-xs text-[var(--success)] font-medium">
              <span>Coupon Discount ({appliedCoupon?.code})</span>
              <span className="font-bold tnum">- ₹{cartDiscount}</span>
            </div>
          )}

          <div className="flex items-center justify-between text-xs text-[var(--muted)]">
            <div className="flex items-center gap-1">
              <span>Delivery Fee</span>
              {deliveryFee === 0 && (
                <span className="text-[10px] text-[var(--success)] font-semibold bg-green-50 px-1 rounded">
                  Free
                </span>
              )}
            </div>
            <span className={`font-semibold tnum ${deliveryFee === 0 ? 'text-[var(--success)]' : 'text-[var(--ink)]'}`}>
              {deliveryFee === 0 ? '₹0' : `₹${deliveryFee}`}
            </span>
          </div>

          {riderTip > 0 && (
            <div className="flex items-center justify-between text-xs text-[var(--ink)] font-medium">
              <span>Rider Tip (Ravi Kumar)</span>
              <span className="font-bold tnum text-[var(--primary)]">+₹{riderTip}</span>
            </div>
          )}

          <div className="pt-2 border-t border-[var(--border)] flex items-center justify-between text-sm font-bold text-[var(--ink)]">
            <span>To Pay</span>
            <span className="text-base text-[var(--brand)] font-extrabold tnum">
              ₹{cartTotal}
            </span>
          </div>

          {cartDiscount > 0 && (
            <div className="p-2 rounded-xl bg-[var(--primary-tint)]/60 text-center">
              <span className="text-xs font-bold text-[var(--primary)]">
                🎉 You are saving ₹{cartDiscount} on this fresh market order!
              </span>
            </div>
          )}
        </div>

        {/* Trust Note */}
        <div className="flex items-center justify-center gap-2 text-[11px] text-[var(--muted)] text-center py-1">
          <ShieldCheck className="w-4 h-4 text-[var(--primary)]" />
          <span>Cold chain guaranteed · No questions asked returns</span>
        </div>
      </div>

      {/* Primary CTA (54dp, full-width, bottom-anchored above safe area per §11.1) */}
      <StickyBottomCta
        label="Proceed to checkout"
        price={cartTotal}
        onClick={() => navigate('checkout')}
        helperText="Doorstep delivery in ~12 mins"
      />

      {/* Coupon Bottom Sheet */}
      {isCouponSheetOpen && (
        <div className="fixed inset-0 z-50 bg-black/40 flex justify-end flex-col animate-fade-in">
          <div className="bg-[var(--surface)] rounded-t-[24px] p-5 max-w-[440px] w-full mx-auto border-t border-[var(--border)] shadow-2xl max-h-[80vh] flex flex-col">
            <div className="flex items-center justify-between pb-3 border-b border-[var(--border)]">
              <h3 className="font-bold text-base text-[var(--ink)]">Available Coupons</h3>
              <button onClick={() => setIsCouponSheetOpen(false)}>
                <X className="w-5 h-5 text-[var(--muted)]" />
              </button>
            </div>

            {/* Manual input */}
            <div className="pt-4 pb-2">
              <div className="flex gap-2">
                <input
                  type="text"
                  placeholder="Enter coupon code"
                  value={customCoupon}
                  onChange={e => setCustomCoupon(e.target.value.toUpperCase())}
                  className="flex-1 h-11 px-3 rounded-xl bg-[var(--sunken)] border border-[var(--border-strong)] text-xs font-mono font-bold uppercase focus:outline-none focus:border-[var(--primary)]"
                />
                <button
                  onClick={() => handleApplyCoupon(customCoupon)}
                  className="px-4 h-11 rounded-xl bg-[var(--primary)] text-white text-xs font-bold"
                >
                  Apply
                </button>
              </div>
              {couponError && (
                <p className="text-xs text-[var(--danger)] font-medium mt-1.5">{couponError}</p>
              )}
            </div>

            {/* Coupon Cards */}
            <div className="flex-1 overflow-y-auto space-y-2.5 py-3">
              {coupons.map(c => (
                <div
                  key={c.code}
                  className="p-3.5 rounded-2xl border border-[var(--border)] bg-[var(--canvas)] flex items-start justify-between gap-3"
                >
                  <div className="flex-1">
                    <div className="flex items-center gap-2 mb-1">
                      <span className="px-2 py-0.5 rounded-md bg-[var(--surface)] border border-[var(--border)] font-mono text-xs font-bold text-[var(--brand)]">
                        {c.code}
                      </span>
                      <span className="text-[11px] font-bold text-[var(--success)]">
                        Save ₹{c.discountAmount}
                      </span>
                    </div>
                    <h4 className="text-xs font-bold text-[var(--ink)]">{c.title}</h4>
                    <p className="text-[11px] text-[var(--muted)] mt-0.5">{c.description}</p>
                    <span className="text-[10px] text-[var(--faint)] block mt-1">{c.expiry}</span>
                  </div>
                  <button
                    onClick={() => handleApplyCoupon(c.code)}
                    className="px-3 py-1.5 rounded-xl bg-[var(--primary-tint)] border border-[var(--primary)]/30 text-[var(--primary)] text-xs font-bold hover:bg-[var(--primary)] hover:text-white transition-colors"
                  >
                    Apply
                  </button>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
