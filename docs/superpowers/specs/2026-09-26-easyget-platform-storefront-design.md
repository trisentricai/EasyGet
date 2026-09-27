# EASYGET Platform Storefront — Design Spec

**Date:** 2026-09-26
**Status:** Approved (design sections 1–3 confirmed by Rahul)
**Repo/branch:** `trisentricai/EasyGet`, `fix/flutter-web-and-ordering`

## 1. Problem & Intent

The customer app is pinned to one hardcoded demo store (`rahuls-store`) for its
storefront design, and the header brand renders that store's name ("Rahul's
Store"). The catalog itself is already platform-wide (the product API has no
store filter), but the storefront shell — theme, hero sections, brand — is
per-store, and the cart/order layer is single-seller.

**Goal:** EASYGET *is* the storefront. One platform-level EASYGET storefront
(theme + sections) that shows everything across all merchants; the store concept
disappears from the customer UI except where seller identity is unavoidable
(cart grouping, checkout, orders); orders split per seller at checkout
(Flipkart/Meesho marketplace rule).

**Success criteria:**
- Customer app always renders branded EASYGET with platform-wide catalog.
- A cart containing items from 2+ tenants places N orders atomically (one per
  seller); each merchant sees only their order.
- Seller name visible in exactly three places: cart grouping, checkout split
  preview, order history.
- No client breaks: Flutter keeps working via legacy API paths (ported in
  Phase E).
- Full test suite green; both web builds green; live smoke verified.

## 2. Decisions (user-confirmed)

| # | Question | Decision |
|---|---|---|
| D1 | Per-store storefront fate | **B — architectural:** EASYGET becomes the single platform storefront; per-store storefront removed from customer UI |
| D2 | Multi-seller cart | **A — split orders at checkout** (Flipkart/Meesho rule) |
| D3 | Seller visibility | **B — only where required:** cart grouping, checkout, orders. Hidden on cards/browse/PDP |
| D4 | Demo "Rahul's Store" data | **A — rename neutral** ("EasyGet Demo Store"), one merchant, products intact |
| D5 | Client scope | **A — web only** this phase; Flutter unchanged (back-compat), ported Phase E |
| D6 | Implementation approach | **Approach 1 — platform store row + `Store.is_platform` flag** |

## 3. Scope

**In scope:**
- `Store.is_platform` schema + platform-row + demo-rename data migrations
- Storefront API: `/api/v1/storefront/platform/` route, section-item guard
  relaxation for the platform store, exclusion audit for `is_platform`
- Cart: cross-tenant guards removed; `tenant_id` + `seller_name` on cart lines
- Orders: split mode on `POST /orders/` (legacy `store` mode preserved)
- customer-web: fixed platform fetch, cart grouping, checkout split UX,
  orders seller line, brand casing
- admin-web: storefront designer staff-only (edits platform store), merchant
  nav hides designer
- Tests, docs updates

**Out of scope:**
- Flutter changes (Phase E)
- Payment/gateway handling of multi-order charges (Phase C)
- Merchant per-store page redesign (their designer row remains in DB but is
  unreachable from customer app)
- Coupon/checkout apply, delivery flow changes, analytics

## 4. Design

### 4.1 Data model & migrations

**Schema migration:**
- `Store.is_platform = models.BooleanField(default=False)`
- `Meta.constraints`: `UniqueConstraint(fields=["is_platform"], condition=Q(is_platform=True), name="unique_platform_store")` — at most one platform store.

**Data migration (idempotent, guarded):**
1. If no `is_platform=True` row exists, create: `name="EASYGET"`,
   `slug="easyget"`, `tenant=NULL`, `is_platform=True`, `is_active=True`,
   `address_line1="EASYGET Marketplace"`, `city="Bengaluru"`,
   `state="Karnataka"`, `postal_code="560001"`, `latitude=12.9716`,
   `longitude=77.5946` (all non-null required fields).
2. If a store named exactly `"Rahul's Store"` exists → rename **name** to
   `"EasyGet Demo Store"` (`slug` untouched — auto-slug only runs when slug is
   empty, `stores/models.py:52-61`, so `rahuls-store` survives for Flutter).
3. Same guarded rename for the tenant named exactly `"Rahul's Store"`.

### 4.2 Storefront API

- **New:** `GET /api/v1/storefront/platform/` → resolves the `is_platform`
  row (404 if absent). Same `StorefrontRenderSerializer` payload as the slug
  route. customer-web calls this — flag lookup, not a magic slug.
- **Unchanged:** `GET /api/v1/storefront/<slug>/` byte-for-byte compatible
  (Flutter, admin preview; `easyget` also resolves here).
- **Section-item guard** (`storefront/views.py:23-29`,
  `_product_allowed_for_store`): for the platform store, allow linking **any
  `is_active` product regardless of tenant**. Merchant stores keep the strict
  tenant check (and the inactive-section read rule is unchanged).
- **Permissions:** no changes. `tenant=NULL` ⇒ `is_tenant_member()` false for
  everyone ⇒ `IsStorefrontManager` is staff-only on the platform row for free.
- **Exclusion audit** (the flag's purpose): `is_platform=True` rows excluded
  from:
  - checkout's store picking (`customer-web` `listStores()` + any backend
    "list active stores" used for order targets)
  - order creation validation (platform store rejected as order target in both
    request modes)
  - customer/merchant store pickers and admin lists shown to non-staff
  - delivery/inventory/agent surfaces (tenant-scoped queries already exclude
    it; verify)
  - staff-facing admin lists may still show it (flagged).

### 4.3 Cart (mixed sellers)

- **Remove** cross-tenant add rejection (`cart/views.py:60-71`) and
  cross-tenant merge rejection (`views.py:122-129`). Any active variant can
  join any cart; auth/ownership checks stay.
- `Cart.store` / `Cart.tenant` model fields stay (legacy single-store path and
  old carts use them) but are no longer guards for new carts (created
  store-less ⇒ tenant denormalization stays NULL).
- **Cart line serializer additions:**
  - `tenant_id` (from `variant.product.tenant_id`)
  - `seller_name`: tenant's first active non-platform store `name` → fallback
    tenant `name` → `"EasyGet"`.

### 4.4 Orders — one endpoint, two modes

`POST /api/v1/orders/`:

- **Legacy mode** (request contains `store`): unchanged — existing
  validations (cart/store match, tenant-catalog check), single-order response
  shape. Flutter and current clients unaffected.
- **Split mode** (only `cart_id`, no `store`):
  1. Group cart lines by `variant.product.tenant_id`.
  2. Resolve store per group: `tenant.stores.filter(is_active=True,
     is_platform=False).order_by("name").first()` (same "first active by name"
     convention checkout used). No store, or `tenant_id IS NULL` →
     `400 {"cart_id": "Some items can't be ordered right now."}`.
  3. Create one `Order` per group inside `transaction.atomic()` — all-or-nothing;
     any group failure rolls back the whole request (HTTP 400, no partial
     orders). Per-order `subtotal`/`total`/`tenant` derived from that group's
     lines through the existing create path.
  4. Response: `201 {"orders": [...]}`. (Legacy mode still returns the single
     order object — a client knows which mode it called.)
  5. Platform store rejected as an order target in both modes.
- Existing per-order side effects (signals/notifications/timeline) fire once
  per created order.
- **Payments:** untouched; multi-order gateway handling is Phase C.

### 4.5 customer-web

- `StorefrontContext.tsx`: delete `eg-cust-store` localStorage, `slugFromHash()`,
  `#/shop/<slug>` handling, dead `setSlug()`; always fetch
  `/storefront/platform/`. Context shape unchanged — header brand resolves from
  `data.store.name` = "EASYGET".
- Brand casing: loading/fallback states, footer → literal `"EASYGET"`;
  `index.html` title → "EASYGET".
- **Cart page:** group lines by `tenant_id` under "Sold by {seller_name}"
  headings with per-group subtotals.
- **Checkout:** remove `listStores()` guess + "No active store available"
  dead end; show split preview ("This will be placed as N orders — one per
  seller") with seller groups; place with `{cart_id}`; handle
  `201 {orders:[...]}`; land on Orders with an "N orders placed" banner.
- **Orders list:** render existing `store_name` as "Seller: X" line (detail
  page too if absent).
- **Cards/browse/search/PDP:** untouched (already platform-wide). PDP seller
  box: replace hardcoded `EasyGet Retail` with a neutral platform line, no
  merchant name.

### 4.6 admin-web

- Storefront designer (`StorefrontPage`): **staff-only** — edits the platform
  store (fetch platform endpoint; keep slug editing path for staff if present).
  Nav entry hidden for merchant role; merchants keep
  Products/Inventory/Orders.
- Store pickers/lists hide `is_platform` rows from non-staff.

### 4.7 Flutter (customer-app)

Zero changes this phase. Back-compat guarantees: slug storefront route stays,
legacy order mode (`store` param) stays, demo store slug `rahuls-store` stays.

## 5. Error handling

- Split mode failures: atomic rollback; single 400 with a human message; no
  partial order sets ever observable.
- `POST /storefront/platform/` when no platform row exists → 404 (migration
  creates it, so only possible on a DB that skipped migrations).
- Platform store referenced as order target → 400 (clear field error).
- NULL-tenant orderable products → 400 with "Some items can't be ordered
  right now." (edge case; staff-created products without tenant).

## 6. Testing

**Backend (new):**
- Platform route resolves / 404 when missing; payload matches slug route.
- Section-item guard: platform store may link any active product; merchant
  store still rejects foreign tenant.
- Store-list/order-target surfaces exclude `is_platform`.
- Order create: split groups by tenant; totals/tenant per order; atomic
  rollback on mid-split failure; NULL-tenant group rejected; platform store
  rejected (both modes).
- Legacy mode: existing tests unchanged and green.

**Backend (flipped — intended behavior change):**
- `test_add_cross_tenant_variant_rejected` → now allowed.
- `test_merge_cross_tenant_carts_rejected` → now allowed.

**Frontend:** both `npm run build` green.

**Live smoke:** platform storefront 200 (brand EASYGET), mixed-tenant cart →
N orders, legacy single-order request still works, demo rename visible in cart
grouping.

## 7. Risks / open edges

- **Exclusion audit completeness** — any missed `Store.objects` listing could
  leak the platform store as an order target; mitigated by validation at the
  order-create chokepoint (rejects even if a picker leaks).
- **Cart.tenant legacy residue** — old carts may carry a tenant; split mode
  ignores `cart.store`/`cart.tenant` (grouping is per line), so residue is
  harmless.
- **Multi-store tenants** — store resolution picks first active by name; stock
  is per-store, so a line stocked only in another store still orders against
  the chosen store (same behavior as today's checkout guess; not a regression).
- **Admin preview deep-links** — `#/shop/<slug>` removed from customer app;
  admin preview points at the platform storefront root instead.
