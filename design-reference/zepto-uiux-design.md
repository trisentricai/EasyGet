# Zepto UI/UX reverse-engineering spec (EasyGet adaptation)

Source: live `https://www.zepto.com/` inspected via browser DOM + computed-style
extraction on 2026-11-26, with location set to Koramangala, Bengaluru so the
real catalogue/price components rendered. Values below are measured, not guessed.
This supersedes the Apple-inspired visual language for the customer surfaces.

## 1. Palette (measured from live computed styles)

| Token | Value | Where it appears |
| --- | --- | --- |
| Zepto pink (primary) | `#F9105E` (`rgb(249,16,94)`) | ADD button text/border/shadow, cart CTA |
| Pink bright | `#FF3269` | hover / emphasis |
| Pink soft | `#FA3778` | secondary accents |
| Ink purple | `#2B1E35` (`rgb(43,30,53)`) | dark text, overlays |
| Deep purple | `#332060` (`rgb(51,32,96)`) | "10 minutes" ETA label |
| Brand purple | `#9A16CA` / `#950EDB` | legacy/promotional surfaces |
| Price green | `#329537` (`rgb(50,149,55)`) | price tag fill |
| Price green edge | `#084121` (`rgb(8,65,33)`) | price tag border + hard shadow |
| Near black | `#101418` (`rgb(16,20,24)`) | headings |
| Muted slate | `#586274` / `#707686` | secondary copy |
| Border | `#E5E7EB` (`rgb(229,231,235)`) | hairlines, dividers |
| Surface | `#FFFFFF` | cards and header |

## 2. Typography

- Family: **Zepto Norms**, `system-ui`, `sans-serif`. We substitute a system sans
  stack (the licensed face is not ours to ship).
- Header ETA: 20px / 700, deep purple.
- Section headings: 20px / 700, near-black.
- Product name: 14px / 600, 3-line clamp, `#262B33`.
- Price: 16px / 700 white on green; pack size 12px muted.
- ADD: 14px / 600, uppercase.
- Small labels: 14px / 450–600.

## 3. Signature component geometry

- **ADD button** — 56×32px, white fill, 1px `#F9105E` border, pink text,
  8px radius, hard offset shadow `1px 1px 0 #F9105E`.
- **Price tag** — green `#329537` fill, white 16/700 price, 1px `#084121`
  border, 6px radius, hard shadow `1.5px 1.5px 0 #084121`; MRP struck through
  beside it in muted text.
- **Product card** — white surface, square-ish image, ADD overlaid on image,
  price tag directly under image, then name (3 lines) and pack size. No soft
  floating shadow — depth comes from hard 1–2px offset shadows.
- **Category tile** — image 100×100 `object-fit: contain` over a label, ~84px
  wide; horizontal scroll rail with "See All".
- **Header** — white, sticky, ~90px desktop; ETA + address on the left,
  pill search (`rounded-lg`, 1px border, `12px 16px` padding) centre,
  Login + Cart on the right.
- **CTA** — `#F9105E` fill, white 16/700, 10px radius, 48px tall
  ("Add to Cart" on PDP).
- **Cart** — right-side drawer (480px desktop); empty state shows "Browse Products".
- **Search** — dedicated route, plain input placeholder "Search for over 70,000
  products", results use the same product cards.
- **PDP** — gallery, green price tag with strikethrough MRP and discount line,
  pink Add to Cart bar, breadcrumb, "Highlights" spec grid, reviews, info.
- **Bottom nav (app)** — flat white bar, pink selected icon/label, 5 nouns:
  Home, Browse, Search, Cart, Orders.

## 4. Interaction language

- Fast, utilitarian feedback: hard shadows and 1–2px state shifts instead of
  long spring animations.
- Quantity steppers use the same pink fill as ADD when active.
- Everything is tappable at ≥32px; primary actions 44–48px.
- Reduced-motion is always honoured.
- Hard constraint retained from the existing app: **no live GPU
  `BackdropFilter` blur** on the Vivo device (Impeller leaks it full-screen).
  Zepto's flat surfaces suit this naturally.

## 5. EasyGet mapping

- Keep every existing API-backed flow untouched (cart pricing stays
  server-owned; coupons revalidated server-side; auth/Google unchanged).
- Web: a final `zepto.css` cascade layer retargets existing class names.
- App: Zepto tokens in `core/theme/tokens.dart`; shared catalog widgets
  (card, price, stepper, category tile), chrome (app bar, search, bottom nav)
  and PDP/cart CTAs adopt them.
- Brand mark stays **EG**; product copy stays EasyGet's own — this is a visual
  and interaction adaptation, not a Zepto clone.
