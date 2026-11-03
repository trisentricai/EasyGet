/**
 * EASYGET icon set — one 24px grid, 1.5px monoline geometry in the
 * Untitled UI / Streamline "core line" tradition: rounded caps, open
 * counters, no filled boxes. Filled variants exist only where the UI needs
 * an on/off state (heart, star, status dots).
 *
 * Everything inherits `currentColor`, so merchant theming and dark mode
 * apply automatically — feature code never picks a colour for an icon.
 */
import type { ReactNode } from "react";

const PATHS = {
  /* ---------- Navigation & chrome ---------- */
  home: (
    <>
      <path d="m3.5 10 8.5-7 8.5 7" />
      <path d="M5.5 8.8V20a1 1 0 0 0 1 1h11a1 1 0 0 0 1-1V8.8" />
      <path d="M9.5 21v-6h5v6" />
    </>
  ),
  search: (
    <>
      <circle cx="11" cy="11" r="6.5" />
      <path d="m20.5 20.5-4.6-4.6" />
    </>
  ),
  grid: (
    <>
      <rect x="3.5" y="3.5" width="7" height="7" rx="1.5" />
      <rect x="13.5" y="3.5" width="7" height="7" rx="1.5" />
      <rect x="13.5" y="13.5" width="7" height="7" rx="1.5" />
      <rect x="3.5" y="13.5" width="7" height="7" rx="1.5" />
    </>
  ),
  user: (
    <>
      <circle cx="12" cy="8" r="3.6" />
      <path d="M4.8 20.5a7.2 7.2 0 0 1 14.4 0" />
    </>
  ),
  menu: <path d="M4 6.5h16M4 12h16M4 17.5h16" />,
  x: <path d="M18 6 6 18M6 6l12 12" />,
  plus: <path d="M12 5v14M5 12h14" />,
  minus: <path d="M5 12h14" />,
  check: <path d="m4.5 12.5 5 5 10-11" />,
  chevronUp: <path d="m6 15 6-6 6 6" />,
  chevronDown: <path d="m6 9 6 6 6-6" />,
  chevronLeft: <path d="m15 18-6-6 6-6" />,
  chevronRight: <path d="m9 18 6-6-6-6" />,
  arrowLeft: <path d="M19 12H5m6 6-6-6 6-6" />,
  arrowRight: <path d="M5 12h14m-6-6 6 6-6 6" />,
  arrowUpRight: <path d="M7 17 17 7M8 7h9v9" />,
  externalLink: (
    <>
      <path d="M14 4h6v6M20 4l-9 9" />
      <path d="M18 14v4.5a1.5 1.5 0 0 1-1.5 1.5h-11A1.5 1.5 0 0 1 4 18.5v-11A1.5 1.5 0 0 1 5.5 6H10" />
    </>
  ),
  filter: <path d="M3.5 5h17l-6.6 7.7V19l-3.8 2v-8.3L3.5 5Z" />,
  sliders: (
    <>
      <path d="M4 8h9M17 8h3M4 16h3M11 16h9" />
      <circle cx="15" cy="8" r="2" />
      <circle cx="9" cy="16" r="2" />
    </>
  ),
  sort: (
    <>
      <path d="M4 7h10M4 12h7M4 17h4" />
      <path d="M17 5v14M14 16l3 3 3-3" />
    </>
  ),
  refresh: (
    <>
      <path d="M20.5 11a8.5 8.5 0 0 0-15-4.5L3 9" />
      <path d="M3 4.5V9h4.5" />
      <path d="M3.5 13a8.5 8.5 0 0 0 15 4.5L21 15" />
      <path d="M21 19.5V15h-4.5" />
    </>
  ),
  share: (
    <>
      <circle cx="18" cy="5.5" r="2.5" />
      <circle cx="6" cy="12" r="2.5" />
      <circle cx="18" cy="18.5" r="2.5" />
      <path d="m8.3 10.8 7.4-4M8.3 13.2l7.4 4" />
    </>
  ),
  copy: (
    <>
      <rect x="8" y="8" width="12" height="12" rx="2" />
      <path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2" />
    </>
  ),

  /* ---------- Commerce ---------- */
  cart: (
    <>
      <circle cx="9" cy="20" r="1.4" />
      <circle cx="18" cy="20" r="1.4" />
      <path d="M2.5 3h2.2l2.5 11.2a1.8 1.8 0 0 0 1.8 1.4h8.6a1.8 1.8 0 0 0 1.8-1.4L21 7H6" />
    </>
  ),
  bag: (
    <>
      <path d="M5.5 8h13l1 12.5h-15L5.5 8Z" />
      <path d="M9 8V6.5a3 3 0 0 1 6 0V8" />
    </>
  ),
  bagCheck: (
    <>
      <path d="M5.5 8h13l1 12.5h-15L5.5 8Z" />
      <path d="M9 8V6.5a3 3 0 0 1 6 0V8" />
      <path d="m9.5 14.5 1.8 1.8 3.4-3.6" />
    </>
  ),
  box: (
    <>
      <path d="M21 7.5 12 3 3 7.5v9L12 21l9-4.5v-9Z" />
      <path d="M3.3 7.4 12 12l8.7-4.6" />
      <path d="M12 21v-9" />
    </>
  ),
  truck: (
    <>
      <path d="M14 7H3.5A1.5 1.5 0 0 0 2 8.5v9A1.5 1.5 0 0 0 3.5 19H6" />
      <path d="M14 7h3.6a2 2 0 0 1 1.6.8L22 12v6.5h-2.5" />
      <path d="M9 19h6" />
      <circle cx="7.5" cy="19" r="1.8" />
      <circle cx="17.5" cy="19" r="1.8" />
    </>
  ),
  store: (
    <>
      <path d="M4 9.5V19a1.5 1.5 0 0 0 1.5 1.5h13A1.5 1.5 0 0 0 20 19V9.5" />
      <path d="M3 9.5 5.2 4.5h13.6L21 9.5" />
      <path d="M3 9.5a3 3 0 0 0 6 0 3 3 0 0 0 6 0 3 3 0 0 0 6 0" />
      <path d="M10 20.5v-5h4v5" />
    </>
  ),
  tag: (
    <>
      <path d="M3 3h7.2L21 13.8 13.8 21 3 10.2V3Z" />
      <circle cx="7.2" cy="7.2" r="1.1" />
    </>
  ),
  percent: (
    <>
      <path d="M19 5 5 19" />
      <circle cx="7" cy="7" r="2.2" />
      <circle cx="17" cy="17" r="2.2" />
    </>
  ),
  rupee: (
    <>
      <path d="M6 3.5h12M6 8h12" />
      <path d="M6 3.5c7.5 0 7.5 9 0 9h2.5L15 20.5" />
    </>
  ),
  creditCard: (
    <>
      <rect x="2.5" y="5" width="19" height="14" rx="2.5" />
      <path d="M2.5 10h19M6 15h3" />
    </>
  ),
  wallet: (
    <>
      <path d="M3.5 7.5A2.5 2.5 0 0 1 6 5h12a2 2 0 0 1 2 2v1" />
      <rect x="3.5" y="7.5" width="17" height="12" rx="2.5" />
      <path d="M16 13.5h2.5" />
    </>
  ),
  receipt: (
    <>
      <path d="M6 3h12v18l-3-2-3 2-3-2-3 2V3Z" />
      <path d="M9 8h6M9 12h6" />
    </>
  ),
  gift: (
    <>
      <rect x="3.5" y="8" width="17" height="4" rx="1" />
      <path d="M5 12v7.5A1.5 1.5 0 0 0 6.5 21h11a1.5 1.5 0 0 0 1.5-1.5V12" />
      <path d="M12 8v13" />
      <path d="M12 8c-1.5 0-4.5-.4-4.5-2.6C7.5 4 8.6 3 10 3c2 0 2 5 2 5Zm0 0c1.5 0 4.5-.4 4.5-2.6C16.5 4 15.4 3 14 3c-2 0-2 5-2 5Z" />
    </>
  ),
  leaf: (
    <>
      <path d="M20 3.5C11 3.5 5.5 7 5.5 13a5.5 5.5 0 0 0 5.5 5.5c6 0 9-5.5 9-15Z" />
      <path d="M3.5 21c2.2-6.5 6.3-10.5 12.5-12.5" />
    </>
  ),

  /* ---------- Status ---------- */
  checkCircle: (
    <>
      <circle cx="12" cy="12" r="9" />
      <path d="m8.5 12.2 2.4 2.4 4.6-4.9" />
    </>
  ),
  alertCircle: (
    <>
      <circle cx="12" cy="12" r="9" />
      <path d="M12 7.5V13M12 16.5h.01" />
    </>
  ),
  xCircle: (
    <>
      <circle cx="12" cy="12" r="9" />
      <path d="m9 9 6 6M15 9l-6 6" />
    </>
  ),
  info: (
    <>
      <circle cx="12" cy="12" r="9" />
      <path d="M12 11v5M12 7.5h.01" />
    </>
  ),
  warning: (
    <>
      <path d="M12 3.5 2.8 19.2a1.2 1.2 0 0 0 1 1.8h16.4a1.2 1.2 0 0 0 1-1.8L12 3.5Z" />
      <path d="M12 9v4.5M12 17h.01" />
    </>
  ),
  help: (
    <>
      <circle cx="12" cy="12" r="9" />
      <path d="M9.6 9.3a2.5 2.5 0 0 1 4.8.8c0 1.7-2.4 2-2.4 3.4" />
      <path d="M12 17h.01" />
    </>
  ),
  shieldCheck: (
    <>
      <path d="M12 2.5 4 5.6v6.1c0 5 8 9.8 8 9.8s8-4.8 8-9.8V5.6L12 2.5Z" />
      <path d="m8.8 11.8 2.2 2.2 4.2-4.4" />
    </>
  ),
  clock: (
    <>
      <circle cx="12" cy="12" r="9" />
      <path d="M12 7v5l3 1.8" />
    </>
  ),
  loader: (
    <path d="M12 3v4M12 17v4M5.6 5.6l2.8 2.8M15.6 15.6l2.8 2.8M3 12h4M17 12h4M5.6 18.4l2.8-2.8M15.6 8.4l2.8-2.8" />
  ),

  /* ---------- Account & actions ---------- */
  lock: (
    <>
      <rect x="4.5" y="10.5" width="15" height="9.5" rx="2" />
      <path d="M8 10.5V7.5a4 4 0 0 1 8 0v3" />
    </>
  ),
  edit: (
    <>
      <path d="M12 20h9" />
      <path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4L16.5 3.5Z" />
    </>
  ),
  trash: (
    <>
      <path d="M4 7h16" />
      <path d="M9.5 7V5.5A1.5 1.5 0 0 1 11 4h2a1.5 1.5 0 0 1 1.5 1.5V7" />
      <path d="M6.5 7 7.4 20a1 1 0 0 0 1 .9h7.2a1 1 0 0 0 1-.9L17.5 7" />
      <path d="M10 11v6M14 11v6" />
    </>
  ),
  logout: (
    <>
      <path d="M9.5 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4.5" />
      <path d="m16 17 5-5-5-5" />
      <path d="M21 12H9.5" />
    </>
  ),
  settings: (
    <>
      <circle cx="12" cy="12" r="3" />
      <path d="M19.4 15a1.7 1.7 0 0 0 .3 1.9l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.9-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.9.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.9 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.9l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.9.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.9-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.9V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1Z" />
    </>
  ),
  bell: (
    <>
      <path d="M18 8.5a6 6 0 0 0-12 0c0 6-2.5 7.5-2.5 7.5h17S18 14.5 18 8.5Z" />
      <path d="M10.5 20a1.8 1.8 0 0 0 3 0" />
    </>
  ),
  eye: (
    <>
      <path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12Z" />
      <circle cx="12" cy="12" r="3" />
    </>
  ),
  eyeOff: (
    <>
      <path d="M10.6 6a10.9 10.9 0 0 1 1.4-.1c6 0 9.5 6.1 9.5 6.1a17 17 0 0 1-3 3.7" />
      <path d="M6.4 7.4A16.6 16.6 0 0 0 2.5 12S6 18.1 12 18.1a10.3 10.3 0 0 0 4.3-.9" />
      <path d="M9.9 9.9a3 3 0 0 0 4.2 4.2M3 3l18 18" />
    </>
  ),
  pin: (
    <>
      <path d="M20 10.5c0 5.2-8 10.5-8 10.5S4 15.7 4 10.5a8 8 0 0 1 16 0Z" />
      <circle cx="12" cy="10.5" r="2.6" />
    </>
  ),
  phone: (
    <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.13.96.36 1.9.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.91.34 1.85.57 2.81.7A2 2 0 0 1 22 16.92Z" />
  ),
  mail: (
    <>
      <rect x="2" y="4.5" width="20" height="15" rx="2.5" />
      <path d="m2.8 7 8.2 5.4a2 2 0 0 0 2 0L21.2 7" />
    </>
  ),

  /* ---------- Marks & accents ---------- */
  heart: (
    <path d="M12 20.3 4.6 13a4.6 4.6 0 0 1 0-6.5 4.6 4.6 0 0 1 6.5 0l.9.9.9-.9a4.6 4.6 0 0 1 6.5 0 4.6 4.6 0 0 1 0 6.5L12 20.3Z" />
  ),
  heartFilled: (
    <path
      d="M12 20.3 4.6 13a4.6 4.6 0 0 1 0-6.5 4.6 4.6 0 0 1 6.5 0l.9.9.9-.9a4.6 4.6 0 0 1 6.5 0 4.6 4.6 0 0 1 0 6.5L12 20.3Z"
      fill="currentColor"
    />
  ),
  star: <path d="m12 3.2 2.6 5.6 6.1.8-4.5 4.2 1.2 6-5.4-3-5.4 3 1.2-6-4.5-4.2 6.1-.8L12 3.2Z" />,
  starFilled: (
    <path
      d="m12 3.2 2.6 5.6 6.1.8-4.5 4.2 1.2 6-5.4-3-5.4 3 1.2-6-4.5-4.2 6.1-.8L12 3.2Z"
      fill="currentColor"
    />
  ),
  sparkles: (
    <>
      <path d="M12 3.5l1.7 4.3 4.3 1.7-4.3 1.7-1.7 4.3-1.7-4.3L6 9.5l4.3-1.7L12 3.5Z" />
      <path d="M18 15.5l.8 2 2 .8-2 .8-.8 2-.8-2-2-.8 2-.8.8-2Z" />
      <path d="M5.5 15.5l.6 1.4 1.4.6-1.4.6-.6 1.4-.6-1.4L3.5 17.5l1.4-.6.6-1.4Z" />
    </>
  ),
  zap: <path d="M13 2.5 4.5 13.5H10l-1 8 8.5-11H12l1-8Z" />,

  /* ---------- Social (monochrome brand marks) ---------- */
  facebook: (
    <path d="M14.5 21v-7h2.4l.6-3h-3V9.2c0-.9.3-1.5 1.6-1.5H18V5.1c-.4-.1-1.6-.2-3-.2-3 0-4.5 1.7-4.5 4.5V11H8v3h2.5v7h4Z" />
  ),
  instagram: (
    <>
      <rect x="3.5" y="3.5" width="17" height="17" rx="5" />
      <circle cx="12" cy="12" r="4" />
      <path d="M17 7h.01" />
    </>
  ),
  xSocial: (
    <path d="M4 3.5h4.2l4.4 6.2L17.8 3.5H20l-6.4 7.4L20.5 20.5h-4.2l-4.7-6.6-5.6 6.6H3.8l6.8-8L4 3.5Z" />
  ),
  linkedin: (
    <>
      <rect x="3.5" y="3.5" width="17" height="17" rx="2.5" />
      <path d="M8 10.5V17M8 7.5h.01M12 17v-3.6a2.2 2.2 0 0 1 4.4 0V17" />
    </>
  ),
  youtube: (
    <>
      <rect x="2.5" y="6" width="19" height="12" rx="4" />
      <path d="m10.5 9.5 4.5 2.5-4.5 2.5v-5Z" />
    </>
  ),
} satisfies Record<string, ReactNode>;

export type IconName = keyof typeof PATHS;

export function Icon({
  name,
  size = 20,
  strokeWidth = 1.6,
  className,
}: {
  name: IconName;
  size?: number;
  strokeWidth?: number;
  className?: string;
}) {
  return (
    <svg
      className={className}
      width={size}
      height={size}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={strokeWidth}
      strokeLinecap="round"
      strokeLinejoin="round"
      aria-hidden="true"
      focusable="false"
    >
      {PATHS[name]}
    </svg>
  );
}
