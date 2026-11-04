import React, { useState, useMemo } from 'react';
import { Search, X, TrendingUp, History, Clock, Mic } from 'lucide-react';
import { useApp } from '../context/AppContext';
import { ProductCard } from '../components/common/ProductCard';
import { VoiceSearchModal } from '../components/modals/VoiceSearchModal';
import { PRODUCTS } from '../data/mockData';

export const SearchScreen: React.FC = () => {
  const { searchQuery, setSearchQuery } = useApp();
  const [query, setQuery] = useState(searchQuery || '');
  const [isVoiceOpen, setIsVoiceOpen] = useState(false);
  const [history, setHistory] = useState<string[]>([
    'Avocado',
    'A2 Gir Cow Milk',
    'Sourdough',
    'Honey',
  ]);

  const trendingQueries = [
    'Organic Hass Avocado',
    'Cold Pressed Sesame Oil',
    'Raw Honey Nilgiris',
    'Hydroponic Cherry Tomato',
    'Tender Coconut Water',
  ];

  const searchResults = useMemo(() => {
    if (!query.trim()) return [];
    const q = query.toLowerCase().trim();
    return PRODUCTS.filter(
      p =>
        p.name.toLowerCase().includes(q) ||
        p.category.toLowerCase().includes(q) ||
        p.description.toLowerCase().includes(q) ||
        p.origin.toLowerCase().includes(q)
    );
  }, [query]);

  const handleSelectQuery = (text: string) => {
    setQuery(text);
    setSearchQuery(text);
    if (!history.includes(text)) {
      setHistory(prev => [text, ...prev.slice(0, 5)]);
    }
  };

  const clearHistoryItem = (item: string) => {
    setHistory(prev => prev.filter(h => h !== item));
  };

  return (
    <div className="pb-24 bg-[var(--canvas)] min-h-screen">
      {/* Search Input Bar */}
      <div className="sticky top-0 z-30 bg-[var(--surface)] border-b border-[var(--border)] p-3">
        <div className="relative flex items-center">
          <Search className="w-4 h-4 text-[var(--primary)] absolute left-3.5" />
          <input
            type="text"
            autoFocus
            value={query}
            onChange={e => {
              setQuery(e.target.value);
              setSearchQuery(e.target.value);
            }}
            placeholder="Search produce, farm dairy, artisan bakes..."
            className="w-full h-12 pl-10 pr-20 rounded-2xl bg-[var(--sunken)] border border-[var(--border-strong)] text-sm text-[var(--ink)] focus:outline-none focus:border-[var(--primary)] placeholder:text-[var(--faint)]"
          />
          <div className="absolute right-2.5 flex items-center gap-1">
            {query ? (
              <button
                onClick={() => {
                  setQuery('');
                  setSearchQuery('');
                }}
                aria-label="Clear search"
                className="w-7 h-7 rounded-full bg-[var(--border-strong)] text-[var(--ink)] flex items-center justify-center hover:bg-[var(--border)]"
              >
                <X className="w-3.5 h-3.5" />
              </button>
            ) : null}
            <button
              type="button"
              onClick={() => setIsVoiceOpen(true)}
              aria-label="Voice Search"
              className="w-8 h-8 rounded-full bg-[var(--primary-tint)] text-[var(--primary)] flex items-center justify-center hover:bg-[var(--primary)] hover:text-white transition-colors"
            >
              <Mic className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* Main Content Area */}
      <div className="p-4">
        {query.trim() === '' ? (
          <div className="space-y-6">
            {/* Recent Searches */}
            {history.length > 0 && (
              <div>
                <div className="flex items-center justify-between mb-2.5">
                  <span className="text-xs font-bold text-[var(--ink)] flex items-center gap-1.5">
                    <History className="w-3.5 h-3.5 text-[var(--muted)]" />
                    Recent Searches
                  </span>
                  <button
                    onClick={() => setHistory([])}
                    className="text-[11px] text-[var(--muted)] hover:text-[var(--ink)]"
                  >
                    Clear all
                  </button>
                </div>
                <div className="flex flex-wrap gap-2">
                  {history.map(item => (
                    <div
                      key={item}
                      className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-[var(--surface)] border border-[var(--border)] text-xs text-[var(--ink)] shadow-2xs hover:border-[var(--border-strong)]"
                    >
                      <button
                        onClick={() => handleSelectQuery(item)}
                        className="font-medium hover:text-[var(--primary)] text-left"
                      >
                        {item}
                      </button>
                      <button
                        onClick={() => clearHistoryItem(item)}
                        className="text-[var(--faint)] hover:text-[var(--ink)]"
                      >
                        <X className="w-3 h-3" />
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Trending Searches */}
            <div>
              <div className="flex items-center gap-1.5 mb-2.5 text-xs font-bold text-[var(--ink)]">
                <TrendingUp className="w-3.5 h-3.5 text-[var(--marigold)]" />
                Trending on EASYGET
              </div>
              <div className="space-y-1.5">
                {trendingQueries.map((t, idx) => (
                  <button
                    key={t}
                    onClick={() => handleSelectQuery(t)}
                    className="w-full p-2.5 rounded-xl bg-[var(--surface)] border border-[var(--border)] flex items-center justify-between text-left hover:border-[var(--primary)] transition-colors group"
                  >
                    <div className="flex items-center gap-2.5">
                      <span className="text-xs font-bold text-[var(--muted)] tnum w-4">
                        0{idx + 1}
                      </span>
                      <span className="text-xs font-semibold text-[var(--ink)] group-hover:text-[var(--primary)]">
                        {t}
                      </span>
                    </div>
                    <span className="text-[10px] text-[var(--primary)] font-bold bg-[var(--primary-tint)] px-2 py-0.5 rounded-full">
                      12 MIN
                    </span>
                  </button>
                ))}
              </div>
            </div>

            {/* Recommended Fresh Picks Rail */}
            <div className="pt-2">
              <span className="text-xs font-bold text-[var(--ink)] block mb-2.5">
                Popular in Your Neighborhood
              </span>
              <div className="grid grid-cols-2 gap-3">
                {PRODUCTS.slice(0, 4).map(p => (
                  <ProductCard key={p.id} product={p} variant="grid" />
                ))}
              </div>
            </div>
          </div>
        ) : (
          <div>
            {/* Results Header */}
            <div className="flex items-center justify-between mb-3 text-xs">
              <span className="font-semibold text-[var(--muted)]">
                Results for "<span className="font-bold text-[var(--ink)]">{query}</span>"
              </span>
              <span className="font-bold text-[var(--primary)] tnum">
                {searchResults.length} match{searchResults.length !== 1 ? 'es' : ''}
              </span>
            </div>

            {searchResults.length === 0 ? (
              <div className="py-14 text-center bg-[var(--surface)] border border-[var(--border)] rounded-2xl p-6">
                <div className="w-12 h-12 rounded-full bg-[var(--sunken)] flex items-center justify-center mx-auto text-[var(--muted)] mb-3">
                  <Search className="w-6 h-6" />
                </div>
                <h3 className="font-bold text-sm text-[var(--ink)]">No items found for "{query}"</h3>
                <p className="text-xs text-[var(--muted)] mt-1 mb-4">
                  Check the spelling or try searching generic terms like "milk", "avocado", or "bread".
                </p>
                <button
                  onClick={() => setQuery('')}
                  className="px-4 py-2 rounded-xl bg-[var(--primary)] text-white text-xs font-bold"
                >
                  View All Produce
                </button>
              </div>
            ) : (
              <div className="grid grid-cols-2 gap-3">
                {searchResults.map(p => (
                  <ProductCard key={p.id} product={p} variant="grid" />
                ))}
              </div>
            )}
          </div>
        )}
      </div>

      {/* Voice Search Modal */}
      <VoiceSearchModal
        isOpen={isVoiceOpen}
        onClose={() => setIsVoiceOpen(false)}
        onSelectQuery={selected => handleSelectQuery(selected)}
      />
    </div>
  );
};
