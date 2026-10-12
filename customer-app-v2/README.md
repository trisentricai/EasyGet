# EasyGet Customer App v2 — The Big README

> Package `com.trisentric.easyget` · Flutter 3.38 · Dart 3.10 · Riverpod 3 · go_router 2
> Status: **all 13 screens + wishlist + engagement + FCM + voice shipped · 332 tests green**
> Audience: a junior developer joining tomorrow. Read top to bottom once, then use as a reference.
> Conventions in this doc: `path/` = folder, `File` = Dart file, `→` = leads to,
> `MUST`/`NEVER` = project law (break the build or the review if violated).
>
> **Reading paths (don't read 2500 lines linearly unless it's week one):**
> newcomer → §1, §2 (setup+run), §27 Day-1, then §7 + §8.1 · backend dev →
> §5, §18 (shapes), §30 (quirks), §R7 (app map) · designer → §6, §22 (exact
> tokens), §24 (wireframes) · debugger → §13 FAQ + decision trees, §26, §31 ·
> reviewer → §27 checklist, §9.1 gate, §21 history. Ctrl+F the `§N` number —
> every cross-reference in this doc uses it.

---

## Table of contents

1. [WHAT — what this app is](#1-what--what-this-app-is)
    - 1.1 Product in one paragraph · 1.2 Facts sheet · 1.3 User roles &
      journeys · 1.4 Surfaces (app vs web vs admin) · 1.5 Status dashboard ·
      1.6 Key numbers
2. [HOW — run, build, test, share](#2-how--run-build-test-share)
    - 2.1 Machine setup · 2.2 Everyday commands · 2.3 Build flavors & sizes ·
      2.4 Release signing · 2.5 Testing guide · 2.6 Logcat & debugging recipes ·
      2.7 WhatsApp distribution SOP · 2.8 Build-time defines · 2.9 Test
      accounts · 2.10 Local backend
3. [Architecture — how the code is organized](#3-architecture--how-the-code-is-organized)
   - 3.1 The 30-second mental model · 3.2 Folder-by-folder map · 3.3 Boot
     sequence · 3.4 Dependency rules with examples
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
15. [Changelog](#15-changelog-readme-level-code-details-in-git-log)
16. [Appendix A — every `lib/` file](#16-appendix-a--every-lib-file-and-what-it-does)
17. [Appendix B — every test file](#17-appendix-b--every-test-file-and-what-it-guards)
18. [Appendix C — API response shapes](#18-appendix-c--api-response-shapes-live-probes-abridged)
19. [Appendix D — new-screen recipe](#19-appendix-d--new-screen-recipe-copy-rename-fill-in)
20. [Appendix E — performance, security, accessibility](#20-appendix-e--performance-security-accessibility-notes)
21. [Appendix F — commit history](#21-appendix-f--commit-history-git-log---oneline---customer-app-v2)
22. [Appendix G — exact token values](#22-appendix-g--exact-token-values-from-tokensdart)
23. [Appendix H — controller state shapes](#23-appendix-h--controller-state-shapes-read-before-you-refactor)
24. [Appendix I — screen layouts](#24-appendix-i--screen-layouts-ascii-wireframes)
25. [Appendix J — provider → endpoint trace](#25-appendix-j--provider--endpoint-trace)
26. [Appendix K — screen-test recipe](#26-appendix-k--screen-test-recipe-copy-rename-fill-in)
27. [Appendix L — onboarding, review, release](#27-appendix-l--onboarding-review-checklist-release-runbook)
28. [Appendix M — architecture decisions](#28-appendix-m--architecture-decision-records)
29. [Appendix N — common-tasks cookbook](#29-appendix-n--common-tasks-cookbook)
30. [Appendix O — backend quirks registry](#30-appendix-o--backend-quirks-registry)
31. [Appendix P — runtime sequences](#31-appendix-p--runtime-sequences-tap--pixels--network)
32. [Appendix Q — quick-reference card](#32-appendix-q--quick-reference-card-print-this)
33. [Appendix R — operational references](#33-appendix-r--operational-references)
34. [Appendix S — monorepo neighbors & safe refactors](#34-appendix-s--monorepo-neighbors--safe-refactors)

---

## 1. WHAT — what this app is

### 1.1 Product in one paragraph

**EasyGet customer-app-v2** is the customer shopping app for EasyGet, a multi-store
quick-commerce SaaS (marketplace catalog, near-store delivery, visual storefront
builder). Shoppers browse a grocery catalog, check delivery pincodes, read and
write reviews, fill a cart, validate coupons, check out with COD or UPI, track
orders live, save wishlists and addresses, and get order alerts — all in light
and dark mode, in English, targeted at Indian grocery shoppers on Android.

It replaces the old `customer-app/` (kept in the repo as a read-only
reference; it will be deleted once v2 fully ships — **do not build features
there**).

### 1.2 Facts sheet

- **Package:** `com.trisentric.easyget`
- **Branch:** `fix/flutter-web-and-ordering` (Render autodeploys this branch —
  every push rebuilds the backend; be deliberate)
- **Backend:** Django 5 + DRF API at `https://easyget-api.onrender.com/api/v1`
  (free tier — sleeps after ~15 min idle; first call after sleep takes 30–90s)
- **Database (live):** Supabase Postgres (`aws-0-ap-northeast-1` pooler,
  verified from the live `DATABASE_URL` host — values never leave the server).
  The app itself has **no database** — every byte of product/order data comes
  over HTTPS. On-device it keeps only: JWTs + cached profile (encrypted secure
  storage), guest-cart key, analytics session id, theme choice, and in-memory
  session state (recents, recent views, card→variant map).
- **Push:** Firebase project `easyget-7a4b0` (`google-services.json` committed
  — designed to ship inside the app).

### 1.3 User roles & journeys

| Role | Journey in this app |
|---|---|
| Guest | Splash → browse/search/PDP (hearts prompt login only when needed) → cart
as guest → login merges guest cart (`POST /cart/merge/`) |
| Customer | Full journey: Home → Browse/Search → PDP (variants, pincode, reviews) →
Cart (coupon, Undo) → Checkout (address, slot, COD/UPI) → Orders → detail
track (30s poll) → Account/Addresses/Wishlist/Notifications |
| Merchant/Agent/Admin | Same app shell; role-gated surfaces live in `admin-web`, not here |

The golden path to demo: login → Home → search "atta" → open a product →
pick a variant → confirm 2 units → snackbar → View cart → coupon → checkout →
pick address + slot + COD → place → Orders → detail timeline.

### 1.4 Surfaces (app vs web vs admin)

| Surface | Stack | Serves | Talks to |
|---|---|---|---|
| `customer-app-v2/` (THIS repo) | Flutter 3 + Riverpod + go_router + Dio | Shoppers on Android | Django API directly |
| `customer-web/` | React 18 + TS + Vite, `:3000` | Shopper storefront web | Same Django API |
| `admin-web/` | React 18 + TS + Vite, `:5174` | Merchant/admin console | Same Django API + `/admin/*` |
| `backend/` | Django 5 + DRF + Postgres(Supabase) + Channels | All of the above | Supabase Postgres + storage |

Backend and webs are sibling folders; app work never touches them (law §1).

### 1.5 Status dashboard

- Screens S1–S13: **all shipped**. Tabs: no placeholders. Every list:
  skeleton → data / empty / error+retry.
- Follow-ups shipped: wishlist screen, notifications inbox + badge, 60s order
  watcher + local alerts, app-update gate, FCM wiring, voice search,
  quick-add pipeline, live card quantities, dynamic delivery ETA, MNC filter,
  show-more pagination, hero/track/pushed-browse, Photon autocomplete.
- Quality gates: `flutter analyze` zero issues (errors AND infos), full suite
  green, one commit per task, ledger line per task.

**Per-screen status** (route → state → test file → notes):

| # | Screen | Route | Guard | Tests | Notes |
|---|---|---|---|---|---|
| S1 | Boot | `/` | — | `boot_screen_test` | cached-profile instant boot + branded splash |
| S2 | Login | `/login` | public | `login_screen_test` | email + Google, merge + push sync on success |
| S3 | Register | `/register` | public | `register_screen_test` | role segmented, auto-login |
| S4 | Home | `/home` | tab | `home_screen_test` (11) | ticker, carousel, track, rails, All-products |
| S5 | Browse | `/browse` | tab | `browse_screen_test` (11) | URL-synced chips, MNC filter, full-page paging |
| S6 | Search | `/search` | tab | `search_screen_test` (14) | debounce + cancel, recents/views, voice, show-more |
| S7 | PDP | `/product/:slug` | push | `product_screen_test` (11) | gallery, variants, pincode, reviews, confirm pipeline |
| S8 | Cart | `/cart` | tab | `cart_screen_test` (11) | Undo, coupons, server bill, trust rows |
| S9 | Checkout | `/checkout` | guarded | `checkout_screen_test` (9) | dynamic methods, idempotent place→pay→clear |
| S10 | Orders | `/orders` | guarded | `orders_screen_test` (6) | Active/Past, cancel + reason |
| S11 | Order detail | `/order/:id` | guarded | `order_detail_test` (6) | timeline, 30s poll, invoice |
| S12 | Account | `/account` | push | `account_screen_test` (8) | profile edit, theme chips, sign-out |
| S13 | Addresses | `/addresses` | guarded | `addresses_screen_test` (13) | radio defaults, shared sheet, Photon |
| W1 | Wishlist | `/wishlist` | guarded | `wishlist_screen_test` (5) | saved grid, remove + Undo |
| E1 | Notifications | `/notifications` | guarded | `notifications_screen_test` (5) | inbox, unread badge, deep-link |
| E2/E3 | Watcher/gate | (background) | — | `order_watcher/update_gate` (10) | 60s alerts, forced/optional update |

### 1.6 Key numbers (update when they move)

- Tests: **332** across 19 `test/` areas. Auth ~37 · widgets ~30 · product ~11
  · browse ~11 · search ~14 · home ~11 · cart ~11 · checkout ~9 · orders ~12 ·
  product ~11 · account ~8 · addresses ~13 · catalog/data + engagement +
  delivery + notifications + wishlist + shell + router + network + theme.
- Commits touching `customer-app-v2/`: **~60** (full list in §10).
- APK: debug all-ABI ~156–192MB (dev only); release arm64 ~19MB (share this).
- Backend cold start: 30–90s; app cold open (warm server): <2s to Home.
- Supported page size: products/search bare-20 lists; search envelope carries
  `total/page/page_size`.

**Budgets (hard — a PR that breaks one needs a ruling, §9):**

| Budget | Limit | Current | Where enforced |
|---|---|---|---|
| `flutter analyze` | 0 issues (errors AND infos) | 0 | gate, §9.1 |
| Full suite | green, <120s on CI-class hardware | ~332 in 30–60s | gate, §9.1 |
| Release arm64 APK | <25MB | ~19MB | §2.3 |
| Cold open, warm server | <2s to interactive Home | <2s | §31 boot |
| Home first paint (skeleton) | <500ms after route | instant (cached) | §6.3 |
| New hex outside `core/theme/` | 0 | 0 | `theme_test` |
| Unguarded private route | 0 | 0 | `redirect_test` |
| `push()` to a tab root | 0 | 0 | `nav_test` scan |

**The three laws of this codebase:**

1. **Never modify backend models, serializers, or tests.** Adapt client-side.
2. **Never invent API endpoints.** If it isn't in §5, ask first.
3. **Every screen works offline-hostile:** skeleton → data / empty / error+retry.
   No dead ends, no silent failures, no invented data.

---

## 2. HOW — run, build, test, share

### 2.1 Machine setup (Windows, first day)

1. Install Flutter 3.38.x and accept licenses (`flutter doctor` clean).
2. Install Android Studio (SDK + platform-tools). Note your SDK path; the
   team default is `C:\Users\Rahul\AppData\Local\Android\Sdk` — adjust every
   `adb` path below if yours differs.
3. Enable USB debugging on the phone (tap Build number 7× → Developer
   options → USB debugging). Verify: `adb devices` lists it.
4. VS Code extensions: Flutter, Dart, (optional) Riverpod snippets,
   Error Lens.
5. Clone, checkout `fix/flutter-web-and-ordering`, `cd customer-app-v2`,
   `flutter pub get`. Run `flutter analyze` — expect `No issues found!`.

### 2.2 Everyday commands (run from `customer-app-v2/`)

```powershell
flutter pub get                          # after any pubspec change
flutter analyze                          # gate 1: zero issues, infos included
flutter test                             # gate 2: full suite (~330, ~30–60s)
flutter test test/browse/                # one area (dir = test/<area>/)
flutter test test/browse/browse_screen_test.dart --plain-name " snacks..."  # one case
flutter run                              # USB phone, debug, hot reload (r)
flutter run -d chrome                    # UI-only check in a browser
adb logcat | Select-String "fcm|FCM"     # grab the FCM token after login
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

PowerShell 5.1 notes: no `&&` (use `;`), no `rg`/`grep` on PATH, quote paths
with spaces, never `cd` inside tool commands (use `workdir`), heredocs don't
exist (write files with the file tools, never `>` redirection for code).

### 2.3 Build flavors & sizes (measured)

| Command | Output | Size | Use |
|---|---|---|---|
| `flutter build apk --debug` | `app-debug.apk` (all ABIs) | ~156–192 MB | dev only, never share |
| `flutter build apk --release --split-per-abi` | `app-arm64-v8a-release.apk` | **~19 MB** | **share this one** |
| same | `app-armeabi-v7a-release.apk` | ~17 MB | 10+ year old phones, skip |
| same | `app-x86_64-release.apk` | ~21 MB | emulators only, skip |

Why debug is huge: all ABIs + JIT + debug symbols + no tree-shaking of
reflection. Release enables R8/shrink (proven green: the release split builds
clean with Firebase/notifications/speech plugins).

### 2.4 Release signing (do before Play Console)

Today release builds sign with **debug keys** (works for sideload/WhatsApp,
blocked by Play). For store release:

1. `keytool -genkey -v -keystore easyget-release.jks -alias easyget -keyalg RSA -keysize 2048 -validity 10000`
2. Create `android/key.properties` (GITIGNORED — never commit):
   `storePassword=…`, `keyPassword=…`, `keyAlias=easyget`,
   `storeFile=../easyget-release.jks`. Keep a backup of the jks OFF-machine.
3. Wire `signingConfigs.release` in `android/app/build.gradle.kts`
   (replace the debug placeholder), bump `versionCode`/`versionName` in
   `pubspec.yaml`, then `flutter build appbundle --release`.

### 2.5 Testing guide

- Layout: `test/<area>/<thing>_test.dart` mirrors `lib/`. Repository contract
  tests live in `test/data/` (fake `HttpClientAdapter`, assert method+path+body).
- Widget tests pump with `ProviderScope` + fakes (never network; the test
  binding 400s all real HTTP — a feature, not a bug).
- Patterns you must know: `pumpAndSettle` HANGS on perpetual animations
  (spinners, pulse skeletons, 60s timers) → use explicit `pump(Duration)`;
  scroll with `scrollUntilVisible(..., scrollable: find.byType(Scrollable).first)`;
  engine back button = `tester.binding.handlePopRoute()` (not `pageBack`,
  which only taps on-screen buttons); timers need explicit `stop()` before the
  test body ends (teardowns run after the invariant check).
- Fakes to reuse: `_FakeCatalogRepo` (per test file, page-aware where needed),
  `_FakeCartRepo` (stateful lines), `_FakeWishlistRepo`, `_FakeAddressRepo`,
  `_FakeOrdersRepo`, `_FakeSearchRepo`, `_NoopApiClient`, `_NoopAnalytics`.

**What to run when (test-selection matrix):**

| You changed… | Run this | Why |
|---|---|---|
| one screen + its controller | `flutter test test/<area>/` | area suite catches sibling regressions |
| a repository method | `flutter test test/data/` + the screen suite | contract + consumer together |
| a core widget (kit/commerce) | `flutter test test/widgets/ test/theme/` | kit is used everywhere; theme scan is cheap |
| router/redirect/nav | `flutter test test/router/ test/shell/` | law + shell cross-check each other |
| tokens/theme | `flutter test test/theme/` + eyeball 3 screens | static scan + human eyes (color needs eyes) |
| anything at all (pre-commit) | FULL `flutter test` + `flutter analyze` | §9.1 gate — no exceptions |
| flaky suspect | `--plain-name` single case ×3, then the area dir | isolates order-dependence (§13 FAQ) |
| release confidence | gate + `flutter build apk --release --split-per-abi` | R8/shrink only runs in release (§13 FAQ) |

### 2.6 Logcat & debugging recipes

```powershell
adb logcat | Select-String "fcm|FCM"          # FCM token after login
adb logcat | Select-String "EASYGET|easyget"  # app logs
adb logcat -c                                 # clear before a repro
```
In-app: `[api]` log lines show method/URL/timeouts (debug builds). Auth 401s
trigger single-flight refresh; session loss broadcasts to login.

### 2.7 WhatsApp distribution SOP

1. `flutter build apk --release --split-per-abi`
2. Copy `app-arm64-v8a-release.apk` → rename `EasyGet.apk`
3. Send as WhatsApp **Document** (not Gallery). Receiver taps → allow
   "install unknown apps" → install. Uninstall the old build first if the
   install looks stale (Android caches signatures on `install -r`).

### 2.8 Build-time defines (`--dart-define=`)

| Key | Default | Purpose |
|---|---|---|
| `API_BASE` | Render URL above | Point at local backend (`http://10.0.2.2:8000/api/v1` on emulator) |
| `STORE_SLUG` | `easyget` | Platform storefront slug |
| `GOOGLE_CLIENT_ID` | baked-in web ID | Google Sign-In web OAuth client |

### 2.9 Test accounts

| Role | Email | Password |
|---|---|---|
| Customer | `customer@easyget.app` | `Customer@123` |
| Merchant | `merchant@easyget.app` | `Merchant@123` |
| Agent | `agent@easyget.app` | `Agent@123` |
| Admin | `admin@easyget.local` | `EasyGet!2026` |

### 2.10 Pointing the app at a local backend (for backend devs)

1. Run Django locally (see repo `GETTING_STARTED.md` for the backend setup;
   migrations + seed the demo catalog first).
2. Emulator: `flutter run --dart-define=API_BASE=http://10.0.2.2:8000/api/v1`
   (`10.0.2.2` = host loopback from the emulator). Physical phone over USB:
   use your machine's LAN IP (`http://192.168.x.x:8000/api/v1`) with the
   phone on the same Wi-Fi — plus `adb reverse tcp:8000 tcp:8000` as fallback.
3. Expect: no cold-start hints (local responds in ms), same suite green
   (tests never hit network anyway). Contract drift shows up FIRST in
   `test/data/*_repository_test.dart` — that's the canary, fix the model
   before the screens.

---

## 3. Architecture — how the code is organized

### 3.1 The 30-second mental model

```
Phone tap → Screen (ConsumerWidget, watches providers)
          → Controller/Notifier (owns UI state, debounces, timers)
          → Repository interface (abstract — screens never see Dio)
          → Http impl → ApiClient (auth header, refresh, errors)
          → Django API → Supabase Postgres
```

Tests replace exactly one layer: the repository (in-memory fakes that record
calls). Everything above (widgets, controllers, router) runs for real.

### 3.2 Folder-by-folder map

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
                                   # mediaUrl() absolutizer (/media/… → full URL)
    network/
      api_client.dart              # Dio factory: 90s connect / 60s receive,
                                   # bearer header, single-flight 401 refresh,
                                   # warmUp() fire-and-forget, CancelToken on GET
      api_endpoints.dart           # FROZEN endpoint map — see §5. Touch only
                                   # to add a verified endpoint + test.
      api_exception.dart           # Every failure → one human sentence.
                                   # fromDio() maps timeout/401/404/400 shapes.
      session_lost.dart            # Broadcast channel: auth layer drops to
                                   # guest when refresh dies.
    router/app_router.dart         # 5-tab StatefulShellRoute, top-level pushed
                                   # routes (/product/*, /checkout, /account,
                                   # /addresses, /order/*, /wishlist,
                                   # /browse/all, /notifications),
                                   # redirectFor() pure law, PAGE_VIEW observer.
    storage/token_store.dart       # TokenStore interface: JWTs, guest session
                                   # key, analytics session id, CACHED USER
                                   # profile JSON. InMemory (tests) + Secure
                                   # (Keychain/Keystore) impls. clear() wipes
                                   # tokens AND profile.
    theme/
      tokens.dart                  # AppColors (+champagne/obsidian), AppSpace
                                   # (4pt), AppRadii, AppMotion, light + dark
                                   # ThemeExtensions, freshColors accessor.
      app_theme.dart               # Material ThemeData light/dark incl.
                                   # NavigationBar, AppBar, buttons, sheets.
      app_typography.dart          # Zodiak display (bundled OTF) + Inter body
                                   # (google_fonts); tabular figures everywhere.
    widgets/                       # Shared kit (all token-only, light+dark):
      nav.dart                     # popOrHome() + THE navigation law comment
      app_bar.dart                 # EasyGetAppBar (surface, hairline, BackButton)
      search_bar.dart              # 52dp AppSearchBar + voice-mic deep link
      bottom_nav.dart              # 5 tabs + live cart badge
      app_shell.dart               # EasyGetShell + EasyGetTabScaffold
      section_header.dart          # Title left + ghost See-all (never centered)
      app_chip.dart                # 44dp pill chips, sunken→primaryTint
      skeletons.dart               # Pulse (no shimmer dep): Line/Grid/Rail
      states.dart                  # Empty/Error/Offline — VERTICALLY CENTERED
      status_pill.dart             # humanizeStatus() + transit/success/muted
      eta_pill.dart                # marigold timer pill (static minutes)
      snackbar.dart                # showAppSnackbar: floating, ink, 3s standard
      address_card.dart            # radio + chips + 2-line + tabular phone
                                   # (id-scoped keys for lists)
      order_timeline.dart          # vertical nodes from status_history[]
  models/                          # One file per domain (see §5 for shapes):
                                   # catalog/cart/order/address/review/payment/
                                   # notification/app_update/pincode/storefront.
                                   # numToDouble/numToInt coerce the API's
                                   # mixed string/number Decimals. fromJson is
                                   # defensive (missing keys → sane defaults).
  features/<name>/
    data/<name>_repository.dart    # Interface + Http impl + provider.
    presentation/<name>_screen.dart         # The screen (ConsumerWidget/State).
    presentation/<name>_controller.dart     # Notifier: UI state + actions.
    presentation/<name>_providers.dart      # FutureProviders when no actions.
    presentation/widgets/          # Shared pieces (catalog only).
```

Feature-by-feature contents:

- **auth** — `app_user` (toJson for cache), `auth_repository`
  (login/Google/register/me/logout/merge), `google_auth_source`;
  `auth_controller` (boot fast-path + background refresh, signIn/Google/
  register/signOut), `auth_state` (Booting/SignedIn/Guest+coldStartHint),
  `boot_screen` (brand splash, 3s hint, retry), `login_screen` (email/Google,
  8s slow hint, push-sync on success), `register_screen` (role segmented).
- **home** — `home_providers` (storefront, categories, hot/top/new fallbacks,
  all-products pager), `home_screen` (ticker, hero/banner carousel, category
  track, rails, promo strip, story, All-products grid, avatar+bell+address).
- **browse** — `browse_providers` (filter + paged items + brands; bare-list
  full-page rule), `browse_screen` (pinned chips, toolbar+badge, 2-col grid,
  infinite scroll, centered loading footer), `browse_filter_sheet` (MNC:
  brands/price/discount/featured).
- **search** — `search_repository` (suggestions/results + recents/views
  session stores), `search_controller` (300ms debounce, CancelToken cancel,
  defensive hasMore, pageSize tracking), `search_screen` (field+mic,
  empty/suggest/results/rail modes, show-more footer), `voice_search`
  (speech_to_text seam, `en_IN`).
- **catalog** — `catalog_repository` (products/product/categories/brands/
  search/pincode/storefront), `presentation/widgets/` (product_card with fixed
  slots + gridAspect + hearts + quick-add control, price_block, rating_pill,
  qty_stepper, variant_sheet, filter_sheet, sort_sheet, category_tile +
  CategoryGridCard), `quick_add.dart` (resolve + pipeline + cardAdditions map).
- **cart** — `cart_repository` (fetch/add/**DELETE+re-POST rewrite**/remove/
  clear + badge count), `coupon_repository` (validate), `cart_controller`
  (optimistic remove + Undo + coupon state), `cart_screen` (ETA pill, coupon
  row/sheet, line cards, server bill, trust rows, checkout CTA).
- **checkout** — `checkout_controller` (addresses/methods/cart load, slot +
  note state, COD/UPI gateway map, idempotent place→pay→clear),
  `checkout_screen` (steps header, address cards + shared sheet, slot picker,
  dynamic method rows, bill, guarded CTA).
- **orders** — `orders_repository` (list/detail/create/cancel/invoice),
  `orders_providers` (list + Active/Past split + detail family controller
  with 30s poll), `orders_screen`, `order_detail_screen`, shared
  `cancel_order_sheet` (returns reason).
- **payments** — `payment_repository` (methods + direct create).
- **reviews** — `review_repository` (list/create). **wishlist** —
  `wishlist_repository` (fetch/fetchProducts/toggle) + `wishlist_controller`
  (optimistic hearts, bool-returning toggle) + `card_heart.dart` +
  `wishlist_screen` (saved grid, reactive remove + Undo).
- **addresses** — `address_repository` (CRUD + set-default),
  `addresses_controller`, `addresses_screen` (radio defaults, confirm delete),
  `address_form_sheet` (shared with checkout; validation + Photon autocomplete),
  `place_autocomplete.dart` (Photon/OSM, keyless, India-only).
- **account** — `profile_repository` (fetch/update me), `account_providers`
  (profile, ThemeMode notifier, notifications stub), `account_screen`
  (monogram header, inline edit, rows, theme chips, help, sign-out).
- **engagement** — `notifications_repository` + screen/providers (inbox,
  unread badge), `order_watcher` (60s poll + LocalNotifier seam + tap shim),
  `push_repository` (device tokens), `push_service` (Firebase seam + sync +
  foreground/tap/cold-start + killed-app handler), `app_update_repository`,
  `update_gate.dart`, analytics tracker.
- **delivery** — `delivery_eta.dart` (address→pincode ETA provider +
  self-hiding pill). **payments/reviews** data only (UI lives in checkout/PDP).

`test/` mirrors `lib/` one level deep: `test/<area>/<thing>_test.dart`
(`auth shell home browse search product cart checkout orders account
addresses catalog data network router theme widgets wishlist notifications
delivery engagement`), plus `test/data/` (repository contract tests with fake
`HttpClientAdapter` asserting method+path+body).

Android bits that matter: `android/app/google-services.json` (Firebase project
`easyget-7a4b0`, committed — designed to ship), branded `launch_background`
splash (`@color/eg_brand` + launcher icon), `POST_NOTIFICATIONS`/`VIBRATE`/
`RECORD_AUDIO` permissions, desugaring for the notifications plugin.

### 3.3 Boot sequence (code order in `main.dart` → first frame)

1. `main()` → WidgetsFlutterBinding + Firebase init (with a try/catch that
   lets the app boot even if Firebase misconfigures — push just stays dead).
2. `ProviderScope` mounts with the router-tap shim override (so notification
   taps can navigate before any screen exists).
3. `EasyGetApp.build` reads `themeModeProvider` (persisted theme, no flash)
   and mounts `MaterialApp.router` with `app_router`.
4. `authController.build` runs: SecureTokenStore read (sync-ish) + cached
   `AppUser` → SignedIn with stale profile OR Guest. First frame paints HERE
   — Home for cached users, splash-then-login for guests.
5. Post-frame callbacks fire: background `_refreshUser()` (reconciles profile),
   `ApiClient.warmUp()` (wakes Render), `OrderWatcher.start()`, FCM token sync.
6. Router `redirectFor` settles the route (unbooted → hold; guest+private →
   `/login`; session+public → `/home`). See §31 for the user-visible version.

### 3.4 Dependency rules (with examples — the analyzer won't catch these, reviews must)

**Rule 1: features import `core/` and `models/`; never each other.**
```dart
// GOOD (cart screen): core kit + own data layer + models
import 'package:easyget/core/widgets/states.dart';
import 'package:easyget/features/cart/data/cart_repository.dart';
import 'package:easyget/models/cart_models.dart';
// BAD: import 'package:easyget/features/orders/data/orders_repository.dart';
//      (use a shared provider in core, or duplicate the 5 lines)
```
Documented exceptions (only two): `product` reads cart state for the PDP cart
map (lazy providers, no init cycle — proven, don't generalize), and
`engagement` reads auth state for push sync (same reasoning).

**Rule 2: screens never touch Dio, Firebase, speech, or launcher SDKs.**
All SDK access hides behind repository/seam interfaces (`PushBackend`,
`VoiceSearchService`, `UrlOpener`, `PlaceAutocompleteService`). If your screen
imports `firebase_messaging` or `speech_to_text` directly, the review fails —
add a seam + fake instead (pattern in §8.2, recipe in §19).

**Rule 3: providers flow one way — data → controller → screen.**
Repositories expose data; controllers own UI state + actions; screens watch and
render. A screen calling `ref.read(cartRepositoryProvider).add(...)` directly
bypasses optimistic state — route it through the controller action instead.

**Rule 4: shared UI lives in `core/widgets/`, feature UI stays in the feature.**
Promoted something twice? Second use = promote to core with a kit test
(`CardHeart` stayed in wishlist because only cards+PDP use it — two uses
inside one domain don't justify core).

## 4. Tech stack — every dependency and why

| Package | Version | Why it exists · config notes |
|---|---|---|
| `flutter_riverpod` | ^3.3.2 | All state. Manual providers (no codegen). **v3 rules:** no
`StateProvider`, no `.valueOrNull`, families take the arg via constructor,
no writes in build/initState/dispose. |
| `go_router` | ^17.5.0 | Declarative routing + `StatefulShellRoute` tabs + `redirectFor` law +
deep links (`?category=`, `?q=`, `?listen=1`). v17 plugin APIs are
all-named-params style (see §11). |
| `dio` | ^5.11.1 | HTTP: 90s connect / 60s receive (Render cold starts), bearer +
single-flight 401 refresh, `warmUp()`, `CancelToken` on suggestions. |
| `flutter_secure_storage` | ^11.2.0 | Encrypted tokens + cached profile (Keychain/Keystore). |
| `cached_network_image` | ^3.4.1 | Every remote image: sunken placeholder + broken-image error widget —
never grey boxes. |
| `google_fonts` | ^8.2.1 | Inter body (runtime-cached after first launch). |
| Bundled `assets/fonts` | Zodiak Regular+Bold OTF ~75KB | Display serif, offline-safe
(Fontshare/ITF free commercial). Declared in `pubspec.yaml` `flutter.fonts`. |
| `flutter_animate` 4.5 + `shimmer` 3.0 | Micro-motion; our skeletons use a
hand-rolled pulse (no shimmer dep at runtime) so tests never hang. |
| `intl` | ^0.20.3 | Date/number formatting helpers. |
| `google_sign_in` | ^7.2.0 | Google login with `serverClientId` = web OAuth ID (backend accepts it). |
| `flutter_local_notifications` | ^22.3.1 | Order alerts, channel `order_updates`.
Needs desugaring (`build.gradle.kts`) + `POST_NOTIFICATIONS`. |
| `package_info_plus` | ^10.2.2 | App version for the update gate. |
| `url_launcher` | ^6.3.2 | Opening the store link on update. |
| `firebase_core` | ^4.15.0 | FCM (project `easyget-7a4b0`,
`google-services.json` + Gradle plugin 4.4.2). Token → `POST
/realtime/devices/`; tap/cold-start deep-link to `/order/:id`. |
| `firebase_messaging` | ^16.7.0 | Push receive + background handler (own isolate, bare plugin). |
| `speech_to_text` | ^7.4.0 | Voice mic (`en_IN`, 30s cap, partial results);
needs `RECORD_AUDIO` + runtime grant; v7 uses `SpeechListenOptions`. |

**Upgrade policy (packages rot; upgrades break silently — do them deliberately):**

1. One package per commit, with its CHANGELOG breaking-changes section quoted
   in the commit message. Never `flutter pub upgrade` blind (it moves everything).
2. Known-sensitive upgrades and what they touch: `go_router` major → re-run
   ALL of `test/router/` + `test/shell/` (redirect law + page-key behavior
   change most); `flutter_riverpod` major → re-read the v3 rules in §8.2
   (v2→v3 removed `StateProvider`/`.valueOrNull`/`FamilyNotifier` — the next
   major will remove something too); `speech_to_text` → voice overlay tests +
   on-device mic check (emulator lies about audio); `firebase_*` → rebuild
   release splits + cold-start push test (§R5 step 3); `google_sign_in` →
   SHA-1 + web-client re-verify (§13 FAQ).
3. After any upgrade: full gate (analyze + whole suite) AND a release-split
   build (debug builds hide R8/shrink breakage — §13 FAQ).
4. Pin versions with `^` in `pubspec.yaml`, record the RESOLVED versions in
   the §4 table when they move (the table above lists resolved versions, not
   wishes — keep it that way).

Fonts: Zodiak (Fontshare/ITF, free commercial) for display; Inter for
everything else. Product names are NEVER serif.

## 5. Backend API map — every endpoint we call

Base `/api/v1/`. JWT access+refresh (`ROTATE_REFRESH_TOKENS=False`; logout
blacklists the presented refresh). Verified live — ★ marks the 5 corrections
found by probing (never trust the draft; probe it).

### Auth / users

```
POST /auth/login/      {email, password} → {access, refresh, user}
POST /auth/refresh/    {refresh} → {access}            (single-flight retry)
POST /auth/logout/     {refresh} → blacklist
POST /auth/register/   {email, password, first_name, last_name, phone, role}
                        role ∈ CUSTOMER/MERCHANT/DELIVERY_AGENT; auto-verified
POST /auth/google/     {id_token} → {access, refresh, user}
GET  /users/me/        → User · PATCH {first_name, last_name, phone}
GET  /users/me/addresses/ · POST (AddressDraft) · PATCH/DELETE /:id/ ·
     POST /:id/set-default/
```
Used by: S2/S3/S9/S12/S13, boot, badge counts. 401 → single-flight refresh →
retry once → session-lost broadcast → guest.

### Catalog / search / misc

```
GET  /products/        ?category&brand&min_price&max_price&min_discount&
                       is_featured&sort&page&sort(newest/rating/price_*)
                       ★ BARE 20-item list, NO envelope → paginate by the
                       full-page rule (full page ⇒ maybe more, empty page ⇒
                       stop), track the REQUESTED page (responses echo page 1),
                       toolbar shows loaded count when total unknown.
GET  /products/:slug/  → detail + offers(top-5) + variants[] + images[]
                       ★ images[] key is "image" (not "url"); align_x is
                       percent (50, not 0.5)
GET  /categories/      → flat list (product_count, has_children) — images
                       currently ALL null (admin uploads pending)
GET  /products/brands/ → distinct brands (never /brands/)
POST /search/          {q, category, min_price, max_price, is_featured,
                       sort, page} → {results, total, page, page_size, ...}
GET  /search/suggestions/?q=  (min 2 chars) → [strings]
GET  /pincode/:code/   → {valid, city, state, eta_days, delivery_fee
                       (strings!), free_delivery_over} · 404 = unserviceable
GET  /storefront/platform/ → {store, theme, sections[], ticker}
                       ★ section type often EMPTY → infer by content
                       (product/category slugs, images, titles)
GET  /banners/         exists but Home renders BANNER/HERO sections instead
```
List rows carry `primary_image` (absolute Supabase URL); detail rows carry
`images[]` + `primary_image_display{align_x,align_y,zoom,effect}`.

### Cart / wishlist / reviews

```
GET  /cart/                 → {id, store, items[{id, variant{}, quantity,
                             line_total}], total_items, subtotal}
POST /cart/items/           {variant_id, quantity} (upsert-increment)
DELETE /cart/items/:id/     ★ PATCH 405s live → qty rewrite = DELETE + re-POST
POST /cart/merge/           {session_key} (NOT guest_token) — best-effort on login
DELETE /cart/clear/
GET  /products/wishlist/    (paginated FULL rows) · POST|DELETE /:slug/
GET|POST /products/:slug/reviews/  (409 = already reviewed)
```

### Orders / payments / coupons

```
POST /orders/          {cart_id, store?, delivery_address,
                       delivery_instructions?} → {"orders":[...]} (take first)
GET  /orders/ · GET /orders/:id/ (+items[] + status_history[]) ·
     POST /orders/:id/cancel/ {reason} (PENDING/CONFIRMED only)
GET  /payments/methods/ → saved methods (CARD|UPI|WALLET|COD)
POST /payments/        {order, gateway, amount, payment_method_id?}
                       v1 = COD + UPI-on-delivery only (UPI→PHONEPE,
                       CARD→STRIPE, WALLET→RAZORPAY; COD skips the call)
POST /admin/coupons/validate/ {code, order_value} (any authed user; 400 = bad)
```

### Engagement / devices / updates

```
GET  /notifications/ · POST /:id/mark_read/ · POST /mark_all_read/ ·
     GET /unread_count/
POST /analytics/events/ (+/batch/) · POST /realtime/devices/
     {platform: ANDROID, device_token, user_agent}
POST /pwa/updates/check/ {platform, current_version} → {update_available,
     version, release_notes, download_url, is_mandatory}
ws   /ws/orders/ · /ws/notifications/ (Channels; sockets NOT used by app v1 —
     30s polls instead)
```

**Dropped paths (never call):** `/auth/otp/*` phone, `/auth/me/`, `/brands/`,
`/wishlist/`, `/addresses/`, `/search/trending/`, `/coupons/active/`,
`/payments/intent|confirm/`, `/orders/:id/track/` (poll detail 30s instead),
`/products/:slug/rating-distribution/`.
**Live payload quirks:** detail images use key `"image"` (not `"url"`);
`align_x` arrives as percent (50, not 0.5); Decimals arrive as strings;
storefront section `type` is often empty (infer by content); category images
are currently all `null` (admin uploads pending).

## 6. Design system — tokens, components, screens

### 6.1 Token tables (`core/theme/tokens.dart` — the ONLY place with hex/px)

`theme_test.dart` fails the build on any `Color(0x` outside `core/theme/`.
Screens compose tokens; they never invent values.

**AppColors** (light + warm-charcoal dark pairs, `ThemeExtension` on both):

| Token | Light | Dark | Used for |
|---|---|---|---|
| brand / brandDeep | `#0C3B2E` deep green | lighter green | shell, app bar, primary buttons |
| marigold (accent) | warm amber | warm amber | badges, CTAs, stars, ETA pill |
| champagne | warm pale gold | — | product cards, PDP surface |
| obsidian | near-black text on champagne | — | text on champagne |
| success / warning / danger | green / amber / red | tuned pairs | status pills, validation |
| surface / sunken / hairline | white / warm grey fill / 1px border | charcoal variants | every container |

**AppSpace** (4pt grid): `xs 4 · sm 8 · md 12 · lg 16 · xl 20 · xxl 24 ·
xxxl 32 · huge 48`. **AppRadii**: card 18, image 14, button 16, sheet 24, pill 999.
**AppMotion**: micro 180ms / base 280 / page 350, `easeOutCubic`; home rail
entrances stagger 40ms, max ~10 items animated.

**Typography** (`app_typography.dart`): Zodiak Regular+Bold (bundled OTF,
offline-safe) for display/headlines/prices-on-hero ONLY; Inter (google_fonts,
runtime-cached) for everything else — **product names are NEVER serif**.
Type scale Display 28 → Headline 22 → Title 18 → Body 15/14 → Caption 12.
EVERY number tabular (`FontFeature.tabularFigures`): prices, quantities,
badges, ETAs, phone numbers — no layout jitter when digits change.

**Theming mechanics:** `AppTheme.light()/dark()` build `ThemeData` (scaffold,
app bar, nav bar, buttons, inputs, sheets, snackbars all tokenized).
`freshColors(context)` reads the extension. `ThemeMode` persists in
`account_providers` (System/Light/Dark chips) and drives `MaterialApp`.

### 6.2 Shared kit (`core/widgets/` — behavior from platforms, visuals ours)

| Widget | File | Contract |
|---|---|---|
| `popOrHome(context)` | `nav.dart` | pushed route → `pop()`; deep-link
with nothing to pop → `go('/home')`. Plus THE navigation-law comment. |
| `EasyGetAppBar` | `app_bar.dart` | surface bg, hairline, BackButton on
details, avatar+bell on Home. Never a centered title. |
| `AppSearchBar` | `search_bar.dart` | 52dp, read-only on Home (taps → `/search`),
editable on Search, mic → `?listen=1`. |
| `EasyGetBottomNav` | `bottom_nav.dart` | 5 tabs + live cart badge (marigold,
from `cartCountProvider`, hidden at 0). |
| `EasyGetShell` / `EasyGetTabScaffold` | `app_shell.dart` | shell + per-tab
navigators; tab reselection scrolls-to-top (Home key). |
| `SectionHeader` | `section_header.dart` | title left + ghost See-all (never
centered); used by every rail/section. |
| `AppChip` | `app_chip.dart` | 44dp pill, sunken→primaryTint selected,
optional count badge (filter sheet counts). |
| `SkeletonLine/Grid/Rail` | `skeletons.dart` | hand-rolled pulse — NOT the
shimmer package (which would hang `pumpAndSettle`). Shimmer forbidden in tests. |
| `EmptyState/ErrorState/OfflineState` | `states.dart` | ALWAYS vertically
centered (`Center`+`SingleChildScrollView`), icon + headline + body + action. |
| `StatusPill` / `EtaPill` | `status_pill.dart` / `eta_pill.dart` |
`humanizeStatus()` maps every backend enum; transit=marigold tint,
success=green, muted=grey. `DeliveryEtaPill` = live pincode ETA, self-hides. |
| `showAppSnackbar` | `snackbar.dart` | floating, ink-on-surface, 3s standard,
action support (Undo). All confirmations flow through it. |
| `AddressCard` | `address_card.dart` | radio + HOME/WORK chips + 2-line
address + tabular phone; id-scoped keys (`address-card-<id>-select`). |
| `OrderTimeline` | `order_timeline.dart` | vertical nodes from `status_history[]`
with timestamps; cancelled branch in red. |
| Commerce kit (`features/catalog/presentation/widgets/`) | `product_card.dart`
(fixed-slot anatomy + `gridAspect()` math + hearts + quick-add), `price_block`
(MRP strike + % off + tax note), `rating_pill` (never renders `0.0`),
`qty_stepper` (44dp targets), `variant_sheet`, `filter_sheet`, `sort_sheet`,
`category_tile` + `CategoryGridCard` (tile 5:6, grid card compact for 3-per-row). |

### 6.3 Screen-by-screen UX (what "done" looks like per route)

- **Boot** (`/`): brand splash (logo+name on brandDeep), cached profile →
  Home instantly; 3s `coldStartHint` on slow networks ("Warming up the
  servers…"), Retry goes straight home.
- **Login/Register** (`/login`, `/register`): email+password + Google button
  side by side; inline errors (no dialogs); 8s slow-network hint; success =
  merge guest cart + sync FCM token + `go('/home')`. Register has role
  segmented (Customer/Merchant/Agent).
- **Home** (`/home`): ticker → BANNER/HERO carousel (50vw peek, dots, autoplay
  4s) → category track (horizontal `home-category-track`) → PRODUCT_ROW rails
  (staggered entrances) → promo strip → story → **All-products grid** (same
  grid as Browse; NOT a legacy showcase rail).
- **Browse** (`/browse?category=`): pinned horizontal chips (URL-synced),
  toolbar (title + filter + sort-with-dot), 2-col card grid, infinite scroll,
  centered loading footer / end-marker; MNC filter sheet (brands/price/discount/
  featured) with badge count.
- **Search** (`/search?q=`): field + mic + recent-searches chips + category
  shortcuts; results = same grid; suggest-during-typing; recents + view-history
  (session); voice overlay with live transcript.
- **PDP** (`/product/:slug`): gallery + wishlist heart, title + rating +
  `PriceBlock`, variant swatches, delivery/pincode checker, description,
  reviews (avg + distribution + helpful + write), sticky bottom bar mirroring
  the card control (Add ↔ stepper in the SAME pressed slot).
- **Cart** (`/cart`): ETA pill, coupon row → sheet → applied bar, line cards
  (image 96 + title + unit price + stepper + line total + remove→Undo), server
  bill (subtotal/discount/delivery/total), trust rows, sticky checkout bar
  (total + count). Empty state → Shop action.
- **Checkout** (`/checkout`, guarded): steps header, address cards + shared form
  sheet, slot picker (Today/Tomorrow/Evening → `delivery_instructions`),
  dynamic method rows (COD always; UPI row live only while a UPI method exists;
  tap dead row = explainer), item summary, bill, guarded Place-order →
  pay (UPI) → clear → receipt.
- **Orders** (`/orders`, guarded): Active (to your door) vs Past (history)
  sections; card = status pill + ETA + items + total; cancel (reason sheet)
  in PENDING/CONFIRMED.
- **Order detail** (`/order/:id`, guarded): hero status, live timeline (30s
  poll), items, address, bill, invoice + cancel actions.
- **Wishlist** (`/wishlist`, guarded): saved grid (same card anatomy; heart-off
  removes with Undo), empty state → Discover.
- **Notifications** (`/notifications`, guarded): inbox rows (unread dot),
  tap → mark-read + deep-link; bell badge everywhere.
- **Addresses** (`/addresses`, guarded): radio default cards, set-default,
  edit/delete (confirm), shared form sheet with Photon autocomplete.
- **Account** (`/account`): monogram header + inline name/phone edit, order/
  address/wishlist rows with counts, appearance chips, notifications toggle,
  help rows, sign-out (clears tokens AND profile).

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
  for deep links) via a framework `BackButton` in `EasyGetAppBar`. Custom
  back icons are forbidden (platform chevron only).
- **Tab reselection scrolls to top** (Home key in the shell); switching tabs
  preserves each tab's scroll position (IndexedStack, no rebuild).
- **Every list nav is a GoRoute `.path` call** (never raw string interpolation)
  so renames propagate; `push` vs `go` violations fail `nav_test.dart`'s
  static source scan of `lib/`.

**Redirect law (DESIGN §14, unit-tested in `redirect_test.dart`):** unbooted →
hold splash; guest + private → `/login`; session + public → `/home`.
`/addresses /wishlist /notifications /order/*` are private (two holes closed
post-launch). Order success uses `go()` (replace, never back-to-checkout).

| Route | Public? | go or push? | Notes |
|---|---|---|---|
| `/` boot | yes | — | holds until `auth_state` resolves |
| `/login`, `/register` | yes | go | session+public → `/home` |
| `/home /browse /search /cart /orders` | yes | **go** | StatefulShellRoute branches |
| `/product/:slug`, `/browse/all` | yes | **push** | type-ahead on PDP reads query first |
| `/checkout`, `/account`, `/addresses` | guarded | **push** | checkout holds a draft cart id |
| `/order/:id`, `/wishlist`, `/notifications` | guarded | **push** | notification taps land here |

**Deep links the app both reads and writes:** `?category=` (Browse chips,
synced both ways — the URL is the source of truth, initState never seeds the
filter), `?q=` (search restores/updates on submit), `?listen=1` (auto-opens
the voice overlay). Push payloads carry `order_id` → cold-start/tap routes to
`/order/:id`. PAGE_VIEW analytics fire from the router observer with zero
screen code.

## 8. State & data patterns — how features are built

### 8.1 The standard feature recipe (copy this for every new screen)

1. **Model** in `lib/models/`: `fromJson` defensive (missing keys → sane
   defaults), `numToDouble`/`numToInt` coercion (the API mixes Decimal strings
   and numbers), `toJson` only where caching needs it (`AppUser`).
2. **Repository** in `features/<x>/data/`: `abstract XxxRepository` +
   `HttpXxxRepository(ApiClient)` + `xxxRepositoryProvider`. All HTTP hides
   here; screens never touch Dio. Contract tests in `test/data/` assert
   method+path+body against a fake `HttpClientAdapter`.
3. **Controller** (`Notifier`/`NotifierProvider` — never `StateProvider`,
   gone in Riverpod 3): owns UI state + actions + timers. Async boot loads use
   the **`loading:false`-explicit pattern** — constructor defaults bite
   (S5/S8/S11 all shipped this bug: Notifier starts non-loading, so the first
   frame must set loading true explicitly before the fetch, else skeletons
   never show and error paths go untested).
4. **Screen** (`ConsumerWidget`/`ConsumerStatefulWidget`): watches controller +
   providers, renders loading/empty/error/data. No business logic, no Dio,
   no `setState` for server state.
5. **Fakes:** every test file carries `_FakeXxxRepo` (in-memory,
   call-recording). No mocks, no network in tests, ever.

### 8.2 Provider rules that bite (all learned the hard way)

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
- **`pumpAndSettle` hangs** on perpetual animations (spinners, pulse
  skeletons, 60s watchers) → use explicit `pump(Duration)` in those tests.
- **Shimmer package widgets must never render in tests** (infinite animation
  frame loop) — our `SkeletonPulse` is a bounded opacity animation instead.

### 8.3 Cross-cutting conventions

- **Snackbars:** one 3s standard (`showAppSnackbar`, hide-first); Undo flows
  refresh-on-dismiss to confirm server truth.
- **Prices:** server truth only; client derives `payable = subtotal − coupon`
  and clamps ≥ 0. `₹` formatting strips `.00`. Every money figure tabular.
- **Optimistic UI + reconcile:** remove/toggle applies instantly, records the
  prior value, reverts + explains on failure, refreshes on Undo-dismiss.
- **Idempotency:** checkout guards `isPlacing`; double-tap can't create two
  orders; order success replaces the route (never back-to-checkout).
- **Analytics:** PAGE_VIEW from the router observer; business events via
  `analyticsRepositoryProvider` (fire-and-forget, never awaited in UI code).

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

## 9. How we work — TDD gate, commits, ledger

### 9.1 The per-task gate (no exceptions, no shortcuts)

1. **RED:** write the failing test first and watch it fail (proves the test
   tests something).
2. **GREEN:** implement until the new test passes.
3. **ANALYZE:** `flutter analyze` prints `No issues found!` (infos included).
4. **FULL SUITE:** `flutter test` — the WHOLE suite, not just your file
   (cross-feature regressions are the norm in a shell+providers app).
5. **COMMIT:** one conventional commit (`feat|fix|test|perf(app): …`),
   staging ONLY `customer-app-v2/**` (+ docs) — **never `git add .`** (the
   tree has other surfaces' dirty files).
6. **LEDGER:** append `Task: complete (commits base..head, tests: …)` to
   `.superpowers/sdd/<plan>/progress.md`.

One screen/component per commit; every commit must analyze clean standalone
(verified in throwaway worktrees when history is rebuilt). Prefix shell
commands with `rtk` (repo convention).

### 9.2 Working with the AI agent (this repo's actual process)

- Work is planned in `docs/superpowers/plans/<date>-<topic>-plan.md` and
  tracked in `.superpowers/sdd/<plan>/progress.md` — read both before touching
  code; they contain the live-probe findings no other doc has.
- Scope discipline: **one component or screen per session** (DESIGN hard rule
  §8). Never batch; never "while I'm here" a second feature.
- `CONTEXT.md` (frozen facts) + `DESIGN.md` (tokens, laws) ride along in every
  AI prompt. If the API surprises you, probe it live, record the finding in
  the ledger, and update the frozen map + a test — don't just work around it.
- PowerShell 5.1: `;` chains, no heredocs for file edits (use the file tools),
  never `*` unquoted in `-match`, quote paths with spaces.

### 9.3 Prompt template (paste this + the task into a fresh AI session)

```
Repo: <path>/EasyGet, branch fix/flutter-web-and-ordering, workdir customer-app-v2/.
Read first: CONTEXT.md (frozen API facts) + DESIGN.md (tokens, laws) +
docs/superpowers/plans/<plan>-plan.md + .superpowers/sdd/<plan>/progress.md.
Task: <one screen/component, scope from the plan>.
Gate: RED test → GREEN → flutter analyze clean → FULL flutter test green →
one conventional commit (stage only customer-app-v2/** + docs, never git add .)
→ ledger line. Laws: navigation §7, tokens §6.1/§22, no invented endpoints (§5).
```

Why this works: the plan holds scope, the ledger holds probe findings, and
the gate holds quality — the agent needs all three or it will invent APIs,
hardcode colors, and batch commits. One component per session, always.

## 10. History — scratch to current, phase by phase

Full log: `git log --oneline -- customer-app-v2` (~70 commits). Highlights:

### Phase 1 — scaffold → S3 (foundation, auth, boot)

Scaffold + Fresh-Market theme + network core (frozen endpoints, `ApiException`)
+ session core (token store, single-flight 401 refresh) + router redirect
matrix + S1 boot + S2 login (+Google, cold-start hints) + S3 register +
splash warm-up + baked OAuth IDs (web client + SHA-1).

### Phase 2 — Commerce Kit (T1–T8, 83 → 163 tests)

Contract reconciliation (live-probe: dropped paths, `942ed65`) → data layers:
catalog/pincode/storefront (`2f2f778`), cart/wishlist+merge (`3d17480`),
orders/addresses/reviews/payments (`7aa41a1`), notifications/analytics/
app-update (`4d66b0f`) → T6 shell (`a3769a6`: StatefulShellRoute, AppBar,
search bar, 5-tab nav + badge, PAGE_VIEW) → T7 commerce widgets (`6c693a8`:
ProductCard/PriceBlock/RatingPill/QtyStepper/VariantSheet + tokens) → T8 kit
(`2bd8d90`: sheets/chips/skeletons/states/pills/cards/timeline).

### Phase 3 — S4–S13 screens (139 → 239 tests, one commit per screen)

Home `9540989` → Browse `12744b7` → Search `f28efa9` → PDP `7d5abd8` → Cart
`819b69a` → Checkout `2fbed3b` → Orders `07fda48` → Order-detail+poll `80e35ac`
→ Account `586a890` → Addresses `2d1fcee`. Each screen: RED contract/widget
tests → GREEN → gate → commit.

### Fix rounds (hardening — every line below is a user-visible bug that died)

PATCH→DELETE+POST rewrite (`94e7de5`) · push-based back nav (`e4905a9` +
`nav.dart` law) · fixed card anatomy (`894d7de` + `gridAspect()`) · category
tiles (`f2143ea`) · dynamic checkout (`27f47ea`) · PDP confirm pipeline
(`d8010ac`) · appearance chips (`9b52976`) · card hearts (`533776c`) ·
address alignment + Photon autocomplete (`865587f`) · instant boot via cached
profile + branded splash (`1a49498`) · bare-list paging + MNC filter + hero/
track/pushed-browse + centered CTA (`5c85566`, `59a8673`, `4a871ce`,
`2a46b93`) · voice search (`435f3f8`) · quick-add pipeline + live badge +
All-products (`9ca77ba`) · centered states (`b985483`) · view-cart tab fix
(`5148fbc`) · release splits ~19MB (`41c68be`) · image-key decode (`2c86b81`)
· Zodiak (`a34708d`) · champagne/obsidian cards (`d90d072`) · live qty +
dynamic ETA (`aa9fbbf`, `27142ed`) · explicit added-state (`9cc273b`) ·
search browser + show-more (`a370656`).

### Phase 4 — engagement (239 → 332 tests)

W1 wishlist screen (`4a111e1`) → E1 inbox + badge (`57a0316`) → E2 60s order
watcher + local alerts (`ca11130`) → E3 update gate (`252507b`) → FCM wiring
on project `easyget-7a4b0` (`0c47edb`: google-services, device sync,
foreground/tap/cold-start, deep-link) → explicit added-state → README
(`b17c346`, then this expansion).

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
12. **Decimals arrive as strings** (`delivery_fee: "49"`) — every money model
    coerces via `numToDouble`; `double.parse` on a number crashes just as hard
    as on a string, so coerce don't cast.
13. **A 200 with an envelope you didn't expect is worse than a 404** — the
    browse pager read `page: 1` echoes as ground truth for a week; always track
    the REQUESTED page for bare lists.
14. **Two sources of truth for one filter will desync** (Browse chips vs
    initState) — the URL wins, everything else syncs post-frame. Same rule
    applies to search `?q=`.
15. **Don't animate what the test must settle** — every entrance animation in
    this app is bounded (stagger caps at ~10 items); infinite loops (shimmer,
    autoplay PageView) are test-hostile and need seams.
16. **Backend fixtures lie; probes don't** — five contract corrections in §5
    came from `curl`/device hits, not docs. When adding an endpoint: probe it,
    paste the shape into the ledger, then write the model.
17. **One commit per screen isn't bureaucracy** — it makes `git bisect` work
    on UI regressions and keeps reverts surgical (the view-cart crash fix
    reverted cleanly because it was one commit).

## 12. Remaining work & roadmap

Ordered by user impact. Items marked **[backend]** need Django work first —
the app must never invent endpoints (§8 hard rule 2).

- [ ] **[backend] FCM sender** (spec below): `firebase-admin` from the Render
  service-account env; send `{order_id}` on status transitions to the user's
  active `Device` rows. Nothing sends pushes yet — this unlocks the whole
  push pipeline.

**FCM sender spec (hand to the backend dev):** on every order status
transition (R1 machine), look up the user's active `Device` rows
(`realtime_devices`, filter revoked/expired), and send a DATA-ONLY FCM message
`{order_id: "<id>"}` + notification `{title, body}` with customer copy
matching `humanizeStatus()` ("Your order is on its way"). Triggers:
CONFIRMED, PREPARING, READY, OUT_FOR_DELIVERY, DELIVERED, CANCELLED. Service
account JSON from the Render env var (never committed); project
`easyget-7a4b0`. Acceptance: a real transition replaces the Firebase-console
test message; killed-app tap lands on `/order/:id` (§31); no duplicates on
retry (idempotency key = order_id + status).
- [ ] **Release signing key + Play Console AAB + store listing** (blocks any
  public launch; procedure in §2.4).
- [ ] **[backend] Category images in admin** (tiles fall back to icons until
  uploaded — biggest visual gap on Home).
- [ ] **[backend] Reorder-from-order** (needs variant ids on order items).
- [ ] **Background order watcher** (WorkManager) — alerts only run app-open
  today; FCM sender reduces the urgency.
- [ ] **[backend] Reviews / Coupons / Payments list screens** (no list
  endpoints exist; Account rows are stubs until then).
- [ ] **Recents + recent-views persistence** (in-memory today; Hive or
  secure-store JSON).
- [ ] **iOS APNs leg for pushes; iOS mic usage string** (Android-only today).
- [ ] Sockets for `/ws/orders/` (today: 30s polls; fine at current scale).
- [ ] Launcher icon polish + feature graphic (splash uses the icon today).

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
- **`flutter run` can't see the phone** → `adb devices` empty → check cable
  (charge-only cables fool everyone), USB debugging on, "allow" prompt
  accepted, `adb kill-server; adb start-server`.
- **Google Sign-In fails on device** → SHA-1 in the Firebase console must match
  the signing key (`keytool -list -v`); debug vs release keys differ — register
  both. Web client ID must match `GOOGLE_CLIENT_ID`.
- **Images load in debug, not release** → cleartext HTTP blocked in release
  (all our URLs are HTTPS — check yours); Supabase host must be in the
  network-security config if you add hosts.
- **Coupon valid on web, rejected in app** → `order_value` sent is the
  client-derived payable (§8.3); if the server disagrees by a rupee the code
  fails — refresh the cart first.
- **Wishlist heart flips back** → optimistic toggle reverted: the POST failed
  (auth? network?) — the snackbar says why. Hearts are per-card; the detail
  screen and grid sync through `wishlistControllerProvider`.
- **Cart badge stuck** → `cartCountProvider` derives from cart state; a failed
  silent refresh leaves it stale — pull-to-refresh the cart (badge follows).
- **Address form won't save** → validation: label + line1 + city + postal code
  required; postal code must pass the pincode check; error text is inline
  under the field, not a toast.
- **Order success but no order in list** → multi-tenant `{"orders":[...]}`:
  we take the first; if the cart spanned sellers, siblings exist — pull to
  refresh Orders.
- **Prices show `66.00`, not `₹66`** → the formatter strips `.00` only when
  the value came through `numToDouble`; a raw string interpolated in a new
  widget skips it — use `tabularPrice` (§22), never string interpolation.
- **Dark mode looks wrong on one screen** → the screen hardcoded a light hex
  (theme_test should have caught it — check the file is covered) or read
  `AppColors.lightX` directly instead of `freshColors(context)`.
- **Filter badge count is wrong** → count derives from `BrowseFilter.active`
  fields; a new filter field needs a line in the counter AND a chip in the
  MNC sheet AND a test row.
- **Search shows stale results after typing fast** → a new query must cancel
  the old one (CancelToken); if you added a second fetch path (e.g. voice
  submit), route it through the same controller method.
- **Two hearts disagree (card vs PDP)** → both must read
  `wishlistControllerProvider`'s set; a locally-`useState`'d heart is the bug
  (`533776c` killed the last one).
- **Badge shows but cart is empty** → `cartCountProvider` derives from cart
  state; stale after failed silent refresh — the cart screen pull-to-refresh
  is the recovery path; don't reset the badge locally.
- **Sheet looks unstyled / wrong radius** → bottom sheets need
  `backgroundColor: surface` + `shape: Rounded(sheet)` (24) explicitly; the
  Material default is NOT our sheet.
- **`go()` from a dialog/sheet does nothing** → pop the sheet first (its
  context is above the router); `popOrHome` after `Navigator.pop`, or use the
  root context.
- **Test passes alone, fails in suite** → shared static state (a singleton
  seam, a global key, a timer) leaked between tests; run
  `flutter test test/<area>/` to bisect, then isolate the fake per-file (§8.1).
- **Analyze clean, device crash on release only** → R8/shrink stripped a
  plugin class (check `proguard-rules.pro` needs) or a debug-only asset path;
  reproduce with `flutter run --release` before guessing.
- **Inter renders as fallback Roboto** → first launch offline (google_fonts
  needs one fetch); Zodiak still renders (bundled). Not a bug — document it
  if QA files it.

**Decision trees (start here, follow down):**

*App won't boot (stuck on splash / red screen):*
provider wiring broke → read the FIRST exception (cascades lie) → missing
override in `main.dart` shim? → new required provider param without a default?
→ run `app_smoke_test` alone (fastest repro) → bisect by commenting watchers.

*Blank screen / wrong data (no crash):*
loading flag stuck? (constructor default — §8.1 step 3) → fake returned empty?
→ repository mapped the wrong key? (re-probe, §30) → URL filter desync?
(§8.2) → `pump(Duration)` too short in the test (not an app bug)?

*Crash on back / tab switch:*
`push()` to a tab root? (`nav_test` scan) → nested navigator missing a
`popOrHome`? → sheet context used for `go()`? (pop first) → engine-back test
missing for the new route? (add it — §26 skeleton).

*Release-only crash:*
R8 stripped a plugin class? → asset path debug-only? → `flutter run --release`
repro → logcat (`adb logcat`, no filters first) → compare debug vs release
widget tree (usually a `kDebugMode` branch that hid the bug all along).

## 14. Logins, links, glossary

- Logins: §2 table. API base §1. Firebase project `easyget-7a4b0`.
- Plans/ledger: `docs/superpowers/plans/`, `.superpowers/sdd/`.
- Repo docs: `DESIGN.md` (design law), `CONTEXT.md` (frozen facts),
  `GETTING_STARTED.md` (multi-surface runbook).
- **Glossary:** PLP = product listing page · PDP = product detail page · CTA
  = call to action · MNC = multinational-company-grade UX bar used in reviews
  · Ruling = a deviation from DESIGN.md recorded in the ledger with proof ·
  RED/GREEN = failing-first / passing-after TDD steps · full-page rule =
  bare-list pagination (§5 Catalog) · navigation law = go/push split (§7) ·
  seam = testability interface with real + fake impls (§8.2) · ledger = the
  per-plan `progress.md` work log (§9) · shim = tiny glue widget/provider
  that adapts an SDK to our seams (router shim, tap shim) · guard =
  `isPlacing`-style re-entrancy flag · rail = horizontal product carousel ·
  track = horizontal category/icon strip · inference = `sectionKind()`
  content-based section typing (Q6) · single-flight = one shared future for
  concurrent 401 refreshes (ADR-11) · cold open = launch with no cached
  session · warm open = launch with cached profile (§31) · split = per-ABI
  release APK (§2.3) · bare list = unenveloped array response (Q1) ·
  envelope = wrapped response (`{"orders":[…]}`) · optimistic = apply-first,
  reconcile-after UI (ADR-9) · tabular = fixed-width figures, no jitter (§22).

## 15. Changelog (README-level; code details in `git log`)

- 2026-10-26: full rewrite (WHAT/HOW split, verified SHAs, release table).
- 2026-10-26: expansion to ~2500 lines / 34 sections — architecture map,
  token tables with exact values, kit catalog, screen specs + wireframes,
  state recipe + test recipe, provider→endpoint trace, API shapes with real
  JSON, controller state tables, ADRs, cookbook, quirks registry, runtime
  sequences, onboarding/review/release, operational references.

**Doc maintenance (who updates this file, and when):** the author of a change
updates the affected sections IN THE SAME COMMIT (review checklist §27
enforces it). Stale docs are bugs: new file → §16; new test → §17 (+ counts);
new endpoint → §5 + §18 + §25; token change → §22; layout change → §24;
new quirk → §30; new decision → §28. The `Last verified` line at the foot
moves with every docs commit — if it's older than the newest app commit,
treat the README as suspect.

**Verify this doc** (after any docs commit — fences must stay even, anchors alive):
```powershell
(Get-Content "customer-app-v2\README.md").Count
(Select-String -Path "customer-app-v2\README.md" -Pattern '```' | Measure-Object).Count
```
- Earlier: 409-line v1 (`b17c346`) covering phases 1–4 + FCM + polish.

## 16. Appendix A — every `lib/` file and what it does

Paths relative to `customer-app-v2/lib/`. 100 files. If you add one, add its
line here.

**`main.dart`** — composition root: ProviderScope (+ router shim so
notification taps navigate), EasyGetApp (themeMode, router, UpdateGate,
watcher + push-sync kickoff post-frame).

**`core/config/app_config.dart`** — `apiBase` / `storeSlug` / `googleClientId`
from `--dart-define`, `mediaUrl()` absolutizer for `/media/…` paths.

**`core/network/`** — `api_client.dart` (Dio factory: 90s/60s timeouts,
bearer, single-flight 401 refresh, `warmUp()`, CancelToken GET);
`api_endpoints.dart` (FROZEN map — §5); `api_exception.dart` (every failure →
one human sentence); `auth_interceptor.dart` (attach + refresh + retry-once);
`session_lost.dart` (broadcast: refresh died → guest).

**`core/router/app_router.dart`** — 5-tab StatefulShellRoute, pushed
top-level routes, `redirectFor()` law, PAGE_VIEW observer, deep-link parsing.

**`core/storage/token_store.dart`** — `TokenStore` interface (JWTs, guest
session key, analytics session id, cached user JSON); `InMemoryTokenStore`
(tests) + `SecureTokenStore` (device); `clear()` wipes tokens AND profile.

**`core/theme/`** — `tokens.dart` (AppColors/champagne/obsidian, AppSpace 4pt,
AppRadii, AppMotion, light+dark extensions, `freshColors`); `app_theme.dart`
(Material ThemeData incl. nav bar/buttons/sheets); `app_typography.dart`
(Zodiak display + Inter body, tabular figures).

**`core/widgets/`** — `nav.dart` (`popOrHome` + law); `app_bar.dart`
(EasyGetAppBar); `search_bar.dart` (52dp AppSearchBar + mic link);
`app_shell.dart` (shell + tab scaffold + reselection scroll-to-top);
`bottom_nav.dart` (5 tabs + live cart badge); `section_header.dart`;
`app_chip.dart` (44dp + count badge); `skeletons.dart` (bounded pulse);
`states.dart` (Centered Empty/Error/Offline); `status_pill.dart`
(`humanizeStatus`); `eta_pill.dart`; `snackbar.dart` (`showAppSnackbar` 3s);
`address_card.dart` (id-scoped keys); `order_timeline.dart`.

**`models/`** — `catalog_models.dart` (Product/Variant/Category/Brand/Image);
`cart_models.dart` (Cart/Line/Coupon); `order_models.dart`
(Order/Item/Event + status enum); `address_model.dart` (+ AddressDraft);
`review_model.dart`; `payment_model.dart`; `notification_model.dart`;
`app_update_model.dart`; `pincode_model.dart`; `storefront_models.dart`
(sections + `sectionKind()` inference).

**`features/auth/`** — `data/app_user.dart` (toJson/fromJson for cache);
`data/auth_repository.dart` (login/Google/register/me/logout/merge);
`data/google_auth_source.dart`; `presentation/auth_controller.dart` (boot
fast-path + background refresh, signIn/Google/register/signOut);
`presentation/auth_state.dart` (Booting/SignedIn/Guest+coldStartHint);
`presentation/boot_screen.dart`; `presentation/login_screen.dart`;
`presentation/register_screen.dart`.

**`features/home/`** — `presentation/home_providers.dart` (storefront,
categories, hot/top/new fallbacks, all-products pager);
`presentation/home_screen.dart`.

**`features/browse/`** — `presentation/browse_providers.dart` (filter + paged
items + brands, full-page rule); `presentation/browse_screen.dart`;
`presentation/browse_filter_sheet.dart` (MNC sheet).

**`features/search/`** — `data/search_repository.dart` (suggestions/results +
recents/views stores); `data/voice_search.dart` (speech seam, `en_IN`);
`presentation/search_controller.dart` (300ms debounce, CancelToken,
defensive hasMore); `presentation/search_screen.dart`.

**`features/catalog/`** — `data/catalog_repository.dart`;
`presentation/quick_add.dart` (resolve + pipeline + `cardAdditionsProvider`);
`presentation/widgets/product_card.dart` (+ `gridAspect()` + `CardAddControl`);
`price_block.dart`; `rating_pill.dart` (hides 0.0); `qty_stepper.dart`;
`variant_sheet.dart`; `filter_sheet.dart`; `sort_sheet.dart`;
`category_tile.dart` (+ `CategoryGridCard`).

**`features/cart/`** — `data/cart_repository.dart` (fetch/add/DELETE+re-POST/
remove/clear + count); `data/coupon_repository.dart`;
`presentation/cart_controller.dart` (optimistic + Undo + coupon);
`presentation/cart_screen.dart`.

**`features/checkout/`** — `presentation/checkout_controller.dart`
(addresses/methods/cart, slot+note, gateway map, idempotent place→pay→clear);
`presentation/checkout_screen.dart`.

**`features/orders/`** — `data/orders_repository.dart`;
`presentation/orders_providers.dart` (list + Active/Past + detail family with
30s poll); `presentation/orders_screen.dart`;
`presentation/order_detail_screen.dart`; `presentation/cancel_order_sheet.dart`.

**`features/payments/`** — `data/payment_repository.dart` (methods + direct
create). **`features/reviews/`** — `data/review_repository.dart`.

**`features/wishlist/`** — `data/wishlist_repository.dart`
(fetch/fetchProducts/toggle); `presentation/wishlist_controller.dart`
(optimistic, bool toggle); `presentation/card_heart.dart`;
`presentation/wishlist_screen.dart`.

**`features/addresses/`** — `data/address_repository.dart`;
`data/place_autocomplete.dart` (Photon, keyless); 
`presentation/addresses_controller.dart`; `presentation/addresses_screen.dart`;
`presentation/address_form_sheet.dart` (shared with checkout).

**`features/account/`** — `data/profile_repository.dart`;
`presentation/account_providers.dart` (profile, ThemeMode, notifications);
`presentation/account_screen.dart`.

**`features/engagement/`** — `data/analytics_repository.dart`;
`data/app_update_repository.dart`; `data/notifications_repository.dart`;
`data/order_watcher.dart` (60s poll + seam); `data/push_repository.dart`;
`data/push_service.dart` (Firebase seam + sync + handlers + deep-link);
`presentation/notifications_providers.dart`;
`presentation/notifications_screen.dart`; `presentation/update_gate.dart`.

**`features/delivery/`** — `presentation/delivery_eta.dart` (address→pincode
ETA + self-hiding pill).

## 17. Appendix B — every test file and what it guards

Paths relative to `customer-app-v2/test/`. 43 files. The suite is the spec —
read the test before changing the code it covers.

**Suite at a glance** (cases per file via grep; runner reports 332 green —
the delta is grouped/parameterized cases):

| File | Cases | File | Cases |
|---|---|---|---|
| `app_smoke_test.dart` | 1 | `engagement/push_service_test.dart` | 5 |
| `theme_test.dart` | 2 | `engagement/update_gate_test.dart` | 5 |
| `account/account_screen_test.dart` | 8 | `home/home_screen_test.dart` | 11 |
| `addresses/addresses_screen_test.dart` | 13 | `network/api_client_test.dart` | 6 |
| `auth/auth_controller_test.dart` | 11 | `network/api_endpoints_test.dart` | 11 |
| `auth/auth_interceptor_test.dart` | 5 | `network/api_exception_test.dart` | 7 |
| `auth/boot_screen_test.dart` | 4 | `notifications/notifications_screen_test.dart` | 5 |
| `auth/guest_cart_merge_test.dart` | 2 | `orders/orders_screen_test.dart` | 6 |
| `auth/login_screen_test.dart` | 6 | `orders/order_detail_test.dart` | 6 |
| `auth/register_screen_test.dart` | 5 | `product/product_screen_test.dart` | 11 |
| `auth/token_store_test.dart` | 4 | `router/nav_test.dart` | 4 |
| `browse/browse_screen_test.dart` | 11 | `router/redirect_test.dart` | 7 |
| `cart/cart_screen_test.dart` | 11 | `search/search_screen_test.dart` | 14 |
| `catalog/quick_add_test.dart` | 7 | `shell/shell_test.dart` | 7 |
| `checkout/checkout_screen_test.dart` | 9 | `widgets/commerce_widgets_test.dart` | 13 |
| `data/*_repository_test.dart` (×8) | 3–9 | `widgets/kit_widgets_test.dart` | 20 |
| `delivery/delivery_eta_test.dart` | 3 | `wishlist/wishlist_screen_test.dart` | 5 |
| `engagement/order_watcher_test.dart` | 5 | | |

- `app_smoke_test.dart` — app boots to splash-or-home with no crash (catches
  provider wiring mistakes at the root).
- `theme_test.dart` — **no `Color(0x` outside `core/theme/`** (static source
  scan); light+dark extensions resolve; tabular figures present.
- `auth/auth_controller_test.dart` — boot fast-path (cached → instant),
  background refresh, signIn/Google/register/signOut, session-lost → guest.
- `auth/auth_interceptor_test.dart` — bearer attach, single-flight 401 refresh,
  retry-once, refresh-fail → session-lost broadcast.
- `auth/boot_screen_test.dart` — splash renders brand, 3s hint appears on
  slow boot, retry goes home.
- `auth/guest_cart_merge_test.dart` — `{session_key}` merge payload on login,
  best-effort (failure never blocks sign-in).
- `auth/login_screen_test.dart` — email + Google paths, inline errors, 8s
  slow hint, success merges + syncs push + goes home.
- `auth/register_screen_test.dart` — role segmented, field errors, auto-login.
- `auth/token_store_test.dart` — save/read/clear round-trips, `clear()` wipes
  profile too, in-memory vs secure parity.
- `browse/browse_screen_test.dart` — chips↔URL sync (URL wins), filter/sort,
  bare-list full-page paging, footer states, centered loading.
- `cart/cart_screen_test.dart` — lines render, DELETE+re-POST rewrite, Undo +
  refresh-on-dismiss, coupon apply/remove, server bill math.
- `catalog/quick_add_test.dart` — resolve-variant rule (single → direct,
  multi → sheet), pipeline states, `cardAdditionsProvider` map.
- `checkout/checkout_screen_test.dart` — dynamic methods (UPI row live/dead),
  slot → instructions, idempotent place→pay→clear, replace-to-receipt.
- `data/*_repository_test.dart` (8 files: address, cart, catalog, engagement,
  orders, payment, review, wishlist) — contract tests: fake `HttpClientAdapter`
  asserts method+path+body per endpoint, defensive fromJson on fixtures.
- `delivery/delivery_eta_test.dart` — address→pincode→ETA, self-hide on
  failure, pill shows minutes only.
- `engagement/order_watcher_test.dart` — 60s poll detects transitions, seam
  notifier fires, tap shim routes; timer `stop()` before body end.
- `engagement/push_service_test.dart` — fake `PushBackend`: sync payload,
  foreground handler, tap/cold-start deep-link to `/order/:id`.
- `engagement/update_gate_test.dart` — forced vs optional copy, store link via
  fake `UrlOpener`, dismiss rules.
- `home/home_screen_test.dart` — ticker, carousel, category track, rails,
  All-products grid, inference fallbacks, avatar+bell+address header.
- `network/api_client_test.dart` — timeouts, headers, refresh flow, warmUp
  never throws, CancelToken respected.
- `network/api_endpoints_test.dart` — frozen map keys match §5 (add-endpoint
  = update this test).
- `network/api_exception_test.dart` — every Dio error shape → one human
  sentence (timeout/401/404/400-envelope/offline).
- `notifications/notifications_screen_test.dart` — inbox rows, unread dot,
  tap → mark-read + deep-link, badge count.
- `orders/orders_screen_test.dart` — Active/Past split, cancel + reason sheet,
  cancel limits (PENDING/CONFIRMED).
- `orders/order_detail_test.dart` — hero, timeline from history[], 30s poll
  updates, invoice + cancel actions.
- `product/product_screen_test.dart` — gallery, variants, pincode checker,
  reviews, type-ahead confirm pipeline, sticky-bar mirror.
- `router/nav_test.dart` — **static scan: no `push()` to tab roots** + route
  table (`go` vs `push` per path) + deep-link parsing.
- `router/redirect_test.dart` — redirect law matrix (unbooted/guest/session ×
  public/private), private-route list, order-success replace.
- `search/search_screen_test.dart` — 300ms debounce, CancelToken cancel,
  suggest/results modes, recents/views, show-more footer, voice overlay seam.
- `shell/shell_test.dart` — 5 tabs render, badge follows cart count, tab switch
  preserves scroll, reselection scrolls to top, gallery grid inside tabs.
- `widgets/commerce_widgets_test.dart` — card anatomy slots, `gridAspect()`
  math, PriceBlock/RatingPill/QtyStepper/VariantSheet contracts.
- `widgets/kit_widgets_test.dart` — chips/sheets/skeletons/states/pills/
  address-card/timeline render + centered-states rule.
- `wishlist/wishlist_screen_test.dart` — saved grid, heart-off remove + Undo,
  reactive sync with detail hearts.

## 18. Appendix C — API response shapes (live probes, abridged)

These are what the backend ACTUALLY returns (not the draft). Models in §16
parse exactly these. Decimals are strings; missing keys are normal.

**`GET /products/` — bare list, no envelope:**
```json
[
  { "id": 12, "name": "Amul Taaza Milk 1L", "slug": "amul-taaza-1l",
    "category": "Dairy", "brand": "Amul", "mrp": "70.00",
    "base_price": "66.00", "discount_percent": 5.7, "is_featured": true,
    "primary_image": "https://xyz.supabase.co/storage/v1/object/public/.../milk.jpg",
    "rating_avg": "4.3", "rating_count": 128 }
]
```

**`GET /products/:slug/` — detail (note `"image"` key, percent aligns):**
```json
{ "id": 12, "name": "Amul Taaza Milk 1L", "slug": "amul-taaza-1l",
  "description": "…", "rating_avg": "4.3", "rating_count": 128,
  "offers": [{ "code": "MILK10", "discount": "10" }],
  "variants": [{ "id": 44, "name": "1 L", "sku": "AMZ-1L",
                 "price": "66.00", "mrp": "70.00", "attributes": {} }],
  "images": [{ "image": "https://…/milk-1.jpg", "is_primary": true }],
  "primary_image_display": { "align_x": 50, "align_y": 50, "zoom": 1.0,
                             "effect": "none" } }
```

**`GET /cart/`:**
```json
{ "id": 7, "store": 1, "total_items": 3, "subtotal": "198.00",
  "items": [{ "id": 91, "quantity": 2, "line_total": "132.00",
    "variant": { "id": 44, "name": "1 L", "price": "66.00",
                 "product": 12, "product_name": "Amul Taaza Milk 1L",
                 "product_slug": "amul-taaza-1l", "image": "https://…/milk.jpg" } }] }
```

**`POST /orders/` → multi-tenant envelope (take first):**
```json
{ "orders": [{ "id": 501, "status": "PENDING", "subtotal": "198.00",
  "discount": "20.00", "total": "187.00" }] }
```

**`GET /orders/:id/` — detail + timeline:**
```json
{ "id": 501, "status": "OUT_FOR_DELIVERY", "subtotal": "198.00",
  "discount": "20.00", "total": "187.00",
  "delivery_address": { "line1": "…", "city": "…", "postal_code": "400001" },
  "items": [{ "variant_name": "Amul Taaza Milk 1L (1 L)", "qty": 2,
               "unit_price": "66.00" }],
  "status_history": [{ "status": "PENDING", "created_at": "2026-10-20T10:01:00Z" },
                     { "status": "CONFIRMED", "created_at": "2026-10-20T10:04:00Z" }] }
```

**`GET /pincode/400001/` (fee fields are strings; 404 = unserviceable):**
```json
{ "valid": true, "pincode": "400001", "city": "Mumbai", "state": "MH",
  "eta_days": 1, "delivery_fee": "49", "free_delivery_over": "499",
  "source": "static" }
```

**`GET /storefront/platform/` — sections need inference:**
```json
{ "store": { "slug": "easyget", "name": "EasyGet" }, "ticker": "…",
  "sections": [{ "id": 3, "type": "", "order": 1,
    "config": { "title": "Dairy picks",
                "product_slugs": ["amul-taaza-1l", "…"] } }] }
```

**`POST /search/` → envelope WITH total (unlike listing):**
```json
{ "results": [ { "slug": "amul-taaza-1l", "name": "…", "base_price": "66.00",
  "primary_image": "https://…", "rating_avg": "4.3" } ],
  "total": 3, "page": 1, "page_size": 20, "took_ms": 41, "query": "milk" }
```

**`POST /admin/coupons/validate/` — 200 vs 400:**
```json
// 200: { "valid": true, "discount": "20.00", "discount_type": "FLAT",
//         "coupon": { "code": "MILK10" } }
// 400: { "valid": false, "message": "Minimum order ₹199" }
```

**`POST /pwa/updates/check/`:**
```json
{ "update_available": true, "version": "1.4.0", "is_mandatory": false,
  "release_notes": "…", "download_url": "https://…" }
```

## 19. Appendix D — new-screen recipe (copy, rename, fill in)

Scaffold order (TDD: tests first, §9.1):

```
lib/models/<thing>_model.dart
lib/features/<thing>/data/<thing>_repository.dart
lib/features/<thing>/presentation/<thing>_controller.dart  (or _providers.dart)
lib/features/<thing>/presentation/<thing>_screen.dart
test/data/<thing>_repository_test.dart
test/<thing>/<thing>_screen_test.dart
(+ route in app_router.dart, nav test update, README §16/§17 lines)
```

**1. Model** — defensive fromJson, coerce numbers:
```dart
class Thing {
  final int id; final String name; final double price;
  Thing({required this.id, required this.name, required this.price});
  factory Thing.fromJson(Map<String, dynamic> j) => Thing(
    id: (j['id'] as num?)?.toInt() ?? 0,
    name: (j['name'] ?? '').toString(),
    price: numToDouble(j['price']),   // strings OR numbers — coerce, don't cast
  );
}
```

**2. Repository** — interface + Http + provider (screens never see Dio):
```dart
abstract class ThingRepository { Future<List<Thing>> list(); }
class HttpThingRepository implements ThingRepository {
  final ApiClient api; HttpThingRepository(this.api);
  @override Future<List<Thing>> list() async {
    final data = await api.get(ApiEndpoints.things);   // frozen map, §5
    return (data as List).map((e) => Thing.fromJson(e)).toList();
  }
}
final thingRepositoryProvider = Provider<ThingRepository>(
  (ref) => HttpThingRepository(ref.watch(apiClientProvider)));
```

**3. Controller** — `loading:false` explicit, actions only (no UI code):
```dart
class ThingState {
  final bool loading; final List<Thing> items; final String? error;
  const ThingState({this.loading = false, this.items = const [], this.error});
  ThingState copyWith({bool? loading, List<Thing>? items, String? error}) => …;
}
class ThingController extends Notifier<ThingState> {
  @override ThingState build() {
    Future.microtask(load);          // never async work synchronously in build
    return const ThingState(loading: true);   // EXPLICIT — §8.1 step 3
  }
  Future<void> load() async {
    try { state = state.copyWith(loading: true, error: null);
      final items = await ref.read(thingRepositoryProvider).list();
      state = state.copyWith(loading: false, items: items);
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);  // one sentence
    }
  }
}
```

**4. Screen** — watch, branch loading/empty/error/data, tokens only:
```dart
class ThingScreen extends ConsumerWidget {
  const ThingScreen({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(thingControllerProvider);
    return EasyGetTabScaffold(
      appBar: const EasyGetAppBar(title: 'Things'),
      body: s.loading ? const SkeletonGrid()
        : s.error != null ? ErrorState(message: s.error!,
            onRetry: () => ref.read(thingControllerProvider.notifier).load())
        : s.items.isEmpty ? const EmptyState(
            headline: 'Nothing here yet', actionLabel: 'Discover',
            onAction: …go('/browse'))
        : GridView.builder(…ThingCard…),   // fixed slots + gridAspect math
    );
  }
}
```

**5. Route** — tab root → shell branch + `go()`; detail → top-level + `push()`;
guarded? add to `_privateRoutes`; update `nav_test.dart` + `redirect_test.dart`.

## 20. Appendix E — performance, security, accessibility notes

**Performance:** images via `cached_network_image` (memory + disk cache, sunken
placeholder); lists are `ListView/GridView.builder` (never materialized
columns); rails stagger max ~10 entrances; search debounced 300ms + cancels
in-flight; boot reads zero network on the critical path (cached profile);
release APK ~19MB arm64. Profile before optimizing: DevTools timeline, not
vibes. Known non-issues: Inter runtime fetch (one-time), Render cold start
(backend tier, not app code).

**Security:** JWTs in Keychain/Keystore (never SharedPreferences); Google ID
token exchanged server-side, never stored; `google-services.json` is designed
to ship (not a secret); release signing key lives OFF-machine (§2.4);
`key.properties` gitignored; no cert pinning (Render rotates certs — pinning
would brick the app); analytics carry no PII; logcat `[api]` lines are
debug-only. Report security issues privately, not in a GitHub issue.

**Accessibility:** 44dp minimum targets (chips, steppers, hearts); semantic
labels on icon-only buttons; snackbar text + action (not color-only);
status pills pair color with text; text scales with the OS (no fixed px text);
contrast pairs checked light + dark. Not yet done: screen-reader pass on
carousels, focus order audit on checkout.

**Accessibility checklist (per new screen, before review):**
TalkBack/VoiceOver pass: every icon-only button announces a label; images
have semantic labels (product images read the product name); the order
timeline reads as a list with states, not a grid of dots. Touch: all targets
≥44dp (steppers, hearts, chips, radio rows — measure, don't eyeball). Motion:
entrances respect `MediaQuery.disableAnimations` (stagger skipped when
reduced-motion is on). Text: 200% OS scaling doesn't clip CTA labels or
sheet titles (test once per screen shape). Color: error/success never
color-only (icon + text always accompany the pill).

## 21. Appendix F — commit history (`git log --oneline -- customer-app-v2`)

Every line below is a real commit on `fix/flutter-web-and-ordering`.
One screen/component per commit (§9.1). Newest first:

```
b17c346 docs(app): the big README - what, how, why, remaining
9cc273b fix(app): explicit added-state, 3s notices, live card quantities
27142ed test(app): live quantities, ETA, trust rows, address entry
aa9fbbf feat(app): live card quantities, dynamic delivery ETA, richer cart
d90d072 feat(app): champagne minimalist grid with obsidian glass
a34708d feat(app): Zodiak display typeface, bundled offline
2c86b81 fix(app): decode live image key, PDP gallery fallback
41c68be test(app): prove cards run quick-add, release split verified
5148fbc fix(app): view-cart goes to cart tab, static guard against tab pushes
b985483 fix(app): centered states, rows and loading footers
9ca77ba feat(app): card quick-add pipeline, live badge, home All-products
435f3f8 feat(app): voice search with mic, camera removed
0c47edb feat(app): FCM push wiring on existing project keys
252507b feat(app): app-update prompt gate
ca11130 feat(app): local alerts on order status changes
57a0316 feat(app): notifications inbox plus unread badge
4a111e1 feat(app): wishlist screen - saved grid, remove plus undo
2a46b93 fix(app): search image grid categories, show-more pagination
4a871ce fix(app): hero banner, horizontal categories, pushed browse, fallback rails
59a8673 fix(app): MNC filter sheet, bare-list paging, centered loading
5c85566 fix(app): hero banner, horizontal categories, pushed browse, bare-list paging, centered CTA
a370656 fix(app): search category browser list, show-more pagination with progress
1a49498 perf(app): instant boot from cached profile, branded native splash
d29debe fix(app): free Photon autocomplete, no key or billing needed
0330ea2 fix(app): no 0.0 pills on unrated products
e3e24e4 test(app): stabilize slot tap with pre-scroll
865587f fix(app): address alignment, Places autocomplete with manual fallback
533776c fix(app): wishlist hearts on cards, loud failures, shared CardHeart
9b52976 fix(app): account appearance as on-brand chips, aligned row
d8010ac fix(app): PDP confirm-before-add unit pipeline
27f47ea fix(app): dynamic checkout - methods, note input, gateway mapping
f2143ea fix(app): category image tiles on home and search
894d7de fix(app): fixed card anatomy, uniform rows, no overflow
e4905a9 fix(app): push-based back navigation, system back walks the stack
94e7de5 fix(app): cart qty rewrite via DELETE+POST, PATCH 405s on live backend
2d1fcee feat(app): S13 addresses - list, default, add/edit, delete
586a890 feat(app): S12 account - profile, theme, sign out
80e35ac feat(app): S11 order detail + 30s tracking poll
07fda48 feat(app): S10 orders - active/past, cancel
2fbed3b feat(app): S9 checkout - address, slot, COD/UPI, place order
819b69a feat(app): S8 cart - lines, coupon, server-truth bill
7d5abd8 feat(app): S7 product detail - gallery, variants, pincode, reviews
f28efa9 feat(app): S6 search - recents, suggestions, results
12744b7 feat(app): S5 browse PLP - chips, filter/sort, paged grid
9540989 feat(app): S4 home screen - ticker, banners, categories, rails
2bd8d90 feat(app): kit overlays + state widgets - sheets, chips, skeletons, states, pills, cards, timeline
6c693a8 feat(app): commerce widgets - ProductCard, PriceBlock, RatingPill, QtyStepper, VariantSheet
a3769a6 feat(app): app shell - AppBar, search bar, 5-tab bottom navigation
4d66b0f feat(app): notifications + analytics tracker + app-update data layer
7aa41a1 feat(app): orders, addresses, reviews, payments data layer
3d17480 feat(app): cart + wishlist data layer with guest session merge on sign-in
2f2f778 feat(app): catalog data layer — products, categories, brands, search, pincode, storefront
942ed65 docs+core(app): reconcile API contract to the verified live backend
7bdc360 chore(app): log Google sign-in failure code for on-device debugging
60eb27d feat(app): bake web OAuth client id into Google sign-in config
6df56c5 feat(app): cold-start warm-up on splash + configurable Google client id
3ffe96e feat(app): S1 boot + app wiring - splash, cold-start retry, real screens (DESIGN 12)
8db98d7 feat(app): S3 register - instant signup, field errors, auto-login (DESIGN 12)
dec8699 feat(app): S2 login - email/password + Google, cold-start hints (DESIGN 12)
9feeb51 feat(app): router redirect matrix - no stranded states (DESIGN 14)
970b7cc feat(app): session core - token store, single-flight 401 refresh, auth controller
33ec4f2 feat(app): network core - config, frozen endpoints, ApiException mapping
29035ba feat(theme): port Fresh Market tokens + light/dark theme + typography
1e81b46 chore(app): scaffold customer-app-v2 (com.trisentric.easyget)
```

## 22. Appendix G — exact token values (from `tokens.dart`)

Copy from here, never from memory. If these drift from the file, the file wins
(and this appendix needs an update — that's a review-checklist item, §24).

**Light ramp:** canvas `FAF6EF` · surface `FFFFFF` · sunken `F1EAE0` ·
ink `1B1712` · muted `655D52` · faint `A79C8F` · border `E7DFD3` ·
borderStrong `D5C9B8`.

**Brand/accent:** brand `0C3B2E` (deep green) · primary `0E7A4D` ·
primaryDark `0A5C3B` · primaryTint `DDF0E4` (selected fills) ·
marigold `E79B12` · marigoldWash `FCEFD4` · success `15803D` ·
warning `B45309` · danger `B91C1C`.

**Champagne/obsidian:** champagne `F7EFDD` · champagneDeep `EFE0C2` (pressed/
nested) · obsidian `141210` (ink on champagne) · champagneInk `F7EFDD`
(champagne text on dark) · darkChampagne `2A241B` · darkChampagneDeep `38301F`.

**Dark ramp:** canvas `12110F` · surface `1B1A17` · sunken `26241F` ·
ink `F4EFE7` · muted `A79C8F` · faint `6F675C` · border `2B2823` ·
borderStrong `3E3A33` · darkPrimary `3AA76D` · darkPrimaryTint `14342A` ·
darkMarigold `FFB020` · darkMarigoldWash `3A2C10` · darkOnPrimary `06281C`.

**Spacing:** xs 4 · sm 8 · md 12 · lg 16 · xl 20 · xxl 24 · xxxl 32 · huge 48.
**Radii:** card 18 · image 14 · button 16 · input 14 · snackbar 14 ·
sheet 24 · pill 999.
**Motion:** micro 180ms · base 280 · page 350, `easeOutCubic` everywhere;
rail stagger 40ms, max ~10 animated items.

**Type scale** (Zodiak = display only; Inter = everything else; all numbers
tabular via `FontFeature.tabularFigures`):

| Style | Font | Size | Weight | Height | Used for |
|---|---|---|---|---|---|
| `displayHero` | Zodiak | 28 | w600 | — | hero banners, order success |
| `sectionHeadline` | Zodiak | 24 | w500 | — | section headlines, screen heroes |
| `screenTitle` | Inter | 20 | w700 | 1.25 | app-bar titles, sheet titles |
| `productName` | Inter | 14 | w600 | 1.3 | product names (NEVER serif) |
| `body` | Inter | 15 | w400 | 1.55 | descriptions, paragraphs |
| `bodyMedium` | Inter | 14 | w500 | 1.5 | list rows, emphasized body |
| `label` | Inter | 13 | w600 | 1.3 | chips, buttons, form labels |
| `tabularPrice` | Inter | 16 | w700 | — | prices (tabular, strips `.00`) |
| `tabularNumber` | Inter | varies | — | — | quantities, badges, ETAs, phones |
| `caption` | Inter | 12 | w400 | 1.4 | hints, timestamps, footnotes |

## 23. Appendix H — controller state shapes (read before you refactor)

One table per stateful feature. Every controller follows §19's skeleton:
explicit loading, nullable error, copyWith, no UI code.

**AuthController** (`auth_controller.dart`): `AuthState = Booting() |
SignedIn(AppUser) | Guest({coldStartHint})`. Boot: tokens+cache → SignedIn
instantly, background `_refreshUser()`; no tokens → Guest. signOut clears
tokens AND profile, then `go('/login')`.

**SearchController**: `{query, phase: idle|suggesting|results, suggestions[],
items[], total?, page, isLoadingMore, error?}`. 300ms debounce; new query
cancels in-flight (CancelToken); empty page ⇒ `hasMore=false`; tracks
REQUESTED page + last requested size.

**BrowseFilter** (plain state in `browse_providers`): `{categorySlug?,
brands{}, minPrice?, maxPrice?, minDiscount?, featuredOnly, sort}`. URL
(`?category=`) is truth; chips sync post-frame; badge count = active filters.

**CartController**: `{cart?, coupon?, couponError?, removingId?, lastRemoved?
(line+index), placing?}`. Optimistic remove + Undo; refresh-on-Undo-dismiss;
coupon validate → payable clamp ≥ 0.

**CheckoutController**: `{addresses[], selectedId?, slot(Today/Tomorrow/
Evening), note, methods[], cart?, isPlacing, error?}`. COD always; UPI row
live while a UPI method exists; place → create order(s) → pay-if-UPI → clear
→ `go()` receipt. `isPlacing` blocks double-tap.

**OrdersList** (`orders_providers`): `{orders[], loading, error?}` + derived
`activeOrders` (PENDING→OUT_FOR_DELIVERY) / `pastOrders` (DELIVERED/CANCELLED/
REFUNDED). **OrderDetail family** (constructor arg id): `{order?, loading,
error?}` + 30s poll timer with `stop()`; cancel via shared sheet.

**WishlistController**: `{slugs{}, loadingIds{}, error?}` + `toggle(slug) →
Future<bool>`. Optimistic; revert + loud snackbar on failure. Screens derive
`isSaved` from the set (reactive hearts everywhere).

**AddressesController**: `{addresses[], defaultId?, loading, error?}`.
Set-default is a dedicated endpoint (not a PATCH flag); delete asks confirm;
form sheet shared with checkout validates label/line1/city/postal.

**AccountProviders**: `profileProvider` (me), `themeModeProvider`
(System/Light/Dark, persisted), `notificationsEnabledProvider` (stub toggle).

**NotificationsProviders**: `{items[], unreadCount, loading}` + mark-read /
mark-all (tap → mark-read + deep-link).

**HomeProviders**: `storefrontProvider` (sections + ticker), `categories-
Provider`, `hot/top/newProviders` (fallback rails), `allProductsProvider`
(full-page pager). Section rendering reads `sectionKind()` inference.

**DeliveryEta** (family, address arg): `{minutes?, fee?, loading}`; pill
self-hides when null (no ETA row on failure — absence, not error UI).

## 24. Appendix I — screen layouts (ASCII wireframes)

Every screen, top to bottom. `[S]` = skeleton while loading, `[E]` = centered
empty/error state, `(tabular)` = tabular figures. These are normative: if a
redesign moves the CTA above the bill, update the wireframe in the same commit.

**Home** (`/home`):
```
[avatar+name | address v] [bell(badge)]
[search bar (read-only) (mic)]
[ticker strip (marquee)]
[HERO carousel (50vw peek, dots, autoplay 4s)]
[category track → horizontal tiles]
[PRODUCT_ROW rails × N (stagger 40ms)]
[promo strip (marigold wash)]
[story block (RICH_TEXT)]
[All-products grid (2-col, infinite)]
[bottom nav ×5 + cart badge]
```

**Browse** (`/browse?category=`):
```
[pinned chip row (All + categories, URL-synced)]
[toolbar: Title (count) | filter(badge) sort(dot)]
[2-col card grid (infinite scroll)]
[footer: spinner (loading) / end-marker / Show-more]
```

**Search** (`/search?q=`):
```
[field (autofocus, mic) × clear]
[empty: recents chips + category shortcuts + trending-terms]
[typing: suggestion rows (tap → submit)]
[results: same 2-col grid + footer (show-more/progress/end)]
[voice overlay (bottom sheet, live transcript, 30s cap)]
```

**PDP** (`/product/:slug`):
```
[gallery (dots, broken-image fallback) + heart (top-right)]
[title (Inter) + rating pill + count]
[PriceBlock (price / MRP strike / % off / tax note)]
[variant swatches (if multi)]
[delivery row: pincode field → city+ETA | trust rows]
[description (body 1.55)]
[reviews: avg + distribution + cards + Write button]
[sticky bottom: price + CardAddControl (Add ↔ stepper in-place)]
```

**Cart** (`/cart`):
```
[DeliveryEtaPill (self-hides)]
[coupon row → sheet → applied bar (code + remove)]
[line cards: img96 + name + unit + stepper + line-total + swipe/remove]
[Undo snackbar (3s, refresh-on-dismiss)]
[bill: subtotal / discount / delivery / TOTAL (tabular)]
[trust rows (returns • support • freshness)]
[sticky bar: total + count → Checkout]
[empty: icon + "Your cart is empty" + Shop action (centered)]
```

**Checkout** (`/checkout`):
```
[steps header (1 Address • 2 Slot • 3 Pay)]
[address cards (radio) + Add/edit → shared sheet]
[slot picker: Today / Tomorrow / Evening (+ note field → instructions)]
[method rows: COD (always) • UPI (live while method exists, else explainer)]
[items summary (collapsed, count + total)]
[bill + Place-order CTA (isPlacing guard, total on button)]
[success → go() receipt (never back-to-checkout)]
```

**Orders / detail** (`/orders`, `/order/:id`):
```
[Active section (to-your-door cards: pill + ETA + items + total)]
[Past section (history cards)]
[detail: hero status + ETA | timeline (nodes+timestamps) | items |
 address | bill | invoice + cancel (reason sheet, PENDING/CONFIRMED only)]
[30s poll while Active (timer stop on dispose)]
```

**Account / addresses / wishlist / notifications:**
```
[account: monogram + name/phone (inline edit) | order/address/wishlist
 rows (counts) | appearance chips (System/Light/Dark) | notifications
 toggle | help rows | sign-out (clears tokens+profile)]
[addresses: radio default cards + set-default + edit/delete(confirm) +
 add → shared sheet (Photon autocomplete)]
[wishlist: saved 2-col grid (same card; heart-off = remove+Undo)]
[notifications: rows (unread dot); tap → mark-read + deep-link]
```

## 25. Appendix J — provider → endpoint trace

Screen shows X → which provider → which endpoint. Read down to find any call
path. Providers live next to their repository (`features/<x>/data/` or
`presentation/`); all HTTP runs inside `Http*Repository` via `ApiClient`.

| Screen shows | Provider(s) | Endpoint(s) hit |
|---|---|---|
| Login / register / Google | `authControllerProvider` → `authRepositoryProvider` | `POST /auth/login\|register\|google/` |
| Boot greeting | `authControllerProvider` → `profileRepositoryProvider` | `GET /users/me/` (background) |
| Home ticker/sections | `storefrontProvider` → `catalogRepositoryProvider` | `GET /storefront/platform/` |
| Home categories | `categoriesProvider` → same | `GET /categories/` |
| Home fallback rails | `hot/top/newProviders` → same | `GET /products/?sort=` |
| Home All-products | `allProductsProvider` → same | `GET /products/?page=` (full-page rule) |
| Browse grid/filter | `browseItemsProvider/browseFilterProvider` → same | `GET /products/?category&brand&…` |
| Brand list (filter) | `brandsProvider` → same | `GET /products/brands/` |
| Search suggestions | `searchControllerProvider` → `searchRepositoryProvider` | `GET /search/suggestions/?q=` |
| Search results | same | `POST /search/` |
| PDP detail | `productProvider(slug)` → `catalogRepositoryProvider` | `GET /products/:slug/` |
| PDP pincode | inline check → same | `GET /pincode/:code/` |
| PDP reviews | `reviewsProvider` → `reviewRepositoryProvider` | `GET /products/:slug/reviews/` |
| PDP/cart hearts | `wishlistControllerProvider` → `wishlistRepositoryProvider` | `POST\|DELETE /products/wishlist/:slug/` |
| Wishlist screen | `wishlistProductsProvider` → same | `GET /products/wishlist/` |
| Card Add/stepper | `quick_add` + `cardAdditionsProvider` → `cartRepositoryProvider` | `POST /cart/items/` |
| Cart screen/badge | `cartControllerProvider` → same | `GET /cart/`, `DELETE /cart/items/:id/` |
| Coupon | same → `couponRepositoryProvider` | `POST /admin/coupons/validate/` |
| Checkout addr/methods | `checkoutControllerProvider` → address + payment repos | `GET /users/me/addresses/`, `GET /payments/methods/` |
| Place order | same → `ordersRepositoryProvider` | `POST /orders/` → `POST /payments/` → `DELETE /cart/clear/` |
| Orders list | `ordersListProvider` → same | `GET /orders/` |
| Order detail/live | `orderDetailProvider(id)` → same | `GET /orders/:id/` (30s poll) |
| Cancel order | same | `POST /orders/:id/cancel/` |
| Addresses CRUD | `addressesControllerProvider` → `addressRepositoryProvider` | `GET/POST/PATCH/DELETE /users/me/addresses/…` |
| Autocomplete | `placeAutocompleteProvider` (Photon, no backend) | `api.castles.io` (OSM, keyless) |
| Account profile | `profileProvider` → `profileRepositoryProvider` | `GET/PATCH /users/me/` |
| Inbox/badge | `notificationsProviders` → `notificationsRepositoryProvider` | `GET /notifications/`, `…/mark_read/`, `…/unread_count/` |
| Update gate | `appUpdateProvider` → `appUpdateRepositoryProvider` | `POST /pwa/updates/check/` |
| Push sync | `push_service` → `pushRepositoryProvider` | `POST /realtime/devices/` |
| Analytics | `analyticsRepositoryProvider` | `POST /analytics/events/` (fire-and-forget) |
| Delivery ETA | `deliveryEtaProvider` → `catalogRepositoryProvider` | `GET /pincode/:code/` (via address postal) |

## 26. Appendix K — screen-test recipe (copy, rename, fill in)

Every screen test follows this skeleton. Fakes are in-file (no shared mocks);
overrides inject them; pumps are explicit where animations never settle.

```dart
// _FakeThingRepo: in-memory rows + call recording (toggle to fail on demand).
class _FakeThingRepo implements ThingRepository {
  List<Thing> rows = […]; int listCalls = 0; bool failNext = false;
  @override Future<List<Thing>> list() async {
    listCalls++;
    if (failNext) { failNext = false; throw const ApiException('Boom'); }
    return rows;
  }
}

Widget _harness(_FakeThingRepo repo, {String? startAt}) =>
  ProviderScope(overrides: [
    thingRepositoryProvider.overrideWithValue(repo),
    // + _NoopApiClient / _NoopAnalytics / fake seams the screen touches
  ], child: TestApp(startAt: startAt ?? '/things'));

testWidgets('renders rows from the repository', (t) async {
  final repo = _FakeThingRepo();
  await t.pumpWidget(_harness(repo));
  await t.pump(const Duration(milliseconds: 100));  // explicit, not settle
  expect(find.text('Amul Taaza Milk 1L'), findsOneWidget);
  expect(repo.listCalls, 1);
});

testWidgets('error state retries', (t) async {
  final repo = _FakeThingRepo()..failNext = true;
  await t.pumpWidget(_harness(repo));
  await t.pump(const Duration(milliseconds: 100));
  expect(find.byType(ErrorState), findsOneWidget);
  await t.tap(find.text('Retry'));
  await t.pump(const Duration(milliseconds: 100));
  expect(find.byType(ErrorState), findsNothing);
});

testWidgets('system back walks the stack (push) — or exits (tab)', (t) async {
  await t.pumpWidget(_harness(repo, startAt: '/thing/abc'));
  expect(find.byType(ThingDetailScreen), findsOneWidget);
  await t.binding.handlePopRoute();   // engine back, NOT pageBack
  await t.pump(const Duration(milliseconds: 100));
  expect(find.byType(ThingDetailScreen), findsNothing);
});
```

**Widget-test cheat-sheet (the rules that prevent flakiness):**

1. `pumpAndSettle` ONLY when no perpetual animation exists on screen. Skeletons
   pulse, spinners spin, watchers tick — use `pump(Duration)` there.
2. Scroll first: `scrollUntilVisible(finder, 200, scrollable:
   find.byType(Scrollable).first)` before tapping anything below the fold
   (slot taps, show-more footers, grid items).
3. Engine back = `tester.binding.handlePopRoute()`; `pageBack()` only taps a
   VISIBLE back button and silently passes when it scrolled off.
4. Timers (`Timer.periodic` watchers/polls): call the controller's `stop()`
   (or equivalent) BEFORE the test body ends — teardowns run after the
   pending-timers invariant check.
5. URL-synced screens (browse/search): pump at the deep link
   (`/browse?category=dairy`), assert the filter FOLLOWED the URL; then tap a
   chip and assert the URL changed (both directions, always).
6. Snackbars: `expect(find.text('Removed'), …)` then
   `await t.pump(const Duration(seconds: 3))` for Undo-dismiss refresh paths.
7. Fakes must record calls (`listCalls`, `lastBody`) — half the suite's value
   is asserting WHAT was sent (merge payload, gateway map, cancel reason).
8. New route? Update `nav_test.dart` (go/push table) and `redirect_test.dart`
   (guard matrix) in the SAME commit — the gates cross-check each other.

## 27. Appendix L — onboarding, review checklist, release runbook

### Day-1 checklist (engineer + buddy, ~2 hours)

- [ ] Repo cloned, on branch `fix/flutter-web-and-ordering`, `flutter doctor`
  clean, `flutter pub get` + `flutter analyze` green in `customer-app-v2/`.
- [ ] `flutter test` full suite green (~30–60s) — proves the machine, not you.
- [ ] App installed on YOUR phone via `flutter run` (not just emulator):
  login as customer (§2 table), scroll Home, open a PDP, add to cart.
- [ ] Read §1, §7, §8.1, §11 in full; skimmed §5 and §25.
- [ ] Posted one question about anything unclear (docs improve from questions).
- [ ] Picked exercise 1 (§27) as the first real commit.

### First-week exercises (each has acceptance criteria — ask for review when green)
1. **Add a "New in" sort to Browse.** Wire `sort=newest` end-to-end (filter
   state → provider → repository → test). Done when: chip appears, URL keeps
   no trace (sort is local, category is URL), `browse_screen_test` covers it,
   analyze + full suite green.
2. **Add an `EtaPill` variant for "Ships in X days".** Token-only, light+dark,
   tabular, kit test. Done when `kit_widgets_test` renders both variants and
   `theme_test` still passes.
3. **Write a contract test for a new `GET /products/featured/` endpoint
   (fictional).** Probe nothing (it doesn't exist) — instead write the test to
   FAIL against the frozen map, then delete it. Done when you can explain why
   step 1 (probe live) precedes step 2 (write model). (§8 hard rule 2.)
4. **Break the navigation law on purpose in a scratch branch.** `push('/cart')`
   from Home, run `nav_test.dart`, watch the static scan fail. Done when you
   can explain the duplicate-page-key crash from memory. (§7.)

### Code-review checklist (paste into every app PR)

- [ ] One screen/component per commit; conventional message; only
  `customer-app-v2/**` (+ docs) staged.
- [ ] RED test observed failing before GREEN (link the failing run or describe it).
- [ ] `flutter analyze` clean + FULL `flutter test` green (paste the counts).
- [ ] Tokens only: no `Color(0x`, no raw px for spacing/radii, tabular numbers,
  Zodiak display-only, product names Inter.
- [ ] Light + dark rendered (attach both screenshots for UI changes).
- [ ] Loading + empty + error states covered (lists) or N/A justified.
- [ ] Navigation: tab roots `go()`, details `push()`, back via `popOrHome`;
  `nav_test`/`redirect_test` updated for route changes.
- [ ] No provider writes in build/initState/dispose; timers stopped in tests;
  no `pumpAndSettle` on animating screens.
- [ ] Ledger line appended (`.superpowers/sdd/<plan>/progress.md`).
- [ ] README touched if: new file (§16), new test (§17), new endpoint (§5),
  token values changed (§22), layout changed (§24).

### Release runbook (WhatsApp → Play)

1. `flutter analyze` + `flutter test` green on the release branch.
2. Bump `versionCode`/`versionName` in `pubspec.yaml`.
3. `flutter build apk --release --split-per-abi` → take
   `app-arm64-v8a-release.apk` (~19MB) → rename `EasyGet.apk`.
4. Install on a real phone over the PREVIOUS release (upgrade path, not fresh):
   cold boot → login → browse → PDP → add → cart → coupon → checkout (COD) →
   order appears in Orders → cancel it. Screenshot each step.
5. Share as WhatsApp **Document** with the changelog (top 5 commits).
6. Play (when signing is ready, §2.4): `flutter build appbundle --release` →
   upload AAB → staged rollout 10% → watch crash reports 48h → full rollout.

## 28. Appendix M — architecture decision records

Short, permanent, and honest: what we chose, what we rejected, and what would
make us reconsider. New ADR? Add the next number, never rewrite history.

**ADR-1 Riverpod over Bloc.** Chosen: `flutter_riverpod` 3 (manual providers).
Rejected: Bloc (event/state boilerplate × 14 screens), GetX (service-locator
magic untestable under our fake-per-file regime). Reconsider if: team Bloc
expertise arrives AND someone ports the seam pattern across.

**ADR-2 Manual providers, no codegen.** Chosen: hand-written `Notifier` +
constructor-arg families. Rejected: `riverpod_generator` (build_runner adds
minutes to every Windows edit-compile cycle; generated families obscured the
v3 constructor-arg rule during migration). Reconsider if: build_runner becomes
incremental enough on Windows.

**ADR-3 go_router with StatefulShellRoute.** Chosen: declarative routes, shell
tabs, `redirectFor` law, deep links for free. Rejected: Navigator 1.0
imperative (untestable redirect matrix), auto_route (codegen — see ADR-2).
The duplicate-page-key crash (§7) was the tax; `nav_test.dart` is the insurance.

**ADR-4 Repository interface + in-memory fakes, no mocks.** Chosen: every
feature defines `abstract XxxRepository`; every test file carries `_FakeXxxRepo`
with call recording. Rejected: mockito/mocktail (mock-per-method brittleness;
fakes caught the merge-payload and gateway-map bugs that mocks would have
waved through). Cost: more fake code; benefit: contract tests ARE the spec.

**ADR-5 Polls, not sockets, for order tracking.** Chosen: 30s detail poll +
60s watcher. Rejected: Channels websockets (`/ws/orders/`) — reconnect logic,
background-socket death on Android, and zero backend push infra made sockets
all-cost-no-benefit at this scale. Reconsider when: backend ships FCM sender
AND live-driver tracking needs sub-5s updates.

**ADR-6 Photon (OSM) for address autocomplete, not Google Places.** Chosen:
keyless, no billing, India-biased (`place_autocomplete.dart`). Rejected:
Google Places (API key + billing + SHA-1 dance per build variant). Trade-off:
fuzzier results; manual-address fallback always present. Reconsider if:
checkout analytics show autocomplete abandonment.

**ADR-7 Zodiak bundled + Inter via google_fonts.** Chosen: display serif
offline-safe (bundled OTF ~75KB), body font runtime-cached. Rejected:
all-bundled (APK bloat), all-runtime (first-launch FOUT on hero). Product
names stay Inter — serif is for display, never for data.

**ADR-8 Champagne/obsidian card system.** Chosen: warm pale-gold cards with
near-black ink, dark-mode pairs. Rejected: pure-white cards (clinical),
heavy brand-green surfaces (shouts, fatigues). Rule: champagne is a stage
for product photography, not a brand megaphone.

**ADR-9 Server truth for all money.** Chosen: cart/checkout render backend
subtotal/discount/delivery; client only derives `payable − coupon`, clamped.
Rejected: client-side cart math (Decimal-string coercion + coupon rules would
desync by rupees — the coupon FAQ entry §13 exists because of this).

**ADR-10 Cached-profile instant boot.** Chosen: tokens + cached `AppUser` →
Home immediately, refresh in background (`1a49498`). Rejected: blocking
`/users/me/` on every cold start (Render cold boot made every open take a
minute — measured, not theorized). Trade-off: profile can be seconds stale;
refresh reconciles silently.

**ADR-11 One commit per screen/component.** Chosen: ~70 linear commits (§21).
Rejected: batched PRs (un-bisectable, un-revertable — the view-cart crash fix
reverted cleanly BECAUSE it was one commit). Cost: more ledger lines; benefit:
every regression has exactly one suspect.

**ADR-12 WhatsApp APK distribution before Play.** Chosen: release splits
(~19MB arm64) shared as documents. Rejected: waiting for Play signing
(debug keys block store upload; the process in §2.4 unblocks it). Internal
testing on real phones caught USB-vs-emulator-only bugs (SHA-1, permissions)
months before store review would have.

## 28. Appendix M — architecture decision records

Format: Context → Decision → Consequences. New ADRs go here with the commit
that implements them. Disagree with one? Open a discussion with measurements,
not opinions.

**ADR-1: Riverpod (manual) over Bloc.** Context: team of one + AI agent,
provider-per-feature fits file-tree thinking. Codegen (`riverpod_generator`)
would add build_runner cycles to every TDD loop (30–60s tax per regeneration).
Decision: `flutter_riverpod` hand-written providers. Consequence: verbose
families, but zero codegen and instant `flutter test` startup.

**ADR-2: Repository interfaces + in-file fakes, no mockito.** Context: the API
contract changed 5 times during development (probes). Decision: every data
source hides behind an interface; tests carry tiny fakes. Consequence: swapping
an endpoint = one Http class + contract test; mockito never needed.

**ADR-3: go_router StatefulShellRoute for tabs.** Context: 5 tabs must keep
scroll state and handle deep links. Decision: shell branches + strict go/push
law (§7) + static scan guard. Consequence: one production crash taught us the
law; the scan means it can't recur silently.

**ADR-4: Cached-profile boot over splash-wait.** Context: Render cold starts
made every open take 60s. Decision: persist `AppUser` JSON; boot from cache,
refresh in background (`1a49498`). Consequence: warm opens feel instant; stale
profile visible for ~1s on cold open (accepted — refresh is silent).

**ADR-5: Polls over WebSockets (v1).** Context: `ws/orders/` exists but needs
reconnect/backoff/auth-refresh plumbing. Decision: 30s order-detail poll + 60s
background watcher; FCM later for push. Consequence: ~2 requests/min per
active order screen — negligible; sockets remain a roadmap item (§12).

**ADR-6: Photon (OSM) over Google Places.** Context: Places needs a billed API
key per install. Decision: keyless Photon narrowed to India + manual fallback
(`d29debe`). Consequence: zero key management; slightly worse ranking than
Google (accepted for an MVP address form).

**ADR-7: Bundled Zodiak + runtime Inter.** Context: display serif must render
offline on first boot (splash/hero); body font can lazy-load. Decision: Zodiak
OTF in `assets/fonts` (~75KB), Inter via google_fonts. Consequence: APK +75KB,
first paint always correct; Inter caches after first launch.

**ADR-8: Champagne/obsidian cards over white grid.** Context: grocery grids all
look identical; brand needs warmth without clutter. Decision: champagne card
surface + obsidian ink + marigold accents (`d90d072`). Consequence: distinctive
look; dark-mode needed dedicated champagne ramps (see §22).

**ADR-9: Optimistic UI with server reconcile (cart/wishlist).** Context: Render
latency makes tap→wait→confirm feel broken. Decision: apply instantly, record
prior, revert + explain on failure, refresh on Undo-dismiss. Consequence: feels
instant on 4G; failure paths must be LOUD (silent revert is a bug — `533776c`).

**ADR-10: URL as source of truth (browse/search).** Context: chips and initState
desynced twice. Decision: `?category=`/`?q=` win; UI syncs post-frame (§8.2).
Consequence: deep links and back-button restore filters for free.

**ADR-11: Single-flight 401 refresh in the interceptor.** Context: parallel
requests on boot stampeded `/auth/refresh/` (token reuse → logout loops).
Decision: one shared refresh future; losers await it, then retry once.
Consequence: no refresh storms; refresh-fail → single session-lost broadcast.

**ADR-12: Monorepo branch, app-only commits.** Context: tree holds backend +
webs with dirty files. Decision: build on `fix/flutter-web-and-ordering`,
stage only `customer-app-v2/**` + docs, never `git add .`. Consequence: clean
app history (`§21`); requires discipline at every commit (§9.1 step 5).

**ADR-13: One commit per screen/component.** Context: batched PRs are
un-bisectable and un-revertable. Decision: ~70 linear commits (§21), each
analyzing clean standalone. Consequence: every regression has exactly one
suspect — the view-cart crash fix reverted cleanly BECAUSE it was one commit.
Cost: more ledger lines.

**ADR-14: WhatsApp APK distribution before Play.** Context: debug keys blockstore upload (§2.4), but real phones catch what emulators can't. Decision:
release splits (~19MB arm64) shared as WhatsApp documents meanwhile. Consequence:
USB-vs-emulator bugs (SHA-1, permissions, cold-start timings) surfaced months
before store review.

## 29. Appendix N — common-tasks cookbook

Each recipe: files → steps → tests to update → commit message shape. Follow
the TDD gate (§9.1) throughout.

**Change a token value (e.g. marigold shade).**
Files: `core/theme/tokens.dart` → nothing else (consumers read the extension).
Steps: edit the hex → `flutter test test/theme/` → eyeball light+dark on
Home, Cart, PDP → update §22 dump in the SAME commit. Commit:
`fix(theme): warm marigold wash for dark cards`.

**Add a tab (6th).** Files: `app_router.dart` (new branch), `bottom_nav.dart`
(icon+label), redirect law if guarded. Steps: branch + `go()` call sites
(never `push` — §7) → shell test (badge/scroll/switch) → `nav_test.dart`
table row → `redirect_test.dart` if guarded. Commit: `feat(app): orders tab…`
— plus a ledger line explaining why 6 tabs don't break the 5-tab design rule
(they might; check DESIGN first).

**Add an endpoint.** Steps: probe live (`curl` + device) → paste shape into
ledger → add to `api_endpoints.dart` + `api_endpoints_test.dart` → model
(fromJson defensive, coerce Decimals) → repository method + contract test
(method+path+body) → provider → controller/screen → README §5 + §25 rows.
Commit: `feat(app): coupon history endpoint + contract tests`. NEVER invent
paths (§8 hard rule 2).

**Add a payment gateway.** Files: `payment_repository.dart` (gateway map),
`checkout_controller.dart` (method row + place pipeline). The v1 map is
UPI→PHONEPE, CARD→STRIPE, WALLET→RAZORPAY, COD→skip. A new gateway = new map
entry + a dynamic method row + fake-method tests (live row + dead-row
explainer). Do NOT hardcode gateway strings outside the repository.

**Change a poll interval.** Watcher 60s (`order_watcher.dart`), detail 30s
(`orders_providers.dart`). Update the timer AND the test's expected pumps
(tests use explicit durations, not wall-clock). Justify battery impact in the
commit message.

**Add analytics event.** Fire via `analyticsRepositoryProvider`, never awaited
in UI code; PAGE_VIEW stays in the router observer (zero screen code). Test:
assert the fake analytics recorded the event (see `order_detail_test`).

**Rename a route.** Use the GoRoute `.path` helpers (never raw strings) →
update `nav_test.dart` table → update deep-link senders (notifications, push)
→ update README §7 table + §24 wireframe + §25 trace. One commit; grep for
the old path string to catch stragglers.

**Fix a backend contract drift.** Symptoms: red contract test after backend
deploy. Steps: re-probe → confirm shape change → update model + fixture +
contract test → scan §18 dump + §5 notes → commit `fix(app): adapt to …`.
If the backend broke the frozen map, file a backend issue the same day.

## 30. Appendix O — backend quirks registry

Every surprise the live backend ever gave us, with the code that absorbs it.
New quirk? Add a row + link the handler — future-you says thanks.

| # | Quirk | Handler | Since |
|---|---|---|---|
| Q1 | `GET /products/` bare 20-list, page echoes 1 | full-page rule + requested-page counter (`browse_providers`) | S5 |
| Q2 | `PATCH /cart/items/` 405 | DELETE + re-POST rewrite (`cart_repository`) | `94e7de5` |
| Q3 | Detail images key `"image"`, not `"url"` | `catalog_models` reads `image` | `2c86b81` |
| Q4 | `align_x` percent (50), not fraction | `primary_image_display` divides by 100 at render | PDP |
| Q5 | Decimals as strings (`"66.00"`, `"49"`) | `numToDouble/numToInt` everywhere | models |
| Q6 | Storefront `type` often `""` | `sectionKind()` content inference | Home |
| Q7 | Category `image` always null (today) | `CategoryGridCard` icon fallback | `f2143ea` |
| Q8 | `POST /orders/` → `{"orders":[…]}` multi | take first; refresh list for siblings | S9 |
| Q9 | `POST /cart/merge/` wants `{session_key}` | guest key persisted pre-login | S2 |
| Q10 | Coupon validate 400 carries `{valid:false,message}` | `ApiException` surfaces `message` verbatim | S8 |
| Q11 | Review duplicate → 409 (not 400) | PDP maps 409 → "already reviewed" copy | S7 |
| Q12 | Render sleeps: first hit 60–90s | 90s/60s timeouts, warmUp, cold-start hints | S1 |
| Q13 | Wishlist list returns full rows (not slugs) | `fetchProducts()` renders directly, no N+1 | W1 |
| Q14 | `unread_count` separate from list | badge provider polls count independently | E1 |
| Q15 | `pwa/updates/check` needs `{platform,current_version}` | `appUpdateProvider` builds body from PackageInfo | E3 |

## 31. Appendix P — runtime sequences (tap → pixels → network)

**Login (email):** LoginScreen validates → `authController.signIn` →
`POST /auth/login/` → tokens to SecureTokenStore + user cached → guest cart
merge (`POST /cart/merge/ {session_key}`, best-effort) → FCM token sync
(`POST /realtime/devices/`, best-effort) → `go('/home')`. Slow network: 3s
hint at 3s, 8s hint at 8s (§6.3). Google path swaps step 2 for
`google_auth_source` → `POST /auth/google/ {id_token}`.

**Cold boot (returning user):** native splash → `authController.build` reads
tokens + cached user SYNCHRONOUSLY → SignedIn → Home renders instantly →
background `_refreshUser()` (`GET /users/me/`) reconciles → `warmUp()` fires
`GET /products/` to wake Render. No tokens → Guest → redirect law decides
splash vs `/login` (§7).

**Quick-add (single-variant):** tap Add → control flips to spinner IN THE SAME
SLOT → `resolveDefaultVariant` (1 variant → direct; N → VariantSheet) →
`POST /cart/items/ {variant_id, quantity:1}` → `cardAdditionsProvider` marks
the card "Added ✓" → badge increments → 3s snackbar. Failure: control snaps
back + loud error (never silent). Multi: stepper replaces Add in-place.

**Checkout (COD):** `isPlacing=true` (double-tap guard) → `POST /orders/
{cart_id, delivery_address, delivery_instructions}` → take `orders[0]` →
COD? skip payment : `POST /payments/ {order, gateway: PHONEPE, amount}` →
`DELETE /cart/clear/` → `isPlacing=false` → `go()` receipt (replace, never
back-to-checkout). Any step throws → guard resets + one-sentence error.

**Push tap → order:** killed-app tap: `pushBackgroundHandler` (bare isolate,
no ref) stashes `order_id` → app boots → shim `go('/order/:id')`.
Foreground: `push_service` shows heads-up via LocalNotifier AND routes on tap.
Background-but-alive: FCM tap handler → same shim. Order screen then polls
every 30s while Active (§23).

## 32. Appendix Q — quick-reference card (print this)

**Daily (from `customer-app-v2/`):**
`flutter pub get` · `flutter analyze` (0 issues) · `flutter test` (332 green)
· `flutter run` (USB phone) · `flutter test test/<area>/` (one area).

**Share:** `flutter build apk --release --split-per-abi` → rename arm64
(~19MB) → WhatsApp Document. Debug APK (~156MB) never leaves the laptop.

**Where is…**
- a color/space/radius/duration? `core/theme/tokens.dart` (exact values §22)
- an endpoint URL? `core/network/api_endpoints.dart` (frozen, §5)
- a route/guard? `core/router/app_router.dart` (law §7, trace §25)
- money math? server bill + `payable − coupon`, clamped (§8.3)
- back behavior? `popOrHome` (§7) · snackbars? `showAppSnackbar` 3s (§8.3)
- the plan/ledger? `docs/superpowers/plans/`, `.superpowers/sdd/` (§9.2)

**Never:** modify backend models/tests · invent endpoints · `Color(0x`
outside theme · `push()` a tab · provider writes in build/dispose ·
`git add .` · network in tests · silent optimistic failures.

**Three laws (§1.6):** backend untouched — adapt client-side · endpoints from
§5 or ask · every screen survives hostile networks (skeleton/empty/error).

## 34. Appendix S — monorepo neighbors & safe refactors

### S1 Neighbors (what else lives in this tree)

`customer-app-v2/` is one surface of four (CONTEXT.md §1): `customer-web/`
(React 18 + Vite, hash router, `:3000`) and `admin-web/` (`:5174`) share the
SAME `/api/v1/` contract (§5) — a backend change that breaks our contract
tests probably breaks the webs too (coordinate). `backend/` (Django 5 + DRF +
Supabase Postgres) owns every quirk in §30; file backend bugs against the
owning app (§R7) with endpoint + probe output. `customer-app/` (old Flutter
app) is FROZEN — never port from it, never commit to it; v2 replaces it
package and all (`com.trisentric.easyget`). Shared docs at root: `DESIGN.md`
(design law), `CONTEXT.md` (frozen facts), `GETTING_STARTED.md` (multi-surface
runbook). When root docs change, check whether §5/§7/§22 need matching edits.

### S2 Safe-refactor checklists (mechanical, reviewable, one commit each)

**Extract a widget** (screen file >400 lines or a section with its own tests):
cut the subtree → new file in feature `widgets/` (or `core/widgets/` if
second use exists — Rule 4, §3.4) → constructor takes data + callbacks only
(no ref reads inside except its own controller) → move the relevant widget
tests → full suite green. Commit: `refactor(app): extract …`.

**Promote to core:** second feature needs it → move + generalize (no
feature imports) → kit test in `kit_widgets_test` (both variants, light+dark,
centered-states rule where applicable) → update §6.2 row + §16 lines.
Commit: `refactor(app): promote … to core kit`.

**Split a controller** (state shape >6 fields or two independent timers):
carve the independent slice → new Notifier + provider → screen watches both →
tests split per controller (timers stopped per test, §8.2) → update §23 entry.
Commit: `refactor(app): split … controller`.

## 33. Appendix R — operational references

### R1 Order state machine (backend enum → app rendering)

```
PENDING → CONFIRMED → PREPARING → READY → OUT_FOR_DELIVERY → DELIVERED
   ↓          ↓
CANCELLED  CANCELLED                                    (REFUNDED terminal
   (reason required, PENDING/CONFIRMED only)             after DELIVERED)
```
Terminal: DELIVERED, CANCELLED, REFUNDED (→ Past section). Everything else →
Active section with ETA (`orders_providers` split). `humanizeStatus()` maps
every enum to customer copy ("Out for delivery", not `OUT_FOR_DELIVERY`);
transit statuses render marigold tint, DELIVERED green, CANCELLED/REFUNDED
muted. Cancel allowed only PENDING/CONFIRMED (server enforces; app hides the
button otherwise). Timeline draws from `status_history[]` (timestamps are
truth; missing entries render as gaps, never invented nodes).

### R2 Coupon semantics

`POST /admin/coupons/validate/ {code, order_value}`. 200 →
`{valid:true, discount, discount_type, coupon}`; apply: `payable = subtotal −
discount`, clamped ≥ 0 (§8.3). 400 → `{valid:false, message}` — surface
`message` verbatim (it carries the reason: minimum order, expired, used up).
`order_value` sent = client-derived payable — refresh the cart first if the
server disagrees by a rupee (§13 FAQ). One coupon per order (server rule);
applying a second code replaces the first (confirm in the sheet).

### R3 Address fields (AddressDraft → POST body)

Required: `label` (HOME/WORK/OTHER chips + custom), `line1`, `city`, `state`,
`postal_code` (5–6 digits, pincode-checked on blur), `phone` (tabular,
10-digit). Optional: `line2` (landmark), `country` (default IN),
`is_default`. Server returns `id`; list renders radio-default cards;
`set-default` is a DEDICATED endpoint (`POST /:id/set-default/`), not a PATCH
flag. Delete asks confirm; deleting the default promotes the most-recent
(server rule — refresh after delete).

### R4 Search & listing params (one reference)

Listing `GET /products/`: `category` (slug) · `brand` · `min_price` ·
`max_price` · `min_discount` · `is_featured` · `sort` (price_asc/price_desc/
newest/rating) · `page`. Search `POST /search/`: same + `q` (required,
min 2 chars for suggestions) + `sort` adds relevance/popular. Sort sheet
options map 1:1 to these values (never invent labels the API can't honor).
Suggestions: `GET /search/suggestions/?q=` → `[strings]` (tap → submit).

### R5 FCM end-to-end (console → device → order screen)

1. Firebase project `easyget-7a4b0` (console access needed): Cloud Messaging
   enabled; `google-services.json` committed in `android/app/` (§16).
2. App: login → `push_service` fetches token → `POST /realtime/devices/
   {platform: ANDROID, device_token, user_agent}` (best-effort, never blocks).
3. Test without backend: Firebase console → Cloud Messaging → "Send test
   message" → paste token from `adb logcat | Select-String "fcm"` (§2.6) →
   include `"data": {"order_id": "<real id>"}` to exercise the deep-link.
4. Payload contract (for the backend sender, §12): data-only message with
   `order_id`; title/body for the visible copy. Tap/cold-start → `/order/:id`
   (§31). Foreground shows heads-up via LocalNotifier even without a tap.
5. Permissions: `POST_NOTIFICATIONS` (runtime grant on Android 13+, rationale
   shown at first order placement, not at login); channel `order_updates`
   (importance HIGH, vibration on).

### R6 Voice search detail

Mic (search bar + search field) → `?listen=1` deep-link (or direct overlay) →
`VoiceSearchService` (seam; real = `speech_to_text` 7, fake = scripted
transcript in tests). Locale `en_IN`, 30s cap, partial results stream into the
field live; final transcript auto-submits through the normal controller path
(debounce skipped for voice — it's already one utterance). Denied permission →
inline explainer + typed-field fallback (never a dead mic). `RECORD_AUDIO` in
manifest + runtime request; v7 API uses `SpeechListenOptions` (see §11
version notes before upgrading the package).

### R7 Backend-app map (which Django app serves which endpoint)

From repo `backend/apps/` (CONTEXT.md §4 — app devs read this when filing
backend issues): `users/` → auth + `/users/me/` + addresses · `products/` +
`categories/` → catalog, brands, reviews · `cart/` → cart + merge · `orders/`
→ orders + cancel + invoice · `payments/` → methods + direct create ·
`search/` → search + suggestions · `delivery/` → pincode · `storefront/` →
platform sections · `notifications/` + `realtime/` → inbox + devices ·
`analytics/` → events · `pwa/` → update check · `admin_panel/` → coupon
validate + staff APIs. File backend bugs against the owning app with the
endpoint + quirk number (§30).

**Backend-bug template (paste into the issue):**
endpoint + method · request body sent · expected shape (§18) · actual shape
(full JSON, abridged to the surprising keys) · quirk number if it matches §30
(or "new quirk — proposes Q(N+1)") · app commit + contract test that caught it.
One endpoint per issue; link the app-side adaptation commit when it lands.

### R8 Adding an asset (images, fonts, lottie)

1. Drop the file in `assets/<images|fonts|…>/` (create the folder if needed).
2. Declare it in `pubspec.yaml` under `flutter:` → `assets:` (images) or
   `fonts:` (family + weights, like Zodiak). Raster images: ship 2x/3x
   variants (`img.png`, `2.0x/img.png`) — Flutter picks density automatically.
3. `flutter pub get` → reference as `AssetImage('assets/images/…')` (never a
   network URL for bundled art). Remote product imagery stays
   `cached_network_image` (§4) — bundled assets are for brand/UI art only.
4. Keep `assets/` lean: every MB ships in ALL splits (§2.3 budgets apply).

*Last verified: full suite 332 green, `flutter analyze` clean.*
