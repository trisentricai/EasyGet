import type { CSSProperties } from "react";
import type { ImageDisplay } from "../services/api";

const DEFAULTS = {
  align_x: 50,
  align_y: 50,
  zoom: 1,
  effect: "none",
  transition_ms: 400,
} as const;

/** Inline style mapping a display config onto an image: focal point via
 *  object-position plus the `--fx-zoom` / `--fx-ms` custom properties that
 *  the shared `.img-fx*` rules consume. Returns undefined for absent config
 *  so images without settings render exactly as before. */
export function fxStyle(v?: ImageDisplay | null): CSSProperties | undefined {
  if (!v) return undefined;
  const align_x = v.align_x ?? DEFAULTS.align_x;
  const align_y = v.align_y ?? DEFAULTS.align_y;
  const zoom = v.zoom ?? DEFAULTS.zoom;
  const transition_ms = v.transition_ms ?? DEFAULTS.transition_ms;
  return {
    objectPosition: `${align_x}% ${align_y}%`,
    "--fx-zoom": String(zoom),
    "--fx-ms": `${transition_ms}ms`,
  } as CSSProperties;
}

/** Class names for the shared effect rules. Empty string when there is no
 *  image config at all (e.g. section items that predate display settings). */
export function fxClass(v?: ImageDisplay | null): string {
  if (!v) return "";
  const effect = v.effect ?? DEFAULTS.effect;
  return effect !== "none" ? `img-fx img-fx-${effect}` : "img-fx";
}
