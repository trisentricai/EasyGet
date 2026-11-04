import React, { useState, useEffect } from 'react';
import {
  Clock,
  Phone,
  MessageSquare,
  CheckCircle2,
  Circle,
  MapPin,
  ChevronRight,
  ShieldCheck,
  AlertTriangle,
  RotateCcw,
  Navigation,
  Star,
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { Header } from '../components/common/Header';
import { RiderChatModal } from '../components/modals/RiderChatModal';
import { CancelOrderModal } from '../components/modals/CancelOrderModal';
import { RateOrderModal } from '../components/modals/RateOrderModal';

export const TrackOrderScreen: React.FC = () => {
  const {
    selectedOrderId,
    orders,
    cancelOrder,
    reorderPastOrder,
    submitOrderReview,
    submitDriverRating,
    navigate,
  } = useApp();
  const order = orders.find(o => o.id === selectedOrderId) || orders[0];
  const [etaSeconds, setEtaSeconds] = useState(660); // 11 mins
  const [isChatOpen, setIsChatOpen] = useState(false);
  const [isCancelModalOpen, setIsCancelModalOpen] = useState(false);
  const [isRateModalOpen, setIsRateModalOpen] = useState(false);

  useEffect(() => {
    if (order.status !== 'In Transit') return;
    const interval = setInterval(() => {
      setEtaSeconds(prev => (prev > 0 ? prev - 1 : 0));
    }, 1000);
    return () => clearInterval(interval);
  }, [order.status]);

  const minutes = Math.floor(etaSeconds / 60);
  const seconds = etaSeconds % 60;

  return (
    <div className="pb-24 bg-[var(--canvas)] min-h-screen">
      <Header showBack title={`Order #${order.id}`} />

      {/* Status Hero (Brand Wash, Big Icon, ETA countdown per §12 S11) */}
      <div className="p-5 bg-[var(--brand)] text-white">
        <div className="flex items-center justify-between mb-3">
          <span className="text-xs uppercase tracking-widest font-bold text-emerald-300">
            {order.status === 'In Transit' ? '⚡ LIVE ORDER STATUS' : 'COMPLETED HARVEST'}
          </span>
          <span className="text-xs font-mono bg-white/10 px-2 py-0.5 rounded">
            #{order.id}
          </span>
        </div>

        {order.status === 'In Transit' ? (
          <div>
            <div className="flex items-baseline gap-2 mb-1">
              <h2 className="font-display font-bold text-3xl tnum text-[#FAF6EF]">
                {minutes}:{seconds < 10 ? `0${seconds}` : seconds}
              </h2>
              <span className="text-sm text-emerald-200 font-semibold">minutes away</span>
            </div>
            <p className="text-xs text-emerald-100/90 leading-snug">
              Ravi Kumar is riding your way with temperature-stabilized bag.
            </p>
          </div>
        ) : (
          <div>
            <h2 className="font-display font-semibold text-2xl text-[#FAF6EF] mb-1">
              {order.status === 'Delivered' ? 'Delivered Safely' : 'Order Cancelled'}
            </h2>
            <p className="text-xs text-emerald-200/90">
              {order.status === 'Delivered'
                ? 'Handed over at doorstep'
                : 'Refund credited to original payment source'}
            </p>
          </div>
        )}

        {/* Live Delivery Mini Route Graphic */}
        {order.status === 'In Transit' && (
          <div className="mt-4 p-3 rounded-xl bg-emerald-950/70 border border-emerald-800/70 flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-emerald-500/20 text-emerald-300 flex items-center justify-center shrink-0">
                <Navigation className="w-5 h-5 animate-pulse" />
              </div>
              <div>
                <span className="text-xs font-bold text-white block">
                  {order.driverName || 'Ravi Kumar'} · Electric Scooter
                </span>
                <span className="text-[11px] text-emerald-300/80">
                  Dark Store #4 ➔ {order.address.area}
                </span>
              </div>
            </div>
            <div className="flex gap-2">
              <a
                href={`tel:${order.driverPhone || '+919123456789'}`}
                className="w-9 h-9 rounded-full bg-white/20 hover:bg-white/30 flex items-center justify-center text-white"
              >
                <Phone className="w-4 h-4" />
              </a>
              <button
                onClick={() => setIsChatOpen(true)}
                className="w-9 h-9 rounded-full bg-white/20 hover:bg-white/30 flex items-center justify-center text-white relative"
              >
                <MessageSquare className="w-4 h-4" />
                <span className="absolute -top-1 -right-1 w-2.5 h-2.5 rounded-full bg-emerald-400 ring-2 ring-emerald-950 animate-pulse" />
              </button>
            </div>
          </div>
        )}
      </div>

      <div className="p-4 space-y-4">
        {/* Vertical Order Timeline (OrderEvent list per §12 S11) */}
        <div className="p-4 bg-[var(--surface)] border border-[var(--border)] rounded-2xl">
          <h3 className="text-xs font-bold uppercase tracking-wider text-[var(--ink)] mb-4">
            Live Delivery Milestones
          </h3>

          <div className="relative pl-6 space-y-6 before:absolute before:left-2.5 before:top-2 before:bottom-2 before:w-0.5 before:bg-[var(--border)]">
            {order.events.map((evt, idx) => (
              <div key={idx} className="relative">
                {/* Timeline Node */}
                <div
                  className={`absolute -left-6 top-0 w-5 h-5 rounded-full flex items-center justify-center border-2 ${
                    evt.completed
                      ? 'bg-[var(--primary)] border-[var(--primary)] text-white'
                      : evt.current
                      ? 'bg-white border-[var(--primary)] text-[var(--primary)] animate-pulse'
                      : 'bg-white border-[var(--border-strong)] text-[var(--faint)]'
                  }`}
                >
                  {evt.completed ? (
                    <CheckCircle2 className="w-3 h-3 stroke-[3]" />
                  ) : (
                    <div
                      className={`w-1.5 h-1.5 rounded-full ${
                        evt.current ? 'bg-[var(--primary)]' : 'bg-transparent'
                      }`}
                    />
                  )}
                </div>

                <div>
                  <div className="flex items-center justify-between">
                    <span
                      className={`text-xs font-bold ${
                        evt.current ? 'text-[var(--primary)]' : 'text-[var(--ink)]'
                      }`}
                    >
                      {evt.status}
                    </span>
                    <span className="text-[11px] text-[var(--muted)] font-mono tnum">
                      {evt.time}
                    </span>
                  </div>
                  <p className="text-[11px] text-[var(--muted)] mt-0.5">{evt.description}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Order Items List */}
        <div className="p-4 bg-[var(--surface)] border border-[var(--border)] rounded-2xl">
          <h3 className="text-xs font-bold uppercase tracking-wider text-[var(--ink)] mb-3">
            Items in this Delivery ({order.items.length})
          </h3>

          <div className="divide-y divide-[var(--border)]/60">
            {order.items.map((item, idx) => (
              <div key={idx} className="py-2.5 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-11 h-11 rounded-xl bg-[var(--sunken)] overflow-hidden shrink-0 border border-[var(--border)]">
                    <img
                      src={item.product.image}
                      alt={item.product.name}
                      className="w-full h-full object-cover"
                    />
                  </div>
                  <div>
                    <h4 className="text-xs font-bold text-[var(--ink)] line-clamp-1">
                      {item.product.name}
                    </h4>
                    <span className="text-[11px] text-[var(--muted)]">
                      {item.quantity} × ₹{item.product.price} ({item.product.weight})
                    </span>
                  </div>
                </div>
                <span className="text-xs font-bold text-[var(--ink)] tnum">
                  ₹{item.product.price * item.quantity}
                </span>
              </div>
            ))}
          </div>

          <div className="pt-3 mt-2 border-t border-[var(--border)]/60 flex items-center justify-between text-xs font-bold">
            <span className="text-[var(--muted)]">Paid via {order.paymentMethod}</span>
            <span className="text-sm font-extrabold text-[var(--brand)] tnum">
              Total ₹{order.total}
            </span>
          </div>
        </div>

        {/* Address Card */}
        <div className="p-4 bg-[var(--surface)] border border-[var(--border)] rounded-2xl">
          <div className="flex items-center gap-2 mb-2 text-xs font-bold text-[var(--ink)]">
            <MapPin className="w-4 h-4 text-[var(--primary)]" />
            <span>Delivering To</span>
          </div>
          <p className="text-xs font-bold text-[var(--ink)]">{order.address.label}</p>
          <p className="text-xs text-[var(--muted)] mt-0.5">
            {order.address.street}, {order.address.area}, {order.address.city}
          </p>
        </div>

        {/* Actions: Cancel if active / Reorder / Rate */}
        <div className="space-y-2 pt-2">
          {order.status === 'In Transit' ? (
            <button
              onClick={() => setIsCancelModalOpen(true)}
              className="w-full py-3 rounded-xl border border-[var(--danger)] text-[var(--danger)] text-xs font-bold hover:bg-rose-50 transition-colors"
            >
              Cancel Order
            </button>
          ) : (
            <div className="space-y-2">
              <button
                onClick={() => setIsRateModalOpen(true)}
                className="w-full py-3 rounded-xl border border-[var(--marigold)] bg-[var(--marigold-wash)]/40 text-[var(--ink)] text-xs font-bold hover:bg-[var(--marigold-wash)] transition-colors flex items-center justify-center gap-1.5 shadow-2xs"
              >
                <Star className="w-4 h-4 fill-[var(--marigold)] text-[var(--marigold)]" />
                {order.driverRating ? `Rated ${order.driverRating}★ · Update Review` : 'Rate Produce & Rider Ravi Kumar'}
              </button>
              <button
                onClick={() => reorderPastOrder(order.id)}
                className="w-full py-3.5 rounded-xl bg-[var(--primary)] text-white text-xs font-bold hover:bg-[var(--primary-dark)] transition-colors flex items-center justify-center gap-2 shadow-sm"
              >
                <RotateCcw className="w-4 h-4" /> Reorder Fresh Items
              </button>
            </div>
          )}

          <button
            onClick={() => alert('Support ticket raised. Live agent will assist you in 60 seconds.')}
            className="w-full py-2.5 text-xs font-semibold text-[var(--muted)] hover:text-[var(--ink)] text-center"
          >
            Need Help with this Order?
          </button>
        </div>
      </div>

      {/* Interactive Modals */}
      <RiderChatModal
        isOpen={isChatOpen}
        onClose={() => setIsChatOpen(false)}
        driverName={order.driverName}
        driverPhone={order.driverPhone}
        driverVehicle={order.driverVehicle}
      />

      <CancelOrderModal
        isOpen={isCancelModalOpen}
        onClose={() => setIsCancelModalOpen(false)}
        order={order}
        onConfirmCancel={reason => cancelOrder(order.id, reason)}
      />

      <RateOrderModal
        isOpen={isRateModalOpen}
        onClose={() => setIsRateModalOpen(false)}
        order={order}
        onSubmit={(review, driverRating) => {
          submitOrderReview(order.id, review);
          submitDriverRating(order.id, driverRating);
        }}
      />
    </div>
  );
};
