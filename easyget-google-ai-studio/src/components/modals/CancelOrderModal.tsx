import React, { useState } from 'react';
import {
  X,
  AlertTriangle,
  RotateCcw,
  CheckCircle2,
  ShieldAlert,
} from 'lucide-react';
import { Order } from '../../types';

interface CancelOrderModalProps {
  isOpen: boolean;
  onClose: () => void;
  order: Order;
  onConfirmCancel: (reason: string) => void;
}

export const CancelOrderModal: React.FC<CancelOrderModalProps> = ({
  isOpen,
  onClose,
  order,
  onConfirmCancel,
}) => {
  const [selectedReason, setSelectedReason] = useState('Placed order by mistake');

  if (!isOpen) return null;

  const reasons = [
    'Placed order by mistake',
    'Delivery time is higher than expected',
    'Want to change delivery address or slot',
    'Forgot to add essential grocery items',
    'Found item available offline',
  ];

  return (
    <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex justify-end flex-col animate-fade-in">
      <div className="w-full max-w-[440px] mx-auto bg-[var(--surface)] rounded-t-[28px] border-t border-[var(--border)] overflow-hidden flex flex-col shadow-2xl">
        {/* Handle */}
        <div className="pt-2 pb-1 flex justify-center">
          <div className="w-12 h-1.5 rounded-full bg-[var(--border-strong)]" />
        </div>

        {/* Header */}
        <div className="px-5 py-3 border-b border-[var(--border)] flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-full bg-rose-100 text-[var(--danger)] flex items-center justify-center">
              <AlertTriangle className="w-4 h-4" />
            </div>
            <div>
              <h3 className="text-sm font-bold text-[var(--ink)]">Cancel Order #{order.id}</h3>
              <p className="text-[11px] text-[var(--muted)]">100% instant refund eligible</p>
            </div>
          </div>
          <button onClick={onClose} className="w-8 h-8 rounded-full flex items-center justify-center text-[var(--muted)] hover:bg-[var(--sunken)]">
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Content */}
        <div className="p-4 space-y-4">
          {/* Refund breakdown card */}
          <div className="p-3.5 rounded-2xl bg-[var(--sunken)]/60 border border-[var(--border)] space-y-2">
            <div className="flex items-center justify-between text-xs font-bold text-[var(--ink)]">
              <span>Refund Amount</span>
              <span className="text-base font-extrabold text-[var(--primary)] tnum">
                ₹{order.total}
              </span>
            </div>
            <div className="flex items-center gap-2 text-[11px] text-[var(--muted)]">
              <CheckCircle2 className="w-3.5 h-3.5 text-[var(--success)] shrink-0" />
              <span>Full ₹{order.total} will be credited back to your original source in 5 minutes.</span>
            </div>
          </div>

          {/* Cancellation Reasons */}
          <div>
            <label className="text-xs font-bold text-[var(--ink)] block mb-2">
              Reason for Cancellation
            </label>
            <div className="space-y-2">
              {reasons.map(r => {
                const isSelected = selectedReason === r;
                return (
                  <div
                    key={r}
                    onClick={() => setSelectedReason(r)}
                    className={`p-3 rounded-xl border flex items-center justify-between cursor-pointer text-xs transition-all ${
                      isSelected
                        ? 'border-[var(--danger)] bg-rose-50/50 text-rose-950 font-semibold'
                        : 'border-[var(--border)] bg-[var(--surface)] text-[var(--ink)] hover:bg-[var(--sunken)]'
                    }`}
                  >
                    <span>{r}</span>
                    <div
                      className={`w-4 h-4 rounded-full border-2 flex items-center justify-center ${
                        isSelected ? 'border-[var(--danger)]' : 'border-[var(--border-strong)]'
                      }`}
                    >
                      {isSelected && <div className="w-2 h-2 rounded-full bg-[var(--danger)]" />}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Buttons */}
          <div className="space-y-2 pt-2">
            <button
              onClick={() => {
                onConfirmCancel(selectedReason);
                onClose();
              }}
              className="w-full h-12 rounded-xl bg-[var(--danger)] text-white text-xs font-bold hover:bg-rose-700 transition-colors shadow-sm"
            >
              Confirm Cancellation & Refund
            </button>
            <button
              onClick={onClose}
              className="w-full h-11 rounded-xl bg-[var(--surface)] border border-[var(--border-strong)] text-[var(--ink)] text-xs font-bold hover:bg-[var(--sunken)]"
            >
              Don't Cancel (Keep Order)
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
