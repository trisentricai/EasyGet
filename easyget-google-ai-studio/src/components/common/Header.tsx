import React from 'react';
import {
  ChevronDown,
  ArrowLeft,
  Clock,
  Bell,
  MapPin,
} from 'lucide-react';
import { useApp } from '../../context/AppContext';

interface HeaderProps {
  title?: string;
  showBack?: boolean;
  onBack?: () => void;
  showAddressRow?: boolean;
}

export const Header: React.FC<HeaderProps> = ({
  title,
  showBack = false,
  onBack,
  showAddressRow = false,
}) => {
  const {
    screen,
    goBack,
    navigate,
    selectedAddress,
    unreadNotifsCount,
    setIsNotifSheetOpen,
    setIsGpsModalOpen,
  } = useApp();

  const handleBack = () => {
    if (onBack) onBack();
    else goBack();
  };

  return (
    <header className="sticky top-0 z-30 bg-[var(--surface)] border-b border-[var(--border)] px-4 py-2.5 transition-colors">
      <div className="flex items-center justify-between gap-2">
        {/* Left side: Back button OR Logo / Location */}
        {showBack ? (
          <div className="flex items-center gap-3">
            <button
              onClick={handleBack}
              aria-label="Go back"
              className="w-10 h-10 -ml-1 rounded-full flex items-center justify-center text-[var(--ink)] hover:bg-[var(--sunken)] active:scale-95 transition-transform"
            >
              <ArrowLeft className="w-5 h-5 stroke-[2.2]" />
            </button>
            {title && (
              <h1 className="text-lg font-bold text-[var(--ink)] tracking-tight truncate max-w-[220px]">
                {title}
              </h1>
            )}
          </div>
        ) : showAddressRow ? (
          <div
            onClick={() => setIsGpsModalOpen(true)}
            className="flex items-center gap-2 cursor-pointer group flex-1 min-w-0"
          >
            <div className="w-8 h-8 rounded-full bg-[var(--primary-tint)] flex items-center justify-center text-[var(--primary)] shrink-0">
              <MapPin className="w-4 h-4" />
            </div>
            <div className="min-w-0">
              <div className="flex items-center gap-1">
                <span className="text-xs font-bold uppercase tracking-wider text-[var(--primary)]">
                  {selectedAddress.type}
                </span>
                <ChevronDown className="w-3.5 h-3.5 text-[var(--muted)] group-hover:translate-y-0.5 transition-transform" />
              </div>
              <p className="text-xs font-medium text-[var(--ink)] truncate max-w-[170px] sm:max-w-[240px]">
                {selectedAddress.area}, {selectedAddress.city}
              </p>
            </div>
          </div>
        ) : (
          <div className="flex items-center gap-2">
            <div
              onClick={() => navigate('home')}
              className="flex items-center gap-1.5 cursor-pointer"
            >
              <span className="w-7 h-7 rounded-lg bg-[var(--brand)] text-white font-bold flex items-center justify-center text-xs tracking-tighter">
                EG
              </span>
              <span className="font-display font-bold text-base tracking-tight text-[var(--brand)]">
                EASYGET
              </span>
            </div>
            {title && (
              <>
                <span className="text-[var(--faint)]">/</span>
                <h1 className="text-base font-bold text-[var(--ink)] truncate max-w-[170px]">
                  {title}
                </h1>
              </>
            )}
          </div>
        )}

        {/* Right side: ETA pill & Notifications */}
        <div className="flex items-center gap-2 shrink-0">
          {/* Fresh Market Marigold ETA Pill */}
          <div
            title="Estimated 10-minute doorstep delivery"
            className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full bg-[var(--marigold-wash)] border border-[var(--marigold)]/30 text-[var(--ink)] shadow-2xs"
          >
            <Clock className="w-3.5 h-3.5 text-[var(--marigold)] shrink-0 animate-pulse" />
            <span className="text-xs font-bold tnum text-[var(--ink)]">12 min</span>
          </div>

          {/* Notification Center Trigger */}
          <button
            onClick={() => setIsNotifSheetOpen(true)}
            aria-label="Notifications"
            className="relative w-9 h-9 rounded-full flex items-center justify-center text-[var(--ink)] hover:bg-[var(--sunken)] active:scale-95 transition-transform"
          >
            <Bell className="w-4.5 h-4.5" />
            {unreadNotifsCount > 0 && (
              <span className="absolute top-1 right-1 w-4 h-4 rounded-full bg-[var(--danger)] text-white text-[9px] font-bold flex items-center justify-center tnum ring-2 ring-[var(--surface)]">
                {unreadNotifsCount}
              </span>
            )}
          </button>
        </div>
      </div>
    </header>
  );
};
