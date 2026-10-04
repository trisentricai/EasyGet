/**
 * EASYGET — design tokens (TypeScript surface)
 *
 * The CSS in ./tokens.css is the source of truth. This module exists for the
 * cases CSS cannot cover: values that must be read in JavaScript, such as
 * Framer Motion stagger delays, scroll-reveal thresholds, or a test asserting
 * that a screen never uses a font weight outside the allowed set.
 *
 * Rule: never add a value here that is not in DESIGN.md §1. If a number is
 * missing, it belongs in DESIGN.md before it belongs here.
 *
 * Hybrid revision: the system is warm and grounded — deep forest accent,
 * live CTA green, cream canvas — with an editorial serif for display moments.
 */

/** DESIGN.md §1 — Motion. The only three durations §2 permits (never <150ms). */
export const MOTION = {
  /** hover, press, toggle */
  micro: 160,
  /** modal, sheet, dropdown */
  base: 240,
  /** page transitions, editorial reveals */
  editorial: 500,
} as const;

/** DESIGN.md §1 — decelerating ease, the default for all motion. */
export const EASE_OUT = "cubic-bezier(0.16, 1, 0.3, 1)" as const;

/** DESIGN.md §1 — the easing tuple Framer Motion's cubicBezier expects. */
export const EASE_OUT_ARRAY = [0.16, 1, 0.3, 1] as const;

/**
 * Stagger step for editorial reveals: one step apart so a group reads as a
 * single gesture instead of N competing ones. Derived from MOTION.editorial
 * so it can never drift from the CSS.
 */
export const STAGGER_STEP_MS = Math.round(MOTION.editorial / 7);

/**
 * Editorial reveals travel at most 8px — calm, never a slide or a bounce.
 */
export const REVEAL_TRAVEL_PX = 8;

/**
 * DESIGN.md §1 — Spacing. The 8pt grid plus grocery-density allowances.
 * Product grids use the 16–20px steps; editorial sections the 64–96px steps.
 * Use for inline styles and JS-driven layout where a Tailwind class cannot
 * reach (e.g. a translate computed from an index).
 */
export const SPACING = {
  4: 4,
  8: 8,
  12: 12,
  16: 16,
  20: 20,
  24: 24,
  32: 32,
  40: 40,
  48: 48,
  64: 64,
  80: 80,
  96: 96,
} as const;

/** DESIGN.md §1 — Radii. Softer than marketplace defaults, never pill-everywhere. */
export const RADIUS = {
  /** inputs, tags */
  sm: 6,
  /** cards, buttons */
  md: 10,
  /** modals, sheets */
  lg: 14,
  /** hero cards */
  xl: 20,
  /** pills, avatars */
  full: 999,
} as const;

/**
 * DESIGN.md §1 — border-first elevation (Instacart pattern). Product surfaces
 * are largely shadow-free; the 1px hairline does the work.
 */
export const HAIRLINE_PX = 1;

/**
 * DESIGN.md §3, §5 — "44x44 minimum touch target on mobile".
 * Use for icon-only controls; anything visually smaller must still reserve
 * this footprint so it stays hittable.
 */
export const TOUCH_TARGET_PX = 44;

/**
 * DESIGN.md §5 — WCAG 2.2 AA thresholds, for review checklists.
 */
export const CONTRAST = {
  /** body text */
  bodyAA: 4.5,
  /** large text (>=24px, or >=18.66px bold) and non-text UI */
  largeAA: 3,
} as const;

/**
 * Measured contrast of the DESIGN.md §1 palette against the canvas, computed
 * with the standard relative-luminance formula. Re-verify after any token
 * change — if a recomputation disagrees with this object, the recomputation
 * is right and this is stale.
 *
 * Read this before using a token for text:
 *   ink-strong  16.71:1 light / 17.28:1 dark — safe for anything
 *   ink-muted    5.42:1 light /  7.18:1 dark — clears AA body
 *   ink-faint    2.53:1 light /  3.36:1 dark — DECORATIVE ONLY on light;
 *                                              large/UI only on dark
 *   accent-fg/accent  11.89:1 light / 7.89:1 dark — safe for anything
 *   cta-fg/cta   4.56:1 both — clears AA body; the live green is text-safe
 *   focus(cta)/canvas  4.30:1 light / 4.23:1 dark — clears 3:1 for the ring
 *   success      4.73:1 light / 11.07:1 dark
 *   warning      4.74:1 light / 11.55:1 dark
 *   danger       6.10:1 light /  6.97:1 dark
 *   cta-dark-fg/cta-dark  12.36:1 — immersive brand moments stay legible
 *   border-subtle/canvas  1.27:1 light / 1.71:1 dark — hairline only, never
 *                                              a state boundary alone
 */
export const MEASURED_CONTRAST = {
  "ink-strong/canvas": { light: 16.71, dark: 17.28 },
  "ink-muted/canvas": { light: 5.42, dark: 7.18 },
  "ink-faint/canvas": { light: 2.53, dark: 3.36 },
  "accent-fg/accent": { light: 11.89, dark: 7.89 },
  "cta-fg/cta": { light: 4.56, dark: 4.56 },
  "focus(cta)/canvas": { light: 4.3, dark: 4.23 },
  "cta-dark-fg/cta-dark": { light: 12.36, dark: 12.36 },
  "success/canvas": { light: 4.73, dark: 11.07 },
  "warning/canvas": { light: 4.74, dark: 11.55 },
  "danger/canvas": { light: 6.1, dark: 6.97 },
  "border-subtle/canvas": { light: 1.27, dark: 1.71 },
} as const;
