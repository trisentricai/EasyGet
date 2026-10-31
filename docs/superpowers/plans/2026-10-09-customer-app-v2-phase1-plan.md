# Plan: customer-app-v2 Phase 1 — foundation + auth (fresh rebuild)

**Spec (binding authority):** `docs/superpowers/specs/2026-10-09-customer-app-v2-design.md`
**Branch:** `fix/flutter-web-and-ordering` (existing feature branch; not main)
**Executor:** inline (executing-plans), standard RED→GREEN TDD (test-driven-development skill not installed)
**Scope:** spec §11 build order steps 1–3 (tokens/theme → shared/auth screens core → Login → Register → Boot). Home/Browse/PDP/Cart/Checkout/Orders are Phase 2+, separate plans.

## Global Constraints

- Work only inside `customer-app-v2/**` and `docs/**`. Stage those paths explicitly — the working tree carries many unrelated modified files; never `git add .`.
- Backend untouched. Endpoints: frozen contract only (CONTEXT §2, DESIGN §15); anything missing = backend ticket, not invention.
- `flutter analyze` zero issues AND `flutter test` green are the gate for every task (`workdir` = `customer-app-v2/`).
- DESIGN.md §10 (tokens — zero `Color(0x…)` outside `core/theme/`), §12 S1–S3 (screen anatomy), §14 (logic rules), §16 (acceptance) are binding.
- Reference reads of the old app (`customer-app/lib/**`) are allowed; nothing in `customer-app/` is modified.
- PowerShell 5.1: no `??`; `rtk` prefix on all git commands.
- Cold-start reality: connect timeout 90s / receive 60s; live API `https://easyget-api.onrender.com/api/v1` (Render free tier sleeps).
- Test login: `customer@easyget.app` / `Customer@123`.
- Commit one per task, conventional (`feat(app):` / `chore(app):`).
- Stop only for: irreversible/destructive ops, security-sensitive actions, side effects outside the worktree needing a norm (push), or a plan so broken every path is a guess.

## Pre-flight: shared interfaces (Task N → Task M)

| # | Produces → Consumes | Finding / ruling |
|---|---|---|
| P1 | T1 `flutter pub add` deps (riverpod, go_router, dio, flutter_secure_storage, cached_network_image, shimmer, google_fonts, flutter_animate, intl, google_sign_in) → T2–T8 | Ruling: let `flutter pub add` resolve current stable; no manual version pinning. |
| P2 | T2 `AppTheme.light()/dark()` + `tokens.dart` → T5–T8 screens | Old source is `customer-app/lib/core/theme/{app_colors,app_theme,app_typography}.dart` (verified implements §10). Port, don't redesign. |
| P3 | T3 `ApiClient` + `ApiException` → T4 AuthRepository, T6/T7 submit | Ruling: T3 is a bare client (error mapping only). Bearer-attach + 401 refresh live in T4's `AuthInterceptor`, not T3 — keeps T3 testable without session state. `/auth/login/` and `/auth/refresh/` are exempt from bearer-attach. |
| P4 | T4 `AuthState` + `AuthController` + `AuthInterceptor.onSessionLost` → T5 router, T6 signIn, T8 boot | Ruling: `AuthState` is sealed (`booting`/`signedIn`/`guest`); router consumes it via go_router `refreshListenable` (ChangeNotifier bridge). `onSessionLost` re-enters the controller (clears → guest). |
| P5 | T5 placeholder routes (`/login`, `/register`, `/`, …) → T6/T7/T8 replace targets at the same paths | Ruling: placeholders carry a unique `Key('placeholder-<route>')` so T6+ widget tests can prove the real screen replaced them. |
| P6 | T4 `TokenStore` (abstract + InMemory + Secure) → T4 interceptor/controller, T8 boot | InMemory used by every test; Secure only at composition root. |

## Task 1: scaffold `customer-app-v2`

**Goal:** clean project at `com.trisentric.easyget`, deps in, strict lints, green smoke test.

### Steps

1. From repo root: `flutter create customer-app-v2 --project-name easyget --org com.trisentric --platforms android` → **EXPECTED:** "Flutter create" success summary.
2. Check `android/app/build.gradle.kts`: `applicationId = "com.trisentric.easyget"`; set `android:label` to `EasyGet` in the manifest → **EXPECTED:** matches.
3. RED: delete generated `test/widget_test.dart`; write `test/app_smoke_test.dart` pumping the app and asserting `find.text('EASYGET')` → **EXPECTED: FAIL** (generated counter app shows `0`).
4. GREEN: replace `lib/main.dart` with minimal `EasyGetApp` (`MaterialApp(home: Scaffold(body: Center(child: Text('EASYGET')))))` → **EXPECTED: PASS**.
5. `flutter pub add flutter_riverpod go_router dio flutter_secure_storage cached_network_image shimmer google_fonts flutter_animate intl google_sign_in` → **EXPECTED:** `pub get` resolves, no version conflicts.
6. `analysis_options.yaml`: include `package:flutter_lints/flutter.yaml` + analyzer `strict-casts/strict-inference/strict-raw-types: true` → `flutter analyze` → **EXPECTED: No issues found.**
7. Commit: `chore(app): scaffold customer-app-v2 (com.trisentric.easyget)`

**Test command (task-done):** `flutter test`

## Task 2: Fresh Market tokens + light/dark theme (DESIGN §10)

**Goal:** theme foundation with zero hardcoded colors anywhere else.

### Steps

1. RED: write `test/theme_test.dart`:
   - `lightAndDarkSchemesAreDefinedAndDistinct` — `AppTheme.light().colorScheme.brightness == Brightness.light`, dark counterpart dark, and `light.primary == AppColorsLight.brandColor` (token equality).
   - `zeroColorLiteralsOutsideTheme` — recursively read every `lib/**/*.dart` except `core/theme/**`; fail if any contains `Color(0x`.
   → **EXPECTED: FAIL** (files missing → compile error).
2. GREEN: port from `customer-app/lib/core/theme/`:
   - `lib/core/theme/tokens.dart` — `FreshMarketColorTokens` abstract + light/dark implementations (brand, primary, primaryTint, primaryDark, marigold, marigoldWash, sunken, ink, muted, faint, success, danger, warning, onPrimary).
   - `lib/core/theme/app_theme.dart` — `AppTheme.light()/dark()`: ColorScheme slot mapping (§10.3), google_fonts Inter text theme + Fraunces display, component themes (inputs, buttons, snackbar).
   - `lib/core/theme/app_typography.dart` if the old file carries shared styles.
   → **EXPECTED: PASS** + `flutter analyze` clean.
3. Commit: `feat(app): Fresh Market tokens + light/dark theme (DESIGN §10)`

**Test command:** `flutter test test/theme_test.dart`

## Task 3: network core (config, frozen endpoints, ApiException)

**Goal:** one Dio client; every failure becomes one human sentence; endpoints pinned to the frozen contract.

### Steps

1. RED: write `test/network/api_endpoints_test.dart`, `test/network/api_exception_test.dart`, `test/network/api_client_test.dart`:
   - endpoints: exact-string asserts for the Phase-1 set — `/auth/login/`, `/auth/refresh/`, `/auth/register/`, `/users/me/`, `/cart/`, `/cart/merge/`, `/banners/`, `/storefront/easyget/`, `/products/`.
   - exception mapping (build `DioException` fixtures): connect timeout → `"Waking up the store, retry."`; receive timeout → same; `badResponse` 500 → human sentence; 400 with DRF `detail`/field payload → surfaced; **message never contains `DioException`/stack jargon**.
   - client: mock `HttpClientAdapter` returning canned JSON → `get<T>(decode)` returns decoded value; adapter throwing `ConnectionErrorException` → `ApiException` with human message.
   → **EXPECTED: FAIL** (missing files).
2. GREEN:
   - `lib/core/config/app_config.dart` — `baseUrl = String.fromEnvironment('API_BASE', defaultValue: 'https://easyget-api.onrender.com/api/v1')`.
   - `lib/core/network/api_endpoints.dart`, `api_exception.dart`, `api_client.dart` — Dio with 90s connect / 60s receive (§14), `get/post/patch/delete<T>` + `decode`, DioException→ApiException mapping.
   → **EXPECTED: PASS** + analyze clean.
3. Commit: `feat(app): network core — config, frozen endpoints, ApiException mapping`

**Test command:** `flutter test test/network/`

## Task 4: session core — token store, single-flight 401 refresh, auth controller

**Goal:** the pain-point machinery, proven by tests before any screen exists.

### Steps

1. RED: write:
   - `test/auth/token_store_test.dart` — InMemory roundtrip + clear.
   - `test/auth/auth_interceptor_test.dart` (mock adapter under Dio):
     - attaches `Authorization: Bearer <access>` to normal requests;
     - auth endpoints (`/auth/login/`, `/auth/refresh/`) never attach bearer and never trigger refresh;
     - **two parallel 401s → exactly ONE refresh call**, both originals retried and succeed;
     - refresh fails (401) → `onSessionLost` fired once, tokens cleared;
     - retried request 401 again → `onSessionLost` (no refresh loop, §14).
   - `test/auth/auth_controller_test.dart` (InMemory store + fake repos):
     - boot with stored refresh → `GET /users/me/` ok → `signedIn`;
     - boot with no tokens → `guest` immediately (no network call);
     - boot with network failure/timeout → `guest` with `coldStartHint` — **never stuck in `booting`**;
     - signIn ok → `signedIn` + tokens persisted; signIn failure → `guest` + `ApiException.message` retained on state;
     - signOut → tokens cleared → `guest`.
   → **EXPECTED: FAIL**.
2. GREEN: implement:
   - `lib/core/storage/token_store.dart` — abstract `TokenStore` + `InMemoryTokenStore` + `SecureTokenStore` (flutter_secure_storage).
   - `lib/core/network/auth_interceptor.dart` — attach, single-flight refresh (`Completer` shared across concurrent 401s), one retry, `onSessionLost` on refresh failure / second 401.
   - `lib/features/auth/data/auth_repository.dart` — `login`, `register`, `refresh`, `me`, `mergeGuestCart` (best-effort after sign-in when a guest token exists — ledger: merge failure never blocks sign-in; server cart is truth per §14).
   - `lib/features/auth/presentation/auth_state.dart` (sealed: `booting(coldStartHint)` / `signedIn(user)` / `guest(error)`) + `auth_controller.dart` (`Notifier`, `boot()/signIn()/register()/signOut()`; guest token in a sibling secure-storage key).
   → **EXPECTED: PASS** + analyze clean.
3. Commit: `feat(app): session core — token store, single-flight 401 refresh, auth controller`

**Test command:** `flutter test test/auth/`

## Task 5: router redirect matrix (no stranded states)

**Goal:** pure, exhaustively-tested redirect logic — the bug class fixed on 2026-10-09 can't recur.

### Steps

1. RED: write `test/router/redirect_test.dart` testing exported pure `redirectFor(String location, {required bool booted, required bool signedIn}) -> String?` over the matrix:
   - `booted=false` → `null` (hold; boot decides — DESIGN §12 S1.2) for every location incl. `/login`;
   - `booted && signedIn && location == '/'` → `/home`;
   - `booted && signedIn && location in {/login, /register}` → `/home`;
   - `booted && signedIn && private ({/, ...wait: private set}` → `null` (allowed);
   - `booted && guest && location == '/'` → `/login`;
   - `booted && guest && public` → `null`;
   - `booted && guest && private ({/home,/browse,/search,/cart,/orders,/checkout,/account,/product/:slug})` → `/login`.
   → **EXPECTED: FAIL**.
2. GREEN: `lib/core/router/app_router.dart` — `redirectFor()` + `GoRouter(initialLocation: '/', refreshListenable: authListenable, redirect: …)` with placeholder route builders for `/`, `/login`, `/register`, `/home`, `/browse`, `/search`, `/cart`, `/orders`, `/checkout`, `/account`, `/product/:slug` — each placeholder a Scaffold with `Key('placeholder-<route>')`.
   → **EXPECTED: PASS** + analyze clean.
3. Commit: `feat(app): router redirect matrix — no stranded states (DESIGN §14)`

**Test command:** `flutter test test/router/`

## Task 6: S2 Login screen (email/password + Google)

**Goal:** the exact screen from DESIGN §12 S2, widget-proven.

### Steps

1. RED: write `test/auth/login_screen_test.dart` (pump login inside a harness providing fake AuthController + `GoogleAuthDataSource` + router):
   - empty/invalid email → inline validation, no repo call;
   - repo failure → human message (e.g. `Wrong email or password.`) shown; **typed input preserved** (controllers not wiped);
   - submit in flight > 8s (fake clock) → `Waking up the store…` hint, CTA locked at fixed size (no layout jump);
   - success → controller `signedIn` and `redirectFor('/login', booted: true, signedIn: true) == '/home'`;
   - google throws (unsupported/not-configured) → snackbar human message, no crash;
   - password obscure toggle flips field.
   → **EXPECTED: FAIL**.
2. GREEN: `lib/features/auth/presentation/login_screen.dart` per §12 S2: brand mark 72dp → "Welcome back" (Fraunces 28) → subtitle → email → password (obscure toggle, 8-char rule) → primary CTA 52–54dp (loading locks size) → divider "or" → Google button → "New here? Create an account" ghost → `/register`. `signIn()` success → guest-cart merge (best-effort) → router refresh → `/home`. `lib/features/auth/data/google_auth_source.dart` — abstract in tests, real impl wraps `google_sign_in`, converts platform/not-configured failures to `ApiException` with an honest sentence.
   → **EXPECTED: PASS** + analyze clean.
3. Commit: `feat(app): S2 login — email/password + Google, cold-start hints (DESIGN §12)`

**Test command:** `flutter test test/auth/login_screen_test.dart`

## Task 7: S3 Register screen

**Goal:** instant-signup register with per-field DRF error mapping.

### Steps

1. RED: write `test/auth/register_screen_test.dart`:
   - validation: name required, email format, password ≥ 8;
   - mocked DRF 400 payload `{email: ["user with this email already exists."]}` → that message lands on the email field, others unaffected;
   - success → auto-login (`signedIn`) → `redirectFor('/register', …, signedIn: true) == '/home'`;
   - network failure → human snackbar, input preserved;
   - role segmented control defaults Customer; phone optional (empty submits fine).
   → **EXPECTED: FAIL**.
2. GREEN: `lib/features/auth/presentation/register_screen.dart` per §12 S3: same shell as S2 → "Create your account" → name → email → password (8+) → phone (optional) → role segmented (Customer/Merchant) → CTA "Create account" → `POST /auth/register/ {email, password, name, [phone, role]}` → session → `/home`. No `/verify` route anywhere.
   → **EXPECTED: PASS** + analyze clean.
3. Commit: `feat(app): S3 register — instant signup, field errors, auto-login (DESIGN §12)`

**Test command:** `flutter test test/auth/`

## Task 8: S1 Boot + on-device proof

**Goal:** boot can never strand; fresh app launches on the emulator and lands on Login.

### Steps

1. RED: write `test/auth/boot_screen_test.dart`:
   - boot pending 1.2s → brand splash visible, no hint yet;
   - pending at 3s+ (fake clock) → `Waking up the store…` progress hint shown;
   - boot resolves `signedIn` → router lands `/home` (`redirectFor('/', booted: true, signedIn: true)`);
   - boot resolves `guest` → `/login` — **assert never `booting` after resolution**;
   - boot failure state → guest with retry banner; Retry re-invokes `boot()`.
   → **EXPECTED: FAIL**.
2. GREEN: `lib/features/auth/presentation/boot_screen.dart` (full-screen `brand`, cream "EG" mark, letterspaced EASYGET; hint after 3s; retry banner on failure) + wire `authController.boot()` from `main()` + router `refreshListenable` bridge.
   → **EXPECTED: PASS** + full `flutter test` + `flutter analyze` green.
3. On-device proof: `flutter build apk --debug` → `adb install -r` → launch → `adb exec-out screencap` shows the boot/login screen; `adb logcat -d` shows no Flutter exceptions (the `NoSuchMethodError`/stranded-splash classes are gone). Fresh install has no tokens → boot resolves `guest` → `/login`.
4. Commit: `feat(app): S1 boot — progress hints, failure recovery, no stranded splash (DESIGN §12)`

**Test command:** `flutter test`

## Review Focus (for final reviewer)

- Single-flight refresh under real concurrency (tests simulate parallel 401s with a mock adapter, not a real network).
- Behavior against a **cold** Render instance (60s receive timeout, progress hints) — not exercised in unit tests.
- Google sign-in on a real Play-Services device + registered OAuth client — untested territory by design; error-path messaging is what's covered.
- Visual fidelity to DESIGN §10/§12 is asserted only via token equality tests, not pixel goldens.
- Old `customer-app/` untouched — confirm no cross-folder edits in the diff.
