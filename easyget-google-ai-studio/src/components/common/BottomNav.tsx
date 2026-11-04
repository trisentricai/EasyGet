import React from 'react';
import {
  Home,
  Grid,
  Search,
  ShoppingBag,
  ReceiptText,
} from 'lucide-react';
import { ScreenType } from '../../types';
import { useApp } from '../../context/AppContext';

export const BottomNav: React.FC = () => {
  const { screen, navigate, cartCount } = useApp();

  const tabs: { id: ScreenType; label: string; icon: React.FC<{ className?: string }> }[] = [
    { id: 'home', label: 'Home', icon: Home },
    { id: 'browse', label: 'Browse', icon: Grid },
    { id: 'search', label: 'Search', icon: Search },
    { id: 'cart', label: 'Cart', icon: ShoppingBag },
    { id: 'orders', label: 'Orders', icon: ReceiptText },
  ];

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-30 max-w-[440px] mx-auto bg-[var(--surface)] border-t border-[var(--border)] px-2 py-1.5 backdrop-blur-md">
      <div className="flex items-center justify-around">
        {tabs.map(tab => {
          const isActive = screen === tab.id;
          const Icon = tab.icon;
          const isCart = tab.id === 'cart';

          return (
            <button
              key={tab.id}
              onClick={() => navigate(tab.id)}
              className={`relative flex flex-col items-center justify-center min-w-[56px] py-1 px-2 rounded-xl transition-all active:scale-95 ${
                isActive ? 'text-[var(--brand)] font-bold' : 'text-[var(--muted)] hover:text-[var(--ink)]'
              }`}
            >
              {/* Active Indicator Wash */}
              <div
                className={`relative px-3 py-1 rounded-full transition-colors flex items-center justify-center ${
                  isActive ? 'bg-[var(--primary-tint)]' : ''
                }`}
              >
                <Icon
                  className={`w-5 h-5 transition-transform ${
                    isActive ? 'stroke-[2.4] text-[var(--brand)] scale-105' : 'stroke-[1.8]'
                  }`}
                />

                {/* Cart Badge with tabular count */}
                {isCart && cartCount > 0 && (
                  <span className="absolute -top-1 -right-1 px-1 min-w-[17px] h-[17px] rounded-full bg-[var(--marigold)] text-[var(--ink)] text-[10px] font-extrabold flex items-center justify-center tnum border-2 border-[var(--surface)] shadow-xs">
                    {cartCount > 99 ? '99+' : cartCount}
                  </span>
                )}
              </div>

              {/* Label: 12sp 600 */}
              <span
                className={`text-[11px] leading-tight mt-0.5 tracking-tight ${
                  isActive ? 'font-bold text-[var(--brand)]' : 'font-medium'
                }`}
              >
                {tab.label}
              </span>
            </button>
          );
        })}
      </div>
    </nav>
  );
};
