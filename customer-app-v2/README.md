# EasyGet Customer App v2 — The Big README

> Package `com.trisentric.easyget` · Flutter 3.38 · Dart 3.10 · Riverpod 3 · go_router 2
> Status: **all 13 screens + wishlist + engagement + FCM + voice shipped · 332 tests green**
> Audience: a junior developer joining tomorrow. Read top to bottom once, then use as a reference.

---

## Table of contents

1. [WHAT — what this app is](#1-what--what-this-app-is)
2. [HOW — run, build, test, share](#2-how--run-build-test-share)
3. [Architecture — how the code is organized](#3-architecture--how-the-code-is-organized)
4. [Tech stack — every dependency and why](#4-tech-stack--every-dependency-and-why)
5. [Backend API map — every endpoint we call](#5-backend-api-map--every-endpoint-we-call)
6. [Design system — tokens, components, screens](#6-design-system--tokens-components-screens)
7. [Navigation laws — read before you route](#7-navigation-laws--read-before-you-route)
8. [State & data patterns — how features are built](#8-state--data-patterns--how-features-are-built)
9. [How we work — TDD gate, commits, ledger](#9-how-we-work--tdd-gate-commits-ledger)
10. [History — scratch to current, phase by phase](#10-history--scratch-to-current-phase-by-phase)
11. [Hard-won lessons — read before you debug](#11-hard-won-lessons--read-before-you-debug)
12. [Remaining work & roadmap](#12-remaining-work--roadmap)
13. [Troubleshooting FAQ](#13-troubleshooting-faq)
14. [Logins, links, glossary](#14-logins-links-glossary)

---

## 1. WHAT — what this app is

**EasyGet customer-app-v2** is the customer shopping app for EasyGet, a multi-store
quick-commerce SaaS (marketplace catalog, near-store delivery, visual storefront
builder). It replaces the old `customer-app/` (kept in the repo as a read-only
reference; it will be deleted once v2 fully ships — do not build features there).

- **Package:** `com.trisentric.easyget`
- **Branch:** `fix/flutter-web-and-ordering` (Render autodeploys this branch)
- **Backend:** Django 5 + DRF API at `https://easyget-api.onrender.com/api/v1`
  (free tier — sleeps after ~15 min idle; first call after sleep takes 30–90s)
- **Database (live):** Supabase Postgres (`aws-0-ap-northeast-1` pooler).
  The app itself has **no database** — every byte of product/order data comes over
  HTTPS. On-device it keeps only: JWTs + cached profile (encrypted secure
  storage), guest-cart key, theme choice, and in-memory session state.
- **What the app does:** browse/search a grocery catalog, product pages with
  variants + reviews + pincode check, cart with coupons, COD/UPI checkout,
  order tracking (30s poll), wishlist, addresses, account + theme, notifications
  inbox, order-status alerts, FCM push, voice search, app-update gate.

**The three laws of this codebase:**

1. **Never modify backend models, serializers, or tests.** Adapt client-side.
2. **Never invent API endpoints.** If it isn't in §5, ask first.
3. **Every screen works offline-hostile:** skeleton → data / empty / error+retry.
   No dead ends, no silent failures, no invented data.

---

## 2. HOW — run, build, test, share

### Prerequisites

- Flutter 3.38.x (`flutter --version`), Android SDK with
  `platform-tools/adb` (Windows: `C:\Users\Rahul\AppData\Local\Android\Sdk\...`).
- A phone with USB debugging, or Chrome (`flutter run -d chrome` works for UI).

### Everyday commands (run from `customer-app-v2/`)

```powershell
flutter pub get
flutter analyze                    # must print "No issues found!"
flutter test                       # full suite (~330 tests, ~30s)
flutter test test/browse/          # one area
flutter run                        # USB phone (debug)
```

PowerShell 5.1 notes: no `&&` (use `;`), no `rg`/`grep` on PATH, quote paths
with spaces, and use `workdir` instead of `cd` in scripts.

### Build flavors

```powershell
# Daily testing / WhatsApp sharing (small, fast):
flutter build apk --release --split-per-abi
# → build/app/outputs/flutter-apk/app-arm64-v8a-release.apk  (~19 MB)
# Rename to EasyGet.apk, send as a WhatsApp *Document*, install with
# "unknown apps" allowed. (The 156 MB debug APK is dev-only — never share it.)

# Debug (logging, slow): flutter build apk --debug
```

### Build-time defines (`--dart-define=`)

| Key | Default | Purpose |
|---|---|---|
| `API_BASE` | Render URL above | Point at local backend (`http://10.0.2.2:8000/api/v1` on emulator) |
| `STORE_SLUG` | `easyget` | Platform storefront slug |
| `GOOGLE_CLIENT_ID` | baked-in web ID | Google Sign-In web OAuth client |

### Test accounts

| Role | Email | Password |
|---|---|---|
| Customer | `customer@easyget.app` | `Customer@123` |
| Merchant | `merchant@easyget.app` | `Merchant@123` |
| Agent | `agent@easyget.app` | `Agent@123` |
| Admin | `admin@easyget.local` | `EasyGet!2026` |

---

## 3. Architecture — how the code is organized

Clean architecture, feature-first. **Rule: features import `core/` and `models/`;
features never import each other** — except two documented cases:
`product` ← `catalog` (quick-add reads the cart + PDP cart map; no init cycle,
providers are lazy), and `engagement` → `auth` (push sync reads auth state).

```
lib/
  main.dart                        # composition root: ProviderScope (+ router
                                   # shim for notification taps), EasyGetApp
                                   # (themeMode, router, UpdateGate, watcher
                                   # + push-sync kickoff post-frame)
  core/
    config/app_config.dart         # apiBase, storeSlug, googleClientId,
                                   # mediaUrl() absolutizer
    network/                       # ApiClient (Dio: 90s/60s timeouts, bearer +
                                   # single-flight 401 refresh, warmUp),
                                   # api_endpoints.dart (FROZEN map — §5),
                                   # api_exception.dart (one-sentence errors),
                                   # session_lost.dart
    router/app_router.dart         # shell + redirect law + PAGE_VIEW observer
    storage/token_store.dart       # JWTs + guest key + session id + CACHED
                                   # USER profile (InMemory + Secure impls)
    theme/                         # tokens.dart (AppColors/AppSpace/AppRadii/
                                   # AppMotion + light/dark extensions),
                                   # app_theme.dart, app_typography.dart
                                   # (Zodiak display bundled, Inter body)
    widgets/                       # nav.dart (popOrHome + navigation law),
                                   # app_bar/search_bar/bottom_nav/app_shell,
                                   # section_header, app_chip, skeletons,
                                   # states (Centered!), pills, snackbar,
                                   # address_card, order_timeline
  models/                          # catalog, cart, order, address, review,
                                   # payment, notification, app_update,
                                   # pincode, storefront models + numToDouble
                                   # coercion (API mixes strings/numbers)
  features/<name>/
    data/                          # Repository interface + Http impl +
                                   # provider (e.g. catalog_repository.dart)
    presentation/                  # screen.dart + *_controller/_providers.dart
                                   # (+ widgets/ for shared pieces)
```

Feature folders: `account` `addresses` `auth` `browse` `cart` `catalog`
`checkout` `delivery` `engagement` `home` `orders` `payments` `product`
`reviews` `search` `wishlist`. Each has `data/`; screens live in
`presentation/` (only `catalog` has an extra `presentation/widgets/` kit).

`test/` mirrors `lib/` one level deep: `test/<area>/<thing>_test.dart`
(`auth shell home browse search product cart checkout orders account
addresses catalog data network router theme widgets wishlist notifications
delivery engagement`), plus `test/data/` (repository contract tests).

Android bits that matter: `android/app/google-services.json` (Firebase project
`easyget-7a4b0`, committed — designed to ship), branded `launch_background`
splash, `POST_NOTIFICATIONS`/`VIBRATE`/`RECORD_AUDIO` permissions, desugaring
for the notifications plugin.

## 4. Tech stack — every dependency and why

| Package | Why it exists |
|---|---|
| `flutter_riverpod` 3.3 | All state. Manual providers (no codegen), `Notifier` + families |
| `go_router` 17.5 | Declarative routing, shell, redirect law, deep links |
| `dio` 5.11 | HTTP (timeouts, interceptors, CancelToken) |
| `flutter_secure_storage` 11 | Encrypted tokens (Keychain/Keystore) |
| `cached_network_image` 3.4 | Every remote image (placeholder + error widget, never grey boxes) |
| `google_fonts` 8.2 | Inter body type (runtime-cached) |
| `flutter_animate` 4.5 + `shimmer` | Micro-motion; skeletons use a shimmer-free pulse instead |
| `intl` | Date/number formatting helpers |
| `google_sign_in` 7.2 | Google login (`serverClientId` = web OAuth ID) |
| `flutter_local_notifications` 22 | Order-status local alerts (channel `order_updates`) |
| `package_info_plus` 10 | App version for the update gate |
| `url_launcher` 6 | Opening the store link on update |
| `firebase_core` 4 + `firebase_messaging` 16 | FCM push (project `easyget-7a4b0`) |
| `speech_to_text` 7 | Voice search mic (`en_IN`, 30s cap) |
| Bundled `assets/fonts` (Zodiak Regular+Bold, ~75KB) | Display serif, offline-safe |

Fonts: Zodiak (Fontshare/ITF, free commercial) for display; Inter for
everything else. Product names are NEVER serif.

## 5. Backend API map — every endpoint we call

Base `/api/v1/`. JWT access+refresh. Verified live — including 5 corrections
found by probing (marked ★):

- **Auth:** `POST /auth/login|refresh|logout|register|google/`,
  `GET /users/me/` (+ `PATCH` name/phone), `/users/me/addresses/` CRUD +
  `set-default/`
- **Catalog:** `GET /products/` (★ bare 20-item list, **no envelope** — paginate
  by full-page rule), `GET /products/:slug/`, `GET /categories/`,
  `GET /products/brands/`, `POST /search/` (+ `GET /search/suggestions/?q=`),
  `GET /pincode/:code/`, `GET /storefront/platform/`
- **Cart:** `GET /cart/`, `POST /cart/items/ {variant_id, quantity}`,
  `DELETE /cart/items/:id/`, `POST /cart/merge/ {session_key}`,
  `DELETE /cart/clear/`. ★ **PATCH 405s live** — qty rewrite = DELETE + re-POST.
- **Wishlist:** `GET /products/wishlist/`, `POST|DELETE /products/wishlist/:slug/`
- **Reviews:** `GET|POST /products/:slug/reviews/` (409 = already reviewed)
- **Orders:** `POST /orders/ {cart_id, delivery_address, delivery_instructions?}`
  (→ `{"orders":[...]}` multi-tenant, take first), `GET /orders/`,
  `GET /orders/:id/`, `POST /orders/:id/cancel/ {reason}`
- **Payments:** `GET /payments/methods/`, direct `POST /payments/`
  (COD + UPI-on-delivery only; no intent/confirm)
- **Coupons:** `POST /admin/coupons/validate/ {code, order_value}`
- **Engagement:** `GET /notifications/` (+ mark read/all-read/unread_count),
  `POST /analytics/events/`, `POST /realtime/devices/ {platform, device_token}`,
  `POST /pwa/updates/check/`
- **Admin** (`/api/v1/admin/`, staff): dashboard, orders/products/inventory/
  reviews/storefront/coupons/banners — app calls only coupon-validate here.

**Dropped paths (never call):** `/auth/otp/*` phone, `/auth/me/`, `/brands/`,
`/wishlist/`, `/addresses/`, `/search/trending/`, `/coupons/active/`,
`/payments/intent|confirm/`, `/orders/:id/track/` (poll detail 30s instead),
`/products/:slug/rating-distribution/`.
**Live payload quirks:** detail images use key `"image"` (not `"url"`);
`align_x` arrives as percent (50, not 0.5); Decimals arrive as strings;
storefront section `type` is often empty (infer by content); category images
are currently all `null` (admin uploads pending).

## 6. Design system — tokens, components, screens

**Tokens (`core/theme/`, the ONLY place with hex/px):** `AppColors` (brand,
primary, marigold, champagne/obsidian, light + warm-charcoal dark),
`AppSpace` (4pt), `AppRadii` (card 18, image 14, button 16, sheet 24…),
`AppMotion` (micro 180ms / base 280 / page 350, easeOutCubic), type scale
(Display Zodiak 28 → Price Inter 700 tabular 18/16; EVERY number tabular).
`theme_test.dart` fails the build on any `Color(0x` outside `core/theme/`.

**Kit:** Button/IconButton/Input/Select/Checkbox/Switch/Badge/Tooltip/Popover/
Modal/Sheet/Toast/Skeleton/Spinner/Avatar/Tabs · ProductCard (rail/grid/line,
fixed-slot anatomy + `gridAspect()` math), PriceBlock, RatingPill, QtyStepper,
VariantSwatch→VariantSheet, FilterPanel/SortSheet, OfferCard, CouponChip,
PincodeChecker, CartLineItem, AddressCard, OrderTimeline, ReviewCard ·
AppShell, scroll-aware StickyHeader, 5-tab BottomNav, rails, SectionHeader,
Empty/Error/Offline (all vertically centered).

**Screens (route → file):** Boot `/` · Login · Register · Home `/home`
(ticker, hero/banners, category track, rails, All-products grid) · Browse
`/browse` (chips, MNC filter sheet, paged grid) + pushed `/browse/all` ·
Search `/search` (recents, suggestions, voice, results + Show-more footer) ·
PDP `/product/:slug` (gallery, variants, pincode, reviews, confirm pipeline) ·
Cart `/cart` (Undo, coupons, server bill, trust rows) · Checkout `/checkout`
(address/slot/COD-UPI, idempotent place) · Orders `/orders` (Active/Past,
cancel) · Order detail `/order/:id` (hero, timeline, 30s poll) · Account
`/account` (profile, theme chips, sign-out) · Addresses `/addresses` (radio
defaults, shared form sheet, Photon autocomplete) · Wishlist `/wishlist`
(saved grid, remove+Undo) · Notifications `/notifications` (inbox, badge).

## 7. Navigation laws — read before you route

**The law (binding, enforced by `test/router/nav_test.dart` static scan):**

- **Tab roots ALWAYS `go()`** (`/home /browse /search /cart /orders`).
  `push()` to a `StatefulShellRoute` branch corrupts the page stack and trips
  the framework duplicate-page-key assertion (`navigator.dart:4032`) — this
  exact crash happened in production once; never again.
- **Detail screens ALWAYS `push()`** (`/product/*`, `/checkout`, `/account`,
  `/addresses`, `/order/*`, `/wishlist`, `/browse/all`) so system back walks
  the stack instead of exiting. Proven with engine `handlePopRoute` tests.
- **Back buttons use `popOrHome(context)`** (pop if stacked, else `/home`
  for deep links) via a framework `BackButton` in `EasyGetAppBar`.

**Redirect law (DESIGN §14, unit-tested in `redirect_test.dart`):** unbooted →
hold splash; guest + private → `/login`; session + public → `/home`.
`/addresses /wishlist /notifications /order/*` are private (two holes closed
post-launch). Order success uses `go()` (replace, never back-to-checkout).

## 8. State & data patterns — how features are built

- **Repository:** `abstract XxxRepository` + `HttpXxxRepository(ApiClient)` +
  `xxxRepositoryProvider`. All HTTP hides here; screens never touch Dio.
- **Fakes:** every test file carries `_FakeXxxRepo` (in-memory, call-recording).
  No mocks, no network in tests, ever.
- **Controllers:** `Notifier`/`NotifierProvider` (never `StateProvider` — gone
  in Riverpod 3). Async boot loads use the `loading:false`-explicit pattern
  (constructor defaults bite — S5/S8/S11 all hit this).
- **Families:** Riverpod 3 manual families take the arg via the **constructor**,
  not `build()` (no `FamilyNotifier` base exists).
- **Seams (testability):** `PushBackend`, `UrlOpener`, `VoiceSearchService`,
  `LocalNotifier`, `PlaceAutocompleteService` — real impl + fake. Firebase /
  speech / launcher SDKs never execute under tests.
- **No provider writes in `initState`/`build`/`dispose`** (Riverpod debug
  assertion): route/url syncs go post-frame; dispose captures services in
  fields instead of `ref`.
- **Nested `ProviderScope` overrides do NOT reach Notifier builds** (proven by
  minimal repro) — route state syncs post-frame from the URL, which is the
  source of truth.
- **Timers in tests:** any `Timer.periodic` needs an explicit `stop()` called
  before the test body ends (teardowns run after the invariant check).
- **Snackbars:** one 3s standard (`showAppSnackbar`, hide-first); Undo flows
  refresh-on-dismiss to confirm server truth.
- **Prices:** server truth only; client derives `payable = subtotal − coupon`
  and clamps ≥ 0. `₹` formatting strips `.00`.

## 9. How we work — TDD gate, commits, ledger

**Per task, no exceptions:** RED test written first and observed failing →
GREEN implementation → `flutter analyze` clean → **full** `flutter test`
green → one conventional commit (`feat|fix|test|perf(app): …`) → ledger line
`Task: complete (commits base..head, tests: …)` in
`.superpowers/sdd/<plan>/progress.md`. Stage only `customer-app-v2/**` (+ docs);
**never `git add .`** (the tree has other surfaces' dirty files).

- One screen/component per commit; every commit must analyze clean standalone
  (verified in throwaway worktrees when history is rebuilt).
- Prefix shell commands with `rtk` (repo convention).
- Windows PowerShell 5.1: `;` chains, no heredocs for file edits (use the
  file tools), Numbers: never `*` unquoted in `-match`.

## 10. History — scratch to current, phase by phase

- **Phase 1 (scaffold→S3):** scaffold, Fresh-Market theme, network core
  (frozen endpoints, `ApiException`), session core (token store, single-flight
  401 refresh), router redirect matrix, S1 boot, S2 login (+Google, cold-start
  hints), S3 register, splash warm-up, baked OAuth IDs.
- **Phase 2 (Commerce Kit):** contract reconciliation (dropped paths), data
  layers (catalog/cart/wishlist/orders/addresses/reviews/payments/notify/
  analytics/app-update), shell (AppBar/search/5 tabs/PAGE_VIEW), commerce
  widgets (ProductCard/PriceBlock/RatingPill/QtyStepper/VariantSheet), kit
  (sheets/chips/skeletons/states/pills/cards/timeline) + spacing/radii/motion
  tokens.
- **Phase 3 (S4–S13 screens):** Home, Browse, Search, PDP, Cart, Checkout,
  Orders, Order-detail+poll, Account, Addresses — one commit per screen.
- **Fix rounds:** PATCH→DELETE+POST rewrite · push-based back nav · fixed card
  anatomy · category tiles · dynamic checkout · PDP confirm pipeline ·
  appearance chips · card hearts · address alignment + Photon autocomplete ·
  shell-test gallery · view-cart tab fix · release splits · image-key decode ·
  Zodiak · champagne/obsidian cards · instant boot (cached profile) + branded
  splash · MNC filter + bare-list paging + hero/track/pushed-browse + centered
  CTA · voice search · quick-add pipeline + live badge + All-products ·
  centered states · wishlist screen · inbox + badge · local alerts · update
  gate · FCM wiring · explicit added-state · search browser + show-more ·
  hero/track/push/browse-paging/CTA round 2.
- **Phase 4 (B+C):** wishlist screen, notifications inbox + badge, 60s order
  watcher + local alerts, app-update gate, FCM on project `easyget-7a4b0`.
  Full log: `git log --oneline -- customer-app-v2` (~60 commits).

## 11. Hard-won lessons — read before you debug

1. **Riverpod 3 removed `StateProvider`, `.valueOrNull`, `FamilyNotifier`.**
   Use tiny Notifiers, `.value`, constructor-arg families.
2. **Set `loading:false` explicitly** in every state branch — constructor
   defaults keep skeletons spinning forever (S5/S8/S11 all burned here).
3. **Never `push()` a tab route** — duplicate-page-key crash; static test guards.
4. **PATCH `/cart/items/` 405s live** — rewrite = DELETE + re-POST.
5. **Detail images use key `"image"`**, `align_x` is percent — fixture lied once.
6. **`GET /products/` is a bare 20-list** — paginate by full-page rule + own
   page counter (responses echo page 1).
7. **Storefront `type` is often empty** — infer sections by content.
8. **Perpetual animations kill `pumpAndSettle`** (spinners, pulse skeletons,
   60s timers) — explicit `pump(Duration)` + timer `stop()` in tests.
9. **`ref` is illegal in `dispose()`** — capture services in fields.
10. **Nested ProviderScope overrides skip Notifier builds** — sync from URL.
11. **Unmounted-`ref` in async callbacks** (Undo after row unmount) — use the
    provider container, guarded by `context.mounted`.

## 12. Remaining work & roadmap

- [ ] **Backend FCM sender** (spec in ledger): `firebase-admin` from the Render
  service-account env; send `{order_id}` on status transitions to the user's
  active `Device` rows. Nothing sends pushes yet.
- [ ] Background order watcher (WorkManager) — alerts only run app-open today.
- [ ] Real **Wishlist screen** — wait, shipped (W1). Remaining stub rows:
  Reviews / Coupons / Payments screens (no list endpoints — needs backend).
- [ ] Recents + recent-views persistence (in-memory today).
- [ ] Release signing key + Play Console AAB + store listing.
- [ ] Category images in admin (tiles fall back to icons until uploaded).
- [ ] Reorder-from-order (needs variant ids on order items — backend).
- [ ] iOS APNs leg for pushes; iOS mic usage string.

## 13. Troubleshooting FAQ

- **First login takes ~60s** → Render free tier waking. Normal once per sleep.
  "Waking up the store…" hint shows after 3s.
- **Every open is slow** → fixed by cached-profile boot (1a49498); warm opens
  are instant, cold opens land instantly on cached data.
- **App exits on back** → was push-to-tab bug, fixed + guarded. Repro: engine
  `handlePopRoute` tests in `test/router/`.
- **Yellow overflow stripes** → card anatomy is fixed-slot + computed aspect;
  add a uniform-height test like the grid one if you touch cards.
- **`pumpAndSettle` times out** → find the perpetual animation/timer (§11.8).
- **Test touches network (`[api]` logs)** → a fake is missing an override;
  hearts/notifications/analytics all have no-op fakes — use them.
- **401s everywhere on device** → access expired + refresh rotated/failed →
  sign out/in once; check `GOOGLE_CLIENT_ID` for Google path.
- **Push not arriving** → permission granted? token registered? (`adb logcat`
  for the token) → Firebase "Send test message" → backend sender (see §12).

## 14. Logins, links, glossary

- Logins: §2 table. API base §1. Firebase project `easyget-7a4b0`.
- Plans/ledger: `docs/superpowers/plans/`, `.superpowers/sdd/`.
- Repo docs: `DESIGN.md` (design law), `CONTEXT.md` (frozen facts),
  `GETTING_STARTED.md` (multi-surface runbook).
- **Glossary:** PLP = product listing page · PDP = product detail page ·
  CTA = call to action · MNC = multinational-company-grade UX bar used in
  reviews · Ruling = a deviation from DESIGN.md recorded in the ledger with
  proof · RED/GREEN = failing-first / passing-after TDD steps.

*Last verified: full suite 332 green, `flutter analyze` clean.*
