import React, { useState } from 'react';
import {
  User,
  MapPin,
  Heart,
  Ticket,
  CreditCard,
  Bell,
  Moon,
  Sun,
  HelpCircle,
  LogOut,
  ChevronRight,
  ShieldCheck,
  Smartphone,
  Sparkles,
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { Header } from '../components/common/Header';

export const AccountScreen: React.FC = () => {
  const {
    user,
    logout,
    navigate,
    wishlist,
    addresses,
    coupons,
    isDark,
    toggleDarkMode,
    setIsNotifSheetOpen,
    setIsGpsModalOpen,
  } = useApp();

  const [notificationsEnabled, setNotificationsEnabled] = useState(true);
  const [copiedReferral, setCopiedReferral] = useState(false);

  const handleCopyCode = () => {
    navigator.clipboard?.writeText('ANANYA100');
    setCopiedReferral(true);
    setTimeout(() => setCopiedReferral(false), 2500);
  };

  return (
    <div className="pb-24 bg-[var(--canvas)] min-h-screen">
      <Header showBack title="My Account" />

      {/* Profile Header */}
      <div className="p-5 bg-[var(--surface)] border-b border-[var(--border)]">
        <div className="flex items-center gap-3.5">
          <div className="w-14 h-14 rounded-2xl bg-[var(--brand)] text-[#FAF6EF] flex items-center justify-center font-display font-bold text-xl shadow-md shrink-0">
            {user?.name
              ? user.name
                  .split(' ')
                  .map(n => n[0])
                  .join('')
              : 'AS'}
          </div>
          <div className="flex-1 min-w-0">
            <h2 className="text-base font-bold text-[var(--ink)] truncate">
              {user?.name || 'Ananya Sharma'}
            </h2>
            <p className="text-xs text-[var(--muted)] truncate font-mono mt-0.5">
              {user?.phone || '+91 98450 12890'}
            </p>
            <span className="inline-block mt-1 px-2 py-0.5 rounded-full bg-[var(--primary-tint)] text-[var(--primary)] text-[10px] font-bold">
              🌿 Fresh Market Premium Member
            </span>
          </div>
        </div>
      </div>

      <div className="p-4 space-y-4">
        {/* Quick Shortcut Tiles */}
        <div className="grid grid-cols-3 gap-2.5">
          <button
            onClick={() => navigate('orders')}
            className="p-3 rounded-2xl bg-[var(--surface)] border border-[var(--border)] text-center hover:border-[var(--primary)] transition-all shadow-2xs"
          >
            <span className="text-xs font-bold text-[var(--ink)] block">Orders</span>
            <span className="text-[10px] text-[var(--muted)]">History & active</span>
          </button>
          <button
            onClick={() => navigate('addresses')}
            className="p-3 rounded-2xl bg-[var(--surface)] border border-[var(--border)] text-center hover:border-[var(--primary)] transition-all shadow-2xs"
          >
            <span className="text-xs font-bold text-[var(--ink)] block">Addresses</span>
            <span className="text-[10px] text-[var(--muted)]">{addresses.length} saved</span>
          </button>
          <button
            onClick={() => navigate('browse')}
            className="p-3 rounded-2xl bg-[var(--surface)] border border-[var(--border)] text-center hover:border-[var(--primary)] transition-all shadow-2xs"
          >
            <span className="text-xs font-bold text-[var(--ink)] block">Wishlist</span>
            <span className="text-[10px] text-[var(--muted)]">{wishlist.length} items</span>
          </button>
        </div>

        {/* Refer & Earn ₹100 Banner */}
        <div className="p-4 rounded-2xl bg-gradient-to-r from-emerald-950 to-[#0C3B2E] text-white shadow-sm flex items-center justify-between gap-3">
          <div>
            <span className="text-[10px] font-extrabold uppercase tracking-wider text-emerald-300">
              EASYGET REFERRAL
            </span>
            <h4 className="text-xs font-bold text-white mt-0.5">
              Invite friends, both get ₹100 grocery credit
            </h4>
            <div className="flex items-center gap-2 mt-2">
              <span className="px-2.5 py-1 rounded-lg bg-white/15 font-mono text-xs font-bold text-emerald-200">
                ANANYA100
              </span>
              <button
                onClick={handleCopyCode}
                className="text-[11px] font-bold text-emerald-300 hover:text-white underline"
              >
                {copiedReferral ? 'Copied! ✓' : 'Copy Code'}
              </button>
            </div>
          </div>
          <div className="w-12 h-12 rounded-2xl bg-white/10 flex items-center justify-center text-2xl shrink-0">
            🎁
          </div>
        </div>

        {/* Account Menu Section */}
        <div className="bg-[var(--surface)] border border-[var(--border)] rounded-2xl overflow-hidden divide-y divide-[var(--border)]/60">
          <div
            onClick={() => setIsGpsModalOpen(true)}
            className="p-3.5 flex items-center justify-between cursor-pointer hover:bg-[var(--sunken)] transition-colors"
          >
            <div className="flex items-center gap-3">
              <MapPin className="w-4 h-4 text-[var(--primary)]" />
              <div>
                <span className="text-xs font-semibold text-[var(--ink)] block">
                  Delivery Pin & GPS Map
                </span>
                <span className="text-[10px] text-[var(--muted)]">12-min store locator</span>
              </div>
            </div>
            <ChevronRight className="w-4 h-4 text-[var(--muted)]" />
          </div>

          <div
            onClick={() => navigate('addresses')}
            className="p-3.5 flex items-center justify-between cursor-pointer hover:bg-[var(--sunken)] transition-colors"
          >
            <div className="flex items-center gap-3">
              <MapPin className="w-4 h-4 text-[var(--primary)]" />
              <span className="text-xs font-semibold text-[var(--ink)]">Saved Addresses</span>
            </div>
            <div className="flex items-center gap-1.5 text-xs text-[var(--muted)]">
              <span>{addresses.length} locations</span>
              <ChevronRight className="w-4 h-4" />
            </div>
          </div>

          <div
            onClick={() => setIsNotifSheetOpen(true)}
            className="p-3.5 flex items-center justify-between cursor-pointer hover:bg-[var(--sunken)] transition-colors"
          >
            <div className="flex items-center gap-3">
              <Bell className="w-4 h-4 text-[var(--marigold)]" />
              <span className="text-xs font-semibold text-[var(--ink)]">Notifications & Alerts</span>
            </div>
            <ChevronRight className="w-4 h-4 text-[var(--muted)]" />
          </div>

          <div
            onClick={() => navigate('cart')}
            className="p-3.5 flex items-center justify-between cursor-pointer hover:bg-[var(--sunken)] transition-colors"
          >
            <div className="flex items-center gap-3">
              <Ticket className="w-4 h-4 text-[var(--primary)]" />
              <span className="text-xs font-semibold text-[var(--ink)]">Coupons & Wallet</span>
            </div>
            <div className="flex items-center gap-1.5 text-xs text-[var(--primary)] font-bold">
              <span>{coupons.length} Active</span>
              <ChevronRight className="w-4 h-4 text-[var(--muted)]" />
            </div>
          </div>
        </div>

        {/* Preferences Section */}
        <div className="bg-[var(--surface)] border border-[var(--border)] rounded-2xl overflow-hidden divide-y divide-[var(--border)]/60">
          <div className="p-3.5 flex items-center justify-between">
            <div className="flex items-center gap-3">
              {isDark ? (
                <Moon className="w-4 h-4 text-amber-300" />
              ) : (
                <Sun className="w-4 h-4 text-[var(--muted)]" />
              )}
              <div>
                <span className="text-xs font-semibold text-[var(--ink)] block">
                  Theme Appearance
                </span>
                <span className="text-[10px] text-[var(--muted)]">
                  {isDark ? 'Dark Mode (Warm Charcoal)' : 'Light Mode (Warm Paper Canvas)'}
                </span>
              </div>
            </div>
            <button
              onClick={toggleDarkMode}
              className={`w-11 h-6 rounded-full p-0.5 transition-colors ${
                isDark ? 'bg-[var(--primary)]' : 'bg-[var(--border-strong)]'
              }`}
            >
              <div
                className={`w-5 h-5 rounded-full bg-white transition-transform ${
                  isDark ? 'translate-x-5' : 'translate-x-0'
                }`}
              />
            </button>
          </div>

          <div className="p-3.5 flex items-center justify-between">
            <div className="flex items-center gap-3">
              <Bell className="w-4 h-4 text-[var(--muted)]" />
              <div>
                <span className="text-xs font-semibold text-[var(--ink)] block">
                  Doorstep Arrival Haptics
                </span>
                <span className="text-[10px] text-[var(--muted)]">
                  Notify when rider reaches within 3 mins
                </span>
              </div>
            </div>
            <button
              onClick={() => setNotificationsEnabled(!notificationsEnabled)}
              className={`w-11 h-6 rounded-full p-0.5 transition-colors ${
                notificationsEnabled ? 'bg-[var(--primary)]' : 'bg-[var(--border-strong)]'
              }`}
            >
              <div
                className={`w-5 h-5 rounded-full bg-white transition-transform ${
                  notificationsEnabled ? 'translate-x-5' : 'translate-x-0'
                }`}
              />
            </button>
          </div>
        </div>

        {/* Support & Logout */}
        <div className="bg-[var(--surface)] border border-[var(--border)] rounded-2xl overflow-hidden divide-y divide-[var(--border)]/60">
          <div
            onClick={() => alert('Support helpline: +91 80 4492 1000 (Available 24x7)')}
            className="p-3.5 flex items-center justify-between cursor-pointer hover:bg-[var(--sunken)] transition-colors"
          >
            <div className="flex items-center gap-3">
              <HelpCircle className="w-4 h-4 text-[var(--muted)]" />
              <span className="text-xs font-semibold text-[var(--ink)]">24x7 Customer Help & FAQ</span>
            </div>
            <ChevronRight className="w-4 h-4 text-[var(--muted)]" />
          </div>

          <div
            onClick={logout}
            className="p-3.5 flex items-center justify-between cursor-pointer hover:bg-rose-50/50 transition-colors"
          >
            <div className="flex items-center gap-3 text-[var(--danger)]">
              <LogOut className="w-4 h-4" />
              <span className="text-xs font-bold">Sign Out</span>
            </div>
            <span className="text-[10px] text-[var(--faint)]">v2.6.4</span>
          </div>
        </div>
      </div>
    </div>
  );
};
