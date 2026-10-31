# EASYGET customer-app-v2 — Fresh Rebuild Design

Date: 2026-10-09
Status: approved (chat design reviewed by Rahul)
Precedes: implementation plan (writing-plans skill)

---

## 1. Intent

Rebuild the Flutter customer app from scratch because the current
`customer-app/` produced persistent reliability problems, specifically
around authentication (email/password appearing stuck on "loading";
Google sign-in failing). Goal: a clean, reliable client where the auth
flow is designed around the backend's real-world behavior (Render
free-tier cold starts) instead of being patched after the fact.

The product requirements are already frozen in DESIGN.md §10–§16 and
CONTEXT.md §2 — this spec defines the *architecture* of the new
codebase, not new product behavior.

**Success criteria:**
- Email/password login and register work reliably; boot cannot strand
  the user on a splash screen (cold-start failure → guest + retry,
  never a hang).
- Google sign-in works on a Play-Services device once an OAuth client
  exists; everywhere else it fails with an honest human message.
- Every MVP screen meets DESIGN.md §16 acceptance (skeleton/empty/error
  states, light+dark, zero hardcoded colors, tabular figures).

## 2. Decisions already made

| Decision | Choice |
|---|---|
| Scope | Fresh MVP, then grow (Auth → Home → Browse/Search → PDP → Cart → Checkout → Orders first) |
| Primary pain to fix | Login / Google reliability |
| Package / applicationId | `com.trisentric.easyget` |
| Location | New folder `customer-app-v2/`; old `customer-app/` stays runnable side-by-side (deleted later, once v2 ships) |
| Architecture | Approach A: feature-core scaffold, manual Riverpod (no codegen), go_router, Dio |
| Auth in MVP | Email/password **and** Google (Google behind graceful "unsupported/not configured" messaging) |
| Backend | No changes required; frozen contracts only (CONTEXT §2) |

## 3. Scaffold & structure

```
flutter create customer-app-v2 --org com.trisentric --platforms android
```

`customer-app-v2/lib/`

```
core/
  theme/        tokens.dart, app_theme.dart
  network/      api_client.dart, api_endpoints.dart, api_exception.dart,
                auth_interceptor.dart   (single-flight 401 refresh)
  storage/      token_store.dart        (flutter_secure_storage)
  router/       app_router.dart
  config/       app_config.dart         (base URL — single source)
features/
  auth/        data/ presentation/
  storefront/  data/ presentation/
  catalog/     data/ presentation/
  product/     data/ presentation/
  cart/        data/ presentation/
  checkout/    data/ presentation/
  orders/      data/ presentation/
shared/        buttons, product_card, skeletons, states, price_block,
               qty_stepper, sheets, chips
```

Dependencies (deliberately few): `flutter_riverpod`, `go_router`,
`dio`, `flutter_secure_storage`, `cached_network_image`, `shimmer`,
`google_fonts`, `flutter_animate`, `intl`, `google_sign_in`.
Strict `analysis_options.yaml` (flutter_lints + riverpod rules) from
day one; `flutter analyze` must stay at zero issues per session.

## 4. Session & auth (built first — this is the pain point)

- **Boot:** saved refresh token → `POST /auth/refresh/` →
  `GET /users/me/`. Three states: `booting` (progress hint shown after
  ~3s, copy like "waking the store…"), `ready-signedin`,
  `ready-guest`. **Boot failure resolves to `ready-guest` with a retry
  banner — never a stuck splash.**
- **401 handling:** `AuthInterceptor` refreshes **once** per 401,
  retries the original request; a second 401 (or refresh failure)
  clears tokens and routes to `/login`. Never loops refreshes
  (DESIGN §14).
- **Google:** `google_sign_in` idToken → `POST /auth/google/`. Device
  without Play Services, or backend/client not configured → explicit
  human-readable error on the button; no silent hang, no crash.
- **Guest cart:** local `guest_token` pre-login; after sign-in
  `POST /cart/merge/` then drop the guest token (DESIGN §14).
- **Timeouts:** connect 90s, receive 60s (free-tier sleep-aware,
  DESIGN §14).

## 5. Network

- One `Dio` instance in `core/network/`; `AuthInterceptor`
  (token attach + single-flight refresh), debug-only `LogInterceptor`.
- All failures normalize to `ApiException` → one human sentence.
  Timeouts map to "waking the store, retry". No Python/HTTP jargon
  ever reaches the UI.
- Base URL comes from `core/config/app_config.dart` only — no URL
  literals elsewhere.
- Endpoints: frozen contract only (CONTEXT §2 / DESIGN §15). Never
  invent endpoints; missing backend support = backend ticket.

## 6. State & data

- Riverpod, manual (no build_runner): `Notifier` for auth/session,
  `AsyncNotifier` / keepAlive `FutureProvider`s for reads.
- Pull-to-refresh re-fires the screen's providers (DESIGN §14).
- Lists are paged (page size 20), infinite scroll with footer
  skeleton and end cap ("You've seen everything").
- Client-side pricing math is preview-only and labeled "est.";
  server totals are truth (DESIGN §14).

## 7. Router

- `go_router` with a stateful shell: tabs Home / Browse / Search /
  Cart / Orders; Account opens via the Home avatar (DESIGN §13 route
  map).
- Redirect matrix keyed on `(booted, signedIn, location)` — every
  combination resolves explicitly; a signed-in user can never be
  parked on `/login`, and a signed-out user on a private route always
  lands on `/login`. Public routes never bounce a signed-in user back
  to boot. (This closes the bug class fixed on 2026-10-09.)

## 8. Theme

- Port the verified `FreshMarketColorTokens` implementation (light +
  dark, implements DESIGN §10) into `core/theme/`.
- Zero `Color(0x…)` / magic values outside `tokens.dart` /
  `app_theme.dart`. Leaf green only on buy actions; marigold rationed.

## 9. Every-screen acceptance (DESIGN §16 verbatim)

- Skeleton / empty / error / populated on every list.
- 48dp targets, Semantics labels, tabular figures on all numbers.
- Router-stable flows (no remount wipes input); human error strings.
- Light + dark designed (not inverted).
- 60fps scrolls; cold start < 3s warm, progressive hints when cold.

## 10. Testing

- Widget test covering the auth flow (login success/failure, boot
  restore, 401-refresh path).
- Repository tests against a mocked Dio adapter (frozen-contract
  response shapes).
- `flutter analyze` zero issues + `flutter test` green required
  before each session is called done.

## 11. Build order (one screen per AI session, DESIGN §16)

1. Tokens + theme (`tokens.dart`, `app_theme.dart`, ColorScheme map)
2. Shared components (buttons, states, skeletons, product card,
   price block, stepper, sheets)
3. S2 Login → S3 Register → S1 Boot polish (session/auth core)
4. S4 Home → S5 Browse → S6 Search
5. S7 PDP → S8 Cart → S9 Checkout (+ minimal address create/pick —
   orders require `address_id`)
6. S10 Orders → S11 Track

**MVP ends after step 6.** Deferred to the grow phase: S12 Account,
full S13 Addresses screen, Wishlist screen, Coupons screen.

## 12. Constraints & risks

- Backend is frozen: no model/serializer/test changes; no invented
  endpoints (CONTEXT §7).
- Google sign-in requires, outside this repo's control: an OAuth
  client for `com.trisentric.easyget` + SHA-1, and a Play-Services
  device. Until both exist, Google fails gracefully by design.
- The old app remains the visual/behavioral reference until v2
  covers it; v2 is deleted-old-later, not a fork that lives forever.
- Render free-tier sleeps: every design decision above assumes the
  first request after idle may take up to ~60s.
