import React, { useState } from 'react';
import {
  ReceiptText,
  Clock,
  CheckCircle2,
  XCircle,
  ChevronRight,
  RotateCcw,
  ShoppingBag,
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { Header } from '../components/common/Header';

export const OrdersScreen: React.FC = () => {
  const { orders, navigate } = useApp();
  const [activeTab, setActiveTab] = useState<'active' | 'past'>('active');

  const activeOrders = orders.filter(o => o.status === 'In Transit');
  const pastOrders = orders.filter(o => o.status !== 'In Transit');
  const displayOrders = activeTab === 'active' ? activeOrders : pastOrders;

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'In Transit':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-[var(--marigold-wash)] border border-[var(--marigold)]/30 text-[var(--ink)] text-[11px] font-bold">
            <Clock className="w-3 h-3 text-[var(--marigold)] animate-spin" />
            11-14 mins ETA
          </span>
        );
      case 'Delivered':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-green-50 border border-green-200 text-[var(--success)] text-[11px] font-bold">
            <CheckCircle2 className="w-3 h-3" />
            Delivered
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full bg-neutral-100 border border-neutral-200 text-[var(--muted)] text-[11px] font-bold">
            <XCircle className="w-3 h-3" />
            Cancelled
          </span>
        );
    }
  };

  return (
    <div className="pb-24 bg-[var(--canvas)] min-h-screen">
      <Header title="Your Orders" />

      {/* Segmented Tabs (Active / Past per §12 S10) */}
      <div className="p-3 bg-[var(--surface)] border-b border-[var(--border)]">
        <div className="p-1 rounded-xl bg-[var(--sunken)] flex gap-1">
          <button
            onClick={() => setActiveTab('active')}
            className={`flex-1 py-2 rounded-lg text-xs font-bold transition-all ${
              activeTab === 'active'
                ? 'bg-[var(--surface)] text-[var(--ink)] shadow-2xs'
                : 'text-[var(--muted)] hover:text-[var(--ink)]'
            }`}
          >
            Active Orders ({activeOrders.length})
          </button>
          <button
            onClick={() => setActiveTab('past')}
            className={`flex-1 py-2 rounded-lg text-xs font-bold transition-all ${
              activeTab === 'past'
                ? 'bg-[var(--surface)] text-[var(--ink)] shadow-2xs'
                : 'text-[var(--muted)] hover:text-[var(--ink)]'
            }`}
          >
            Past Orders ({pastOrders.length})
          </button>
        </div>
      </div>

      <div className="p-4 space-y-3">
        {displayOrders.length === 0 ? (
          <div className="py-16 text-center bg-[var(--surface)] border border-[var(--border)] rounded-2xl p-6">
            <ReceiptText className="w-10 h-10 mx-auto text-[var(--faint)] mb-3" />
            <h3 className="font-bold text-sm text-[var(--ink)]">
              No {activeTab} orders
            </h3>
            <p className="text-xs text-[var(--muted)] mt-1 mb-4">
              Your organic farm picks will appear here once ordered.
            </p>
            <button
              onClick={() => navigate('browse')}
              className="px-4 py-2 rounded-xl bg-[var(--primary)] text-white text-xs font-bold"
            >
              Browse Fresh Market
            </button>
          </div>
        ) : (
          displayOrders.map(order => (
            <div
              key={order.id}
              onClick={() => navigate('track', { orderId: order.id })}
              className="p-4 rounded-2xl bg-[var(--surface)] border border-[var(--border)] hover:border-[var(--border-strong)] transition-all cursor-pointer shadow-2xs active:scale-[0.99]"
            >
              {/* Order Header */}
              <div className="flex items-center justify-between pb-2.5 border-b border-[var(--border)]/60">
                <div>
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-bold text-[var(--ink)] font-mono">
                      #{order.id}
                    </span>
                    <span className="text-[11px] text-[var(--muted)]">{order.date}</span>
                  </div>
                  <p className="text-[11px] text-[var(--muted)] mt-0.5 truncate max-w-[200px]">
                    To: {order.address.label}
                  </p>
                </div>
                {getStatusBadge(order.status)}
              </div>

              {/* Items Preview Thumbs (up to 3 thumbs per §12 S10) */}
              <div className="py-3 flex items-center justify-between gap-3">
                <div className="flex items-center gap-2 overflow-hidden">
                  {order.items.slice(0, 3).map((item, idx) => (
                    <div
                      key={idx}
                      className="w-12 h-12 rounded-xl bg-[var(--sunken)] overflow-hidden shrink-0 border border-[var(--border)]"
                    >
                      <img
                        src={item.product.image}
                        alt={item.product.name}
                        className="w-full h-full object-cover"
                      />
                    </div>
                  ))}
                  {order.items.length > 3 && (
                    <div className="w-12 h-12 rounded-xl bg-[var(--sunken)] border border-[var(--border)] flex items-center justify-center text-[11px] font-bold text-[var(--muted)] tnum">
                      +{order.items.length - 3}
                    </div>
                  )}
                </div>

                <div className="text-right">
                  <span className="text-[10px] text-[var(--muted)] block">Total Paid</span>
                  <span className="text-sm font-bold text-[var(--ink)] tnum">
                    ₹{order.total}
                  </span>
                </div>
              </div>

              {/* Bottom Action Row */}
              <div className="pt-2.5 border-t border-[var(--border)]/60 flex items-center justify-between text-xs">
                <span className="font-semibold text-[var(--primary)] flex items-center gap-1">
                  {order.status === 'In Transit' ? 'Track Live Progress' : 'View Receipt & Tracking'}
                  <ChevronRight className="w-3.5 h-3.5" />
                </span>

                {order.status === 'Delivered' && (
                  <button
                    onClick={e => {
                      e.stopPropagation();
                      navigate('track', { orderId: order.id });
                    }}
                    className="text-[11px] font-bold text-[var(--primary)] hover:underline flex items-center gap-1"
                  >
                    <RotateCcw className="w-3 h-3" /> Reorder
                  </button>
                )}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};
