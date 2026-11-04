"""Contrast audit for DESIGN.md §1 (luxury / achromatic revision).

DESIGN.md quotes specific contrast ratios. Asserting numbers in a spec is
unacceptable, so this script computes them — the table can only contain
measured values. It also enforces the two rules the luxury system depends on:

  * every body / UI ink pair clears AA (4.5:1) or AA-large / non-text (3:1)
  * `ink-faint` and `border-subtle` are reported as DECORATIVE ONLY, because
    DESIGN.md §1 declares them below threshold — if they are ever used to carry
    meaning, that is an accessibility defect.

The achromatic system has no accent hue, so the interesting pairs are ink
against canvas in both themes, action block on its own text, and focus ring
against canvas.

Run:  python scripts/audit_contrast.py
"""

import re
import sys
from pathlib import Path

TOKENS_CSS = Path(__file__).resolve().parent.parent / "customer-web" / "src" / "theme" / "tokens.css"

LIGHT = {
    "bg-canvas": "#FFFFFF",
    "bg-surface": "#FFFFFF",
    "bg-sunken": "#F6F5F4",
    "bg-band": "#0F0F0F",
    "bg-band-ink": "#F5F3F1",
    "ink-strong": "#1C1A17",
    "ink-body": "#33312E",
    "ink-muted": "#75726E",
    "ink-faint": "#A8A5A1",
    "border-subtle": "#E6E4E1",
    "border-strong": "#D2CFCB",
    "action": "#0F0F0F",
    "action-fg": "#FFFFFF",
    "focus": "#0F0F0F",
    "state-ok": "#4A5D4E",
    "state-alert": "#7A3B34",
}

DARK = {
    "bg-canvas": "#0B0A0A",
    "bg-surface": "#141313",
    "bg-sunken": "#1C1B1A",
    "bg-band": "#F5F3F1",
    "bg-band-ink": "#1C1A17",
    "ink-strong": "#F5F3F1",
    "ink-body": "#DCD9D6",
    "ink-muted": "#918D89",
    "ink-faint": "#66625E",
    "border-subtle": "#26241F",
    "border-strong": "#3B3835",
    "action": "#F5F3F1",
    "action-fg": "#0B0A0A",
    "focus": "#F5F3F1",
    "state-ok": "#7E9A85",
    "state-alert": "#C98B82",
}

# (fg, bg, required ratio, role)
PAIRS = [
    ("ink-strong", "bg-canvas", 4.5, "headings / body"),
    ("ink-body", "bg-canvas", 4.5, "body copy"),
    ("ink-body", "bg-sunken", 4.5, "body on well"),
    ("ink-muted", "bg-canvas", 4.5, "secondary text"),
    ("ink-muted", "bg-surface", 4.5, "secondary on card"),
    ("ink-faint", "bg-canvas", 4.5, "DECORATIVE ONLY"),
    ("border-subtle", "bg-canvas", 3.0, "hairline (non-text)"),
    ("action-fg", "action", 4.5, "button label"),
    ("focus", "bg-canvas", 3.0, "focus ring (non-text)"),
    ("bg-band-ink", "bg-band", 4.5, "text on editorial band"),
    ("state-ok", "bg-canvas", 4.5, "in-stock / confirmed"),
    ("state-alert", "bg-canvas", 4.5, "out of stock / error"),
]


def hex_to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i : i + 2], 16) for i in (0, 2, 4))


def luminance(rgb):
    def chan(c):
        c /= 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4

    r, g, b = (chan(c) for c in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a, b):
    la = luminance(hex_to_rgb(a))
    lb = luminance(hex_to_rgb(b))
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


def run(theme, palette):
    print(f"\n{theme}")
    print("-" * 76)
    print(f"{'pair':<40} {'ratio':>7} {'need':>6}  {'':2} role")
    print("-" * 76)
    failures = 0
    decorations = 0
    for fg, bg, need, role in PAIRS:
        ratio = contrast(palette[fg], palette[bg])
        ok = ratio >= need
        if not ok:
            # ink-faint / border-subtle are declared below threshold in §1 —
            # they are reported, not treated as build failures.
            if "DECORATIVE" in role or "non-text" in role:
                mark = "~"
                decorations += 1
            else:
                mark = "X"
                failures += 1
        else:
            mark = "OK"
        name = f"{fg} on {bg}"
        print(f"{name:<40} {ratio:>6.2f}:1 {need:>5} {mark:>3}  {role}")
    return failures, decorations


def read_css_tokens():
    """Parse the real token file so this audit measures the shipped system.

    The bug this guards against: the script's own LIGHT/DARK dicts are a copy
    of DESIGN.md. If CSS and the copy drift — a token present in the audit but
    missing from the dark block, say — the audit happily reports passing
    numbers for values that are never applied. That is exactly how
    `state-ok` shipped at 2.79:1 on dark while the audit claimed 6.45:1.
    """
    if not TOKENS_CSS.exists():
        return None, [f"cannot find {TOKENS_CSS}"]

    text = TOKENS_CSS.read_text(encoding="utf-8")
    errors = []

    dark_match = re.search(r'html\[data-theme="dark"\]\s*\{(.*?)\}', text, re.S)
    if not dark_match:
        return None, ["tokens.css has no html[data-theme=dark] block"]
    dark_block = dark_match.group(1)
    # Light tokens live in the @theme block, i.e. before the dark block.
    light_block = text[: dark_match.start()]

    def css_name(name):
        """DESIGN.md names surfaces `--bg-canvas`; Tailwind needs `--color-canvas`
        so the utility reads `bg-canvas`. Audit keys follow DESIGN.md, CSS
        follows Tailwind — translate rather than fail on the prefix."""
        return name[3:] if name.startswith("bg-") else name

    def grab(block, name):
        m = re.search(
            r"--color-" + re.escape(css_name(name)) + r"\s*:\s*(#[0-9a-fA-F]{3,8})",
            block,
        )
        return m.group(1).lower() if m else None

    for name, hexv in LIGHT.items():
        found = grab(light_block, name)
        if found is None:
            errors.append(f"LIGHT  --color-{css_name(name)} missing from tokens.css")
        elif found != hexv.lower():
            errors.append(
                f"LIGHT  --color-{css_name(name)} is {found}, audit assumes {hexv.lower()}"
            )

    for name, hexv in DARK.items():
        found = grab(dark_block, name)
        if found is None:
            errors.append(
                f"DARK   --color-{css_name(name)} not remapped - ships the light value"
            )
        elif found != hexv.lower():
            errors.append(
                f"DARK   --color-{css_name(name)} is {found}, audit assumes {hexv.lower()}"
            )

    return text, errors


def main():
    print("=" * 76)
    print("SYNCHRONISATION CHECK - audit dicts vs customer-web/src/theme/tokens.css")
    print("=" * 76)
    _, sync_errors = read_css_tokens()
    if sync_errors:
        for e in sync_errors:
            print("  " + e)
        print(f"\nOUT OF SYNC: {len(sync_errors)} token(s). Fix tokens.css or this script.")
        return 1
    print("  in sync - every audited token exists in tokens.css, light and dark")

    lf, ld = run("LIGHT", LIGHT)
    print()
    dr, dd = run("DARK", DARK)

    print("\n" + "=" * 76)
    print("POLARITY CHECK - luxury achromatic requires warm, not cold, neutrals")
    print("=" * 76)
    for theme, palette in (("light", LIGHT), ("dark", DARK)):
        for key in ("ink-strong", "ink-body", "ink-muted"):
            r, g, b = hex_to_rgb(palette[key])
            warm = r >= g >= b
            print(
                f"  {theme:>5} {key:<11} {palette[key]}  "
                f"rgb({r},{g},{b})  "
                f"{'warm (OK)' if warm else 'COLD - should be warm'}"
            )

    total_fail = lf + dr
    print("\n" + "=" * 76)
    if total_fail:
        print(f"FAIL — {total_fail} pair(s) below required ratio")
        return 1
    print(
        "PASS — all body/UI pairs clear AA. "
        f"{ld + dd} declared-decorative pair(s) below 3:1, as §1 documents."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
