# Plan: customer-app-v2 Phase 2 — Commerce Kit (data spine + design system)

**Spec (binding authority):** `DESIGN.md` §§10–16 + `docs/superpowers/specs/2026-10-09-customer-app-v2-design.md` (spec §11 build-order steps 4+).
**Branch:** `fix/flutter-web-and-ordering` (existing feature branch; not main — same worktree ruling as Phase 1).
**Executor:** inline (executing-plans), standard RED→GREEN TDD.
**Scope:** roadmap Phase 1 = the "commerce kit": contract realignment to the VERIFIED live backend, full data layer, guest-cart merge, analytics tracker, app shell, and the prime commerce widgets. S4–S13 screens come in later plans.
**Source authority for endpoints:** live backend exploration (verified paths below). Ruling agreed with partner: build against the real backend AND reconcile `CONTEXT.md §2` (docs-only). No `/payments/intent|confirm/`, `/auth/otp/*` phone, `/search/trending/`, `/brands/`, `/wishlist/`, `/addresses/`, `/orders/:id/track/`, `/coupons/active/`, `/products/:slug/rating-distribution/` — they do not exist.

## Global Constraints (inherit from Phase 1 plan)

- Work only inside `customer-app-v2/**` and `docs/**`. Never `git add .` — the working tree carries many unrelated modified files.
- Backend untouched (hard rule). Build against the verified live paths below.
- Gate per task (workdir `customer-app-v2/`): `flutter analyze` == No issues AND `flutter test` green.
- DESIGN §10 tokens (zero `Color(0x…)` / magic numbers outside `core/theme/`), §11 component anatomy, §14 logic rules, §16 acceptance are binding.
- PowerShell 5.1; `rtk` prefix on git; one conventional commit per task (`feat(app):`/`chore(app):`/`docs:`); ledger line per task.
- Live API `https://easyget-api.onrender.com/api/v1`; cold-start connect 90s / receive 60s; tests never hit the network (Dio fake adapter like `test/network/api_client_test.dart`).
- Repos are `abstract XRepository` + `HttpXRepository(api)` + `xRepositoryProvider` — the Phase-1 `AuthRepository` pattern, so screens and controllers use fakes.

## Verified endpoint map (the real backend — replaces CONTEXT §2 for the app)

```
POST /auth/login/                {email,password} → {access, refresh, user}
POST /auth/refresh/              {refresh} → {access}
POST /auth/logout/               {refresh} → blacklist
POST /auth/register/             {email,password,first_name,last_name,phone,role}
POST /auth/google/               {id_token} → {access, refresh, user}
GET  /users/me/                  GET + PATCH {first_name,last_name,phone}
GET   /users/me/addresses/       POST {label,line1,line2,city,state,postal_code,country,phone,is_default}
PATCH/DELETE /users/me/addresses/{id}/   POST /users/me/addresses/{id}/set-default/
GET  /categories/                flat list (product_count, has_children → children on detail)
GET  /products/                  ?category&brand&min_price&max_price&min_discount&is_featured&sort(price_asc|price_desc|newest|rating)&page
GET  /products/{slug}/           detail + variants[] + images[] + offers[] (top-5 coupons)
GET  /products/brands/           distinct brands
GET  /products/wishlist/         POST/DELETE /products/wishlist/{slug}/ → {added, slug, count}
GET  /products/{slug}/reviews/   GET (paged 10) + POST {rating,title,body} (409 duplicate)
POST /search/                    {q, category, min_price, max_price, is_featured, sort, page} → {results,total,…}
GET  /search/suggestions/?q=     min 2 chars → [strings]
GET  /cart/                      → {id, store, items[{id, variant{...}, quantity, line_total, tenant_id, seller_name}], total_items, subtotal}
POST /cart/items/                {variant_id, quantity} (upsert-inc)
PATCH/DELETE /cart/items/{id}/   POST /cart/merge/ {session_key} · DELETE /cart/clear/
GET  /orders/                    list (+item_count)
POST /orders/                    {cart_id, store?, delivery_address, delivery_instructions} → {"orders":[...]} (per-seller split)
GET  /orders/{id}/               detail + items[] + status_history[]  · POST /orders/{id}/cancel/ {reason} · GET /orders/{id}/invoice/
GET  /payments/methods/          saved methods (CARD|UPI|WALLET|COD)
POST /payments/                  {order, gateway, amount, payment_method_id?} → payment row (COD/UPI-delivery for v1)
GET  /pincode/{code}/            → {valid, city, state, eta_days, delivery_fee("29.00"), free_delivery_over("499.00"), source}
POST /admin/coupons/validate/    {code, order_value} (any auth) → {valid:true, discount, discount_type, coupon} | 400 {valid:false, message}
GET  /banners/                   public, paginated (type CAROUSEL|POPUP|BANNER)
GET  /storefront/platform/       → {store, theme, sections[], ticker{items,speed,color,bg,symbol,fontSize,radius}}
GET  /storefront/{slug}/         same shape
GET  /notifications/             list · POST /notifications/{id}/mark_read/ · /notifications/mark_all_read/ · GET /notifications/unread_count/
GET  /notifications/preferences/ + /all_preferences/ + /bulk_update/
POST /realtime/devices/          {platform: IOS|ANDROID|WEB, device_token, user_agent}
POST /analytics/events/          {event_type, session_id, properties}
POST /analytics/events/batch/    [events]
POST /pwa/updates/check/         {platform, current_version} → {update_available, version, release_notes, download_url, is_mandatory}
ws/orders/ · ws/notifications/   (Phase 5, not this plan)
```

## Pre-flight: shared interfaces

| # | Produces → Consumes | Finding / ruling |
|---|---|---|
| P1 | T1 `ApiEndpoints` realignment → T2–T5 repositories | Ruling: replace the frozen-contract path set with the verified map above; keep `googleAuth`, add `addresses`, `brands`, `wishlist`, `cartClear`, `ordersCancel`, `invoice`, `paymentCreate`, `paymentMethods`, `couponsValidate`, `notifications*`, `realtimeDevices`, `analyticsEvents`, `analyticsBatch`, `pwaUpdatesCheck`; DROP `otpSend/otpVerify`, `searchTrending`, `ratingDist`. Update CONTEXT §2 to match. |
| P2 | T2 catalog/storefront/pincode repos → T6/T7 widgets + S4/S5/S7 | Models: `Category`, `Brand`, `CatalogProduct` (list shape), `StorefrontRender` (store/theme/sections/ticker), `SectionItem`, `PincodeInfo`. List products decode both `/products/` and `/search/` results. |
| P3 | T3 cart+wishlist + guest merge → S8/S7, T6 shell badge | Ruling: cart merge payload is `{session_key}` not `{guest_token}`; guest key lives in `TokenStore` (`guestSessionKey` + `{save,read,clear}`); `AuthRepository.login`/`loginWithGoogle` must merge the guest cart using session_key before returning user. `cartCountProvider` reads `/cart/` totals. |
| P4 | T4 orders/addresses/reviews/payments repos → S9–S13 | Order price fields: `subtotal, delivery_fee, discount, total` (NOT `subtotal, discount, total` as CONTEXT says). Order create body is `{cart_id, delivery_address, delivery_instructions}` not `{address_id, payment_method, coupon_code}`. |
| P5 | T5 notifications/analytics/app-update → S12, S11, release | Analytics tracker fires `APP_OPEN` (boot) + `PAGE_VIEW` on route change + commerce events; batching via `/analytics/events/batch/`. Session id = device-generated UUID stored in `TokenStore`. |
| P6 | T6 shell + T7/T8 widgets → every later screen | Shell ships placeholders for tabs (Key pattern from Phase 1 T5) so later plans prove replacement. BottomNav = exactly 5 tabs §11.5, `StatefulShellRoute.indexedStack`. |

## Task 1: contract realignment — endpoints to the verified live backend

**Goal:** `ApiEndpoints` matches the real API exactly; CONTEXT §2 reconciled; tests pin every path string.

### Steps
1. RED: rewrite `test/network/api_endpoints_test.dart` to assert the FULL verified set as exact strings (map above) — including `googleAuth`, `addressesBase/addressDetail`, `brands`, `wishlistBase/wishlistItem`, `cartClear`, `ordersCancel`, `ordersInvoice`, `paymentCreate/methods` (POST `/payments/` uses `paymentBase`), `couponsValidate`, `pincodeCheck`, `storefrontPlatform`, `notifications/unread`, `realtimeDevices`, `analyticsEventsBase` (double as create + batch), `pwaUpdatesCheck`, and asserts the DROPPED ones are absent (no `otpSend`, no `searchTrending`, no `ratingDist`) → **EXPECTED: FAIL** (strings differ from current frozen set).
2. GREEN: rewrite `lib/core/network/api_endpoints.dart` per the map (grouped Auth/Users/Storefront/Catalog/Search/Cart/Wishlist/Orders/Payments/Pincode/Coupons/Admin/Notifications/Realtime/Analytics/Pwa) → **EXPECTED: PASS** + analyze clean.
3. Docs: update `CONTEXT.md` §2 so Auth/Addresses/Wishlist/Orders/Payments/Pincode/Search/Cart/Reviews/Coupons/Admin match the verified map; prefix with a note "§2 reconciled 2026-10-11 against the live backend".
4. Commit: `docs+core(app): reconcile API contract to the verified live backend`

**Test command:** `flutter test test/network/api_endpoints_test.dart`

## Task 2: catalog / storefront / search / pincode data layer

**Goal:** typed models + `Http*Repository` + providers for everything the Discover screens + PDP consume.

### Steps
1. RED: write `test/data/catalog_repository_test.dart`:
   - `_FakeAdapter` (copy pattern) serving canned JSON; `catalogRepositoryProvider` overridden with `HttpCatalogRepository` over that ApiClient.
   - Tests (each decode → typed object):
     a. `fetchProducts` maps `?category&brand&min_price&max_price&min_discount&sort&page` query and decodes `CatalogProduct(id,name,slug,brand,mrp,base_price,discount_percent,is_featured,primary_image,rating_avg,rating_count)`.
     b. `detail(fetchProduct)` decodes variants/images/offers; `fetchCategories` decodes `Category(id,name,slug,parent,image,has_children,product_count)`; `fetchBrands` decodes `{name,slug,logo}`; `fetchPincode` decodes `PincodeInfo(valid,city,state,etaDays,deliveryFee,freeDeliveryOver)`.
     c. `search` POSTs `{q, sort, page}` and maps result rows to `CatalogProduct`.
   → **EXPECTED: FAIL** (no models/repos yet).
2. GREEN: `lib/models/`:
   - `catalog_models.dart` — `Category`, `Brand`, `CatalogProduct`, `ProductDetail` (adds `description`, `offers:List<Offer>`, `variants:List<Variant>`, `images:List<ProductImage>`), `Offer(code,name,description,discountType,discountValue,maxDiscount)`, `Variant(id,name,sku,price,discountPercent,isActive)`, `ProductImage(url,isPrimary,alignX,alignY,zoom,effect,transitionMs)`.
   - `pincode_model.dart` — `PincodeInfo` (numeric-safe parse of `delivery_fee`/`free_delivery_over` strings).
   - `storefront_models.dart` — `StorefrontRender(store,theme,sections,ticker)`, `StoreTheme`, `StorefrontSection(id,type,title,subtitle,image,config,items)`, `SectionItem(id,itemType,productSlug,productPrice,categorySlug,caption,image,link,config)`, `Ticker(items,speed,color,bg,symbol,fontSize,radius)` (all tolerant of absent fields).
   - `lib/features/catalog/data/catalog_repository.dart` — abstract + `HttpCatalogRepository` with `products(query)`, `product(slug)`, `categories()`, `brands()`, `search(q,{sort,page,category,filters})`, `pincode(code)`, `storefront()` (+ `storefront(slug)`).
   - `catalogRepositoryProvider`, `storefrontRepositoryProvider` (or one `catalogRepositoryProvider` covering all) → **EXPECTED: PASS** + analyze clean.
3. Commit: `feat(app): catalog data layer — products, categories, brands, search, pincode, storefront`

**Test command:** `flutter test test/data/`

## Task 3: cart + wishlist + guest-cart merge

**Goal:** real cart/wishlist repos, `cartCountProvider`, and the guest session-cart merge on sign-in (DESIGN §14).

### Steps
1. RED: write `test/data/cart_repository_test.dart` + `test/data/wishlist_repository_test.dart`:
   - cart: `fetchCart` decodes `Cart(id,items,totalItems,subtotal)` + `CartItem(id,variantLabel,variantName,price,quantity,lineTotal,tenantId,sellerName)`; `addItem(variantId,qty)` posts `{variant_id, quantity}`; `updateQty(id,qty)` PATCHes `{quantity}`; `remove(id)` DELETEs; `clear()` DELETEs `/cart/clear/`.
   - wishlist: `fetch()` GETs, `toggle(slug)` POST/DELETE `/products/wishlist/{slug}/` decoding `{added,slug,count}`.
   - guest merge: `AuthRepository.login` (existing fake) now also merges when a guest session key exists — assert merge POSTs `{session_key}` and clears it.
   → **EXPECTED: FAIL**.
2. GREEN: `lib/models/cart_models.dart`, `lib/features/cart/data/cart_repository.dart` (+provider), `lib/features/wishlist/data/wishlist_repository.dart` (+provider); extend `TokenStore` abstract + InMemory + Secure with `guestSessionKey` (save/read/clear); update `HttpAuthRepository.login` + `loginWithGoogle` to merge guest session cart; add `cartCountProvider` (`ref.watch` → number for the shell badge) → **EXPECTED: PASS** + analyze clean.
3. Commit: `feat(app): cart + wishlist data layer with guest session merge on sign-in`

**Test command:** `flutter test test/data/ test/auth/`

## Task 4: orders + addresses + reviews + payments data layer

**Goal:** typed repos for checkout/orders/account (S9–S13), server-truth pricing only.

### Steps
1. RED: write `test/data/orders_repository_test.dart`, `test/data/address_repository_test.dart`, `test/data/review_repository_test.dart`, `test/data/payment_repository_test.dart`:
   - orders: `list()` decodes `Order(id,orderNumber,status,subtotal,deliveryFee,discount,total,createdAt,itemCount)`; `detail(id)` adds `items[]`, `statusHistory[]` (`OrderStatusEvent(from,to,note,createdAt)`), `estimatedDeliveryAt`, `deliveredAt`, `cancelledAt+reason`; `create(cartId,address,instructions)` posts `{cart_id, delivery_address, delivery_instructions}` and decodes the `{"orders":[Order]}` envelope (take first); `cancel(id,reason)` posts `{reason}`; `invoice(id)` GETs.
   - addresses: `list/create/update/delete/setDefault` against `/users/me/addresses/…`; `Address(label,line1,line2,city,state,postalCode,country,phone,isDefault)`.
   - reviews: `list(slug)` (paged) + `create(slug,rating,title,body)`; expects 409 duplicate → `ApiException` human error.
   - payments: `methods()` decodes `PaymentMethod(type,label,last4?,upiId?,gatewayToken?)`; `createForOrder({order,gateway,amount,paymentMethodId})` POSTs `/payments/`.
   → **EXPECTED: FAIL**.
2. GREEN: `lib/models/order_models.dart`, `lib/models/address_model.dart`, `lib/models/review_model.dart`, `lib/models/payment_model.dart`; `lib/features/orders/data/orders_repository.dart`, `lib/features/addresses/data/address_repository.dart`, `lib/features/reviews/data/review_repository.dart`, `lib/features/payments/data/payment_repository.dart` (+ providers) → **EXPECTED: PASS** + analyze clean.
3. Commit: `feat(app): orders, addresses, reviews, payments data layer`

**Test command:** `flutter test test/data/`

## Task 5: notifications + analytics tracker + app-update

**Goal:** engagement data layer + telemetry wired from boot + version check.

### Steps
1. RED: write `test/data/engagement_repository_test.dart`:
   - notifications: `list()`, `unreadCount()` → `int`, `markRead(id)`, `markAllRead()`.
   - analytics: `track(eventType, properties)` POSTs `/analytics/events/`; `trackBatch(events)` POSTs `/analytics/events/batch/`; tracker stamps a stable `session_id` from `TokenStore`.
   - app update: `checkUpdate(platform,version)` POSTs `/pwa/updates/check/` → `AppUpdateInfo(updateAvailable,version,releaseNotes,downloadUrl,isMandatory)`.
   - tracker behavior: `APP_OPEN` fired on `boot()` (assert through fake repo) and `PAGE_VIEW` when router location changes.
   → **EXPECTED: FAIL**.
2. GREEN: `lib/features/engagement/data/…` (notifications_repository, analytics_repository with `AnalyticsTracker`, app_update_repository) + providers; wire `APP_OPEN` in `AuthController.boot()` (fire-and-forget, never throws — mirrors warmUp); provide `routeObserver`/location listener later in T6 shell → **EXPECTED: PASS** + analyze clean.
3. Commit: `feat(app): notifications + analytics tracker + app-update data layer`

**Test command:** `flutter test test/data/ test/auth/`

## Task 6: shell — AppBar, SearchBar, 5-tab StatefulShell BottomNav

**Goal:** the navigation chrome every tab screen drops into (DESIGN §11.5), with tab placeholders (Key pattern) so later plans prove replacement.

### Steps
1. RED: write `test/shell/shell_test.dart`:
   - `EasyGetApp` (overrides: fakes for auth + api + catalog) lands on `/` boot → with no session routes to `/login`; with session → `/home` renders `BottomNav` with the 5 noun tabs Home/Browse/Search/Cart/Orders, cart badge hidden when 0.
   - tab switch `/home`→`/browse` renders `Key('placeholder-browse')` and selects Browse; back on `/home` re-renders state (StatefulShell keeps tab state).
   - SearchBar tap on home calls `context.push('/search')`.
   - the AppBar shows an ETA pill slot and address row slot on home (placeholders ok).
   → **EXPECTED: FAIL** (no shell).
2. GREEN: `lib/core/widgets/app_bar.dart` (`EasyGetAppBar`), `search_bar.dart` (`AppSearchBar` → push `/search`), `bottom_nav.dart` (`EasyGetBottomNav` + `_navItems`, marigold badge via `cartCountProvider`); rewrite `lib/core/router/app_router.dart` routes `/home|/browse|/search|/cart|/orders` under `StatefulShellRoute.indexedStack` wrapping 5 placeholder children with `Key('placeholder-<route>')`; keep auth redirect law (§13) intact → **EXPECTED: PASS** + analyze clean.
3. Commit: `feat(app): app shell — AppBar/SearchBar/5-tab StatefulShell BottomNav`

**Test command:** `flutter test test/shell/ test/router/ test/auth/`

## Task 7: prime commerce widgets — ProductCard, PriceBlock, RatingPill, QtyStepper, VariantSheet

**Goal:** DESIGN §11.2–11.4 chips that every catalog surface reuses (3 densities + one Add/stepper system).

### Steps
1. RED: write `test/widgets/commerce_widgets_test.dart`:
   - `PriceBlock`: shows price (tabular) + strikethrough MRP + save line when mrp > base; no MRP when equal; never "SALE".
   - `RatingPill`: marigold star + tabular `4.3` + muted `(212)`; taps callback.
   - `QtyStepper`: 0 state shows `Add` pill; tap → `− 1 +`; stepper caps at `maxQty` (tooltip); back to 0 morphs to Add.
   - `ProductCard` grid: skeleton→image→name→weightline→PriceBlock→Add/stepper; tap opens VariantSheet when >1 variant; `Semantics` labels present.
   - `VariantSheet`: option rows 56dp, checked ring, price delta tabular, footer CTA "Add · ₹240" sums selected variant price.
   → **EXPECTED: FAIL**.
2. GREEN: `lib/features/catalog/presentation/widgets/{price_block,rating_pill,qty_stepper,product_card,variant_sheet}.dart` using tokens/motion (§10.6–10.8: radius 18 card/14 image; 180ms stepper morph; light haptic). ProductCard 3 constructors/params for rail/grid/line density (same Add system). All numbers `FontFeature.tabularFigures()` (§10.4). → **EXPECTED: PASS** + analyze clean.
3. Commit: `feat(app): commerce widgets — ProductCard, PriceBlock, RatingPill, QtyStepper, VariantSheet`

**Test command:** `flutter test test/widgets/`

## Task 8: overlays + state — FilterSheet, SortSheet, SectionHeader, chips, skeletons, Empty/Error/Offline, pills, AddressCard, OrderTimeline, Snackbar helper

**Goal:** the remaining kit pieces screens compose (DESIGN §11.1/11.3/11.6).

### Steps
1. RED: write `test/widgets/kit_widgets_test.dart`:
   - `FilterSheet`/`SortSheet`: bottom sheet anatomy; Filter rows are switches (not checkboxes), Apply shows live count "Show 42", Clear ghost resets.
   - `SectionHeader`: Title 17/700 left + ghost "See all →" right; never centered.
   - `Chip`: rounded 999 sunken rest → primaryTint selected; 44dp min.
   - Skeletons: `SkeletonGrid`/`SkeletonLine`/`SkeletonRail` match target layouts; shimmer-free pulse.
   - `EmptyState/ErrorState/OfflineState`: icon dot + Title + Body + primary CTA; Offline labels "You're offline".
   - `StatusPill` colors (transit=marigold wash/delivered=success/cancelled=muted); `EtaPill` marigold wash + timer + tabular "12 min".
   - `AddressCard`: radio + label chip + 2-line + tabular phone + default badge + delete.
   - `OrderTimeline`: renders `List<OrderStatusEvent>` vertical, current node primary, cancelled/refunded muted.
   - `showAppSnackbar` helper: floating radius-14, ink fill, optional action.
   → **EXPECTED: FAIL**.
2. GREEN: implement under `lib/core/widgets/` and `lib/features/catalog/presentation/widgets/` with tokens only → **EXPECTED: PASS** + analyze clean.
3. Commit: `feat(app): kit overlays + state widgets — sheets, chips, skeletons, states, pills, cards, timeline`

**Test command:** `flutter test test/widgets/`

## Completion contract (per task)

- Every test the brief names ran and was read; final task run is the `flutter test <brief>` command → green; analyze == No issues; commit per brief; deviation → `Ruling:` in ledger (`.superpowers/sdd/2026-10-09-customer-app-v2-phase2-plan/progress.md`).