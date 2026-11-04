import React, { useState } from 'react';
import {
  X,
  Send,
  Phone,
  ShieldCheck,
  CheckCheck,
  Navigation,
} from 'lucide-react';

interface RiderChatModalProps {
  isOpen: boolean;
  onClose: () => void;
  driverName?: string;
  driverPhone?: string;
  driverVehicle?: string;
}

interface Message {
  id: string;
  sender: 'user' | 'driver';
  text: string;
  time: string;
}

export const RiderChatModal: React.FC<RiderChatModalProps> = ({
  isOpen,
  onClose,
  driverName = 'Ravi Kumar',
  driverPhone = '+91 91234 56789',
  driverVehicle = 'KA 01 EK 8812 (Ather 450X)',
}) => {
  const [messages, setMessages] = useState<Message[]>([
    {
      id: 'm1',
      sender: 'driver',
      text: 'Namaste! I have picked up your fresh harvest pack from HSR Hub #4. On my way.',
      time: '8:23 AM',
    },
  ]);
  const [inputText, setInputText] = useState('');

  if (!isOpen) return null;

  const quickReplies = [
    'Leave at flat door, thank you!',
    "Please don't ring the bell",
    'Call me once at apartment gate',
    'Hand over to security guard',
  ];

  const sendMessage = (text: string) => {
    if (!text.trim()) return;
    const userMsg: Message = {
      id: `u-${Date.now()}`,
      sender: 'user',
      text: text.trim(),
      time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    };

    setMessages(prev => [...prev, userMsg]);
    setInputText('');

    // Simulate driver automated reply after 900ms
    setTimeout(() => {
      const driverReplies = [
        'Noted! Reaching your doorstep in 3 minutes.',
        'Sure, will follow your instructions carefully.',
        'Arrived at building gate, heading up via lift now.',
      ];
      const driverMsg: Message = {
        id: `d-${Date.now()}`,
        sender: 'driver',
        text: driverReplies[Math.floor(Math.random() * driverReplies.length)],
        time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      };
      setMessages(prev => [...prev, driverMsg]);
    }, 900);
  };

  return (
    <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex justify-end flex-col animate-fade-in">
      <div className="w-full max-w-[440px] mx-auto bg-[var(--surface)] rounded-t-[28px] border-t border-[var(--border)] overflow-hidden flex flex-col shadow-2xl h-[80vh]">
        {/* Handle */}
        <div className="pt-2 pb-1 flex justify-center">
          <div className="w-12 h-1.5 rounded-full bg-[var(--border-strong)]" />
        </div>

        {/* Driver Header */}
        <div className="px-4 py-3 border-b border-[var(--border)] flex items-center justify-between bg-[var(--sunken)]/40">
          <div className="flex items-center gap-3">
            <div className="relative">
              <div className="w-11 h-11 rounded-full bg-[var(--primary)] text-white font-bold flex items-center justify-center text-sm shadow-xs">
                RK
              </div>
              <div className="absolute -bottom-0.5 -right-0.5 w-3.5 h-3.5 rounded-full bg-emerald-500 border-2 border-white" />
            </div>
            <div>
              <div className="flex items-center gap-1.5">
                <h3 className="text-sm font-bold text-[var(--ink)]">{driverName}</h3>
                <span className="text-[10px] bg-green-100 text-green-800 font-bold px-1.5 py-0.2 rounded flex items-center gap-0.5">
                  <ShieldCheck className="w-3 h-3" /> VERIFIED
                </span>
              </div>
              <p className="text-[11px] text-[var(--muted)] flex items-center gap-1">
                <Navigation className="w-3 h-3 text-[var(--primary)]" />
                {driverVehicle}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <a
              href={`tel:${driverPhone}`}
              className="w-9 h-9 rounded-full bg-[var(--primary-tint)] text-[var(--primary)] flex items-center justify-center hover:bg-[var(--primary)] hover:text-white transition-colors"
            >
              <Phone className="w-4 h-4" />
            </a>
            <button
              onClick={onClose}
              className="w-9 h-9 rounded-full flex items-center justify-center text-[var(--muted)] hover:bg-[var(--sunken)]"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* Chat Messages */}
        <div className="flex-1 overflow-y-auto p-4 space-y-3 bg-[var(--canvas)]">
          {messages.map(m => {
            const isUser = m.sender === 'user';
            return (
              <div
                key={m.id}
                className={`flex flex-col ${isUser ? 'items-end' : 'items-start'}`}
              >
                <div
                  className={`max-w-[78%] px-3.5 py-2.5 rounded-2xl text-xs leading-relaxed ${
                    isUser
                      ? 'bg-[var(--primary)] text-white rounded-br-xs shadow-xs'
                      : 'bg-[var(--surface)] text-[var(--ink)] border border-[var(--border)] rounded-bl-xs shadow-xs'
                  }`}
                >
                  <p>{m.text}</p>
                </div>
                <div className="flex items-center gap-1 mt-1 px-1">
                  <span className="text-[10px] text-[var(--faint)] font-mono">{m.time}</span>
                  {isUser && <CheckCheck className="w-3 h-3 text-[var(--primary)]" />}
                </div>
              </div>
            );
          })}
        </div>

        {/* Quick Suggestion Chips */}
        <div className="p-2 border-t border-[var(--border)] bg-[var(--surface)] overflow-x-auto flex gap-1.5 no-scrollbar">
          {quickReplies.map(reply => (
            <button
              key={reply}
              onClick={() => sendMessage(reply)}
              className="px-3 py-1.5 rounded-full bg-[var(--sunken)] border border-[var(--border)] text-[11px] font-semibold text-[var(--ink)] whitespace-nowrap hover:bg-[var(--primary-tint)] hover:text-[var(--primary)] active:scale-95 transition-all shrink-0"
            >
              {reply}
            </button>
          ))}
        </div>

        {/* Message Input Box */}
        <div className="p-3 border-t border-[var(--border)] bg-[var(--surface)] flex items-center gap-2">
          <input
            type="text"
            value={inputText}
            onChange={e => setInputText(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && sendMessage(inputText)}
            placeholder="Message delivery partner..."
            className="flex-1 h-11 px-4 rounded-xl bg-[var(--sunken)] border border-[var(--border-strong)] text-xs text-[var(--ink)] focus:outline-none focus:border-[var(--primary)]"
          />
          <button
            onClick={() => sendMessage(inputText)}
            disabled={!inputText.trim()}
            className="w-11 h-11 rounded-xl bg-[var(--primary)] hover:bg-[var(--primary-dark)] text-white flex items-center justify-center disabled:opacity-40 transition-all active:scale-95"
          >
            <Send className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  );
};
