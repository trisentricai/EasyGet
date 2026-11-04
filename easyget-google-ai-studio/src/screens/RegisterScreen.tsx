import React, { useState } from 'react';
import { ArrowLeft, User, Mail, Lock, Phone, Loader2 } from 'lucide-react';
import { useApp } from '../context/AppContext';

export const RegisterScreen: React.FC = () => {
  const { setUser, navigate } = useApp();
  const [name, setName] = useState('Ananya Sharma');
  const [email, setEmail] = useState('ananya.sharma@example.com');
  const [phone, setPhone] = useState('+91 98450 12890');
  const [password, setPassword] = useState('securepass123');
  const [role, setRole] = useState<'Customer' | 'Merchant'>('Customer');
  const [loading, setLoading] = useState(false);

  const handleRegister = (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      setUser({ name, email, phone });
      navigate('home');
    }, 600);
  };

  return (
    <div className="min-h-screen bg-[var(--canvas)] text-[var(--ink)] flex flex-col justify-between p-6">
      <div>
        <div className="flex items-center justify-between mb-6">
          <button
            onClick={() => navigate('login')}
            className="w-10 h-10 rounded-full flex items-center justify-center text-[var(--ink)] hover:bg-[var(--sunken)]"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
          <span className="text-xs font-semibold text-[var(--muted)]">Join Fresh Market</span>
        </div>

        {/* Title */}
        <div className="text-center mb-6">
          <div className="w-14 h-14 mx-auto rounded-2xl bg-[var(--brand)] text-[#FAF6EF] flex items-center justify-center font-display font-bold text-xl shadow-md mb-2">
            EG
          </div>
          <h2 className="font-display font-semibold text-2xl tracking-tight text-[var(--ink)]">
            Create your account
          </h2>
          <p className="text-xs text-[var(--muted)] mt-1">
            Shop farm-direct produce delivered in 10-14 minutes
          </p>
        </div>

        {/* Form */}
        <form onSubmit={handleRegister} className="space-y-3.5 max-w-sm mx-auto">
          {/* Role selector segmented */}
          <div className="p-1 rounded-xl bg-[var(--sunken)] flex gap-1">
            <button
              type="button"
              onClick={() => setRole('Customer')}
              className={`flex-1 py-1.5 rounded-lg text-xs font-bold transition-all ${
                role === 'Customer'
                  ? 'bg-[var(--surface)] text-[var(--ink)] shadow-2xs'
                  : 'text-[var(--muted)] hover:text-[var(--ink)]'
              }`}
            >
              Shopper / Customer
            </button>
            <button
              type="button"
              onClick={() => setRole('Merchant')}
              className={`flex-1 py-1.5 rounded-lg text-xs font-bold transition-all ${
                role === 'Merchant'
                  ? 'bg-[var(--surface)] text-[var(--ink)] shadow-2xs'
                  : 'text-[var(--muted)] hover:text-[var(--ink)]'
              }`}
            >
              Artisan / Farm Merchant
            </button>
          </div>

          <div>
            <label className="block text-xs font-semibold text-[var(--ink)] mb-1">Full Name</label>
            <div className="relative">
              <User className="w-4 h-4 text-[var(--faint)] absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                required
                value={name}
                onChange={e => setName(e.target.value)}
                placeholder="Your name"
                className="w-full h-11 pl-10 pr-3 rounded-xl bg-[var(--surface)] border border-[var(--border-strong)] text-xs text-[var(--ink)] focus:outline-none focus:border-[var(--primary)]"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-[var(--ink)] mb-1">Email</label>
            <div className="relative">
              <Mail className="w-4 h-4 text-[var(--faint)] absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="email"
                required
                value={email}
                onChange={e => setEmail(e.target.value)}
                placeholder="name@example.com"
                className="w-full h-11 pl-10 pr-3 rounded-xl bg-[var(--surface)] border border-[var(--border-strong)] text-xs text-[var(--ink)] focus:outline-none focus:border-[var(--primary)]"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-[var(--ink)] mb-1">Mobile Phone</label>
            <div className="relative">
              <Phone className="w-4 h-4 text-[var(--faint)] absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="tel"
                value={phone}
                onChange={e => setPhone(e.target.value)}
                placeholder="+91 98450 12890"
                className="w-full h-11 pl-10 pr-3 rounded-xl bg-[var(--surface)] border border-[var(--border-strong)] text-xs text-[var(--ink)] focus:outline-none focus:border-[var(--primary)]"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-[var(--ink)] mb-1">Password</label>
            <div className="relative">
              <Lock className="w-4 h-4 text-[var(--faint)] absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="password"
                required
                value={password}
                onChange={e => setPassword(e.target.value)}
                placeholder="8+ characters"
                className="w-full h-11 pl-10 pr-3 rounded-xl bg-[var(--surface)] border border-[var(--border-strong)] text-xs text-[var(--ink)] focus:outline-none focus:border-[var(--primary)]"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full h-[52px] mt-4 rounded-[16px] bg-[var(--primary)] hover:bg-[var(--primary-dark)] text-white font-bold text-sm flex items-center justify-center transition-all active:scale-[0.98] shadow-md cursor-pointer"
          >
            {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : 'Create Account'}
          </button>
        </form>
      </div>

      <div className="text-center pt-4 pb-2">
        <p className="text-xs text-[var(--muted)]">
          Already registered?{' '}
          <button
            onClick={() => navigate('login')}
            className="font-bold text-[var(--primary)] hover:underline"
          >
            Sign in
          </button>
        </p>
      </div>
    </div>
  );
};
