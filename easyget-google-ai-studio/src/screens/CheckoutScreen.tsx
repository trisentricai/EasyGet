import React, { useState } from 'react';
import {
  MapPin,
  Clock,
  CreditCard,
  CheckCircle,
  Plus,
  ShieldCheck,
  ChevronRight,
  Sparkles,
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { Header } from '../components/common/Header';
import { StickyBottomCta } from '../components/common/StickyBottomCta';

export const CheckoutScreen: React.FC = () => {
  const {
    cart,
    cartTotal,
    cartSubtotal,
    cartDiscount,
    deliveryFee,
    riderTip,
    setRiderTip,
    deliveryInstructions,
    toggleDeliveryInstruction,
    addresses,
    selectedAddress,
    setSelectedAddress,
    placeOrder,
    navigate,
  } = useApp();

  const [deliveryDay, setDeliveryDay] = useState<'today' | 'tomorrow'>('today');
  const [selectedSlot, setSelectedSlot] = useState('10-Minute Express (8:30 - 8:45 AM)');
  const [paymentMethod, setPaymentMethod] = useState<'upi' | 'card' | 'cod'>('upi');
  const [isPlacing, setIsPlacing] = useState(false);

  const todaySlots = [
    '10-Minute Express (8:30 - 8:45 AM)',
    'Morning Slot (9:00 - 10:30 AM)',
    'Midday Slot (12:00 - 1:30 PM)',
    'Evening Harvest (6:00 - 7:30 PM)',
  ];

  const tomorrowSlots = [
    'Dawn Delivery (6:30 - 8:00 AM)',
    'Morning Slot (8:30 - 10:00 AM)',
    'Afternoon Slot (2:00 - 3:30 PM)',
  ];

  const instructionOptions = [
    { id: 'leave_door', label: '🚪 Leave at door' },
    { id: 'no_bell', label: '🔕 Do not ring bell' },
    { id: 'avoid_call', label: '📵 Avoid calling' },
    { id: 'guard', label: '🛡️ Hand to security' },
    { id: 'pet_home', label: '🐾 Pet at home' },
  ];

  const handlePlaceOrder = () => {
    setIsPlacing(true);
    setTimeout(() => {
      const order = placeOrder(
        paymentMethod === 'upi'
          ? 'Google Pay (UPI)'
          : paymentMethod === 'card'
          ? 'Credit Card'
          : 'Cash on Delivery',
        `${deliveryDay === 'today' ? 'Today' : 'Tomorrow'} · ${selectedSlot}`,
        riderTip,
        deliveryInstructions
      );
      setIsPlacing(false);
      navigate('track', { orderId: order.id });
    }, 900);
  };

  return (
    <div className="pb-32 bg-[var(--canvas)] min-h-screen">
      <Header showBack title="Checkout" />

      {/* Steps Header (Numbered, calm Instacart pattern per §12 S9) */}
      <div className="px-4 py-2.5 bg-[var(--surface)] border-b border-[var(--border)] flex items-center justify-between text-xs font-semibold">
        <div className="flex items-center gap-1.5 text-[var(--primary)] font-bold">
          <span className="w-5 h-5 rounded-full bg-[var(--primary-tint)] flex items-center justify-center text-[11px]">
            1
          </span>
          <span>Address</span>
        </div>
        <div className="w-6 h-px bg-[var(--border-strong)]" />
        <div className="flex items-center gap-1.5 text-[var(--primary)] font-bold">
          <span className="w-5 h-5 rounded-full bg-[var(--primary-tint)] flex items-center justify-center text-[11px]">
            2
          </span>
          <span>Time Slot</span>
        </div>
        <div className="w-6 h-px bg-[var(--border-strong)]" />
        <div className="flex items-center gap-1.5 text-[var(--primary)] font-bold">
          <span className="w-5 h-5 rounded-full bg-[var(--primary-tint)] flex items-center justify-center text-[11px]">
            3
          </span>
          <span>Payment</span>
        </div>
      </div>

      <div className="p-4 space-y-4">
        {/* Step 1: Address Card */}
        <div className="p-4 bg-[var(--surface)] border border-[var(--border)] rounded-2xl">
          <div className="flex items-center justify-between mb-3">
            <span className="text-xs font-bold uppercase tracking-wider text-[var(--ink)] flex items-center gap-1.5">
              <MapPin className="w-4 h-4 text-[var(--primary)]" />
              Delivery Address
            </span>
            <button
              onClick={() => navigate('addresses')}
              className="text-xs font-bold text-[var(--primary)] hover:underline"
            >
              Change
            </button>
          </div>

          <div className="p-3 rounded-xl bg-[var(--sunken)]/60 border border-[var(--border)]">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-[var(--ink)]">
                {selectedAddress.label}
              </span>
              <span className="text-[10px] font-bold text-[var(--primary)] bg-[var(--primary-tint)] px-2 py-0.5 rounded-full">
                DEFAULT
              </span>
            </div>
            <p className="text-xs text-[var(--muted)] mt-1">
              {selectedAddress.street}, {selectedAddress.area}, {selectedAddress.city} - {selectedAddress.pincode}
            </p>
            <p className="text-[11px] text-[var(--faint)] mt-1 tnum">
              Contact: {selectedAddress.phone}
            </p>
          </div>
        </div>

        {/* Step 2: Slot Picker (Instacart pattern: Today / Tomorrow chips + time windows) */}
        <div className="p-4 bg-[var(--surface)] border border-[var(--border)] rounded-2xl">
          <span className="text-xs font-bold uppercase tracking-wider text-[var(--ink)] flex items-center gap-1.5 mb-3">
            <Clock className="w-4 h-4 text-[var(--marigold)]" />
            Select Delivery Window
          </span>

          {/* Today / Tomorrow Selector */}
          <div className="flex gap-2 mb-3">
            <button
              onClick={() => setDeliveryDay('today')}
              className={`flex-1 py-2 rounded-xl text-xs font-bold border transition-all ${
                deliveryDay === 'today'
                  ? 'bg-[var(--primary-tint)] border-[var(--primary)] text-[var(--primary)] shadow-2xs'
                  : 'bg-[var(--sunken)] border-[var(--border)] text-[var(--muted)]'
              }`}
            >
              Today (Instant / Slotted)
            </button>
            <button
              onClick={() => setDeliveryDay('tomorrow')}
              className={`flex-1 py-2 rounded-xl text-xs font-bold border transition-all ${
                deliveryDay === 'tomorrow'
                  ? 'bg-[var(--primary-tint)] border-[var(--primary)] text-[var(--primary)] shadow-2xs'
                  : 'bg-[var(--sunken)] border-[var(--border)] text-[var(--muted)]'
              }`}
            >
              Tomorrow Morning
            </button>
          </div>

          {/* Slots Radio List */}
          <div className="space-y-2">
            {(deliveryDay === 'today' ? todaySlots : tomorrowSlots).map(slot => {
              const isSelected = selectedSlot === slot;
              return (
                <div
                  key={slot}
                  onClick={() => setSelectedSlot(slot)}
                  className={`p-3 rounded-xl border flex items-center justify-between cursor-pointer transition-all ${
                    isSelected
                      ? 'border-[var(--primary)] bg-[var(--primary-tint)]/40 shadow-xs'
                      : 'border-[var(--border)] bg-[var(--surface)] hover:bg-[var(--sunken)]'
                  }`}
                >
                  <div className="flex items-center gap-2.5">
                    <div
                      className={`w-4 h-4 rounded-full border-2 flex items-center justify-center ${
                        isSelected ? 'border-[var(--primary)]' : 'border-[var(--border-strong)]'
                      }`}
                    >
                      {isSelected && (
                        <div className="w-2 h-2 rounded-full bg-[var(--primary)]" />
                      )}
                    </div>
                    <span className="text-xs font-semibold text-[var(--ink)]">{slot}</span>
                  </div>
                  {slot.includes('10-Minute') && (
                    <span className="text-[10px] font-bold text-[var(--marigold)] bg-[var(--marigold-wash)] px-2 py-0.5 rounded-full">
                      FASTEST
                    </span>
                  )}
                </div>
              );
            })}
          </div>
        </div>

        {/* Step 3: Payment Method */}
        <div className="p-4 bg-[var(--surface)] border border-[var(--border)] rounded-2xl">
          <span className="text-xs font-bold uppercase tracking-wider text-[var(--ink)] flex items-center gap-1.5 mb-3">
            <CreditCard className="w-4 h-4 text-[var(--brand)]" />
            Payment Options
          </span>

          <div className="space-y-2">
            {[
              {
                id: 'upi',
                title: 'UPI Instant (Google Pay, PhonePe, Paytm)',
                desc: 'Fastest contactless checkout',
                badge: 'RECOMMENDED',
              },
              {
                id: 'card',
                title: 'Credit / Debit Card',
                desc: 'Visa, Mastercard, RuPay',
              },
              {
                id: 'cod',
                title: 'Cash on Doorstep Handover',
                desc: 'Pay cash or UPI on delivery',
              },
            ].map(m => {
              const isSelected = paymentMethod === m.id;
              return (
                <div
                  key={m.id}
                  onClick={() => setPaymentMethod(m.id as any)}
                  className={`p-3 rounded-xl border flex items-center justify-between cursor-pointer transition-all ${
                    isSelected
                      ? 'border-[var(--primary)] bg-[var(--primary-tint)]/40 shadow-xs'
                      : 'border-[var(--border)] bg-[var(--surface)] hover:bg-[var(--sunken)]'
                  }`}
                >
                  <div className="flex items-center gap-2.5">
                    <div
                      className={`w-4 h-4 rounded-full border-2 flex items-center justify-center ${
                        isSelected ? 'border-[var(--primary)]' : 'border-[var(--border-strong)]'
                      }`}
                    >
                      {isSelected && (
                        <div className="w-2 h-2 rounded-full bg-[var(--primary)]" />
                      )}
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-bold text-[var(--ink)]">{m.title}</span>
                        {m.badge && (
                          <span className="text-[9px] font-bold text-[var(--primary)] bg-[var(--primary-tint)] px-1.5 py-0.2 rounded">
                            {m.badge}
                          </span>
                        )}
                      </div>
                      <p className="text-[11px] text-[var(--muted)]">{m.desc}</p>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Delivery Instructions Chips */}
        <div className="p-4 bg-[var(--surface)] border border-[var(--border)] rounded-2xl">
          <span className="text-xs font-bold uppercase tracking-wider text-[var(--ink)] block mb-2">
            Delivery Instructions
          </span>
          <div className="flex flex-wrap gap-2">
            {instructionOptions.map(opt => {
              const active = deliveryInstructions.includes(opt.id);
              return (
                <button
                  key={opt.id}
                  type="button"
                  onClick={() => toggleDeliveryInstruction(opt.id)}
                  className={`px-3 py-1.5 rounded-full text-xs font-medium border transition-all ${
                    active
                      ? 'bg-[var(--primary-tint)] border-[var(--primary)] text-[var(--primary)] font-bold'
                      : 'bg-[var(--sunken)] border-[var(--border)] text-[var(--muted)] hover:text-[var(--ink)]'
                  }`}
                >
                  {opt.label}
                </button>
              );
            })}
          </div>
        </div>

        {/* Rider Tipping Selector */}
        <div className="p-4 bg-[var(--surface)] border border-[var(--border)] rounded-2xl">
          <div className="flex items-center justify-between mb-2">
            <div>
              <span className="text-xs font-bold uppercase tracking-wider text-[var(--ink)] block">
                Tip Delivery Partner
              </span>
              <p className="text-[11px] text-[var(--muted)]">
                100% goes directly to electric rider Ravi Kumar
              </p>
            </div>
            {riderTip > 0 && (
              <span className="text-xs font-bold text-[var(--primary)] font-mono tnum">
                +₹{riderTip}
              </span>
            )}
          </div>

          <div className="grid grid-cols-4 gap-2 pt-1">
            {[0, 20, 30, 50].map(tipAmount => {
              const isSelected = riderTip === tipAmount;
              return (
                <button
                  key={tipAmount}
                  type="button"
                  onClick={() => setRiderTip(tipAmount)}
                  className={`py-2 rounded-xl text-xs font-bold border transition-all ${
                    isSelected
                      ? 'bg-[var(--primary-tint)] border-[var(--primary)] text-[var(--primary)] shadow-2xs'
                      : 'bg-[var(--sunken)] border-[var(--border)] text-[var(--muted)] hover:text-[var(--ink)]'
                  }`}
                >
                  {tipAmount === 0 ? 'No tip' : `₹${tipAmount}`}
                </button>
              );
            })}
          </div>
        </div>

        {/* Server Bill Recap */}
        <div className="p-3.5 bg-[var(--sunken)]/60 border border-[var(--border)] rounded-2xl text-xs space-y-1.5">
          <div className="flex justify-between text-[var(--muted)]">
            <span>Items subtotal</span>
            <span className="tnum font-medium text-[var(--ink)]">₹{cartSubtotal}</span>
          </div>
          {cartDiscount > 0 && (
            <div className="flex justify-between text-[var(--success)] font-medium">
              <span>Savings</span>
              <span className="tnum">- ₹{cartDiscount}</span>
            </div>
          )}
          <div className="flex justify-between text-[var(--muted)]">
            <span>Delivery</span>
            <span className="tnum font-medium text-[var(--ink)]">
              {deliveryFee === 0 ? 'FREE' : `₹${deliveryFee}`}
            </span>
          </div>
          {riderTip > 0 && (
            <div className="flex justify-between text-[var(--ink)] font-medium">
              <span>Rider Tip (Ravi Kumar)</span>
              <span className="tnum font-bold text-[var(--primary)]">₹{riderTip}</span>
            </div>
          )}
          <div className="pt-1.5 border-t border-[var(--border)] flex justify-between font-bold text-sm text-[var(--ink)]">
            <span>Total Payable</span>
            <span className="text-base text-[var(--brand)] tnum font-extrabold">₹{cartTotal}</span>
          </div>
        </div>
      </div>

      {/* Sticky Bottom CTA (54dp, idempotent, Place Order) */}
      <StickyBottomCta
        label="Place order"
        price={cartTotal}
        loading={isPlacing}
        onClick={handlePlaceOrder}
        helperText={`Slot: ${selectedSlot.split('(')[0]}`}
      />
    </div>
  );
};
