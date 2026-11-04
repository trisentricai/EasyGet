import React from 'react';

interface PriceBlockProps {
  price: number;
  mrp?: number;
  savingsText?: string;
  size?: 'sm' | 'md' | 'lg';
  stacked?: boolean;
}

export const PriceBlock: React.FC<PriceBlockProps> = ({
  price,
  mrp,
  savingsText,
  size = 'md',
  stacked = false,
}) => {
  const priceSizes = {
    sm: 'text-sm font-bold',
    md: 'text-base font-bold',
    lg: 'text-xl font-bold',
  };

  const mrpSizes = {
    sm: 'text-[11px]',
    md: 'text-xs',
    lg: 'text-sm',
  };

  return (
    <div className={stacked ? 'flex flex-col gap-0.5' : 'flex items-baseline flex-wrap gap-x-1.5 gap-y-0.5'}>
      <div className="flex items-baseline gap-1.5">
        <span className={`${priceSizes[size]} text-[var(--ink)] tnum tracking-tight`}>
          ₹{price}
        </span>
        {mrp && mrp > price && (
          <span className={`${mrpSizes[size]} text-[var(--muted)] line-through tnum`}>
            ₹{mrp}
          </span>
        )}
      </div>
      {savingsText && (
        <span className="text-[11px] font-semibold text-[var(--success)] leading-none">
          {savingsText}
        </span>
      )}
    </div>
  );
};
