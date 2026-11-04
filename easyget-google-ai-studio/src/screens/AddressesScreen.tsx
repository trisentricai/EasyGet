import React, { useState } from 'react';
import {
  MapPin,
  Plus,
  Check,
  Trash2,
  X,
  Home,
  Briefcase,
  Building,
} from 'lucide-react';
import { useApp } from '../context/AppContext';
import { Header } from '../components/common/Header';
import { Address } from '../types';

export const AddressesScreen: React.FC = () => {
  const {
    addresses,
    selectedAddress,
    setSelectedAddress,
    addAddress,
    navigate,
  } = useApp();

  const [isAddOpen, setIsAddOpen] = useState(false);
  const [type, setType] = useState<'Home' | 'Work' | 'Other'>('Home');
  const [label, setLabel] = useState('Home · Flat 101');
  const [street, setStreet] = useState('');
  const [area, setArea] = useState('Koramangala 4th Block');
  const [city, setCity] = useState('Bengaluru');
  const [pincode, setPincode] = useState('560034');
  const [phone, setPhone] = useState('+91 98450 12890');

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    if (!street) return;

    addAddress({
      type,
      label,
      street,
      area,
      city,
      pincode,
      phone,
      isDefault: false,
    });

    setStreet('');
    setIsAddOpen(false);
  };

  return (
    <div className="pb-24 bg-[var(--canvas)] min-h-screen">
      <Header showBack title="Saved Delivery Addresses" />

      <div className="p-4 space-y-3">
        <button
          onClick={() => setIsAddOpen(true)}
          className="w-full h-12 rounded-2xl border-2 border-dashed border-[var(--primary)] text-[var(--primary)] text-xs font-bold flex items-center justify-center gap-2 hover:bg-[var(--primary-tint)]/40 transition-colors"
        >
          <Plus className="w-4 h-4 stroke-[2.5]" />
          Add New Delivery Address
        </button>

        {addresses.map(addr => {
          const isSelected = selectedAddress.id === addr.id;
          return (
            <div
              key={addr.id}
              onClick={() => setSelectedAddress(addr)}
              className={`p-4 rounded-2xl border transition-all cursor-pointer ${
                isSelected
                  ? 'border-[var(--primary)] bg-[var(--surface)] shadow-xs ring-1 ring-[var(--primary)]/30'
                  : 'border-[var(--border)] bg-[var(--surface)] hover:border-[var(--border-strong)]'
              }`}
            >
              <div className="flex items-start justify-between">
                <div className="flex items-center gap-2">
                  <div
                    className={`w-7 h-7 rounded-lg flex items-center justify-center ${
                      isSelected
                        ? 'bg-[var(--primary-tint)] text-[var(--primary)]'
                        : 'bg-[var(--sunken)] text-[var(--muted)]'
                    }`}
                  >
                    {addr.type === 'Home' ? (
                      <Home className="w-3.5 h-3.5" />
                    ) : addr.type === 'Work' ? (
                      <Briefcase className="w-3.5 h-3.5" />
                    ) : (
                      <Building className="w-3.5 h-3.5" />
                    )}
                  </div>
                  <div>
                    <span className="text-xs font-bold text-[var(--ink)] block">
                      {addr.label}
                    </span>
                    <span className="text-[10px] font-semibold text-[var(--primary)] uppercase tracking-wider">
                      {addr.type}
                    </span>
                  </div>
                </div>

                <div className="flex items-center gap-2">
                  {isSelected && (
                    <span className="inline-flex items-center gap-1 text-[10px] font-bold text-[var(--primary)] bg-[var(--primary-tint)] px-2 py-0.5 rounded-full">
                      <Check className="w-3 h-3 stroke-[3]" />
                      Selected
                    </span>
                  )}
                </div>
              </div>

              <p className="text-xs text-[var(--muted)] mt-2 leading-relaxed">
                {addr.street}, {addr.area}, {addr.city} - {addr.pincode}
              </p>
              <p className="text-[11px] text-[var(--faint)] font-mono mt-1">
                Phone: {addr.phone}
              </p>
            </div>
          );
        })}
      </div>

      {/* Add Address Modal Sheet */}
      {isAddOpen && (
        <div className="fixed inset-0 z-50 bg-black/40 flex justify-end flex-col animate-fade-in">
          <div className="bg-[var(--surface)] rounded-t-[24px] p-5 max-w-[440px] w-full mx-auto border-t border-[var(--border)] shadow-2xl max-h-[85vh] overflow-y-auto">
            <div className="flex items-center justify-between pb-3 border-b border-[var(--border)] mb-4">
              <h3 className="font-bold text-base text-[var(--ink)]">New Delivery Address</h3>
              <button onClick={() => setIsAddOpen(false)}>
                <X className="w-5 h-5 text-[var(--muted)]" />
              </button>
            </div>

            <form onSubmit={handleSave} className="space-y-3 text-xs">
              {/* Type pills */}
              <div>
                <label className="font-bold text-[var(--ink)] block mb-1.5">Address Type</label>
                <div className="flex gap-2">
                  {(['Home', 'Work', 'Other'] as const).map(t => (
                    <button
                      key={t}
                      type="button"
                      onClick={() => setType(t)}
                      className={`flex-1 py-2 rounded-xl font-bold border transition-all ${
                        type === t
                          ? 'bg-[var(--primary-tint)] border-[var(--primary)] text-[var(--primary)]'
                          : 'bg-[var(--sunken)] border-[var(--border)] text-[var(--muted)]'
                      }`}
                    >
                      {t}
                    </button>
                  ))}
                </div>
              </div>

              <div>
                <label className="font-bold text-[var(--ink)] block mb-1">Address Label</label>
                <input
                  type="text"
                  required
                  value={label}
                  onChange={e => setLabel(e.target.value)}
                  placeholder="e.g. Home, Office, Mom's Place"
                  className="w-full h-11 px-3 rounded-xl bg-[var(--sunken)] border border-[var(--border-strong)] text-[var(--ink)] focus:outline-none focus:border-[var(--primary)]"
                />
              </div>

              <div>
                <label className="font-bold text-[var(--ink)] block mb-1">House / Flat / Street</label>
                <input
                  type="text"
                  required
                  value={street}
                  onChange={e => setStreet(e.target.value)}
                  placeholder="Flat 302, Palm Meadows, 4th Cross"
                  className="w-full h-11 px-3 rounded-xl bg-[var(--sunken)] border border-[var(--border-strong)] text-[var(--ink)] focus:outline-none focus:border-[var(--primary)]"
                />
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="font-bold text-[var(--ink)] block mb-1">Area / Locality</label>
                  <input
                    type="text"
                    required
                    value={area}
                    onChange={e => setArea(e.target.value)}
                    className="w-full h-11 px-3 rounded-xl bg-[var(--sunken)] border border-[var(--border-strong)] text-[var(--ink)] focus:outline-none focus:border-[var(--primary)]"
                  />
                </div>
                <div>
                  <label className="font-bold text-[var(--ink)] block mb-1">Pincode</label>
                  <input
                    type="text"
                    required
                    value={pincode}
                    onChange={e => setPincode(e.target.value)}
                    className="w-full h-11 px-3 rounded-xl bg-[var(--sunken)] border border-[var(--border-strong)] text-[var(--ink)] focus:outline-none focus:border-[var(--primary)] font-mono"
                  />
                </div>
              </div>

              <div>
                <label className="font-bold text-[var(--ink)] block mb-1">Phone Number for Delivery</label>
                <input
                  type="tel"
                  required
                  value={phone}
                  onChange={e => setPhone(e.target.value)}
                  className="w-full h-11 px-3 rounded-xl bg-[var(--sunken)] border border-[var(--border-strong)] text-[var(--ink)] focus:outline-none focus:border-[var(--primary)] font-mono"
                />
              </div>

              <div className="pt-2">
                <button
                  type="submit"
                  className="w-full h-12 rounded-xl bg-[var(--primary)] text-white font-bold text-sm shadow-md"
                >
                  Save Delivery Address
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
