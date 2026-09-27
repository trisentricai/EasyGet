import type { CSSProperties } from "react";
import { EFFECT_LABELS, type ImageDisplay, type ImageEffect } from "../services/api";

const ALIGN_PRESETS: { x: number; y: number; label: string }[] = [
  { x: 0, y: 0, label: "↖" },
  { x: 50, y: 0, label: "↑" },
  { x: 100, y: 0, label: "↗" },
  { x: 0, y: 50, label: "←" },
  { x: 50, y: 50, label: "•" },
  { x: 100, y: 50, label: "→" },
  { x: 0, y: 100, label: "↙" },
  { x: 50, y: 100, label: "↓" },
  { x: 100, y: 100, label: "↘" },
];

/** Inline style that maps a display config onto an <img> — object-position +
 *  CSS custom properties consumed by the shared `img-fx*` rules. */
export function imageFxStyle(v: ImageDisplay): CSSProperties {
  return {
    objectPosition: `${v.align_x}% ${v.align_y}%`,
    "--fx-zoom": String(v.zoom),
    "--fx-ms": `${v.transition_ms}ms`,
  } as CSSProperties;
}

export function imageFxClass(v: ImageDisplay): string {
  return v.effect && v.effect !== "none" ? `img-fx img-fx-${v.effect}` : "img-fx";
}

/** Live preview + controls for align / zoom / hover effect / transition.
 *  Controlled: parent owns `value` and persists via its own save action. */
export default function ImageDisplayEditor({
  src,
  value,
  onChange,
  aspect = "16 / 9",
}: {
  src: string | null;
  value: ImageDisplay;
  onChange: (patch: Partial<ImageDisplay>) => void;
  aspect?: string;
}) {
  return (
    <div className="ide">
      <div className={`ide-frame ${imageFxClass(value)}`} style={{ aspectRatio: aspect }}>
        {src ? (
          <img src={src} alt="" decoding="async" style={imageFxStyle(value)} />
        ) : (
          <div className="ide-empty">No image</div>
        )}
      </div>

      <div className="ide-group">
        <div className="ide-label">
          Align <span className="ide-val">{value.align_x}%, {value.align_y}%</span>
        </div>
        <div className="ide-align">
          {ALIGN_PRESETS.map((p) => (
            <button
              key={`${p.x}-${p.y}`}
              type="button"
              className={`ide-align-cell ${value.align_x === p.x && value.align_y === p.y ? "on" : ""}`}
              title={`Left/right ${p.x}% · Top/bottom ${p.y}%`}
              onClick={() => onChange({ align_x: p.x, align_y: p.y })}
            >
              {p.label}
            </button>
          ))}
        </div>
        <div className="ide-row">
          <label className="ide-slider">
            X
            <input
              type="range"
              min={0}
              max={100}
              step={1}
              value={value.align_x}
              onChange={(e) => onChange({ align_x: Number(e.target.value) })}
            />
          </label>
          <label className="ide-slider">
            Y
            <input
              type="range"
              min={0}
              max={100}
              step={1}
              value={value.align_y}
              onChange={(e) => onChange({ align_y: Number(e.target.value) })}
            />
          </label>
        </div>
      </div>

      <div className="ide-group">
        <div className="ide-label">
          Zoom <span className="ide-val">×{value.zoom.toFixed(2)}</span>
        </div>
        <input
          type="range"
          min={1}
          max={3}
          step={0.05}
          value={value.zoom}
          onChange={(e) => onChange({ zoom: Number(e.target.value) })}
        />
      </div>

      <div className="ide-group">
        <div className="ide-label">Hover effect</div>
        <select
          className="input"
          value={value.effect}
          onChange={(e) => onChange({ effect: e.target.value as ImageEffect })}
        >
          {(Object.keys(EFFECT_LABELS) as ImageEffect[]).map((fx) => (
            <option key={fx} value={fx}>
              {EFFECT_LABELS[fx]}
            </option>
          ))}
        </select>
      </div>

      <div className={`ide-group ${value.effect === "none" ? "dim" : ""}`}>
        <div className="ide-label">
          Transition <span className="ide-val">{value.transition_ms}ms</span>
        </div>
        <input
          type="range"
          min={0}
          max={1000}
          step={50}
          value={value.transition_ms}
          disabled={value.effect === "none"}
          onChange={(e) => onChange({ transition_ms: Number(e.target.value) })}
        />
      </div>

      <p className="ide-hint">
        Hover the preview to feel the effect. Zoom &amp; alignment apply to every
        card, gallery and banner that shows this image once saved.
      </p>
    </div>
  );
}
