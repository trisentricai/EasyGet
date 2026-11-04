import React, { useState } from 'react';
import {
  X,
  Star,
  CheckCircle2,
  Sparkles,
  Bike,
  Heart,
} from 'lucide-react';
import { Order } from '../../types';

interface RateOrderModalProps {
  isOpen: boolean;
  onClose: () => void;
  order: Order;
  onSubmit: (review: { rating: number; tags: string[]; text: string }, driverRating: number) => void;
}

export const RateOrderModal: React.FC<RateOrderModalProps> = ({
  isOpen,
  onClose,
  order,
  onSubmit,
}) => {
  const [productRating, setProductRating] = useState(5);
  const [driverRating, setDriverRating] = useState(5);
  const [selectedTags, setSelectedTags] = useState<string[]>(['Super Fresh Produce', '10-Min Delivery']);
  const [comment, setComment] = useState('');

  if (!isOpen) return null;

  const availableTags = [
    'Super Fresh Produce',
    'Crisp Packaging',
    '10-Min Fast Delivery',
    'Polite Rider',
    'Perfect Ripeness',
    'Zero Plastic Used',
  ];

  const toggleTag = (tag: string) => {
    setSelectedTags(prev =>
      prev.includes(tag) ? prev.filter(t => t !== tag) : [...prev, tag]
    );
  };

  const handleSubmit = () => {
    onSubmit(
      {
        rating: productRating,
        tags: selectedTags,
        text: comment,
      },
      driverRating
    );
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex justify-end flex-col animate-fade-in">
      <div className="w-full max-w-[440px] mx-auto bg-[var(--surface)] rounded-t-[28px] border-t border-[var(--border)] overflow-hidden flex flex-col shadow-2xl max-h-[90vh]">
        {/* Handle */}
        <div className="pt-2 pb-1 flex justify-center">
          <div className="w-12 h-1.5 rounded-full bg-[var(--border-strong)]" />
        </div>

        {/* Header */}
        <div className="px-5 py-3 border-b border-[var(--border)] flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-full bg-[var(--marigold-wash)] text-[var(--marigold)] flex items-center justify-center">
              <Star className="w-4 h-4 fill-[var(--marigold)]" />
            </div>
            <div>
              <h3 className="text-sm font-bold text-[var(--ink)]">Rate Harvest & Delivery</h3>
              <p className="text-[11px] text-[var(--muted)]">Order #{order.id}</p>
            </div>
          </div>
          <button onClick={onClose} className="w-8 h-8 rounded-full flex items-center justify-center text-[var(--muted)] hover:bg-[var(--sunken)]">
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Body */}
        <div className="p-4 space-y-4 overflow-y-auto">
          {/* Section 1: Produce Quality Rating */}
          <div className="p-4 rounded-2xl bg-[var(--sunken)]/60 border border-[var(--border)] text-center">
            <span className="text-xs font-bold text-[var(--ink)] block mb-1">
              How was the freshness of today's harvest?
            </span>
            <div className="flex justify-center gap-2 py-2">
              {[1, 2, 3, 4, 5].map(star => (
                <button
                  key={star}
                  onClick={() => setProductRating(star)}
                  className="p-1 active:scale-125 transition-transform"
                >
                  <Star
                    className={`w-7 h-7 ${
                      star <= productRating
                        ? 'fill-[var(--marigold)] text-[var(--marigold)]'
                        : 'text-[var(--border-strong)]'
                    }`}
                  />
                </button>
              ))}
            </div>
            <span className="text-[11px] font-semibold text-[var(--primary)]">
              {productRating === 5 ? 'Farm-fresh perfection!' : productRating >= 4 ? 'Great quality' : 'Needs attention'}
            </span>
          </div>

          {/* Section 2: Delivery Partner Rating */}
          <div className="p-3.5 rounded-2xl bg-[var(--surface)] border border-[var(--border)] flex items-center justify-between">
            <div className="flex items-center gap-2.5">
              <div className="w-9 h-9 rounded-full bg-[var(--primary-tint)] flex items-center justify-center text-[var(--primary)]">
                <Bike className="w-4 h-4" />
              </div>
              <div>
                <span className="text-xs font-bold text-[var(--ink)] block">
                  Ravi Kumar (Delivery Rider)
                </span>
                <span className="text-[10px] text-[var(--muted)]">Doorstep handover & speed</span>
              </div>
            </div>
            <div className="flex gap-1">
              {[1, 2, 3, 4, 5].map(s => (
                <button key={s} onClick={() => setDriverRating(s)}>
                  <Star
                    className={`w-4 h-4 ${
                      s <= driverRating ? 'fill-[var(--marigold)] text-[var(--marigold)]' : 'text-neutral-300'
                    }`}
                  />
                </button>
              ))}
            </div>
          </div>

          {/* Section 3: Tag Badges */}
          <div>
            <label className="text-xs font-bold text-[var(--ink)] block mb-2">
              What did you love most?
            </label>
            <div className="flex flex-wrap gap-1.5">
              {availableTags.map(tag => {
                const isSelected = selectedTags.includes(tag);
                return (
                  <button
                    key={tag}
                    onClick={() => toggleTag(tag)}
                    className={`px-3 py-1.5 rounded-full text-xs font-semibold transition-all border ${
                      isSelected
                        ? 'bg-[var(--primary-tint)] border-[var(--primary)] text-[var(--primary)]'
                        : 'bg-[var(--surface)] border-[var(--border)] text-[var(--muted)] hover:text-[var(--ink)]'
                    }`}
                  >
                    {tag}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Section 4: Comment Textarea */}
          <div>
            <label className="text-xs font-bold text-[var(--ink)] block mb-1">
              Additional Feedback (Optional)
            </label>
            <textarea
              value={comment}
              onChange={e => setComment(e.target.value)}
              placeholder="Tell our farmer collectives what you thought of the avocados, milk, and breads..."
              className="w-full h-20 p-3 rounded-xl bg-[var(--sunken)] border border-[var(--border-strong)] text-xs text-[var(--ink)] focus:outline-none focus:border-[var(--primary)] resize-none"
            />
          </div>

          {/* Submit CTA */}
          <button
            onClick={handleSubmit}
            className="w-full h-[52px] rounded-2xl bg-[var(--primary)] hover:bg-[var(--primary-dark)] text-white font-bold text-sm shadow-md active:scale-95 transition-all"
          >
            Submit Feedback & Earn 20 Coins
          </button>
        </div>
      </div>
    </div>
  );
};
