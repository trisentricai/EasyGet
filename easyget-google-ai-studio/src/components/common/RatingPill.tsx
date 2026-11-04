import React from 'react';
import { Star } from 'lucide-react';

interface RatingPillProps {
  rating: number;
  reviewCount?: number;
  size?: 'sm' | 'md';
  onClick?: () => void;
}

export const RatingPill: React.FC<RatingPillProps> = ({
  rating,
  reviewCount,
  size = 'sm',
  onClick,
}) => {
  const isSm = size === 'sm';

  return (
    <div
      onClick={onClick}
      className={`inline-flex items-center gap-1 px-1.5 py-0.5 rounded-full bg-[var(--surface)]/90 backdrop-blur-xs border border-[var(--border)] shadow-xs ${
        onClick ? 'cursor-pointer hover:bg-[var(--sunken)]' : ''
      }`}
    >
      <Star className={`${isSm ? 'w-3 h-3' : 'w-3.5 h-3.5'} fill-[var(--marigold)] text-[var(--marigold)]`} />
      <span className={`${isSm ? 'text-[11px]' : 'text-xs'} font-bold text-[var(--ink)] tnum`}>
        {rating.toFixed(1)}
      </span>
      {reviewCount !== undefined && (
        <span className={`${isSm ? 'text-[10px]' : 'text-[11px]'} text-[var(--muted)] tnum`}>
          ({reviewCount})
        </span>
      )}
    </div>
  );
};
