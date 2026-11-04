import React from 'react';
import { Loader2 } from 'lucide-react';

interface StickyBottomCtaProps {
  label: string;
  price?: number;
  loading?: boolean;
  disabled?: boolean;
  onClick: () => void;
  helperText?: string;
}

export const StickyBottomCta: React.FC<StickyBottomCtaProps> = ({
  label,
  price,
  loading = false,
  disabled = false,
  onClick,
  helperText,
}) => {
  return (
    <div className="fixed bottom-0 left-0 right-0 z-30 max-w-[440px] mx-auto bg-[var(--surface)]/95 backdrop-blur-md border-t border-[var(--border)] p-3">
      {helperText && (
        <p className="text-[11px] text-center text-[var(--muted)] mb-2 font-medium">
          {helperText}
        </p>
      )}
      <button
        disabled={disabled || loading}
        onClick={onClick}
        className="w-full h-[54px] rounded-[16px] bg-[var(--primary)] hover:bg-[var(--primary-dark)] text-white font-bold text-base flex items-center justify-between px-5 transition-all active:scale-[0.98] disabled:opacity-40 disabled:cursor-not-allowed shadow-md cursor-pointer"
      >
        <span className="flex items-center gap-2">
          {loading ? (
            <Loader2 className="w-5 h-5 animate-spin" />
          ) : (
            <span>{label}</span>
          )}
        </span>
        {price !== undefined && !loading && (
          <span className="text-white font-extrabold tnum tracking-tight bg-white/20 px-3 py-1 rounded-full text-sm">
            ₹{price}
          </span>
        )}
      </button>
    </div>
  );
};
