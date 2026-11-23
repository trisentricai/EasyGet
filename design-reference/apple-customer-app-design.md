# EASYGET Customer App — Apple Design Specification

**Target:** `customer-app-v2` (Flutter / Riverpod / go_router / Dio)  
**Source skill:** `apple-design` — WWDC *Designing Fluid Interfaces*, *The Details of UI Typography*, *Principles of Great Design*, translated to Flutter.  
**Status:** design codified from the shipped Apple-inspired redesign (`9af65f4`). This document is the normative interaction/visual spec; the working interactive concept is `design-reference/easyget-mobile.html`.

---

## 1. Design intent

EASYGET is a quick-commerce app for everyday essentials. The interface should feel calm, certain and fast — not decorative. Every motion and material choice below serves Apple's eight principles:

| Principle | EASYGET expression |
|---|---|
| **Purpose** | One job per screen: browse, decide, buy, track. No membership/plan fiction; no feature that does not move a real order forward. |
| **Agency** | Sheets can be grabbed, reversed and dismissed; removals offer **Undo**; destructive actions confirm once; the user can leave any screen via the 5-tab nav or system back. |
| **Responsibility** | Prices and totals are always server-owned — never computed on device. Notifications are opt-in and fail silently when unavailable. |
| **Familiarity** | Bottom tab bar, iOS-style stacked navigation, grab-handle sheets, stepper controls and standard Material semantics with Apple-style physical behaviour. |
| **Flexibility** | Light/dark schemes, Reduced Motion, large text, 2-column grids, safe-area padding and scrollable sheet bodies for small devices. |
| **Simplicity** | Common path first: Add → cart → checkout. Filters/sorts/variants live one level deeper in sheets. |
| **Craft** | Warm paper/forest palette, 4pt spacing, size-specific type tracking, aligned iconography, no hardcoded colors outside `core/theme/`. |
| **Delight** | Reserved for meaningful moments: a quick-add snapping into an explicit added state, a sheet throwing away with velocity, a cart total settling into place. |

**Emotion target:** *confident and unhurried*. Speed comes from directness, not from more animation.

---

## 2. Visual system

### 2.1 Color (source: `lib/core/theme/tokens.dart`)

| Role | Light | Dark | Use |
|---|---|---|---|
| Canvas | `#FAF6EF` | `#12110F` | Screen background — warm, never pure white/black |
| Surface | `#FFFFFF` | `#1B1A17` | Cards, sheets, elevated blocks |
| Sunken | `#F1EAE0` | `#26241F` | Inputs, tracks, chips |
| Ink | `#1B1712` | `#F4EFE7` | Primary text |
| Muted / Faint | `#655D52` / `#A79C8F` | `#A79C8F` / `#6F675C` | Secondary / tertiary text |
| Brand | `#0C3B2E` | `#0C3B2E` | Monogram, identity |
| Primary | `#0E7A4D` | `#3AA76D` | CTAs, selected states |
| Primary tint | `#DDF0E4` | `#14342A` | Selected pills, added-state bars |
| Marigold | `#E79B12` | `#FFB020` | Badges, savings, cart count |
| Border | `#E7DFD3` | `#2B2823` | Hairlines, outlines |
| Obsidian glass | `rgba(20,18,16,.70)` | same | Overlay pills, sheet handles |

**Rule:** color lives on a solid layer; translucent chrome carries only neutral ink + blur.

### 2.2 Space, radius, elevation

- Spacing is a 4pt scale: `xs 4 · sm 8 · md 12 · lg 16 · xl 20 · xxl 24 · xxxl 32 · huge 48`.
- Radii: card `18`, image `14`, input `14`, button `16`, sheet `24`, pill `999`.
- Material weight: **chrome** (nav/app bar) = strongest blur `18–22px`, `~0.78` opacity; **sheet** = `24px` blur, `~0.94` fill; **card** = soft shadow, no blur unless explicitly a glass card.
- Never stack a light translucent surface on another light translucent surface.

### 2.3 Typography

- Default to the platform system family (`AppTypography`); no decorative face.
- Large text: tight leading (`~1.05–1.15`) and **negative** tracking (`-0.02em` at display sizes).
- Body/UI: near-zero tracking, comfortable leading (`~1.4–1.5`).
- Emphasis comes from weight + size + leading together, not color alone.
- Tabular numerals for prices, counts and bill rows.

---

## 3. Screen designs

| Screen | Job | Design decisions |
|---|---|---|
| **Boot / Login / Register** | Trusted entry | Plain language, inline validation, no blocking splash beyond the real token check. Primary action uses a full-width pill with pointer-down press color. |
| **Home** | Orient and entice | Frosted app bar over a warm canvas. Delivery-ETA pill, category rail, “Hot sales / Top rated / New arrivals” rails, then the full catalog. Every card is a real product with real price/stock. |
| **Browse** | Find by category | Category chips (horizontal, snap-scrolling), count + Filter/Sort toolbar. 2-column grid with 12dp gap. Filter/Sort are draggable sheets, not inline accordions. |
| **Search** | Find by name | Search field owns focus; recent searches and category shortcuts when empty; suggestions and paginated results when typing. Voice input is a visible affordance. Recents are local-only. |
| **Product detail** | Decide and add | Hero image, price blocks, variant selection, pincode check, story/reviews, sticky Add bar. Add is the single primary action; multiple-choice variants open an interruptible sheet. |
| **Cart** | Review and correct | Server-owned bill block, coupon row, line cards with stepper, Undo on remove, trust ticker. Checkout bar is persistent but gets out of the way on empty/error states. |
| **Checkout** | Commit | Sections in order: address → slot → payment → bill. Real COD/UPI paths only. Add-address is a sheet; success is a confirmation, not a celebration. |
| **Orders / Order detail** | Track | Active/Past segments, status timeline, items, cancellation with confirmation. Tracking communicates “where it is” before “how it looks”. |
| **Account / Addresses / Wishlist / Notifications** | Manage | Settings grouped by proximity; addresses use radio-default semantics; wishlist preserves the same card language as Browse; notifications mark-read is explicit. |
| **Global shell** | Wayfinding | Five noun tabs — **Home · Browse · Search · Cart · Orders** — with cart badge. Selected tab uses a stadium indicator and brand-ink icon. |

---

## 4. Interaction & motion specification

### 4.1 Response — kill latency
- Feedback begins on **pointer-down**, not release. Tabs and cards give immediate haptic/visual acknowledgement.
- Haptics are fire-and-forget (`unawaited`) so a platform-channel delay never blocks the real add/navigation call.
- During a drag, the UI tracks the finger continuously at **1:1**.

### 4.2 Direct manipulation
- `FluidSheet` drag zone is the handle + header only; scrollable bodies keep their own gestures.
- Movement respects the grab point: offset is `pointer.dy - startY`, never a snap to sheet center.
- A ~10px threshold separates a tap from a drag before direction commits.

### 4.3 Interruptibility — the single most important rule
- On pointer-down, any running settle spring is stopped and the new gesture starts from the **current on-screen offset** (`_offset`), never a logical target.
- No input lockout during transitions; a sheet can be grabbed again mid-flight and reversed.
- Velocity is carried through a re-target, so reversal never hits a “brick wall”.

### 4.4 Springs
| Interaction | Damping ratio | Response / stiffness |
|---|---|---|
| Default UI settle | `1.0` (critical) | `0.3–0.4s` |
| Snap-back after a drag | `0.86` — slight, earned overshoot | `stiffness 320`, `mass 1` |
| Dismiss / exit | `1.0` — no bounce | `stiffness 320`, `mass 1` |

Implemented in `lib/core/widgets/fluid_sheet.dart` via `SpringSimulation`.

### 4.5 Velocity handoff & momentum projection
- Sample the last **~120ms** of pointer positions; if the user paused, fall back to the last two samples.
- Hand the release velocity directly to the spring.
- Dismiss decision uses a projected endpoint: `offset + velocity * 0.5`, with thresholds `projected > 130`, `velocity > 900 && offset > 20`, or `offset > height * 0.5`.
- **Gap:** replace the fixed `0.5` with Apple's exponential projection (`project(v) = v/1000 * 0.998 / (1 - 0.998)`) and choose the nearest snap point. See §6.

### 4.6 Spatial consistency
- Sheets enter from the bottom and exit to the bottom — symmetric path.
- The drag handle and header join one continuous grab zone; no separate “close” gesture with a different exit.
- Dialogs anchored to a row (e.g. coupon) inherit that row's spatial context.

### 4.7 Rubber-banding
- Past the resting point or the screen bottom, resistance ramps progressively:
  `(overshoot * dimension * 0.55) / (dimension + 0.55 * |overshoot|)`.
- No hard stops; the boundary should feel responsive but finite.

### 4.8 Materials & depth
- App bar and bottom nav are frosted translucent chrome; content scrolls underneath.
- Sheets are heavier: stronger blur, dimming scrim on modal tasks, no scrim for parallel non-blocking panels.
- Use a scroll-edge blur/gradient where floating chrome meets content — avoid a permanent hard 1px divider.
- Over blurred surfaces, use higher-contrast ink and slightly heavier weight.

### 4.9 Multimodal feedback
- **Causality:** haptic fires on the actual event (tab switch, drag grab, snap-to-dismiss, add).
- **Harmony:** visual and haptic fire on the same frame; no delayed platform-channel awaits.
- **Utility:** no haptics on passive scrolling or repeated low-value events.

### 4.10 Reduced motion & accessibility
- `MediaQuery.disableAnimationsOf(context)` → no translation during drag, immediate pop on dismiss; fades ≤ `AppMotion.micro` remain.
- Respect increased contrast by strengthening borders and raising surface opacity.
- Keep hit targets ≥ `44×44`, preserve semantics on all controls, and let text scale without clipping fixed-height slots.

---

## 5. Implementation map

| Pattern | File | Status |
|---|---|---|
| Spring sheet, rubber-band, velocity handoff, reduced motion | `lib/core/widgets/fluid_sheet.dart` | ✅ Implemented |
| Sheet adoption (variant, filter, sort, browse filter, coupon) | `lib/features/catalog/presentation/widgets/*_sheet.dart`, `browse_filter_sheet.dart`, `cart_screen.dart` | ✅ Implemented |
| Frosted 5-tab navigation + press state | `lib/core/widgets/bottom_nav.dart` | ✅ Implemented |
| Translucent app bar / search chrome | `lib/core/widgets/app_bar.dart`, `search_bar.dart` | ✅ Implemented |
| Product card polish, circular Add, haptic + explicit added state | `lib/features/catalog/presentation/widgets/product_card.dart` | ✅ Implemented |
| Warm palette, radii, motion tokens | `lib/core/theme/tokens.dart`, `app_theme.dart` | ✅ Implemented |
| Server-owned pricing / no fake plans | cart, product, checkout providers | ✅ Preserved |
| Apple exponential momentum projection | `fluid_sheet.dart` | ✅ Implemented — named `decay = 0.998` model |
| Scroll-edge fade instead of hard app-bar divider | `core/widgets/app_bar.dart` | ✅ Implemented — scroll-driven gradient, no permanent divider |
| Dynamic Type growth for reserved slots | product card name/brand/price slots | ✅ Implemented — `ConstrainedBox(minHeight:)` |
| Pointer-down press feedback on cards | `core/widgets/pressable_scale.dart` + product card | ✅ Implemented — reduced-motion aware |
| Fire-and-forget haptics everywhere | all `HapticFeedback` call sites | ✅ Implemented — every call wrapped in `unawaited()` |

---

## 6. Applied polish pass

All five items from the original gap list are now implemented in `customer-app-v2`:

1. **Momentum projection** — `FluidSheet` uses the named Apple decay model
   (`velocity / 1000 * 0.998 / (1 - 0.998)`) instead of a magic `0.5`, while
   keeping the velocity handoff and interruptible spring.
2. **Scroll-edge material** — `EasyGetAppBar` listens for vertical scroll
   updates and fades a translucent gradient in only when content is under it.
3. **Dynamic Type** — product card name/brand/price slots are
   `ConstrainedBox(minHeight:)`, so the 1× geometry is unchanged but large
   text scales without clipping.
4. **Press state** — `PressableScale` gives cards a pointer-down response;
   buttons keep their Material press overlay. Reduced Motion disables the scale.
5. **Haptic audit** — every `HapticFeedback` call is fire-and-forget via
   `unawaited()` and fires only on a causal event.

---

## 7. Acceptance criteria

- [x] A sheet tracks the finger 1:1 and can be reversed mid-flight without a jump.
- [x] A fast downward flick dismisses; a slow short drag snaps back.
- [x] Dismiss exits downward and never springs back up past the screen bottom.
- [x] Reduced Motion: no sheet translation, immediate pop, fades only.
- [x] Dark mode keeps text legible on frosted chrome with no nested light glass.
- [x] Prices/totals in cart and checkout always match the API response.
- [x] All primary actions have ≥44px targets, visible focus/press state, and semantics.
- [x] `flutter analyze` clean; `flutter test` green (`342 passed`).

**Verification run:** `flutter analyze` → *No issues found!*; `flutter test` →
*342 passed*; `flutter build apk --debug` → built successfully.

---

**Reference concept:** `design-reference/easyget-mobile.html` — interactive prototype with pointer-down feedback, draggable sheets, spring physics and reduced-motion fallbacks.
