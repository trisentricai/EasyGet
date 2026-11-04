import React, { useState } from 'react';
import {
  WifiOff,
  ServerCrash,
  FileQuestion,
  RotateCcw,
  Home,
  CheckCircle2,
  Clock,
  Sparkles,
  SignalZero,
} from 'lucide-react';
import { useApp } from '../context/AppContext';

export const OfflineErrorScreen: React.FC = () => {
  const { setIsOffline, navigate } = useApp();
  const [retrying, setRetrying] = useState(false);

  const handleRetry = () => {
    setRetrying(true);
    setTimeout(() => {
      setRetrying(false);
      setIsOffline(false);
      navigate('home');
    }, 800);
  };

  return (
    <div className="min-h-screen bg-[var(--canvas)] flex flex-col justify-between p-6 select-none">
      <div className="w-full flex justify-between items-center text-xs text-[var(--muted)]">
        <span className="font-mono text-[10px] tracking-widest text-[var(--danger)] uppercase font-bold flex items-center gap-1">
          <SignalZero className="w-3.5 h-3.5" /> SHAKY 4G DETECTED
        </span>
        <span className="text-[10px] bg-[var(--sunken)] px-2 py-0.5 rounded font-mono">
          STATUS: OFFLINE
        </span>
      </div>

      <div className="flex flex-col items-center text-center max-w-sm mx-auto">
        {/* Brand Wash Illustration Dot per §11.6 */}
        <div className="w-20 h-20 rounded-full bg-rose-100 dark:bg-rose-950/40 border border-rose-300 dark:border-rose-900/60 flex items-center justify-center text-[var(--danger)] mb-5 shadow-sm">
          <WifiOff className="w-10 h-10 stroke-[1.8]" />
        </div>

        <span className="px-3 py-1 rounded-full bg-[var(--sunken)] text-[var(--muted)] text-[11px] font-bold uppercase tracking-wider mb-2">
          You're Offline
        </span>

        <h2 className="font-display font-semibold text-2xl text-[var(--ink)] tracking-tight">
          Connection Interrupted
        </h2>

        <p className="text-xs text-[var(--muted)] mt-2 leading-relaxed max-w-[280px]">
          The app works on shaky 4G. Your basket items and active delivery status are cached safely on this device.
        </p>

        <div className="w-full mt-6 p-3 rounded-2xl bg-[var(--surface)] border border-[var(--border)] text-left space-y-2">
          <div className="flex items-center gap-2 text-xs font-semibold text-[var(--ink)]">
            <CheckCircle2 className="w-4 h-4 text-[var(--success)] shrink-0" />
            <span>Cart state preserved locally</span>
          </div>
          <div className="flex items-center gap-2 text-xs font-semibold text-[var(--ink)]">
            <Clock className="w-4 h-4 text-[var(--marigold)] shrink-0" />
            <span>Driver delivery queue is progressing</span>
          </div>
        </div>
      </div>

      <div className="space-y-2.5 max-w-sm mx-auto w-full pb-4">
        <button
          disabled={retrying}
          onClick={handleRetry}
          className="w-full h-[52px] rounded-[16px] bg-[var(--primary)] hover:bg-[var(--primary-dark)] text-white font-bold text-sm flex items-center justify-center gap-2 transition-all active:scale-[0.98] shadow-md cursor-pointer"
        >
          <RotateCcw className={`w-4 h-4 ${retrying ? 'animate-spin' : ''}`} />
          {retrying ? 'Connecting to Fresh Market...' : 'Retry Connection Now'}
        </button>

        <button
          onClick={() => {
            setIsOffline(false);
            navigate('cart');
          }}
          className="w-full h-11 rounded-[16px] bg-[var(--surface)] border border-[var(--border-strong)] text-[var(--ink)] text-xs font-bold hover:bg-[var(--sunken)]"
        >
          View Cached Basket
        </button>
      </div>
    </div>
  );
};

export const ServerErrorScreen: React.FC = () => {
  const { setIsServerError, navigate } = useApp();
  const [countdown, setCountdown] = useState(8);
  const [wakingUp, setWakingUp] = useState(false);

  const handleWakeUp = () => {
    setWakingUp(true);
    setTimeout(() => {
      setWakingUp(false);
      setIsServerError(false);
      navigate('home');
    }, 1200);
  };

  return (
    <div className="min-h-screen bg-[var(--canvas)] flex flex-col justify-between p-6 select-none">
      <div className="w-full flex justify-between items-center text-xs text-[var(--muted)]">
        <span className="font-mono text-[10px] tracking-widest text-[var(--warning)] uppercase font-bold flex items-center gap-1">
          <ServerCrash className="w-3.5 h-3.5" /> COLD BOOT RECOVERY
        </span>
        <span className="text-[10px] bg-[var(--sunken)] px-2 py-0.5 rounded font-mono">
          HTTP 503 / RECONNECT
        </span>
      </div>

      <div className="flex flex-col items-center text-center max-w-sm mx-auto">
        <div className="w-20 h-20 rounded-full bg-amber-100 dark:bg-amber-950/40 border border-amber-300 dark:border-amber-800 flex items-center justify-center text-[var(--warning)] mb-5 shadow-sm">
          <ServerCrash className="w-10 h-10 stroke-[1.8] animate-pulse" />
        </div>

        <span className="px-3 py-1 rounded-full bg-[var(--marigold-wash)] text-[var(--ink)] text-[11px] font-bold uppercase tracking-wider mb-2">
          Store Server Spinning Up
        </span>

        <h2 className="font-display font-semibold text-2xl text-[var(--ink)] tracking-tight">
          Waking up the store...
        </h2>

        <p className="text-xs text-[var(--muted)] mt-2 leading-relaxed max-w-[280px]">
          Free-tier store microservice went to sleep. The dark store catalog, live inventory, and pricing engine are warming up.
        </p>

        <div className="mt-5 w-full bg-[var(--surface)] border border-[var(--border)] rounded-2xl p-4 text-xs">
          <div className="flex justify-between items-center mb-1 text-[var(--muted)]">
            <span className="font-medium">Orchestration Progress</span>
            <span className="font-mono font-bold text-[var(--primary)] tnum">
              {wakingUp ? '92%' : '65%'}
            </span>
          </div>
          <div className="w-full h-2 rounded-full bg-[var(--sunken)] overflow-hidden">
            <div
              className={`h-full bg-[var(--primary)] transition-all duration-700 ${
                wakingUp ? 'w-[92%]' : 'w-[65%]'
              }`}
            />
          </div>
          <p className="text-[10px] text-[var(--faint)] mt-2 font-mono">
            GET /storefront/easyget/ · Retrying automatically in ~8s
          </p>
        </div>
      </div>

      <div className="space-y-2.5 max-w-sm mx-auto w-full pb-4">
        <button
          disabled={wakingUp}
          onClick={handleWakeUp}
          className="w-full h-[52px] rounded-[16px] bg-[var(--primary)] hover:bg-[var(--primary-dark)] text-white font-bold text-sm flex items-center justify-center gap-2 transition-all active:scale-[0.98] shadow-md cursor-pointer"
        >
          <RotateCcw className={`w-4 h-4 ${wakingUp ? 'animate-spin' : ''}`} />
          {wakingUp ? 'Database Ready! Launching...' : 'Wake Up Store Now'}
        </button>

        <button
          onClick={() => {
            setIsServerError(false);
            navigate('home');
          }}
          className="w-full h-11 rounded-[16px] bg-[var(--surface)] border border-[var(--border-strong)] text-[var(--ink)] text-xs font-bold hover:bg-[var(--sunken)]"
        >
          Continue with Offline Cache
        </button>
      </div>
    </div>
  );
};

export const NotFoundScreen: React.FC = () => {
  const { navigate } = useApp();

  return (
    <div className="min-h-screen bg-[var(--canvas)] flex flex-col justify-between p-6 select-none">
      <div className="w-full flex justify-between items-center text-xs text-[var(--muted)]">
        <span className="font-mono text-[10px] tracking-widest text-[var(--faint)] uppercase font-bold">
          EASYGET FRESH MARKET
        </span>
        <span className="text-[10px] bg-[var(--sunken)] px-2 py-0.5 rounded font-mono">
          404 NOT FOUND
        </span>
      </div>

      <div className="flex flex-col items-center text-center max-w-sm mx-auto">
        <div className="w-20 h-20 rounded-full bg-[var(--sunken)] border border-[var(--border)] flex items-center justify-center text-[var(--muted)] mb-5 shadow-sm">
          <FileQuestion className="w-10 h-10 stroke-[1.8]" />
        </div>

        <h2 className="font-display font-semibold text-2xl text-[var(--ink)] tracking-tight">
          Item Not In Today's Harvest
        </h2>

        <p className="text-xs text-[var(--muted)] mt-2 leading-relaxed max-w-[280px]">
          This product or route may have finished for the day or belongs to a different regional dark store.
        </p>
      </div>

      <div className="max-w-sm mx-auto w-full pb-4">
        <button
          onClick={() => navigate('home')}
          className="w-full h-[52px] rounded-[16px] bg-[var(--primary)] hover:bg-[var(--primary-dark)] text-white font-bold text-sm flex items-center justify-center gap-2 shadow-md cursor-pointer"
        >
          <Home className="w-4 h-4" />
          Back to Fresh Market Storefront
        </button>
      </div>
    </div>
  );
};
