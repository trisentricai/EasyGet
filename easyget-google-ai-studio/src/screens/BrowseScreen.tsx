import React, { useState, useMemo } from 'react';
import {
  SlidersHorizontal,
  ArrowUpDown,
  Search,
  X,
  Check,
  RotateCcw,
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { Header } from '../components/common/Header';
import { ProductCard } from '../components/common/ProductCard';
import { CATEGORIES, PRODUCTS } from '../data/mockData';

export const BrowseScreen: React.FC = () => {
  const { selectedCategory, navigate } = useApp();
  const [activeCat, setActiveCat] = useState<string | null>(selectedCategory || null);
  const [sortBy, setSortBy] = useState<'relevance' | 'price_asc' | 'price_desc' | 'rating'>('relevance');
  const [onlyVeg, setOnlyVeg] = useState(false);
  const [inStockOnly, setInStockOnly] = useState(true);
  const [selectedDietary, setSelectedDietary] = useState<string[]>([]);

  // Sheets
  const [isSortOpen, setIsSortOpen] = useState(false);
  const [isFilterOpen, setIsFilterOpen] = useState(false);

  const toggleDietary = (tag: string) => {
    setSelectedDietary(prev =>
      prev.includes(tag) ? prev.filter(t => t !== tag) : [...prev, tag]
    );
  };

  // Filter products
  const filteredProducts = useMemo(() => {
    return PRODUCTS.filter(p => {
      if (activeCat && p.category !== activeCat) return false;
      if (onlyVeg && !p.isVeg) return false;
      if (inStockOnly && !p.inStock) return false;
      if (selectedDietary.length > 0) {
        // match dietary or category characteristics
        const matches = selectedDietary.some(tag => {
          if (tag === 'Organic' && (p.name.toLowerCase().includes('organic') || p.origin.toLowerCase().includes('organic'))) return true;
          if (tag === 'Gluten-Free' && p.category !== 'bakery') return true;
          if (tag === 'Vegan' && p.category !== 'dairy' && !p.name.toLowerCase().includes('honey')) return true;
          if (tag === 'Cold-Pressed' && p.name.toLowerCase().includes('pressed')) return true;
          return false;
        });
        if (!matches) return false;
      }
      return true;
    }).sort((a, b) => {
      if (sortBy === 'price_asc') return a.price - b.price;
      if (sortBy === 'price_desc') return b.price - a.price;
      if (sortBy === 'rating') return b.rating - a.rating;
      return 0; // relevance
    });
  }, [activeCat, onlyVeg, inStockOnly, sortBy]);

  return (
    <div className="pb-24 bg-[var(--canvas)] min-h-screen">
      <Header title="Fresh Market Catalog" />

      {/* Sticky Category Chips Row */}
      <div className="sticky top-[57px] z-20 bg-[var(--surface)] border-b border-[var(--border)] shadow-2xs">
        <div className="flex gap-2 overflow-x-auto p-3 no-scrollbar">
          <button
            onClick={() => setActiveCat(null)}
            className={`h-9 px-4 rounded-full text-xs font-bold shrink-0 transition-all active:scale-95 ${
              activeCat === null
                ? 'bg-[var(--primary)] text-white shadow-xs'
                : 'bg-[var(--sunken)] text-[var(--muted)] hover:text-[var(--ink)]'
            }`}
          >
            All Aisles ({PRODUCTS.length})
          </button>
          {CATEGORIES.map(c => {
            const isSelected = activeCat === c.id;
            return (
              <button
                key={c.id}
                onClick={() => setActiveCat(c.id)}
                className={`h-9 px-3.5 rounded-full text-xs font-bold shrink-0 flex items-center gap-1.5 transition-all active:scale-95 ${
                  isSelected
                    ? 'bg-[var(--primary-tint)] text-[var(--primary)] border border-[var(--primary)]/40 shadow-xs'
                    : 'bg-[var(--sunken)] text-[var(--muted)] hover:text-[var(--ink)]'
                }`}
              >
                <span>{c.name.split(' ')[0]}</span>
                <span className="text-[10px] opacity-70 tnum">({c.itemCount})</span>
              </button>
            );
          })}
        </div>

        {/* Toolbar: Live Count + Filter + Sort */}
        <div className="px-4 py-2 bg-[var(--canvas)] flex items-center justify-between border-t border-[var(--border)]/60 text-xs">
          <div className="font-semibold text-[var(--muted)] tnum">
            Showing <span className="font-bold text-[var(--ink)]">{filteredProducts.length}</span> items
          </div>

          <div className="flex items-center gap-2">
            {/* Filter Trigger */}
            <button
              onClick={() => setIsFilterOpen(true)}
              className={`px-2.5 py-1 rounded-lg border text-xs font-semibold flex items-center gap-1.5 transition-colors ${
                onlyVeg
                  ? 'bg-[var(--primary-tint)] border-[var(--primary)] text-[var(--primary)]'
                  : 'bg-[var(--surface)] border-[var(--border)] text-[var(--ink)]'
              }`}
            >
              <SlidersHorizontal className="w-3.5 h-3.5" />
              Filter
              {onlyVeg && <span className="w-1.5 h-1.5 rounded-full bg-[var(--primary)]" />}
            </button>

            {/* Sort Trigger */}
            <button
              onClick={() => setIsSortOpen(true)}
              className="px-2.5 py-1 rounded-lg bg-[var(--surface)] border border-[var(--border)] text-xs font-semibold text-[var(--ink)] flex items-center gap-1.5"
            >
              <ArrowUpDown className="w-3.5 h-3.5 text-[var(--muted)]" />
              <span>
                {sortBy === 'relevance'
                  ? 'Relevance'
                  : sortBy === 'price_asc'
                  ? 'Price: Low'
                  : sortBy === 'price_desc'
                  ? 'Price: High'
                  : 'Rating'}
              </span>
            </button>
          </div>
        </div>
      </div>

      {/* Grid: 2 columns, 12dp gap per §11.2 */}
      <div className="p-4">
        {filteredProducts.length === 0 ? (
          <div className="py-16 text-center bg-[var(--surface)] border border-[var(--border)] rounded-2xl p-6">
            <div className="w-12 h-12 rounded-full bg-[var(--sunken)] flex items-center justify-center mx-auto text-[var(--muted)] mb-3">
              <Search className="w-6 h-6" />
            </div>
            <h3 className="font-bold text-base text-[var(--ink)]">No items in this filter</h3>
            <p className="text-xs text-[var(--muted)] mt-1 mb-4">
              Try resetting your category or vegetarian preferences.
            </p>
            <button
              onClick={() => {
                setActiveCat(null);
                setOnlyVeg(false);
              }}
              className="px-4 py-2 rounded-xl bg-[var(--primary)] text-white text-xs font-bold inline-flex items-center gap-1.5"
            >
              <RotateCcw className="w-3.5 h-3.5" />
              Reset Filters
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-2 gap-3">
            {filteredProducts.map(p => (
              <ProductCard key={p.id} product={p} variant="grid" />
            ))}
          </div>
        )}
      </div>

      {/* End of list cap */}
      {filteredProducts.length > 0 && (
        <div className="text-center py-6 text-xs text-[var(--faint)] font-medium">
          🌱 You've reached the end of today's harvest
        </div>
      )}

      {/* Filter Bottom Sheet */}
      {isFilterOpen && (
        <div className="fixed inset-0 z-50 bg-black/40 flex justify-end flex-col animate-fade-in">
          <div className="bg-[var(--surface)] rounded-t-[24px] p-5 max-w-[440px] w-full mx-auto border-t border-[var(--border)] shadow-2xl">
            <div className="flex items-center justify-between pb-3 border-b border-[var(--border)]">
              <h3 className="font-bold text-base text-[var(--ink)]">Filter Catalog</h3>
              <button onClick={() => setIsFilterOpen(false)}>
                <X className="w-5 h-5 text-[var(--muted)]" />
              </button>
            </div>

            <div className="py-4 space-y-4">
              {/* Veg Only Toggle */}
              <div className="flex items-center justify-between p-3 rounded-xl bg-[var(--sunken)]">
                <div>
                  <h4 className="text-xs font-bold text-[var(--ink)]">Vegetarian Only</h4>
                  <p className="text-[11px] text-[var(--muted)]">Show strictly plant-based produce</p>
                </div>
                <button
                  onClick={() => setOnlyVeg(!onlyVeg)}
                  className={`w-11 h-6 rounded-full p-0.5 transition-colors ${
                    onlyVeg ? 'bg-[var(--primary)]' : 'bg-[var(--border-strong)]'
                  }`}
                >
                  <div
                    className={`w-5 h-5 rounded-full bg-white transition-transform ${
                      onlyVeg ? 'translate-x-5' : 'translate-x-0'
                    }`}
                  />
                </button>
              </div>

              {/* In-Stock Only Toggle */}
              <div className="flex items-center justify-between p-3 rounded-xl bg-[var(--sunken)]">
                <div>
                  <h4 className="text-xs font-bold text-[var(--ink)]">In Stock Immediately</h4>
                  <p className="text-[11px] text-[var(--muted)]">Items ready at dark store #4</p>
                </div>
                <button
                  onClick={() => setInStockOnly(!inStockOnly)}
                  className={`w-11 h-6 rounded-full p-0.5 transition-colors ${
                    inStockOnly ? 'bg-[var(--primary)]' : 'bg-[var(--border-strong)]'
                  }`}
                >
                  <div
                    className={`w-5 h-5 rounded-full bg-white transition-transform ${
                      inStockOnly ? 'translate-x-5' : 'translate-x-0'
                    }`}
                  />
                </button>
              </div>

              {/* Dietary Lifestyles */}
              <div>
                <label className="text-xs font-bold text-[var(--ink)] block mb-2">
                  Dietary & Farm Certifications
                </label>
                <div className="flex flex-wrap gap-1.5">
                  {['Organic', 'Gluten-Free', 'Vegan', 'Cold-Pressed'].map(tag => {
                    const isSelected = selectedDietary.includes(tag);
                    return (
                      <button
                        key={tag}
                        type="button"
                        onClick={() => toggleDietary(tag)}
                        className={`px-3 py-1.5 rounded-full text-xs font-semibold border transition-all ${
                          isSelected
                            ? 'bg-[var(--primary-tint)] border-[var(--primary)] text-[var(--primary)]'
                            : 'bg-[var(--sunken)] border-[var(--border)] text-[var(--muted)] hover:text-[var(--ink)]'
                        }`}
                      >
                        {tag}
                      </button>
                    );
                  })}
                </div>
              </div>
            </div>

            <div className="flex gap-2 pt-2">
              <button
                onClick={() => {
                  setOnlyVeg(false);
                  setInStockOnly(true);
                  setIsFilterOpen(false);
                }}
                className="flex-1 py-3 rounded-xl border border-[var(--border-strong)] text-xs font-bold text-[var(--ink)]"
              >
                Clear All
              </button>
              <button
                onClick={() => setIsFilterOpen(false)}
                className="flex-1 py-3 rounded-xl bg-[var(--primary)] text-white text-xs font-bold"
              >
                Apply Filters
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Sort Bottom Sheet */}
      {isSortOpen && (
        <div className="fixed inset-0 z-50 bg-black/40 flex justify-end flex-col animate-fade-in">
          <div className="bg-[var(--surface)] rounded-t-[24px] p-5 max-w-[440px] w-full mx-auto border-t border-[var(--border)] shadow-2xl">
            <div className="flex items-center justify-between pb-3 border-b border-[var(--border)]">
              <h3 className="font-bold text-base text-[var(--ink)]">Sort Catalog</h3>
              <button onClick={() => setIsSortOpen(false)}>
                <X className="w-5 h-5 text-[var(--muted)]" />
              </button>
            </div>

            <div className="py-2 divide-y divide-[var(--border)]/60">
              {[
                { id: 'relevance', label: 'Recommended / Relevance' },
                { id: 'rating', label: 'Highest Rated' },
                { id: 'price_asc', label: 'Price: Low to High' },
                { id: 'price_desc', label: 'Price: High to Low' },
              ].map(opt => (
                <button
                  key={opt.id}
                  onClick={() => {
                    setSortBy(opt.id as any);
                    setIsSortOpen(false);
                  }}
                  className="w-full py-3.5 flex items-center justify-between text-xs font-semibold text-[var(--ink)] hover:text-[var(--primary)]"
                >
                  <span>{opt.label}</span>
                  {sortBy === opt.id && <Check className="w-4 h-4 text-[var(--primary)]" />}
                </button>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
