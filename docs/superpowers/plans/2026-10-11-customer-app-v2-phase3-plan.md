# Phase 3 — Screens S4–S13 (customer-app-v2)

Goal: replace every shell-tab placeholder + inner-route placeholder with its
DESIGN §12 screen, composing the Phase-2 kit. One screen per task (CONTEXT.md
Hard Rule #7). S1–S3 shipped in Phase 1; do not touch auth.

Execute inline on `fix/flutter-web-and-ordering` (same-worktree ruling).
Per-task gate (workdir `customer-app-v2/`): RED test observed failing →
GREEN implementation → `flutter analyze` clean → full `flutter test` green →
one conventional commit → ledger line in
`.superpowers/sdd/2026-10-11-customer-app-v2-phase3-plan/progress.md`.
Stage only `customer-app-v2/**` (+ ledger). Never `git add .`.

## Verified-endpoint reconciliations (RULINGS — supersede DESIGN §12 prose)

DESIGN §12 names endpoints dropped in the Phase-2 T1 reconciliation. The
replacements below are binding; do not call the dropped paths:
- S4: NO `GET /coupons/active/` (dropped). Offer/ticker line comes from the
  `ticker` object of `GET /storefront/platform/`. NO separate `GET /banners/`
  call — the banner carousel renders BANNER/HERO sections of the same render.
- S5: brands come from `GET /products/brands/` (NOT `/brands/`). Sort set is
  the verified one: price_asc, price_desc, newest, rating (default
  -updated_at). Filter query keys: category, brand, min_price, max_price,
  min_discount, is_featured, sort, page.
- S6: search is `POST /search/ { q, category, min_price, max_price,
  is_featured, sort, page }` (NOT `GET /search/?q=`). Suggestions stay
  `GET /search/suggestions/?q=`. NO `/search/trending/` — trending slot shows
  category shortcuts instead. Recents = local (TokenStore/session, never
  server). Recent-views rail = local last-viewed slugs.
- S7: NO `rating-distribution` — reviews block shows list + RatingPill
  summary (avg/count from the detail payload). Wishlist toggles via
  `POST|DELETE /products/wishlist/:slug/`. Pincode via `GET /pincode/:code/`.
- S8: coupons validate via `POST /admin/coupons/validate/ { code,
  order_value }` (any authenticated user; 400 = invalid). Bill lines are
  server truth from `GET /cart/` (+ coupon discount). Totals never computed.
- S9: payments v1 = COD + UPI-on-delivery only, direct `POST /payments/`
  AFTER `POST /orders/` (no intent/confirm). Addresses via
  `/users/me/addresses/` CRUD. NO slot endpoint exists — slot picker is
  local (Today/Tomorrow chips + windows) and the choice travels in
  `delivery_instructions`. Order body: `{ cart_id, delivery_address,
  delivery_instructions? }` (multi-tenant → take `orders[0]`).
- S10: Active/Past segmented tabs filter the `GET /orders/` list
  client-side (active = PENDING…OUT_FOR_DELIVERY; past = DELIVERED,
  CANCELLED, REFUNDED). Cancel only on PENDING/CONFIRMED via
  `POST /orders/:id/cancel/ { reason }`.
- S11: NO `/orders/:id/track/` — tracking polls `GET /orders/:id/` every
  30s while active, stops on DELIVERED/CANCELLED/REFUNDED. `OrderTimeline`
  renders `status_history[]`. Reorder re-adds items via cart repo.
- S12: profile via `GET|PATCH /users/me/`; wishlist count via wishlist repo;
  theme toggle = local (AppTheme mode provider); notifications toggle local
  stub (preferences screen later); sign-out clears tokens → `/login`.
- S13: address CRUD via `/users/me/addresses/` (+`/set-default/`); reuses
  `AddressCard` from the kit; delete behind confirm sheet.

## Tasks

### S4 · Home (`/home`, tab 1)
Steps:
1. RED `test/home/home_screen_test.dart`: with faked repos — ticker line
   renders; BANNER section renders 16:7 carousel with dots; category grid
   shows 8 tiles + See all → `go('/browse')`; PRODUCT_ROW renders rail
   cards; pull-to-refresh re-fires; error → ErrorState + Retry;
   empty storefront → EmptyState. → EXPECTED: FAIL.
2. GREEN `lib/features/home/presentation/{home_screen,home_sections}.dart`
   (+ `home_providers.dart` if needed): `platformStorefront()` render +
   `categories()` (8 + See all) composed with kit (SectionHeader,
   ProductCard rail density, SkeletonRail, states). Skeleton → populated /
   empty / error(+retry) via `AsyncValue.when`. RefreshIndicator
   invalidates providers. Router `/home` → HomeScreen.
   → EXPECTED: PASS + analyze clean.
3. Commit: `feat(app): S4 home screen — ticker, banners, categories, rails`

Test command: `flutter test test/home/`

### S5 · Browse / PLP (`/browse?category=`, tab 2)
1. RED `test/browse/browse_screen_test.dart`: chips synced with
   `?category=`; toolbar shows "N items" + Filter/Sort buttons opening the
   kit sheets; grid 2-col; filter change resets page; empty → EmptyState
   with "Clear filters"; error → retry. → FAIL.
2. GREEN `lib/features/browse/...`: `browseControllerProvider`
   (query+filters+sort+page state) + paged `products()` grid + FilterSheet /
   SortSheet wiring + `?category=` deep-link sync. → PASS + analyze.
3. Commit: `feat(app): S5 browse PLP — chips, filter/sort, paged grid`

Test command: `flutter test test/browse/`

### S6 · Search (`/search?q=`, tab 3)
1. RED `test/search/search_screen_test.dart`: empty query → recents chips +
   category shortcuts (never blank); typing debounces 300ms then
   suggestions dropdown; in-flight cancelled on new keystroke; submit →
   `POST /search/` PLP grid; result tap → PDP. → FAIL.
2. GREEN `lib/features/search/...`: `searchControllerProvider` (debounce +
   cancel via Dio CancelToken), recents in TokenStore/session, suggestions
   list, results grid reusing PLP cards. → PASS + analyze.
3. Commit: `feat(app): S6 search — recents, suggestions, results`

Test command: `flutter test test/search/`

### S7 · PDP (`/product/:slug`, auth)
1. RED `test/product/product_screen_test.dart`: gallery 1:1 + dots; heart
   toggles wishlist (hearts-only); name + RatingPill + PriceBlock; ≤3
   variants inline else VariantSheet button; pincode checker quiet inline
   (valid + invalid states); sticky bar PriceBlock + stepper; reviews list +
   post form (409 → "already reviewed"); related rail. → FAIL.
2. GREEN `lib/features/product/...`: slug-family provider, variant state
   (price swap, no reload), `QtyStepper`, pincode inline, reviews paged.
   → PASS + analyze.
3. Commit: `feat(app): S7 product detail — gallery, variants, pincode, reviews`

Test command: `flutter test test/product/`

### S8 · Cart (`/cart`, tab 4)
1. RED `test/cart/cart_screen_test.dart`: line cards (76dp, stepper,
   remove → Undo snackbar 5s); coupon row → sheet → validate ok/invalid;
   server-truth bill block; CTA "Proceed to checkout · ₹X" → `/checkout`;
   empty cart → EmptyState. → FAIL.
2. GREEN `lib/features/cart/presentation/cart_screen.dart` (+ controller):
   `cartControllerProvider` mutations (PATCH qty, DELETE + undo restore via
   re-add), coupon validate inline errors, CTA total from server.
   → PASS + analyze.
3. Commit: `feat(app): S8 cart — lines, coupon, server-truth bill`

Test command: `flutter test test/cart/`

### S9 · Checkout (`/checkout`, auth)
1. RED `test/checkout/checkout_screen_test.dart`: steps header; address
   list preselects default + add/edit sheet; slot chips → lands in
   `delivery_instructions`; COD/UPI rows; bill server truth; double-tap
   guard (one order); success → cart cleared → `/order/:id`. → FAIL.
2. GREEN `lib/features/checkout/...`: `checkoutControllerProvider`
   (address/slot/method state, idempotent place-order), order-then-payment
   (COD skips payment), medium haptic on success. → PASS + analyze.
3. Commit: `feat(app): S9 checkout — address, slot, COD/UPI, place order`

Test command: `flutter test test/checkout/`

### S10 · Orders (`/orders`, tab 5)
1. RED `test/orders/orders_screen_test.dart`: Active/Past segmented;
   order cards (tabular id, date, StatusPill, total); tap → detail; cancel
   affordance only on PENDING/CONFIRMED; pull-to-refresh; empty → EmptyState.
   → FAIL.
2. GREEN `lib/features/orders/presentation/orders_screen.dart`:
   `ordersListProvider` + client-side Active/Past split + cancel + confirm
   sheet. → PASS + analyze.
3. Commit: `feat(app): S10 orders — active/past, cancel`

Test command: `flutter test test/orders/`

### S11 · Order detail + Track (`/order/:id`, auth)
1. RED `test/orders/order_detail_test.dart`: status hero + ETA; vertical
   OrderTimeline from `status_history[]`; line items with reorder Add;
   address + bill blocks; Cancel (if allowed) / Reorder (if delivered);
   polling timer fires refresh while active (fake async). → FAIL.
2. GREEN `lib/features/orders/presentation/order_detail_screen.dart`:
   id-family provider + 30s poll (Timer, cancelled on dispose/stop
   states) + actions. Router `/order/:id` added (keep `/orders` tab).
   → PASS + analyze.
3. Commit: `feat(app): S11 order detail + 30s tracking poll`

Test command: `flutter test test/orders/`

### S12 · Account (`/account`, auth)
1. RED `test/account/account_screen_test.dart`: header (monogram, name,
   phone); rows navigate (Addresses, Reviews, Payments, Settings theme
   segmented, Help); edit name/phone inline; sign-out → confirm → `/login`.
   → FAIL.
2. GREEN `lib/features/account/...`: `_profileProvider` + patch, theme-mode
   provider wiring MaterialApp (light/dark/system), sign-out clears tokens
   + Google session. Router `/account` added (avatar entry: Home AppBar
   avatar → `/account`; add avatar button to EasyGetAppBar actions on Home).
   → PASS + analyze.
3. Commit: `feat(app): S12 account — profile, theme, sign out`

Test command: `flutter test test/account/`

### S13 · Addresses (`/addresses`, auth)
1. RED `test/addresses/addresses_screen_test.dart`: radio list of
   AddressCards + default badge; set-default on select; add/edit sheet
   (validated fields + pincode); delete behind confirm; empty → EmptyState
   + "Add address" CTA. → FAIL.
2. GREEN `lib/features/addresses/...`: `_addressListProvider` CRUD +
   set-default, sheet form with DRF field-error mapping. Router `/addresses`
   added. → PASS + analyze.
3. Commit: `feat(app): S13 addresses — list, default, add/edit, delete`

Test command: `flutter test test/addresses/`

## Completion contract (per task)
- Every named test ran and was read; final run is the brief's `flutter test
  <dir>` → green; full suite green; analyze clean; commit per brief;
  deviation → `Ruling:` line in the Phase-3 ledger.
