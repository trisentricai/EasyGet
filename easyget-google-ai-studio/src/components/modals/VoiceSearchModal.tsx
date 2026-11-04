import React, { useState, useEffect } from 'react';
import {
  X,
  Mic,
  Sparkles,
  Search,
} from 'lucide-react';

interface VoiceSearchModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSelectQuery: (query: string) => void;
}

export const VoiceSearchModal: React.FC<VoiceSearchModalProps> = ({
  isOpen,
  onClose,
  onSelectQuery,
}) => {
  const [listening, setListening] = useState(true);

  if (!isOpen) return null;

  const sampleVoices = [
    'Organic Hass Avocado',
    'A2 Gir Cow Milk',
    'Country Sourdough Loaf',
    'Wood Pressed Sesame Oil',
    'Tender Coconut Water',
  ];

  return (
    <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-xs flex items-center justify-center p-4 animate-fade-in">
      <div className="w-full max-w-sm bg-[var(--surface)] rounded-[32px] border border-[var(--border)] p-6 text-center shadow-2xl relative">
        <button
          onClick={onClose}
          className="absolute top-4 right-4 w-8 h-8 rounded-full flex items-center justify-center text-[var(--muted)] hover:bg-[var(--sunken)]"
        >
          <X className="w-4 h-4" />
        </button>

        {/* Animated Mic Wave */}
        <div className="relative my-6 flex items-center justify-center">
          <div className="absolute w-28 h-28 rounded-full bg-[var(--primary)]/20 animate-ping" />
          <div className="absolute w-20 h-20 rounded-full bg-[var(--primary)]/30 animate-pulse" />
          <div className="relative z-10 w-16 h-16 rounded-full bg-[var(--primary)] text-white flex items-center justify-center shadow-lg">
            <Mic className="w-8 h-8 animate-bounce" />
          </div>
        </div>

        <h3 className="font-display font-semibold text-xl text-[var(--ink)] mb-1">
          Listening to your voice...
        </h3>
        <p className="text-xs text-[var(--muted)] max-w-xs mx-auto mb-6">
          Say any grocery, fruit, farm dairy item or tap a quick query below:
        </p>

        {/* Suggestion speech bubbles */}
        <div className="space-y-1.5">
          {sampleVoices.map(item => (
            <button
              key={item}
              onClick={() => {
                onSelectQuery(item);
                onClose();
              }}
              className="w-full py-2.5 px-3.5 rounded-xl bg-[var(--sunken)]/70 hover:bg-[var(--primary-tint)] hover:text-[var(--primary)] border border-[var(--border)] text-xs font-semibold text-[var(--ink)] text-left flex items-center justify-between transition-colors group"
            >
              <span>"{item}"</span>
              <Search className="w-3.5 h-3.5 text-[var(--muted)] group-hover:text-[var(--primary)]" />
            </button>
          ))}
        </div>
      </div>
    </div>
  );
};
