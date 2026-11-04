import React, { useState } from 'react';
import {
  Smartphone,
  Maximize2,
  Moon,
  Sun,
  Bell,
  WifiOff,
  ServerCrash,
  ChevronDown,
  Layers,
  Sparkles,
  RefreshCw,
  MapPin,
} from 'lucide-react';
import { ScreenType } from '../../types';
import { useApp } from '../../context/AppContext';

export const FigmaToolbar: React.FC = () => {
  const {
    screen,
    navigate,
    viewportMode,
    setViewportMode,
    isDark,
    toggleDarkMode,
    simulateIncomingNotification,
    isOffline,
    setIsOffline,
    isServerError,
    setIsServerError,
    triggerException,
    setIsGpsModalOpen,
  } = useApp();

  const [isMenuOpen, setIsMenuOpen] = useState(false);

  const screensList: { id: ScreenType; label: string; group: string }[] = [
    { id: 'splash', label: 'S1 · Splash Brand', group: 'Auth & Onboarding' },
    { id: 'login', label: 'S2 · Login', group: 'Auth & Onboarding' },
    { id: 'otp_verify', label: 'S2b · WhatsApp/SMS OTP', group: 'Auth & Onboarding' },
    { id: 'register', label: 'S3 · Register', group: 'Auth & Onboarding' },
    { id: 'home', label: 'S4 · Home Storefront', group: 'Main Shopping' },
    { id: 'browse', label: 'S5 · Browse Categories', group: 'Main Shopping' },
    { id: 'search', label: 'S6 · Search & Discovery', group: 'Main Shopping' },
    { id: 'pdp', label: 'S7 · Product Story (PDP)', group: 'Main Shopping' },
    { id: 'cart', label: 'S8 · Cart & Vouchers', group: 'Checkout Flow' },
    { id: 'checkout', label: 'S9 · Checkout & Slots', group: 'Checkout Flow' },
    { id: 'orders', label: 'S10 · Orders History', group: 'Orders & Tracking' },
    { id: 'track', label: 'S11 · Live Delivery Track', group: 'Orders & Tracking' },
    { id: 'account', label: 'S12 · Account & Preferences', group: 'Profile & Settings' },
    { id: 'addresses', label: 'S13 · Address Book', group: 'Profile & Settings' },
    { id: 'offline_error', label: '⚠️ Exception: Shaky 4G / Offline', group: 'Edge Cases & Errors' },
    { id: 'server_error', label: '⚠️ Exception: 500 Cold Backend', group: 'Edge Cases & Errors' },
    { id: 'not_found', label: '⚠️ Exception: 404 Not Found', group: 'Edge Cases & Errors' },
  ];

  return (
    <div className="w-full bg-[#1A1815] text-[#FAF8F5] border-b border-neutral-800 px-3 py-2 text-xs flex items-center justify-between z-50 sticky top-0 shadow-md select-none font-sans">
      {/* Left: Brand & Screen Jumper */}
      <div className="flex items-center gap-2">
        <div className="flex items-center gap-1.5 px-2 py-0.5 rounded bg-emerald-950 text-emerald-300 font-semibold tracking-wider text-[10px] uppercase border border-emerald-800/60">
          <Sparkles className="w-3 h-3 text-emerald-400" />
          Figma Live · Fresh Market
        </div>

        {/* Screen Picker Dropdown */}
        <div className="relative">
          <button
            onClick={() => setIsMenuOpen(prev => !prev)}
            className="flex items-center gap-1.5 bg-neutral-800/90 hover:bg-neutral-700 text-white px-2.5 py-1 rounded-md text-xs font-medium border border-neutral-700 transition-colors"
          >
            <Layers className="w-3.5 h-3.5 text-emerald-400" />
            <span className="font-semibold text-neutral-200">
              {screensList.find(s => s.id === screen)?.label || screen}
            </span>
            <ChevronDown className="w-3 h-3 text-neutral-400" />
          </button>

          {isMenuOpen && (
            <div
              className="absolute left-0 top-full mt-1.5 w-64 max-h-80 overflow-y-auto bg-neutral-900 border border-neutral-700 rounded-lg shadow-2xl z-50 p-1.5 text-xs divide-y divide-neutral-800"
              onClick={() => setIsMenuOpen(false)}
            >
              {['Auth & Onboarding', 'Main Shopping', 'Checkout Flow', 'Orders & Tracking', 'Profile & Settings', 'Edge Cases & Errors'].map(group => (
                <div key={group} className="py-1">
                  <div className="px-2 py-0.5 text-[10px] font-bold text-neutral-400 uppercase tracking-wider">
                    {group}
                  </div>
                  {screensList
                    .filter(s => s.group === group)
                    .map(item => (
                      <button
                        key={item.id}
                        onClick={() => navigate(item.id)}
                        className={`w-full text-left px-2 py-1.5 rounded-md flex items-center justify-between text-xs transition-colors ${
                          screen === item.id
                            ? 'bg-emerald-900/60 text-emerald-300 font-bold'
                            : 'text-neutral-300 hover:bg-neutral-800 hover:text-white'
                        }`}
                      >
                        <span>{item.label}</span>
                        {screen === item.id && <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" />}
                      </button>
                    ))}
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Right: Viewport mode, simulation buttons & Dark mode */}
      <div className="flex items-center gap-1.5">
        {/* Toggle Full Screen Mobile vs iPhone Frame */}
        <button
          onClick={() =>
            setViewportMode(
              viewportMode === 'mobile-fullscreen' ? 'figma-mockup' : 'mobile-fullscreen'
            )
          }
          title={viewportMode === 'mobile-fullscreen' ? 'Switch to iPhone Frame' : 'Switch to Full Screen'}
          className="flex items-center gap-1 bg-neutral-800 hover:bg-neutral-700 text-neutral-200 px-2 py-1 rounded border border-neutral-700 text-[11px]"
        >
          {viewportMode === 'figma-mockup' ? (
            <>
              <Smartphone className="w-3.5 h-3.5 text-amber-400" />
              <span className="hidden sm:inline">Phone Frame</span>
            </>
          ) : (
            <>
              <Maximize2 className="w-3.5 h-3.5 text-emerald-400" />
              <span className="hidden sm:inline">Full Screen</span>
            </>
          )}
        </button>

        {/* Simulate Push Notification */}
        <button
          onClick={simulateIncomingNotification}
          title="Simulate push notification alert"
          className="flex items-center gap-1 bg-neutral-800 hover:bg-neutral-700 text-neutral-200 px-2 py-1 rounded border border-neutral-700 text-[11px]"
        >
          <Bell className="w-3.5 h-3.5 text-amber-400" />
          <span className="hidden md:inline">Test Alert</span>
        </button>

        {/* GPS Map Pin Modal Trigger */}
        <button
          onClick={() => setIsGpsModalOpen(true)}
          title="Open GPS Location Map Picker"
          className="flex items-center gap-1 bg-neutral-800 hover:bg-neutral-700 text-neutral-200 px-2 py-1 rounded border border-neutral-700 text-[11px]"
        >
          <MapPin className="w-3.5 h-3.5 text-emerald-400" />
          <span className="hidden md:inline">GPS Pin</span>
        </button>

        {/* Shaky 4G / Offline Toggle */}
        <button
          onClick={() => {
            if (isOffline) {
              setIsOffline(false);
              navigate('home');
            } else {
              triggerException('offline');
            }
          }}
          title="Test 4G Disconnect"
          className={`flex items-center gap-1 px-2 py-1 rounded text-[11px] border ${
            isOffline
              ? 'bg-rose-900/70 border-rose-600 text-rose-200'
              : 'bg-neutral-800 hover:bg-neutral-700 border-neutral-700 text-neutral-300'
          }`}
        >
          <WifiOff className="w-3.5 h-3.5 text-rose-400" />
          <span className="hidden md:inline">Shaky 4G</span>
        </button>

        {/* 500 Cold Server Toggle */}
        <button
          onClick={() => {
            if (isServerError) {
              setIsServerError(false);
              navigate('home');
            } else {
              triggerException('500');
            }
          }}
          title="Test 500 Database Cold Wake-up"
          className={`flex items-center gap-1 px-2 py-1 rounded text-[11px] border ${
            isServerError
              ? 'bg-amber-900/70 border-amber-600 text-amber-200'
              : 'bg-neutral-800 hover:bg-neutral-700 border-neutral-700 text-neutral-300'
          }`}
        >
          <ServerCrash className="w-3.5 h-3.5 text-amber-400" />
          <span className="hidden md:inline">500 Wake-up</span>
        </button>

        {/* Dark/Light mode toggle */}
        <button
          onClick={toggleDarkMode}
          title="Toggle Theme"
          className="p-1 rounded bg-neutral-800 hover:bg-neutral-700 border border-neutral-700 text-neutral-300"
        >
          {isDark ? <Sun className="w-3.5 h-3.5 text-amber-300" /> : <Moon className="w-3.5 h-3.5 text-neutral-400" />}
        </button>
      </div>
    </div>
  );
};
