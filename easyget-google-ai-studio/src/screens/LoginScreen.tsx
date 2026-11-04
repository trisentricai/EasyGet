import React, { useState } from 'react';
import { Eye, EyeOff, ArrowLeft, Loader2, Mail, Lock } from 'lucide-react';
import { useApp } from '../context/AppContext';

export const LoginScreen: React.FC = () => {
  const { login, navigate } = useApp();
  const [email, setEmail] = useState('ananya.sharma@example.com');
  const [password, setPassword] = useState('pass1234');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError('');

    if (!email || !password) {
      setError('Please provide your email and password.');
      return;
    }

    if (password.length < 6) {
      setError('Password must be at least 6 characters.');
      return;
    }

    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      login(email);
    }, 700);
  };

  return (
    <div className="min-h-screen bg-[var(--canvas)] text-[var(--ink)] flex flex-col justify-between p-6">
      {/* Top Bar */}
      <div>
        <div className="flex items-center justify-between mb-8">
          <button
            onClick={() => navigate('home')}
            className="w-10 h-10 rounded-full flex items-center justify-center text-[var(--ink)] hover:bg-[var(--sunken)]"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
          <span className="text-xs font-semibold text-[var(--muted)]">Step 1 of 1</span>
        </div>

        {/* Brand Mark 72dp */}
        <div className="flex flex-col items-center text-center mb-8">
          <div className="w-[72px] h-[72px] rounded-2xl bg-[var(--brand)] text-[#FAF6EF] flex items-center justify-center font-display font-bold text-2xl shadow-lg mb-3">
            EG
          </div>
          <h2 className="font-display font-semibold text-2xl tracking-tight text-[var(--ink)]">
            Welcome back
          </h2>
          <p className="text-sm text-[var(--muted)] mt-1 max-w-[260px]">
            Log in to access your farm picks, active orders, and 10-minute delivery.
          </p>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="space-y-4 max-w-sm mx-auto">
          {error && (
            <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-xs font-medium">
              {error}
            </div>
          )}

          <div>
            <label className="block text-xs font-semibold text-[var(--ink)] mb-1.5">
              Email Address
            </label>
            <div className="relative">
              <Mail className="w-4 h-4 text-[var(--faint)] absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="email"
                value={email}
                onChange={e => setEmail(e.target.value)}
                placeholder="name@example.com"
                className="w-full h-12 pl-10 pr-4 rounded-xl bg-[var(--surface)] border border-[var(--border-strong)] text-sm text-[var(--ink)] focus:outline-none focus:border-[var(--primary)] transition-colors"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-[var(--ink)] mb-1.5">
              Password
            </label>
            <div className="relative">
              <Lock className="w-4 h-4 text-[var(--faint)] absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={e => setPassword(e.target.value)}
                placeholder="Enter your password"
                className="w-full h-12 pl-10 pr-11 rounded-xl bg-[var(--surface)] border border-[var(--border-strong)] text-sm text-[var(--ink)] focus:outline-none focus:border-[var(--primary)] transition-colors"
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3.5 top-1/2 -translate-y-1/2 text-[var(--muted)] hover:text-[var(--ink)]"
              >
                {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>
          </div>

          <div className="flex justify-end">
            <button
              type="button"
              className="text-xs font-semibold text-[var(--primary)] hover:underline"
            >
              Forgot password?
            </button>
          </div>

          {/* Primary CTA (54dp) */}
          <button
            type="submit"
            disabled={loading}
            className="w-full h-[54px] rounded-[16px] bg-[var(--primary)] hover:bg-[var(--primary-dark)] text-white font-bold text-base flex items-center justify-center transition-all active:scale-[0.98] shadow-md cursor-pointer"
          >
            {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : 'Sign in'}
          </button>
        </form>

        <div className="relative my-6 max-w-sm mx-auto text-center">
          <div className="absolute inset-0 flex items-center">
            <div className="w-full border-t border-[var(--border)]" />
          </div>
          <span className="relative bg-[var(--canvas)] px-3 text-xs text-[var(--faint)] uppercase font-semibold">
            or continue with
          </span>
        </div>

        {/* OTP Login and Guest Continue */}
        <div className="max-w-sm mx-auto space-y-2.5">
          <button
            type="button"
            onClick={() => navigate('otp_verify')}
            className="w-full h-12 rounded-[16px] border border-[var(--primary)] bg-[var(--primary-tint)]/40 text-[var(--primary)] font-bold text-xs flex items-center justify-center gap-2 hover:bg-[var(--primary-tint)] transition-colors"
          >
            <span>📱 Login via SMS / WhatsApp OTP</span>
          </button>

          <button
            type="button"
            onClick={() => navigate('home')}
            className="w-full h-12 rounded-[16px] border border-[var(--border-strong)] bg-[var(--surface)] text-[var(--ink)] font-semibold text-xs flex items-center justify-center hover:bg-[var(--sunken)] transition-colors"
          >
            Continue as Guest Shopper
          </button>
        </div>
      </div>

      {/* Footer link to Register */}
      <div className="text-center pt-6 pb-2">
        <p className="text-xs text-[var(--muted)]">
          New to EASYGET?{' '}
          <button
            onClick={() => navigate('register')}
            className="font-bold text-[var(--primary)] hover:underline"
          >
            Create an account
          </button>
        </p>
      </div>
    </div>
  );
};
