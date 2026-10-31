# EASYGET — DESIGN.md

> Two surfaces, one brand family.
> - **Web** (`customer-web`, `admin-web`): hybrid direction, frozen tokens in §1.
> - **Mobile** (`customer-app`, shopper): **Fresh Market** direction, tokens in §10.
> Paste into EVERY AI prompt alongside CONTEXT.md.

---

## 0. Direction Statement

### Web (frozen)

EASYGET web is a **curated neighborhood marketplace** — the visual calm of a
specialty grocer, the editorial pacing of a luxury boutique, and the
functional clarity of a delivery platform.

**The interface recedes.** Products and store stories take center stage.
Density is present but disciplined — like Instacart, not like Flipkart.
Every surface feels considered, not assembled.

North stars: Tata CLiQ Luxury (slow commerce), Patyka (organic warmth),
Instacart (functional density), Aldi (clean storefront).

### Mobile — Fresh Market (new direction, supersedes the old indigo/amber app)

The phone is where EASYGET gets **fast, thumb-driven, and joyful**.
Where web whispers, mobile moves: big touch targets, one-thumb buying,
delivery time always visible, prices in tabular figures that scan instantly.

**Personality:** a friendly morning market, not a boutique and not a
warehouse. Warm paper background, deep-evergreen brand ink, one lively leaf
green for every "buy" moment, a single marigold accent for speed and rating.
No purple, no blue, no Material-default look anywhere.

North stars: Blinkit (10-minute clarity, thumb-first), BigBasket (grocery
trust, honest pricing), Aldi (clean, no theater). EASYGET mobile takes their
usability and gives it a warmer, ownable skin.

**Five principles (test every screen against these):**
1. **Buy in two taps.** Product → Add → stepper. Never a detour to buy.
2. **Delivery time is always on screen.** ETA pill in header, cart, checkout.
3. **Prices scan, never shout.** Tabular figures, muted MRP, honest green
   savings line. No red SALE theater.
4. **Thumb zone owns actions.** Primary CTAs bottom-anchored, 54dp tall,
   full-width on checkout flows.
5. **The app works on a shaky 4G.** Skeletons first, cached images, no dead
   spinners, offline state with retry — never a blank screen.

---

## 1. Frozen Tokens (WEB ONLY — customer-web / admin-web)

> Do not change these values: shipped web code and hard rules reference
> this section. Mobile uses §10 instead.

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

Mobile additions (apply on top of everything above):
- ❌ Material-default look: seed-indigo `ColorScheme`, amber accents,
  Roboto, stock `NavigationBar`/`FAB` styling — every M3 widget restyled
  to §10 tokens
- ❌ More than 5 bottom tabs; tab labels are nouns (Home, Browse, Search,
  Cart, Orders) — never actions
- ❌ Full-screen `CircularProgressIndicator` on any list — skeleton only
- ❌ Primary CTA above the thumb zone on checkout flows (must be
  bottom-anchored, full-width, 54dp)
- ❌ Price in non-tabular figures (columns of prices must align)
- ❌ Client-side price math shown as truth — totals always come from
  `/cart/` and `/orders/` responses

---

## 3. Component Rules (web — frozen)

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

## 4. Screen Specs (web — frozen)

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

Mobile note: touch targets are **48×48dp minimum** on `customer-app`
(stricter than web); every icon-only button gets a `Semantics` label;
haptics always paired with a visual change, never as the only feedback.

---

## 6. Performance Targets

- LCP < 2.0s on 4G
- CLS < 0.05
- INP < 200ms
- Lighthouse: Perf ≥ 90, A11y ≥ 95, BP ≥ 95
- Images: AVIF/WebP + srcset + fixed aspect ratios + blurhash

Mobile additions: cold start < 3s on mid-range Android; jank-free 60fps
scrolls (no image decoding on the UI thread — `cached_network_image`
only); release APK stays lean (no unused font weights — Inter 400/500/700
+ Fraunces 500/600 only); first contentful paint = skeleton, never blank.

---

## 7. Acceptance Criteria

- ✅ Zero hardcoded hex / px
- ✅ Dark mode on every screen
- ✅ Empty / error / loading on every list
- ✅ 6 interactive states per element
- ✅ WCAG 2.2 AA
- ✅ Serif display + Inter UI + Geist Mono numeric
- ✅ Warm palette, no saturated UI chrome

Mobile acceptance checklist lives in §16 (same bar, mobile wording —
numeric face is Inter tabular, see §10).

---

## 8. Constraints (web — frozen)

- Do NOT touch backend models, serializers, or the passing tests
  (288 must stay green)
- Do NOT invent API endpoints unless a separate ticket
- Ship behind `NEXT_UI` feature flag
- One component / screen per AI session

====================================================================
MOBILE — FRESH MARKET SYSTEM (§§9–16)
====================================================================
The old indigo/amber Material app is retired by this section.
Everything below is the build spec for `customer-app`.

---

## 9. Mobile Tokens (§10 is normative; this section is the why)

- **Brand ink** (deep evergreen) = trust + recognition. Headers, active
  tab, brand screens. Never a full-page background except splash.
- **Leaf CTA green** = the only color that means "buy". Add buttons,
  steppers, checkout CTA, in-stock dots. Nothing else may use it.
- **Marigold** = speed + delight, rationed: ETA pill, rating stars,
  offer tags. Never buttons, never large surfaces.
- **Warm paper canvas** (never pure white/black) + hairline borders,
  shadow-last — same calm as web, tuned for sunlight readability.
- **Fraunces** display serif (soft, market-fresh, legible small) +
  **Inter** UI + **Inter tabular figures** for every number.
  (Geist Mono is web-only — it is not on Google Fonts, so mobile uses
  `FontFeature.tabularFigures()` instead.)

---

## 10. Mobile Tokens (normative — zero hardcoded values outside this section)

> Flutter mapping: define once in `app_theme.dart` as `const Color(0xFF…)`,
> wire into `ColorScheme` per the slot table, expose spacing/radii/motion
> as `static const` on a `Tokens` class. No `Color(0x…)` literals in
> feature code, no magic numbers for padding/radius/duration.

### 10.1 Color — light
```
canvas        #FAF6EF   scaffold / page background
surface       #FFFFFF   cards, sheets, app bars
sunken        #F1EAE0   image wells, pressed states, skeleton base
ink           #1B1712   primary text
muted         #655D52   secondary text (4.5:1 on canvas)
faint         #A79C8F   captions, placeholders
border        #E7DFD3   hairlines
borderStrong  #D5C9B8   inputs, selected rings

brand         #0C3B2E   headers, active tab, brand moments (on: #FFFFFF)
primary       #0E7A4D   every BUY action (on: #FFFFFF)
primaryDark   #0A5C3B   pressed CTA
primaryTint   #DDF0E4   selected chips, tab indicator, in-stock wash
marigold      #E79B12   ETA pill text/star fill/offer tags (on ink)
marigoldWash  #FCEFD4   offer tag background

success       #15803D   verified, delivered, in-stock
warning       #B45309   low stock, ETA delay
danger        #B91C1C   errors, destructive (remove, cancel)
```

### 10.2 Color — dark (warm charcoal, never pure black)
```
canvas        #12110F
surface       #1B1A17
sunken        #26241F
ink           #F4EFE7
muted         #A79C8F
faint         #6F675C
border        #2B2823
borderStrong  #3E3A33

brand         #0C3B2E   brand panels stay deep (on: #FFFFFF)
primary       #3AA76D   lightened for 4.5:1 on dark canvas (on: #06281C)
primaryDark   #2C8757   pressed CTA
primaryTint   #14342A   selected chips, tab indicator wash
marigold      #FFB020   (on: #1B1712)
marigoldWash  #3A2C10

success       #4ADE80
warning       #FBBF24
danger        #F87171
```

### 10.3 ColorScheme slot mapping (both modes)
```
primary            → primary            onPrimary          → §10.1/10.2 on-color
primaryContainer   → primaryTint        onPrimaryContainer → primary (light) / ink (dark)
secondary          → marigold           onSecondary        → ink
surface            → surface            onSurface          → ink
surfaceContainerLowest → canvas
surfaceContainerLow    → surface
surfaceContainerHigh   → sunken
outline            → border             outlineVariant     → borderStrong
error              → danger             onError            → #FFFFFF
```
`tertiary`, `inverse*` slots: do not use. Anything needing brand ink
uses an explicit `brand` extension color, not a scheme slot.

### 10.4 Typography (packages: add `google_fonts`)
```
Display  Zodiak   600/500   28/24sp, -0.5, 1.15   hero, section display
Headline Inter   700        20sp,   -0.25, 1.25   screen titles, PDP name
Title    Inter   600/700    17/16/15sp, -0.25     cards, sheet titles
Body     Inter   400/500    15/14sp, 0, 1.55      descriptions, lines
Label    Inter   500/600    13/12/11sp, +0.2      tabs, chips, captions, ETA
Price    Inter   700 tabular 18/16sp             every price, total, ETA mins
```
Rules: max 2 weights per screen; product names Inter (never serif);
EVERY number (price, qty, ETA, order id, rating) sets
`FontFeature.tabularFigures()`; line-height ≥ 1.5 for body (readability).

### 10.5 Spacing (dp, 4pt base — no odd numbers)
```
4  8  12  16  20  24  32  48
page gutter 16 · card padding 14–16 · grid gaps 12 · section gaps 24–32
```

### 10.6 Radii
```
card 18 · image 14 (inside card) · button/CTA 16 · input 14
sheet 24 top · chip/pill/avatar 999 · badge 999
```

### 10.7 Elevation — hairline first (same law as web)
Cards: 1dp `border` hairline, elevation 0. Pressed/hover: `sunken` fill.
Sheets/snackbar: elevation 3 + scrim `ink @ 40%`. No shadows on product
surfaces, ever.

### 10.8 Motion + haptics
```
micro 180ms  easeOutCubic   press, toggle, stepper tick, chip select
base  280ms  easeOutCubic   sheets, snackbars, route push (fade + 4% rise)
page  350ms  easeOutCubic   tab switch, gallery swipe settle
HapticFeedback.light()      Add tap, stepper +/−, chip select, tab switch
HapticFeedback.medium()     order placed, payment success
HapticFeedback.selectionClick()  variant/size option pick
```
Reduced motion (`MediaQuery.disableAnimations`): skip rise/slide, keep
fades ≤ 180ms. Haptics always accompany a visual change.

### 10.9 Touch, safe-area, icons, imagery
- Touch target **48×48dp minimum** (stepper buttons, chips, icon buttons).
- Respect `SafeArea` top + bottom on every screen; sticky CTAs sit above
  the bottom inset with 12dp padding.
- Icons: outlined rest / filled selected, 22dp in bars, 20dp inline.
- Imagery: `cached_network_image` everywhere; card 4:5, rail 1:1, PDP
  gallery 1:1, banner 16:7; `sunken` well behind every image; error icon
  (never grey box) when a URL dies.

---

## 11. Mobile Components (anatomy + placement)

Global law: every component ships light + dark, 48dp targets, skeleton /
empty / error variants where it loads data, and token-only motion.

### 11.1 Buttons
- **Primary CTA**: full-width, 54dp, radius 16, `primary` fill / white 16sp
  700 label. Placement: bottom-anchored above safe-area (Sign in, Place
  order, Proceed to checkout, Add address). Loading: label → 22dp spinner,
  button stays sized (no layout jump), disabled.
- **Secondary**: `OutlinedButton`, 52dp, `borderStrong` border, ink label.
  Placement: beside/inline (Retry, Change address, View all).
- **Ghost/TextButton**: marigold-free ink/muted text. Placement: helper
  rows ("Create an account", "Apply coupon").
- **Destructive**: text button in `danger`. Placement: remove line item,
  cancel order, sign out, delete address (always with confirm sheet).
- States: rest / pressed (`primaryDark` or `sunken`) / disabled
  (ink 38% on sunken, no events) / loading. 6-state keyboard rules are
  web-only; mobile needs rest/pressed/disabled/loading + Semantics label.

### 11.2 ProductCard — 3 densities, one Add system
Shared anatomy top→bottom: image well (sunken, radius 14) → veg badge dot
→ name (Inter 600, 2-line clamp) → weight/variant line (muted 12sp) →
PriceBlock → Add control. RatingPill floats top-left on image (marigold
star + tabular rating).
- **Rail card** (home rails, search suggestions): 148dp wide, image 1:1.
- **Grid card** (browse/search PLP): 2 columns, 12dp gap, image 4:5.
- **Line card** (cart, order detail): 76dp thumb left, 3-line middle,
  stepper right.
**Add stepper morph** (identical on all three): `Add` pill (primary
outline, 40dp) → on tap becomes `− qty +` stepper (primaryTint fill,
primary icons, light haptic, 180ms). Qty 0 → morphs back. Max qty =
stock; at cap, `+` disables with tooltip "Only N available".

### 11.3 PriceBlock
Row: price (Inter 700 tabular 16sp, ink) + MRP (strikethrough muted 13sp,
only if higher) + save line ("Save ₹40 · 20% off", success-green 12sp 600,
only if real). Never red, never "SALE".

### 11.4 RatingPill / QtyStepper / VariantSheet
- **RatingPill**: marigold star + tabular `4.3` + muted `(212)`. Taps open
  reviews (PDP) — decorative elsewhere.
- **QtyStepper**: defined in 11.2; standalone in cart line cards.
- **VariantSheet** (bottom sheet, radius 24 top): option rows 56dp with
  radio semantics, price delta tabular right, thumb 44dp left; footer =
  primary CTA with live price ("Add · ₹240"). Used for multi-variant
  products everywhere instead of inline swatches.

### 11.5 Navigation chrome
- **AppBar**: surface fill, no elevation, hairline bottom border. Left:
  back (inner pages) or store mark (tabs). Title: Headline 20sp 700.
  Right: search icon (tabs) / wishlist heart (PDP) / overflow (orders).
  Home tab replaces title with delivery-address row (chevron → address
  sheet) + ETA pill (marigold wash, timer icon, tabular "12 min").
- **SearchBar**: persistent under Home/Browse app bars, 52dp, sunken fill,
  radius 16, hint "Search atta, milk, soap…", mic + camera icons decorative
  v1. Taps → `/search` with autofocus + keyboard up.
- **BottomNav**: exactly 5 tabs — Home (storefront), Browse (grid),
  Search, Cart (badge = `cartCountProvider`, marigold dot + tabular count,
  99+ cap), Orders (receipt). Selected: brand-ink icon + 12sp 600 label +
  primaryTint indicator pill; unselected muted. Haptic light on switch.
  Badge animates scale on count change.

### 11.6 Sheets, chips, feedback
- **FilterSheet / SortSheet** (browse): bottom sheet, radius 24 top,
  drag handle, 56dp rows, toggles (Switch) not checkboxes; footer twin
  buttons (Clear ghost + Apply primary showing live count "Show 42").
- **Chips**: 44dp tall, radius 999, sunken rest / primaryTint + primary
  700 label selected; horizontal scroll, 8dp gap.
- **SectionHeader**: Title 17sp 700 left + ghost "See all →" right
  (marigold-free). Never centered.
- **Snackbar**: floating, radius 14, ink fill / canvas text, 1 action
  (Retry / View cart / Undo). Errors are human sentences from
  `ApiException` — never codes, never "Exception:".
- **Skeletons**: shimmer-free pulse on `sunken` blocks matching the exact
  target layout (card grid, rail, line rows). Full-screen spinner is banned.
- **Empty / Error / Offline**: centered illustration dot (brand wash),
  Title + muted Body + primary CTA (Shop now / Retry / Try again).
  Offline adds "You're offline" label and queues nothing silently.

---

## 12. Mobile Screens (build order = numbered order, one per session)

Conventions: `→` = top-to-bottom layout. Logic names real providers.
API = exact `METHOD /path/` from CONTEXT.md (no invented endpoints).
Every list screen: skeleton → populated / empty / error(+retry).

### S1 · Boot / Splash (`/` → redirect)
1. Full-screen `brand` with cream "EG" mark + "EASYGET" letterspaced.
2. Logic: `authBootProvider` awaits `authControllerProvider` → saved token
   ? `GET /users/me/` : signed out. Router gate holds all redirects until
   boot done. Max 1.2s, then route (no lingering splash).
3. API: `GET /users/me/`.

### S2 · Login (`/login`, public)
1. Brand mark 72dp → "Welcome back" (Fraunces 28) → subtitle.
2. Email field → password field (obscure toggle, 8-char rule) → primary
   CTA "Sign in" (52–54dp, loading locks size) → divider "or" → Google
   button (web shows clean "use email" message) → "New here? Create an
   account" ghost → `/register`.
3. Logic: `authControllerProvider.signIn` → tokens saved → `go('/home')`.
   Failure → snackbar with cleaned message, fields KEEP input (router is
   stable — never remounts mid-flight). First tap may take ~60s on a cold
   backend: spinner + "Waking up the store…" hint after 8s.
4. API: `POST /auth/login/` → `{ access, refresh, user }`.
   Then `POST /cart/merge/ { guest_token }` if a guest cart exists.

### S3 · Register (`/register`, public)
1. Same shell as S2 → "Create your account" → name → email → password
   (8+) → phone (optional) → role picker (Customer / Merchant, segmented)
   → primary CTA "Create account".
2. Logic: auto-login on success (no OTP — gate retired), land `/home`.
   Field errors inline (from DRF field-error payloads, mapped per field).
3. API: `POST /auth/register/ { email, password, name, [phone, role] }`
   → session. (`/verify` route retired — do not build.)

### S4 · Home (`/home`, tab 1)
1. AppBar: address row + ETA pill → SearchBar → offer ticker (single
   quiet line, admin text — no animation wars) → banner carousel (16:7,
   edge-to-edge, dots) → "Shop by category" grid (4-col, 8 tiles + See
   all → `/browse`) → product rails ("Fresh picks", "Deals",
   horizontal 148dp cards) → store story block (image + Fraunces line).
2. Logic: `storefrontProvider` (`GET /storefront/easyget/`), section
   products via `_sectionProductsProvider`; pull-to-refresh re-fires all;
   rails paginate horizontally (no full reload).
3. API: `GET /storefront/easyget/`, `GET /banners/`,
   `GET /coupons/active/` (offer line), `GET /products/` per rail.

### S5 · Browse / PLP (`/browse?category=`, tab 2)
1. AppBar + SearchBar → category chips row (sticky under bar, synced with
   `?category=`) → toolbar (count "42 items" + Filter + Sort buttons) →
   2-col grid cards (12dp gap) → infinite scroll (paged) → FilterSheet /
   SortSheet.
2. Logic: `browseControllerProvider` (query+filters+sort+page),
   `categoryListProvider`, `catalogRepositoryProvider`. Filter changes
   reset page=1. Sort ∈ relevance / price_asc / price_desc / newest /
   rating. Empty category → empty state with "Clear filters".
3. API: `GET /products/?category&brand&min_price&max_price&discount&sort&page`,
   `GET /categories/`, `GET /brands/`.

### S6 · Search (`/search?q=`, tab 3)
1. Autofocus field (recent searches as chips below when empty) → trending
   searches (from API) → live suggestions dropdown (debounced 300ms) →
   results = PLP grid (S5 cards) → recent views rail at bottom.
2. Logic: `searchRepositoryProvider`; suggestions cancel in-flight on
   new keystroke; empty query shows history + trending (never blank).
3. API: `GET /search/?q=`, `GET /search/suggestions/?q=`,
   `GET /search/trending/`.

### S7 · PDP (`/product/:slug`)
1. Gallery (1:1, swipe + dots, hero transition from card image) →
   wishlist heart (top-right over gallery) → name (Headline) → variant
   line + RatingPill + rating count → PriceBlock → variant selector
   (inline ≤3 options else VariantSheet) → delivery row (ETA pill +
   pincode checker inline) → sticky bottom bar: PriceBlock left + Add /
   stepper right (thumb zone) → "The Story" block → rating distribution
   + reviews (collapsed, paged) → related rail.
2. Logic: `_productProvider` (family by slug); variant change swaps price/
   stock without reload; Add uses line-card stepper rules; pincode check
   is quiet inline (no celebration); reviews post only if bought
   (verified flag from API).
3. API: `GET /products/:slug/`, `GET /pincode/:code/`,
   `GET /products/:slug/reviews/`,
   `GET /products/:slug/rating-distribution/`,
   `POST /products/:slug/reviews/`, wishlist `POST /wishlist/`.

### S8 · Cart (`/cart`, tab 4)
1. AppBar "Your cart" + item count → ETA pill row → coupon row
   ("Apply coupon" → sheet with `GET /coupons/active/` list + Validate) →
   line cards (76dp thumb, stepper, remove-danger) → bill block (subtotal,
   discount green, delivery fee, total — ALL from API, tabular) →
   bottom-anchored primary CTA "Proceed to checkout · ₹X".
2. Logic: `cartControllerProvider` / `cartCountProvider`; stepper hits
   `PATCH /cart/items/:id/`, remove is swipe + Undo snackbar (5s);
   coupon validate inline errors; totals never computed client-side.
3. API: `GET /cart/`, `POST /cart/items/`, `PATCH /cart/items/:id/`,
   `DELETE /cart/items/:id/`, `POST /coupons/validate/`.

### S9 · Checkout (`/checkout`, auth)
1. Steps header (Address → Slot → Payment, numbered, no stepper theater)
   → address cards (radio, Add/Edit → address sheet) → slot picker
   (Today/Tomorrow chips + time windows, Instacart pattern) → payment
   methods (UPI/Card/COD rows from API) → bill block (server truth) →
   bottom CTA "Place order · ₹X" (double-tap guard, idempotent).
2. Logic: `_addressesProvider`, `_storesProvider` (slot source),
   `checkoutRepositoryProvider`; order created THEN payment intent
   (never before); COD skips intent; success → clear cart → `/order/:id`
   + medium haptic + confetti-free calm confirmation.
3. API: `GET /addresses/`, `POST /addresses/`, `PATCH /addresses/:id/`,
   `POST /orders/ { address_id, payment_method, coupon_code }`,
   `GET /payments/methods/`, `POST /payments/intent/`,
   `POST /payments/confirm/`.

### S10 · Orders (`/orders`, tab 5)
1. Segmented tabs (Active / Past) → order cards (id tabular, date, status
   pill, 3 thumbs, total) → tap → detail. Cancel action (danger ghost)
   only on cancellable statuses.
2. Logic: `ordersListProvider` / `ordersRepositoryProvider`; pull-to-
   refresh; status pills color-map (transit=marigold wash, delivered=
   success, cancelled=muted).
3. API: `GET /orders/`, `POST /orders/:id/cancel/`.

### S11 · Order detail + Track (`/order/:id`, auth)
1. Status hero (brand wash, big icon, ETA/countdown tabular) → vertical
   timeline (OrderEvent list, current node primary) → items (line cards,
   reorder Add buttons) → address + bill blocks → actions (Cancel if
   allowed, Help ghost, Reorder primary if delivered).
2. Logic: `_orderDetailProvider`; track polls timeline (30s while active,
   stops when delivered/cancelled — no socket yet).
3. API: `GET /orders/:id/`, `GET /orders/:id/track/`.

### S12 · Account (`/account`, auth, reachable via Home avatar)
1. Profile header (avatar monogram, name, phone) → rows: Addresses,
   Wishlist (count), Reviews, Coupons, Payments, Settings (theme
   Light/Dark/System segmented, notifications toggle), Help, Sign out
   (danger, confirm sheet).
2. Logic: `_profileProvider` (`GET /users/me/`), `accountRepositoryProvider`
   for patch (name/phone). Sign out clears tokens + Google session →
   `/login`.
3. API: `GET /users/me/`, `PATCH /users/me/`.

### S13 · Addresses (`/addresses`, auth)
1. Radio list of AddressCards (label chip Home/Work, 2-line address,
   phone tabular) → default badge → Add/Edit bottom sheet (pincode +
   validated fields) → delete (danger + confirm).
2. Logic: `_addressListProvider`; default flows into checkout preselect.
3. API: `GET /addresses/`, `POST /addresses/`, `PATCH /addresses/:id/`,
   `DELETE /addresses/:id/`.

---

## 13. Mobile Route Map (mirrors `app_router.dart` — update both together)
```
public (no session):   /login · /register
auth required:         /home /browse /search /cart /orders /product/:slug
                       /checkout /order/:id /account /addresses
retired:               /verify (OTP gate removed — route stays as dead end,
                       do not link it anywhere)
tabs (StatefulShell):  /home /browse /search /cart /orders  (5, fixed order)
redirect law:          booted=false → hold · anon+private → /login ·
                       session+public → /home
transitions:           push = fade + 4% rise 280ms · tabs = 350ms fade ·
                       gallery = hero on image · sheets slide up 280ms
router law:            GoRouter created ONCE + refreshListenable; NEVER
                       rebuild the router on auth change (remounts wipe
                       forms and drop in-flight results — see Oct 2026 fix)
```

---

## 14. Mobile Logic Rules (apply on every screen)

- **Session**: boot restores via saved tokens + `GET /users/me/`; any 401
  refreshes ONCE via `POST /auth/refresh/` then retries; second 401 →
  clear tokens → `/login`. Never loop refreshes.
- **Guest cart**: keep a local `guest_token` pre-login; after sign-in
  `POST /cart/merge/` then drop it. Badge = server count after merge.
- **Pricing truth**: display only server totals; client math (if any) is
  preview-only and labeled "est.".
- **Stock**: stepper cap = available qty; 0 stock → card shows "Notify me"
  ghost (no dead Add button); never sell past inventory.
- **Search**: 300ms debounce, cancel in-flight, history on device
  (last 8), trending from API.
- **Images**: `cached_network_image` + fixed aspect (no layout jump) +
  `sunken` well + error icon. Preload first 2 PDP gallery images.
- **Lists**: paged everywhere (page size 20); pull-to-refresh refires the
  screen's providers; infinite scroll has footer skeleton + end cap
  ("You've seen everything").
- **Fonts**: add `google_fonts` (Inter 400/500/600/700, Fraunces 500/600);
  offline first-run falls back to system — layout must not depend on the
  webfont metrics.
- **Errors**: every catch → human sentence via `ApiException`; timeouts
  say "waking the store, retry"; 60s+ cold starts show progress hints,
  not dead spinners. Timeouts: connect 90s, receive 60s (free-tier sleeps).
- **No silent queues**: offline writes (cart add, wishlist) attempt live,
  fail loudly with retry — never pretend success.

---

## 15. Mobile API Wiring (screen → calls; all paths under `/api/v1/`)
```
S1  Boot      GET /users/me/
S2  Login     POST /auth/login/ · POST /cart/merge/ (if guest)
S3  Register  POST /auth/register/
S4  Home      GET /storefront/easyget/ · GET /banners/ ·
              GET /coupons/active/ · GET /products/ (rails)
S5  Browse    GET /products/?… · GET /categories/ · GET /brands/
S6  Search    GET /search/?q= · GET /search/suggestions/?q= ·
              GET /search/trending/
S7  PDP       GET /products/:slug/ · GET /pincode/:code/ ·
              GET+POST /products/:slug/reviews/ ·
              GET /products/:slug/rating-distribution/ ·
              POST /wishlist/ · DELETE /wishlist/:product_id/
S8  Cart      GET /cart/ · POST /cart/items/ · PATCH /cart/items/:id/ ·
              DELETE /cart/items/:id/ · POST /coupons/validate/
S9  Checkout  GET /addresses/ · POST /orders/ · GET /payments/methods/ ·
              POST /payments/intent/ · POST /payments/confirm/
S10 Orders    GET /orders/ · POST /orders/:id/cancel/
S11 Track     GET /orders/:id/ · GET /orders/:id/track/ (30s poll, active only)
S12 Account   GET /users/me/ · PATCH /users/me/
S13 Addresses GET /addresses/ · POST /addresses/ · PATCH /addresses/:id/ ·
              DELETE /addresses/:id/
```
Wishlist screen: deferred — heart on cards/PDP only until its own ticket.
No other endpoints exist; anything missing needs a backend ticket first.

---

## 16. Mobile Acceptance + Build Order

**Acceptance (every screen):**
- ✅ Zero `Color(0x…)` / magic numbers outside `app_theme.dart` + `Tokens`
- ✅ Light + dark (dark is designed, not inverted)
- ✅ Skeleton / empty / error / populated on every list
- ✅ 48dp targets, Semantics labels, tabular figures on all numbers
- ✅ Router-stable flows (no remount wipes input), human error strings
- ✅ Fraunces display + Inter UI + tabular numerics; warm palette;
  leaf green ONLY on buy actions; marigold rationed
- ✅ 60fps scrolls, skeletons first paint, cold start < 3s warm < 1s

**Build order (one screen per AI session, in this order):**
1. Tokens + theme (`app_theme.dart`, `Tokens`, ColorScheme mapping)
2. Shared components (buttons, cards, stepper, sheets, states)
3. S2 Login → S3 Register → S1 Boot polish
4. S4 Home → S5 Browse → S6 Search
5. S7 PDP → S8 Cart → S9 Checkout
6. S10 Orders → S11 Track → S12 Account → S13 Addresses
