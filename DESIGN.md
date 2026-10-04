# EASYGET — DESIGN.md

> Hybrid direction: editorial (Tata CLiQ Luxury) + organic (Patyka)
> + utilitarian density (Instacart) + clean storefront (Aldi).
> Paste into EVERY AI prompt alongside CONTEXT.md.

---

## 0. Direction Statement

EASYGET is a **curated neighborhood marketplace** — the visual calm of a
specialty grocer, the editorial pacing of a luxury boutique, and the
functional clarity of a delivery platform.

**The interface recedes.** Products and store stories take center stage.
Density is present but disciplined — like Instacart, not like Flipkart.
Every surface feels considered, not assembled.

North stars: Tata CLiQ Luxury (slow commerce), Patyka (organic warmth),
Instacart (functional density), Aldi (clean storefront).

---

## 1. Frozen Tokens

### Typography
- Display: **Cormorant Garamond** (serif) — headings, editorial moments
- UI / body: **Inter** — navigation, labels, product names, body
- Numeric: **Geist Mono** — prices, ETAs, order IDs (tabular)

Rules:
- Display: weight 400–500, `letter-spacing: -0.01em`, line-height 1.15
- Body: weight 400, line-height 1.6
- Max 2 font weights per screen region
- Serif display only on hero + section headings; product names stay Inter

Scale:
```
--text-display: clamp(2.5rem, 5vw, 4rem)
--text-h1:      2.25rem
--text-h2:      1.75rem
--text-h3:      1.25rem
--text-body:    0.9375rem
--text-sm:      0.8125rem
--text-xs:      0.75rem
```

### Color — warm, grounded, functional
```css
/* Light — warm paper, Instacart-inspired greens */
--bg-canvas:     #FAF8F5   /* warm cream */
--bg-surface:    #FFFFFF
--bg-sunken:     #F2EEE9
--ink-strong:    #1A1815   /* warm near-black */
--ink-muted:     #6B6560
--ink-faint:     #A39D96
--border-subtle: #E8E2DB
--border-strong: #D4CCC3

/* Brand — one deep accent + one live CTA */
--accent:        #1F3D2F   /* deep forest — headers, primary brand */
--accent-fg:     #FFFFFF
--cta:           #108910   /* Instacart-style live green — Add to cart */
--cta-fg:        #FFFFFF
--cta-dark:      #003D29   /* Kale — immersive brand moments */

--success:       #15803D
--warning:       #B45309
--danger:        #B91C1C

/* Dark — warm near-black, not pure #000 */
[data-theme="dark"] {
  --bg-canvas:     #0F0E0D
  --bg-surface:    #1A1815
  --bg-sunken:     #242220
  --ink-strong:    #F5F2EE
  --ink-muted:     #A39D96
  --ink-faint:     #6B6560
  --border-subtle: #2A2724
  --border-strong: #3D3A36
  --accent:        #2D5A45   /* lighter forest for dark mode */
  --cta:           #108910
}
```

### Spacing (8pt grid + grocery-density allowances)
```
4  8  12  16  20  24  32  40  48  64  80  96
```
Density rule: product grids use 16–20px gaps (Instacart-like).
Editorial sections use 64–96px gaps (Tata CLiQ-like).

### Radii
```
--r-sm:   6px    /* inputs, tags */
--r-md:   10px   /* cards, buttons */
--r-lg:   14px   /* modals, sheets */
--r-xl:   20px   /* hero cards */
--r-full: 999px  /* pills, avatars */
```
Slightly softer than marketplace defaults; not pill-shaped everywhere.

### Elevation — border-first, shadow-last (Instacart pattern)
```css
--elev-1: 0 0 0 1px var(--border-subtle);
--elev-2: 0 2px 8px rgba(26,24,21,.04), 0 0 0 1px var(--border-subtle);
--elev-3: 0 8px 24px rgba(26,24,21,.06), 0 0 0 1px var(--border-subtle);
```
Instacart's UI is "largely shadow-free on product surfaces".
Use `--elev-1` for cards; `--elev-2` for hover/dropdown; `--elev-3` for modals only.

### Motion
```
--ease-out:    cubic-bezier(.16,1,.3,1)
--dur-micro:   160ms   /* hover, press, toggle */
--dur-base:    240ms   /* modal, sheet, dropdown */
--dur-editorial: 500ms /* page transitions, editorial reveals */
```
Always respect `prefers-reduced-motion`.

---

## 2. Forbidden List (paste into every prompt)

- ❌ `#6366F1`, `#8B5CF6`, `#3B82F6`, Tailwind defaults
- ❌ Purple→blue gradients, gradient blobs, mesh gradients
- ❌ Glassmorphism / `backdrop-filter: blur()` on cards
- ❌ Pure `#000` / `#FFF` as page backgrounds
- ❌ Red discount badges, "SALE" tags, urgency copy ("Only 2 left!")
- ❌ Countdown timers, exit-intent popups, newsletter overlays
- ❌ More than 3 products per row on mobile
- ❌ Card borders AND shadows together (pick one — prefer border)
- ❌ Sans-serif headings (display must be serif)
- ❌ Spinners where a skeleton fits
- ❌ `alert()` / `confirm()` — use toasts / modals
- ❌ Placeholder Lorem Ipsum — use realistic EASYGET grocery/retail content
- ❌ Dark mode as an auto-inverted light mode
- ❌ Motion under 150ms (feels cheap)

---

## 3. Component Rules

**Every interactive component ships with:**
- 6 states: rest / hover / focus-visible / active / disabled / loading
- Light + dark variants
- Keyboard accessible, ARIA labels on icon-only buttons
- 44×44 minimum touch target on mobile
- Motion using tokens only

**Every list / collection ships with:**
- Loading (skeleton matching final layout exactly)
- Empty (illustrated, with a CTA)
- Error (retry action)
- Populated

---

## 4. Screen Specs

### Homepage — editorial + functional
- Full-bleed hero (70vh) with serif headline over image. One story.
- "Shop by aisle" — Aldi/Garden Grocer-style category tiles, 4–6 large tiles.
- "Fresh picks" — 3 products per row, large images, no discount theater.
- "Store stories" — one editorial block (image left, text right).
- No offer ticker. No banner carousel. No "Recommended for you" rails.

### PDP — product as story
- Gallery: full-width, one image at a time, slow crossfade.
- Title in Inter (product names stay UI-font), 1.5rem+.
- Price: muted, no discount theater.
- Variants: large swatches, hairline ring for selected.
- **Editorial block**: "The Story" — 2–3 paragraphs about the product/store.
- Add to Bag: `--cta` green, full-width, calm.
- Pincode: quiet, inline, no green checkmark celebration.
- Reviews: collapsed by default.

### PLP / Search — gallery with density
- 3 columns desktop, 2 mobile. 16–20px gaps.
- 4:5 imagery, consistent.
- Filter: slide-over sheet, toggles not checkboxes.
- Aisle-based navigation (Garden Grocer pattern).
- Sort: relevance, price, rating, newest.

### Cart / Checkout — calm, deliberate
- Single column, max-width 640px.
- Large product images, clear delivery slot picker.
- "Proceed to Checkout" — not "Buy Now".
- No urgency copy.

### Grocery-specific additions
- **Delivery slot picker** (Instacart pattern): time windows, same-day/next-day.
- **Aisle navigation** — browse by category like a physical store.
- **Sort by brand** (Garden Grocer pattern).
- **Specialty filters**: Gluten Free, Organic, Vegan.

---

## 5. Accessibility (WCAG 2.2 AA)

- Contrast ≥ 4.5:1 body, ≥ 3:1 large text
- Visible focus ring using `--cta`
- Full keyboard nav, screen-reader labels
- 44×44 touch targets
- `prefers-reduced-motion` respected

---

## 6. Performance Targets

- LCP < 2.0s on 4G
- CLS < 0.05
- INP < 200ms
- Lighthouse: Perf ≥ 90, A11y ≥ 95, BP ≥ 95
- Images: AVIF/WebP + srcset + fixed aspect ratios + blurhash

---

## 7. Acceptance Criteria

- ✅ Zero hardcoded hex / px
- ✅ Dark mode on every screen
- ✅ Empty / error / loading on every list
- ✅ 6 interactive states per element
- ✅ WCAG 2.2 AA
- ✅ Serif display + Inter UI + Geist Mono numeric
- ✅ Warm palette, no saturated UI chrome

---

## 8. Constraints

- Do NOT touch backend models, serializers, or the 195 passing tests
- Do NOT invent API endpoints unless a separate ticket
- Ship behind `NEXT_UI` feature flag
- One component / screen per AI session
