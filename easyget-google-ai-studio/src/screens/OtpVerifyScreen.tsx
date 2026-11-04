import React, { useState, useEffect, useRef } from 'react';
import {
  ArrowLeft,
  ShieldCheck,
  RotateCcw,
  Smartphone,
  CheckCircle2,
} from 'lucide-react';
import { useApp } from '../context/AppContext';

export const OtpVerifyScreen: React.FC = () => {
  const { login, navigate } = useApp();
  const [otp, setOtp] = useState(['5', '8', '2', '9']);
  const [timer, setTimer] = useState(28);
  const [loading, setLoading] = useState(false);
  const inputRefs = [
    useRef<HTMLInputElement>(null),
    useRef<HTMLInputElement>(null),
    useRef<HTMLInputElement>(null),
    useRef<HTMLInputElement>(null),
  ];

  useEffect(() => {
    if (timer <= 0) return;
    const interval = setInterval(() => setTimer(prev => prev - 1), 1000);
    return () => clearInterval(interval);
  }, [timer]);

  const handleChange = (index: number, val: string) => {
    if (val.length > 1) val = val[val.length - 1];
    const newOtp = [...otp];
    newOtp[index] = val;
    setOtp(newOtp);

    // Auto advance
    if (val && index < 3) {
      inputRefs[index + 1].current?.focus();
    }
  };

  const handleKeyDown = (index: number, e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Backspace' && !otp[index] && index > 0) {
      inputRefs[index - 1].current?.focus();
    }
  };

  const handleVerify = () => {
    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      login('ananya.sharma@example.com');
    }, 600);
  };

  return (
    <div className="min-h-screen bg-[var(--canvas)] flex flex-col justify-between p-6 select-none">
      <div>
        <div className="flex items-center justify-between mb-8">
          <button
            onClick={() => navigate('login')}
            className="w-10 h-10 rounded-full flex items-center justify-center text-[var(--ink)] hover:bg-[var(--sunken)]"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>
          <span className="text-xs font-semibold text-[var(--muted)]">OTP Authentication</span>
        </div>

        <div className="text-center max-w-sm mx-auto mb-8">
          <div className="w-16 h-16 rounded-2xl bg-[var(--primary-tint)] text-[var(--primary)] mx-auto flex items-center justify-center mb-4 shadow-sm">
            <Smartphone className="w-8 h-8" />
          </div>
          <h2 className="font-display font-semibold text-2xl text-[var(--ink)]">
            Verify 4-Digit Code
          </h2>
          <p className="text-xs text-[var(--muted)] mt-1.5 leading-relaxed">
            We sent a verification SMS to{' '}
            <span className="font-bold font-mono text-[var(--ink)]">+91 98450 12890</span>
          </p>
        </div>

        {/* 4 Digit Boxes */}
        <div className="flex justify-center gap-3 max-w-xs mx-auto mb-6">
          {otp.map((digit, idx) => (
            <input
              key={idx}
              ref={inputRefs[idx]}
              type="text"
              inputMode="numeric"
              maxLength={1}
              value={digit}
              onChange={e => handleChange(idx, e.target.value)}
              onKeyDown={e => handleKeyDown(idx, e)}
              className="w-14 h-16 text-center text-2xl font-bold font-mono rounded-2xl bg-[var(--surface)] border-2 border-[var(--border-strong)] focus:border-[var(--primary)] text-[var(--ink)] focus:outline-none shadow-xs transition-colors"
            />
          ))}
        </div>

        <div className="text-center text-xs text-[var(--muted)] mb-8">
          {timer > 0 ? (
            <p>
              Resend code in <span className="font-bold font-mono text-[var(--ink)]">{timer}s</span>
            </p>
          ) : (
            <button
              onClick={() => setTimer(30)}
              className="text-[var(--primary)] font-bold hover:underline inline-flex items-center gap-1"
            >
              <RotateCcw className="w-3.5 h-3.5" /> Resend OTP via SMS / WhatsApp
            </button>
          )}
        </div>

        <div className="max-w-sm mx-auto">
          <button
            disabled={loading}
            onClick={handleVerify}
            className="w-full h-[54px] rounded-[16px] bg-[var(--primary)] hover:bg-[var(--primary-dark)] text-white font-bold text-sm shadow-md active:scale-95 transition-all flex items-center justify-center gap-2"
          >
            {loading ? 'Verifying Code...' : 'Verify & Enter Fresh Market'}
          </button>
        </div>
      </div>

      <div className="text-center pb-2">
        <p className="text-[11px] text-[var(--faint)] flex items-center justify-center gap-1">
          <ShieldCheck className="w-3.5 h-3.5 text-[var(--primary)]" />
          Bank-grade 256-bit encrypted authentication
        </p>
      </div>
    </div>
  );
};
