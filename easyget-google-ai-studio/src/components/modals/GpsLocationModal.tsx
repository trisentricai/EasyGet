import React, { useState } from 'react';
import {
  MapPin,
  Navigation,
  X,
  Search,
  CheckCircle2,
  Clock,
  Crosshair,
  Building,
} from 'lucide-react';
import { useApp } from '../../context/AppContext';

export const GpsLocationModal: React.FC = () => {
  const { isGpsModalOpen, setIsGpsModalOpen, updateLocationFromGps, selectedAddress } = useApp();
  const [isLocating, setIsLocating] = useState(false);
  const [selectedPin, setSelectedPin] = useState({
    area: 'HSR Layout Sector 4',
    street: '14th Main Rd, Green Glen Palms',
    pincode: '560102',
  });

  if (!isGpsModalOpen) return null;

  const handleUseCurrentLocation = () => {
    setIsLocating(true);
    setTimeout(() => {
      setIsLocating(false);
      setSelectedPin({
        area: 'Indiranagar 100ft Road',
        street: 'Flat 302, Palm Vista, 12th Cross',
        pincode: '560038',
      });
    }, 700);
  };

  const handleConfirmLocation = () => {
    updateLocationFromGps(selectedPin);
  };

  return (
    <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex justify-end flex-col animate-fade-in">
      <div className="w-full max-w-[440px] mx-auto bg-[var(--surface)] rounded-t-[28px] border-t border-[var(--border)] overflow-hidden flex flex-col shadow-2xl max-h-[90vh]">
        {/* Handle */}
        <div className="pt-2 pb-1 flex justify-center">
          <div className="w-12 h-1.5 rounded-full bg-[var(--border-strong)]" />
        </div>

        {/* Modal Header */}
        <div className="px-5 py-3 border-b border-[var(--border)] flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-full bg-[var(--primary-tint)] flex items-center justify-center text-[var(--primary)]">
              <MapPin className="w-4 h-4" />
            </div>
            <div>
              <h3 className="text-sm font-bold text-[var(--ink)]">Select Delivery Location</h3>
              <p className="text-[11px] text-[var(--muted)]">10-14 min delivery radius</p>
            </div>
          </div>
          <button
            onClick={() => setIsGpsModalOpen(false)}
            className="w-8 h-8 rounded-full flex items-center justify-center text-[var(--muted)] hover:bg-[var(--sunken)]"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Interactive Map Visual Simulation */}
        <div className="relative w-full h-52 bg-[#E6ECE8] overflow-hidden border-b border-[var(--border)] select-none">
          {/* Simulated Street Grid SVG */}
          <svg className="w-full h-full opacity-40" xmlns="http://www.w3.org/2000/svg">
            <defs>
              <pattern id="grid" width="40" height="40" patternUnits="userSpaceOnUse">
                <path d="M 40 0 L 0 0 0 40" fill="none" stroke="#2D5A45" strokeWidth="1" />
              </pattern>
            </defs>
            <rect width="100%" height="100%" fill="url(#grid)" />
            {/* Roads */}
            <path d="M 0 60 Q 200 120 440 80" stroke="#FFF" strokeWidth="14" fill="none" />
            <path d="M 120 0 L 160 220" stroke="#FFF" strokeWidth="10" fill="none" />
            <path d="M 280 0 L 260 220" stroke="#FFF" strokeWidth="12" fill="none" />
          </svg>

          {/* Central Pulsing Delivery Pin */}
          <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
            <div className="relative flex items-center justify-center">
              {/* Pulse waves */}
              <div className="absolute w-16 h-16 rounded-full bg-[var(--primary)]/20 animate-ping" />
              <div className="absolute w-10 h-10 rounded-full bg-[var(--primary)]/30" />
              {/* Pin icon */}
              <div className="relative z-10 w-10 h-10 rounded-full bg-[var(--primary)] text-white flex items-center justify-center shadow-lg transform -translate-y-2">
                <MapPin className="w-5 h-5 fill-white" />
              </div>
            </div>
          </div>

          {/* Current GPS Trigger Button */}
          <button
            onClick={handleUseCurrentLocation}
            className="absolute bottom-3 right-3 bg-[var(--surface)] text-[var(--ink)] text-xs font-bold px-3 py-2 rounded-xl border border-[var(--border)] shadow-md flex items-center gap-1.5 hover:bg-[var(--sunken)] active:scale-95 transition-all"
          >
            <Crosshair className={`w-4 h-4 text-[var(--primary)] ${isLocating ? 'animate-spin' : ''}`} />
            <span>{isLocating ? 'Detecting GPS...' : 'Locate Me'}</span>
          </button>

          {/* ETA Badge on Map */}
          <div className="absolute top-3 left-3 bg-[var(--surface)]/95 backdrop-blur-xs px-2.5 py-1 rounded-full border border-[var(--border)] shadow-xs flex items-center gap-1.5">
            <Clock className="w-3.5 h-3.5 text-[var(--marigold)]" />
            <span className="text-[11px] font-bold text-[var(--ink)] tnum">12 Min Delivery Hub #04</span>
          </div>
        </div>

        {/* Selected Location Address Details */}
        <div className="p-4 space-y-3">
          <div className="p-3.5 rounded-2xl bg-[var(--sunken)]/60 border border-[var(--border)]">
            <div className="flex items-center justify-between mb-1">
              <span className="text-xs font-bold text-[var(--ink)] flex items-center gap-1">
                <Building className="w-3.5 h-3.5 text-[var(--primary)]" />
                {selectedPin.area}
              </span>
              <span className="text-[10px] font-bold text-[var(--primary)] bg-[var(--primary-tint)] px-2 py-0.5 rounded-full">
                SERVICEABLE
              </span>
            </div>
            <p className="text-xs text-[var(--muted)] leading-relaxed">
              {selectedPin.street}, Bengaluru - {selectedPin.pincode}
            </p>
          </div>

          {/* Quick preset locations */}
          <div>
            <span className="text-[11px] font-bold text-[var(--muted)] uppercase tracking-wider block mb-2">
              Popular Delivery Areas
            </span>
            <div className="grid grid-cols-2 gap-2">
              {[
                { area: 'HSR Layout Sector 4', street: '14th Main Rd, Green Glen Palms', pincode: '560102' },
                { area: 'Indiranagar 100ft Rd', street: '12th Cross, Near Metro', pincode: '560038' },
                { area: 'Koramangala 4th Block', street: '80 Feet Rd, 5th Cross', pincode: '560034' },
                { area: 'Bellandur EcoSpace', street: 'Outer Ring Rd, Tech Park', pincode: '560103' },
              ].map(loc => (
                <button
                  key={loc.area}
                  onClick={() => setSelectedPin(loc)}
                  className={`p-2.5 rounded-xl border text-left text-xs transition-all ${
                    selectedPin.area === loc.area
                      ? 'border-[var(--primary)] bg-[var(--primary-tint)]/40 font-bold text-[var(--primary)]'
                      : 'border-[var(--border)] bg-[var(--surface)] text-[var(--ink)] hover:bg-[var(--sunken)]'
                  }`}
                >
                  <span className="block truncate">{loc.area}</span>
                  <span className="text-[10px] text-[var(--muted)] font-normal font-mono">{loc.pincode}</span>
                </button>
              ))}
            </div>
          </div>

          <div className="pt-2">
            <button
              onClick={handleConfirmLocation}
              className="w-full h-[52px] rounded-2xl bg-[var(--primary)] hover:bg-[var(--primary-dark)] text-white font-bold text-sm shadow-md flex items-center justify-center gap-2 active:scale-95 transition-all"
            >
              <CheckCircle2 className="w-4 h-4" />
              Confirm Delivery Location
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
