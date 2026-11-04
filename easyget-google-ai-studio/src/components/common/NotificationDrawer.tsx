import React from 'react';
import {
  Bell,
  X,
  CheckCheck,
  ShoppingBag,
  Sparkles,
  Info,
  ChevronRight,
  Send,
} from 'lucide-react';
import { useApp } from '../../context/AppContext';

export const NotificationDrawer: React.FC = () => {
  const {
    notifications,
    unreadNotifsCount,
    markNotifAsRead,
    markAllNotifsAsRead,
    isNotifSheetOpen,
    setIsNotifSheetOpen,
    activePushBanner,
    dismissPushBanner,
    simulateIncomingNotification,
    navigate,
  } = useApp();

  const getIcon = (type: string) => {
    switch (type) {
      case 'order':
        return <ShoppingBag className="w-4 h-4 text-[var(--primary)]" />;
      case 'promo':
        return <Sparkles className="w-4 h-4 text-[var(--marigold)]" />;
      default:
        return <Info className="w-4 h-4 text-[var(--brand)]" />;
    }
  };

  return (
    <>
      {/* 1. Floating In-App Push Banner (Real-time dynamic popup) */}
      {activePushBanner && (
        <div className="fixed top-3 left-4 right-4 z-50 max-w-[408px] mx-auto animate-bounce-short">
          <div className="bg-[var(--surface)] border border-[var(--border-strong)] rounded-2xl p-3.5 shadow-xl flex items-start gap-3">
            <div className="w-9 h-9 rounded-xl bg-[var(--sunken)] flex items-center justify-center shrink-0">
              {getIcon(activePushBanner.type)}
            </div>
            <div
              className="flex-1 min-w-0 cursor-pointer"
              onClick={() => {
                markNotifAsRead(activePushBanner.id);
                dismissPushBanner();
                if (activePushBanner.actionScreen) {
                  navigate(activePushBanner.actionScreen);
                }
              }}
            >
              <div className="flex items-center justify-between gap-1">
                <span className="text-[11px] font-bold text-[var(--primary)] uppercase tracking-wider">
                  EASYGET LIVE
                </span>
                <span className="text-[10px] text-[var(--faint)]">Just now</span>
              </div>
              <h4 className="text-xs font-bold text-[var(--ink)] line-clamp-1 mt-0.5">
                {activePushBanner.title}
              </h4>
              <p className="text-[11px] text-[var(--muted)] line-clamp-2 mt-0.5 leading-tight">
                {activePushBanner.body}
              </p>
            </div>
            <button
              onClick={dismissPushBanner}
              aria-label="Dismiss"
              className="p-1 rounded-full text-[var(--faint)] hover:text-[var(--ink)]"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>
      )}

      {/* 2. Notification Center Modal / Bottom Sheet */}
      {isNotifSheetOpen && (
        <div className="fixed inset-0 z-40 bg-black/40 backdrop-blur-2xs flex justify-end flex-col animate-fade-in">
          <div
            className="w-full max-w-[440px] mx-auto bg-[var(--surface)] rounded-t-[28px] border-t border-[var(--border)] max-h-[85vh] flex flex-col shadow-2xl overflow-hidden"
            onClick={e => e.stopPropagation()}
          >
            {/* Sheet Handle */}
            <div className="pt-2 pb-1 flex justify-center">
              <div className="w-12 h-1.5 rounded-full bg-[var(--border-strong)]" />
            </div>

            {/* Header */}
            <div className="px-5 py-3 border-b border-[var(--border)] flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-full bg-[var(--primary-tint)] flex items-center justify-center text-[var(--primary)]">
                  <Bell className="w-4 h-4" />
                </div>
                <div>
                  <h3 className="text-base font-bold text-[var(--ink)]">Notification Center</h3>
                  <p className="text-[11px] text-[var(--muted)]">
                    {unreadNotifsCount} unread alert{unreadNotifsCount !== 1 ? 's' : ''}
                  </p>
                </div>
              </div>

              <div className="flex items-center gap-2">
                {unreadNotifsCount > 0 && (
                  <button
                    onClick={markAllNotifsAsRead}
                    className="text-xs font-semibold text-[var(--primary)] flex items-center gap-1 hover:underline"
                  >
                    <CheckCheck className="w-3.5 h-3.5" />
                    Read all
                  </button>
                )}
                <button
                  onClick={() => setIsNotifSheetOpen(false)}
                  className="w-8 h-8 rounded-full flex items-center justify-center text-[var(--muted)] hover:bg-[var(--sunken)]"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>
            </div>

            {/* Simulation action button */}
            <div className="px-5 py-2.5 bg-[var(--sunken)]/60 border-b border-[var(--border)] flex items-center justify-between">
              <span className="text-xs text-[var(--muted)] font-medium">
                Simulate real-time delivery update:
              </span>
              <button
                onClick={simulateIncomingNotification}
                className="text-xs font-bold text-[var(--primary)] bg-[var(--surface)] px-2.5 py-1 rounded-full border border-[var(--border)] flex items-center gap-1 hover:bg-[var(--primary-tint)] active:scale-95 transition-all shadow-2xs"
              >
                <Send className="w-3 h-3" />
                Send Ping
              </button>
            </div>

            {/* Notification List */}
            <div className="flex-1 overflow-y-auto p-4 space-y-2.5 divide-y-0">
              {notifications.length === 0 ? (
                <div className="text-center py-12">
                  <Bell className="w-10 h-10 mx-auto text-[var(--faint)] mb-2 stroke-[1.5]" />
                  <p className="text-sm font-semibold text-[var(--ink)]">All caught up!</p>
                  <p className="text-xs text-[var(--muted)] mt-1">
                    No active notifications right now.
                  </p>
                </div>
              ) : (
                notifications.map(n => (
                  <div
                    key={n.id}
                    onClick={() => {
                      markNotifAsRead(n.id);
                      setIsNotifSheetOpen(false);
                      if (n.actionScreen) navigate(n.actionScreen);
                    }}
                    className={`p-3.5 rounded-2xl border transition-all cursor-pointer flex items-start gap-3 ${
                      !n.read
                        ? 'bg-[var(--surface)] border-[var(--primary)]/30 shadow-xs'
                        : 'bg-[var(--sunken)]/40 border-[var(--border)] opacity-85'
                    }`}
                  >
                    <div
                      className={`w-9 h-9 rounded-xl flex items-center justify-center shrink-0 ${
                        !n.read ? 'bg-[var(--primary-tint)]' : 'bg-[var(--sunken)]'
                      }`}
                    >
                      {getIcon(n.type)}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between gap-1 mb-0.5">
                        <span className="text-xs font-bold text-[var(--ink)] truncate">
                          {n.title}
                        </span>
                        <span className="text-[10px] text-[var(--faint)] shrink-0">
                          {n.timestamp}
                        </span>
                      </div>
                      <p className="text-xs text-[var(--muted)] leading-relaxed">
                        {n.body}
                      </p>
                    </div>
                    <ChevronRight className="w-4 h-4 text-[var(--faint)] shrink-0 self-center" />
                  </div>
                ))
              )}
            </div>

            {/* Footer */}
            <div className="p-3 border-t border-[var(--border)] bg-[var(--surface)] text-center">
              <button
                onClick={() => setIsNotifSheetOpen(false)}
                className="w-full py-2.5 rounded-xl bg-[var(--sunken)] text-xs font-bold text-[var(--ink)] hover:bg-[var(--border)] transition-colors"
              >
                Close Notifications
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
};
