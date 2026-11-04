import React, { useEffect } from 'react';
import { useApp } from '../context/AppContext';
import { Clock } from 'lucide-react';

export const SplashScreen: React.FC = () => {
  const { navigate } = useApp();

  useEffect(() => {
    const timer = setTimeout(() => {
      navigate('home');
    }, 1200);
    return () => clearTimeout(timer);
  }, [navigate]);

  return (
    <div className="min-h-screen bg-[var(--brand)] text-white flex flex-col items-center justify-between p-8 select-none">
      <div className="w-full pt-8 flex justify-end">
        <span className="text-[11px] font-mono tracking-widest text-emerald-300/80 uppercase">
          Fresh Market v2.6
        </span>
      </div>

      <div className="flex flex-col items-center text-center">
        {/* EG Monogram */}
        <div className="w-24 h-24 rounded-3xl bg-[#FAF6EF] text-[var(--brand)] flex items-center justify-center font-display font-bold text-4xl shadow-2xl mb-5">
          EG
        </div>

        {/* Brand wordmark */}
        <h1 className="font-display font-medium text-4xl tracking-tight text-[#FAF6EF]">
          EASYGET
        </h1>
        <p className="text-xs uppercase tracking-[0.25em] text-emerald-300 font-semibold mt-1">
          Fresh Market
        </p>
      </div>

      {/* Footer Pill */}
      <div className="pb-8 flex flex-col items-center gap-3">
        <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-emerald-950/60 border border-emerald-800/60 text-emerald-200 text-xs font-medium">
          <Clock className="w-3.5 h-3.5 text-[var(--marigold)]" />
          <span>10-Minute Doorstep Delivery</span>
        </div>
        <p className="text-[11px] text-emerald-400/60 font-mono">
          Single-estate milk · Farm harvest · Artisanal bakery
        </p>
      </div>
    </div>
  );
};
