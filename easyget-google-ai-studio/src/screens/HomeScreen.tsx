import React, { useState } from 'react';
import {
  Search,
  Sparkles,
  ChevronRight,
  TrendingUp,
  Award,
  Leaf,
  Clock,
  ArrowRight,
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { Header } from '../components/common/Header';
import { ProductCard } from '../components/common/ProductCard';
import { CATEGORIES, PRODUCTS } from '../data/mockData';

export const HomeScreen: React.FC = () => {
  const { navigate } = useApp();
  const [activeBanner, setActiveBanner] = useState(0);

  const banners = [
    {
      id: 1,
      badge: 'DAWN HARVEST',
      title: 'Kodaikanal Hass Avocados & Sweet Berries',
      subtitle: 'Single-estate, naturally ripened · Under 12 min delivery',
      bgGradient: 'from-emerald-950 via-[#0C3B2E] to-emerald-900',
      image: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=800&auto=format&fit=crop&q=80',
    },
    {
      id: 2,
      badge: 'FRESH CHURN',
      title: 'Pure A2 Gir Cow Whole Milk & Bilona Ghee',
      subtitle: 'Glass-bottled at 4°C · 0 chemical processing',
      bgGradient: 'from-[#2A241C] via-[#3D3325] to-[#1F1912]',
      image: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=800&auto=format&fit=crop&q=80',
    },
  ];

  const freshPicks = PRODUCTS.slice(0, 5);
  const pantryPicks = PRODUCTS.slice(4, 9);

  return (
    <div className="pb-24 bg-[var(--canvas)] min-h-screen">
      {/* 1. Header with Address row + ETA Pill */}
      <Header showAddressRow />

      {/* 2. Persistent SearchBar (52dp, sunken fill, radius 16) */}
      <div className="px-4 pt-3 pb-2 bg-[var(--surface)] border-b border-[var(--border)]">
        <div
          onClick={() => navigate('search')}
          className="h-[50px] bg-[var(--sunken)] hover:bg-[var(--sunken)]/80 rounded-[16px] px-4 flex items-center justify-between cursor-pointer border border-[var(--border)]/70 transition-colors shadow-2xs"
        >
          <div className="flex items-center gap-2.5 text-[var(--muted)]">
            <Search className="w-4 h-4 text-[var(--primary)]" />
            <span className="text-xs font-medium truncate">
              Search atta, Gir cow milk, hass avocado...
            </span>
          </div>
          <div className="flex items-center gap-1.5 pl-2 border-l border-[var(--border-strong)]">
            <span className="text-[10px] font-bold tracking-wider text-[var(--primary)] bg-[var(--primary-tint)] px-2 py-0.5 rounded-full">
              10 MIN
            </span>
          </div>
        </div>
      </div>

      {/* 3. Quiet Offer Ticker (§12 "single quiet line, admin text — no animation wars") */}
      <div className="px-4 py-2 bg-[var(--sunken)]/60 border-b border-[var(--border)] flex items-center justify-between text-xs">
        <div className="flex items-center gap-1.5 text-[var(--ink)]">
          <Sparkles className="w-3.5 h-3.5 text-[var(--marigold)] shrink-0" />
          <span className="font-semibold text-[11px] truncate">
            Today's Fresh Code: Use <span className="font-bold text-[var(--primary)] font-mono">FRESH20</span> for ₹50 off on farm orders
          </span>
        </div>
        <button
          onClick={() => navigate('cart')}
          className="text-[11px] font-bold text-[var(--primary)] shrink-0 hover:underline flex items-center"
        >
          View <ChevronRight className="w-3 h-3" />
        </button>
      </div>

      {/* 4. Banner Carousel (16:7 aspect ratio edge-to-edge with dots) */}
      <div className="p-4">
        <div className="relative rounded-[20px] overflow-hidden shadow-sm border border-[var(--border)]">
          <div className={`w-full aspect-[16/7] relative overflow-hidden bg-gradient-to-r ${banners[activeBanner].bgGradient}`}>
            <img
              src={banners[activeBanner].image}
              alt="Harvest"
              className="absolute right-0 top-0 w-1/2 h-full object-cover opacity-60 mix-blend-overlay"
            />
            <div className="absolute inset-0 p-4 sm:p-5 flex flex-col justify-between z-10 text-white">
              <div>
                <span className="inline-block px-2 py-0.5 rounded-full bg-white/20 backdrop-blur-xs text-[10px] font-extrabold uppercase tracking-wider text-emerald-200 border border-white/20 mb-1.5">
                  {banners[activeBanner].badge}
                </span>
                <h3 className="font-display font-medium text-base sm:text-lg leading-snug max-w-[220px] sm:max-w-xs text-white">
                  {banners[activeBanner].title}
                </h3>
              </div>
              <p className="text-[11px] text-white/80 line-clamp-1">
                {banners[activeBanner].subtitle}
              </p>
            </div>
          </div>

          {/* Dots */}
          <div className="absolute bottom-2 right-3 flex items-center gap-1 z-20">
            {banners.map((_, i) => (
              <button
                key={i}
                onClick={() => setActiveBanner(i)}
                aria-label={`Slide ${i + 1}`}
                className={`h-1.5 rounded-full transition-all ${
                  activeBanner === i ? 'w-5 bg-white' : 'w-1.5 bg-white/40'
                }`}
              />
            ))}
          </div>
        </div>
      </div>

      {/* 5. "Shop by Category" Grid (4-col, 8 tiles + See all) */}
      <section className="px-4 py-2">
        <div className="flex items-center justify-between mb-3">
          <div>
            <h2 className="text-base font-bold text-[var(--ink)]">Shop by Aisle</h2>
            <p className="text-[11px] text-[var(--muted)]">Curated morning market categories</p>
          </div>
          <button
            onClick={() => navigate('browse')}
            className="text-xs font-bold text-[var(--primary)] hover:underline flex items-center gap-0.5"
          >
            See all <ArrowRight className="w-3.5 h-3.5" />
          </button>
        </div>

        <div className="grid grid-cols-3 sm:grid-cols-6 gap-2.5">
          {CATEGORIES.map(cat => (
            <div
              key={cat.id}
              onClick={() => navigate('browse', { category: cat.id })}
              className="flex flex-col items-center text-center p-2 rounded-2xl bg-[var(--surface)] border border-[var(--border)] hover:border-[var(--border-strong)] cursor-pointer group transition-all active:scale-95 shadow-2xs"
            >
              <div className="w-14 h-14 rounded-xl overflow-hidden bg-[var(--sunken)] mb-1.5 group-hover:scale-105 transition-transform">
                <img
                  src={cat.image}
                  alt={cat.name}
                  className="w-full h-full object-cover"
                  loading="lazy"
                />
              </div>
              <span className="text-[11px] font-semibold text-[var(--ink)] line-clamp-2 leading-tight">
                {cat.name.split(' ')[0]}
              </span>
              <span className="text-[9px] text-[var(--muted)] mt-0.5 tnum">
                {cat.itemCount} items
              </span>
            </div>
          ))}
        </div>
      </section>

      {/* 6. Product Rail: "Fresh Picks at Dawn" (Horizontal 148dp cards) */}
      <section className="mt-4 pt-4 border-t border-[var(--border)]">
        <div className="px-4 flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <div className="w-7 h-7 rounded-lg bg-[var(--primary-tint)] flex items-center justify-center text-[var(--primary)]">
              <Leaf className="w-4 h-4" />
            </div>
            <div>
              <h2 className="text-base font-bold text-[var(--ink)]">Fresh Picks at Dawn</h2>
              <p className="text-[11px] text-[var(--muted)]">Harveted today & direct from orchard</p>
            </div>
          </div>
          <button
            onClick={() => navigate('browse')}
            className="text-xs font-bold text-[var(--primary)] hover:underline"
          >
            View all
          </button>
        </div>

        {/* 148dp card horizontal rail */}
        <div className="flex gap-3 overflow-x-auto px-4 pb-2 no-scrollbar">
          {freshPicks.map(prod => (
            <ProductCard key={prod.id} product={prod} variant="rail" />
          ))}
        </div>
      </section>

      {/* 7. Product Rail: "Pantry & Artisanal Staples" */}
      <section className="mt-4 pt-4 border-t border-[var(--border)]">
        <div className="px-4 flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <div className="w-7 h-7 rounded-lg bg-[var(--marigold-wash)] flex items-center justify-center text-[var(--marigold)]">
              <Award className="w-4 h-4" />
            </div>
            <div>
              <h2 className="text-base font-bold text-[var(--ink)]">Heritage & Cold Pressed</h2>
              <p className="text-[11px] text-[var(--muted)]">Slow-made oils, forest honey & loaves</p>
            </div>
          </div>
          <button
            onClick={() => navigate('browse')}
            className="text-xs font-bold text-[var(--primary)] hover:underline"
          >
            View all
          </button>
        </div>

        <div className="flex gap-3 overflow-x-auto px-4 pb-2 no-scrollbar">
          {pantryPicks.map(prod => (
            <ProductCard key={prod.id} product={prod} variant="rail" />
          ))}
        </div>
      </section>

      {/* 8. Editorial Store Story Block (§12 "store story block (image + Fraunces line)") */}
      <section className="mx-4 mt-6 p-4 rounded-[22px] bg-[var(--surface)] border border-[var(--border)] overflow-hidden">
        <div className="flex flex-col sm:flex-row gap-4 items-center">
          <div className="w-full sm:w-1/3 aspect-[4/3] rounded-xl overflow-hidden bg-[var(--sunken)] shrink-0">
            <img
              src="https://images.unsplash.com/photo-1595974482597-4b8da8879bc5?w=800&auto=format&fit=crop&q=80"
              alt="Farm Story"
              className="w-full h-full object-cover"
              loading="lazy"
            />
          </div>
          <div className="flex-1">
            <span className="text-[10px] font-extrabold uppercase tracking-widest text-[var(--primary)]">
              EASYGET COLLECTIVE · STORY #04
            </span>
            <h3 className="font-display font-medium text-lg text-[var(--ink)] mt-1 mb-2 leading-snug">
              "We harvest in the pre-dawn mist so your breakfast table tastes like the orchard."
            </h3>
            <p className="text-xs text-[var(--muted)] leading-relaxed mb-3">
              Every vegetable and milk bottle passes cold-chain validation in our neighborhood micro-hubs. Honest weights, zero shelf chemical coatings, delivered in 10 minutes.
            </p>
            <div className="flex items-center gap-4 text-xs font-bold text-[var(--brand)]">
              <span className="flex items-center gap-1">
                <Leaf className="w-3.5 h-3.5 text-[var(--primary)]" /> 100% Traceable
              </span>
              <span className="flex items-center gap-1">
                <Clock className="w-3.5 h-3.5 text-[var(--marigold)]" /> Tabular Pricing
              </span>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
};
