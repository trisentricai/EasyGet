import React, { useState, useEffect } from 'react';
import { AppProvider, useApp } from './context/AppContext';
import { FigmaToolbar } from './components/common/FigmaToolbar';
import { BottomNav } from './components/common/BottomNav';
import { NotificationDrawer } from './components/common/NotificationDrawer';

// Screens
import { SplashScreen } from './screens/SplashScreen';
import { LoginScreen } from './screens/LoginScreen';
import { RegisterScreen } from './screens/RegisterScreen';
import { OtpVerifyScreen } from './screens/OtpVerifyScreen';
import { HomeScreen } from './screens/HomeScreen';
import { BrowseScreen } from './screens/BrowseScreen';
import { SearchScreen } from './screens/SearchScreen';
import { PdpScreen } from './screens/PdpScreen';
import { CartScreen } from './screens/CartScreen';
import { CheckoutScreen } from './screens/CheckoutScreen';
import { OrdersScreen } from './screens/OrdersScreen';
import { TrackOrderScreen } from './screens/TrackOrderScreen';
import { AccountScreen } from './screens/AccountScreen';
import { AddressesScreen } from './screens/AddressesScreen';
import {
  OfflineErrorScreen,
  ServerErrorScreen,
  NotFoundScreen,
} from './screens/ErrorScreens';

// Modals
import { GpsLocationModal } from './components/modals/GpsLocationModal';

// Lucide icons for device frame status bar
import { Wifi, Battery } from 'lucide-react';

const MobileAppContent: React.FC = () => {
  const {
    screen,
    viewportMode,
    isDark,
  } = useApp();

  const [currentTime, setCurrentTime] = useState('9:41');

  useEffect(() => {
    const updateTime = () => {
      const now = new Date();
      setCurrentTime(
        now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: false })
      );
    };
    updateTime();
    const interval = setInterval(updateTime, 30000);
    return () => clearInterval(interval);
  }, []);

  // Determine if bottom nav should be visible (only on 5 core tabs)
  const showBottomNav = ['home', 'browse', 'search', 'cart', 'orders'].includes(screen);

  // Render current active screen
  const renderScreen = () => {
    switch (screen) {
      case 'splash':
        return <SplashScreen />;
      case 'login':
        return <LoginScreen />;
      case 'register':
        return <RegisterScreen />;
      case 'otp_verify':
        return <OtpVerifyScreen />;
      case 'home':
        return <HomeScreen />;
      case 'browse':
        return <BrowseScreen />;
      case 'search':
        return <SearchScreen />;
      case 'pdp':
        return <PdpScreen />;
      case 'cart':
        return <CartScreen />;
      case 'checkout':
        return <CheckoutScreen />;
      case 'orders':
        return <OrdersScreen />;
      case 'track':
        return <TrackOrderScreen />;
      case 'account':
        return <AccountScreen />;
      case 'addresses':
        return <AddressesScreen />;
      case 'offline_error':
        return <OfflineErrorScreen />;
      case 'server_error':
        return <ServerErrorScreen />;
      case 'not_found':
        return <NotFoundScreen />;
      default:
        return <HomeScreen />;
    }
  };

  const isFigmaMockup = viewportMode === 'figma-mockup';

  return (
    <div className="min-h-screen flex flex-col bg-[var(--canvas)] text-[var(--ink)]">
      {/* Top Prototype Controls Bar (Screen Switcher, Frame toggle, Error simulator) */}
      <FigmaToolbar />

      {/* Main Container */}
      {isFigmaMockup ? (
        /* MNC Figma Prototype Canvas with simulated iPhone 16 Pro hardware chassis */
        <div className="flex-1 flex flex-col items-center justify-start p-2 sm:p-6 bg-[#161513] overflow-y-auto">
          {/* Mockup Frame Header Note */}
          <div className="mb-3 text-center hidden sm:block">
            <span className="text-[11px] font-mono text-neutral-400 tracking-wider">
              IPHONE 16 PRO · FRESH MARKET MOBILE CLIENT (393 × 852 DP)
            </span>
          </div>

          {/* Device Frame */}
          <div className="relative w-full max-w-[410px] bg-[var(--canvas)] rounded-[48px] overflow-hidden shadow-[0_20px_60px_-15px_rgba(0,0,0,0.7)] border-[9px] border-[#2B2925] ring-1 ring-white/10 flex flex-col">
            {/* iOS Status Bar */}
            <div className="w-full h-11 px-6 bg-[var(--surface)] text-[var(--ink)] flex items-center justify-between text-xs select-none shrink-0 z-40 border-b border-[var(--border)]/30">
              <span className="font-bold font-mono tracking-tight text-[13px]">{currentTime}</span>

              {/* Dynamic Island Notch */}
              <div className="w-24 h-5 rounded-full bg-black flex items-center justify-end px-2 gap-1.5 shadow-inner">
                <div className="w-2.5 h-2.5 rounded-full bg-neutral-900 ring-1 ring-neutral-800" />
                <div className="w-2 h-2 rounded-full bg-[#053018]" />
              </div>

              {/* Status Icons */}
              <div className="flex items-center gap-1.5 text-[var(--ink)]">
                {/* 5G Bars */}
                <div className="flex items-end gap-0.5 h-2.5">
                  <span className="w-0.5 h-1 bg-[var(--ink)] rounded-xs" />
                  <span className="w-0.5 h-1.5 bg-[var(--ink)] rounded-xs" />
                  <span className="w-0.5 h-2 bg-[var(--ink)] rounded-xs" />
                  <span className="w-0.5 h-2.5 bg-[var(--ink)] rounded-xs" />
                </div>
                <Wifi className="w-3.5 h-3.5" />
                <div className="flex items-center gap-0.5">
                  <div className="w-5 h-2.5 border border-[var(--ink)] rounded-[3px] p-0.5 flex items-center">
                    <div className="w-full h-full bg-[var(--primary)] rounded-[1px]" />
                  </div>
                </div>
              </div>
            </div>

            {/* Mobile Viewport Screen Content */}
            <main className="relative flex-1 min-h-[740px] max-h-[820px] overflow-y-auto no-scrollbar bg-[var(--canvas)]">
              {renderScreen()}
              {showBottomNav && <BottomNav />}
              <NotificationDrawer />
              <GpsLocationModal />
            </main>

            {/* iOS Home Indicator Bar */}
            <div className="w-full h-5 bg-[var(--surface)] flex items-center justify-center shrink-0 z-40">
              <div className="w-32 h-1 rounded-full bg-[var(--border-strong)]" />
            </div>
          </div>
        </div>
      ) : (
        /* Full Screen Native Viewport Mode (Ideal for real mobile devices or full browser) */
        <div className="flex-1 w-full max-w-[440px] mx-auto relative bg-[var(--canvas)] shadow-md min-h-screen flex flex-col">
          <main className="flex-1 relative">
            {renderScreen()}
            {showBottomNav && <BottomNav />}
            <NotificationDrawer />
            <GpsLocationModal />
          </main>
        </div>
      )}
    </div>
  );
};

export default function App() {
  return (
    <AppProvider>
      <MobileAppContent />
    </AppProvider>
  );
}
