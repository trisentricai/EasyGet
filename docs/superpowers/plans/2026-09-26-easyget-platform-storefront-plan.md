# Plan: EASYGET platform storefront + split-order marketplace

**Spec (binding authority):** `docs/superpowers/specs/2026-09-26-easyget-platform-storefront-design.md`
**Branch:** `fix/flutter-web-and-ordering` (existing feature branch; not main)
**Executor:** inline (executing-plans), standard RED→GREEN TDD (test-driven-development skill not installed)

## Global Constraints

- Tests from repo root, always with explicit labels (bare discovery finds 0):
  `$env:DATABASE_URL='sqlite:///db.sqlite3'; .venv\Scripts\python.exe backend\manage.py test <labels>`
  Labels set: `admin_panel analytics cart categories common delivery inventory notifications orders payments products pwa realtime search storefront stores tenants users webhooks`
- Watch every test fail before implementing; a test that passes before the fix is a finding.
- PowerShell 5.1: no `??`; `rtk` prefix on all git commands.
- Frontend has no test runner: gate is `npm run build` (= `tsc --noEmit && vite build`) in the app dir.
- Backend server runs `--noreload`: restart (`Start-Process .venv\Scripts\python.exe -ArgumentList 'backend\manage.py','runserver','0.0.0.0:8000','--noreload'`) after backend changes when live-smoking.
- Live DB migrations: run `.venv\Scripts\python.exe backend\manage.py migrate` (default env = Supabase) as part of Task 1, after sqlite tests pass.
- Commits: conventional (`feat:`/`fix:`/`docs:`), one per task unless stated. Docs (`currentUpdate.md` + `GitCheck.md`) updated in Task 8 with all hashes (repo precedent: `docs: record commit hash in changelog`).
- Logins: admin `admin@easyget.local`/`EasyGet!2026` (is_staff), merchant `merchant@easyget.app`/`Merchant@123` (STORE_MANAGER), customer `customer@easyget.app`/`Customer@123`.
- Stop only for: irreversible/destructive ops, security-sensitive actions, side effects outside the worktree needing a norm (push is the established session norm at Task 8), or a plan so broken every path is a guess.

## Pre-flight: shared interfaces (Task N → Task M)

| # | Produces → Consumes | Finding / ruling |
|---|---|---|
| P1 | T1 `Store.is_platform` + platform row → T2 route, T3? no, T4 legacy guard, T5/T7 frontend | Consistent; T1 lands schema+data+exclusions first. Ruling: single migration (schema + RunPython data) — one deployable unit. |
| P2 | T1 platform row exists in test DBs (data migration runs at DB creation) → `common._store_state` picks it first by `created_at` → breaks pincode tests | Ruling: exclusion (`is_platform=False`) is part of T1's audit; test `test_store_state_ignores_platform_store` RED→GREEN in T1. |
| P3 | T2 `GET /storefront/platform/` → T5 StorefrontContext | Same `StorefrontPayload` type as existing route; T5 adds `getStorefrontPlatform()` in api.ts. |
| P4 | T3 cart line `tenant_id` + `seller_name` → T6 CartPage grouping + CheckoutPage preview | Field names fixed here: `tenant_id: number \| null`, `seller_name: string` (fallback chain store→tenant→"EasyGet"). |
| P5 | T4 split response `201 {"orders": Order[]}` + legacy single echo → T6 createOrder typing/checkout | `OrderCreateSerializer` response in legacy mode is `{store, delivery_address, delivery_instructions}` (cart_id write-only) — existing `createOrder → OrderDetail` type is already a lie the code works around (CheckoutPage.tsx:105-118). Ruling: split mode serializes each order with `OrderListSerializer` (adds `store_name` — also fixes OrdersPage which reads `o.store_name` from a list payload that never contained it). |
| P6 | T4 `store` optional in `OrderCreateSerializer` → legacy clients unchanged | `Order.store` FK is NOT nullable (orders/models.py:32) → split mode needs `extra_kwargs store required=False`; branch in viewset `create()`. Legacy path (store present) byte-identical. |
| P7 | T7 admin StorefrontPage platform targeting needs `is_platform` on store list | Ruling: `is_platform` added to `StoreListSerializer` in T1 (read-only) — consumed by T7. |

## Task 1: `is_platform` migration + platform row + demo rename + exclusion audit

**Goal:** schema flag, guarded data migration (platform row + demo rename), and every global store query excluding the platform row for non-staff/order-target/pincode purposes. Legacy order target guard lands here.

### Steps (RED first)

1. Append tests to `backend/stores/tests.py`:
   - `test_platform_store_auto_created_by_migration` — `Store.objects.get(is_platform=True)` exists: name "EASYGET", slug "easyget", `tenant_id is None`, `is_active` True.
   - `test_only_one_platform_store_allowed` — `with transaction.atomic(): with self.assertRaises(IntegrityError): Store.objects.create(name="E2", slug="e2", is_platform=True, address_line1="x", city="x", state="x", postal_code="1", latitude=0, longitude=0)` (partial unique constraint).
   - `test_store_list_excludes_platform_for_non_staff` — customer GET `/api/v1/stores/` → no `easyget` slug and no `is_platform: true` row; staff GET → includes it.
   - `test_store_detail_platform_hidden_from_non_staff` — customer GET `/api/v1/stores/easyget/` → 404; staff → 200.
   - Requires `is_platform` in `StoreListSerializer` (read-only) — add in step 4 so the field assertion can be part of these tests (`is_platform` key present for staff).
2. Append to `backend/common/tests.py`:
   - `test_store_state_ignores_platform_store` — with the migrated platform row (Karnataka) present, create a store `state="Tamil Nadu"`; `from common.views import _store_state; self.assertEqual(_store_state(), "Tamil Nadu")`.
3. Append to `backend/orders/tests.py`:
   - `test_order_create_rejects_platform_store` — legacy payload `{cart_id, store: platform.id, delivery_address}` → 400, error key `store`.
4. Run the three test modules → **EXPECTED: new tests FAIL** (no `is_platform` field / list includes platform / `_store_state` returns Karnataka / platform accepted).
5. Implement:
   - `backend/stores/models.py`: `is_platform = models.BooleanField(default=False)` + `Meta.constraints = [models.UniqueConstraint(fields=["is_platform"], condition=models.Q(is_platform=True), name="unique_platform_store")]`.
   - One migration `stores/migrations/0003_store_is_platform.py` (schema + `RunPython`):
     a. create platform row if absent (`get_or_create(slug="easyget", defaults={...})` — set `is_platform=True`, `tenant=None`, `is_active=True`, `name="EASYGET"`, `address_line1="EASYGET Marketplace"`, `city="Bengaluru"`, `state="Karnataka"`, `postal_code="560001"`, `latitude=12.9716`, `longitude=77.5946`; if a non-platform row already owns slug `easyget`, `get_or_create` by that row and flag it only if it was created by us — keep it simple: create with slug `easyget`; on collision fail loudly);
     b. guarded renames: `Store.objects.filter(name="Rahul's Store").update(name="EasyGet Demo Store")` and same for `Tenant` (slug untouched — save() auto-slug only runs when slug empty).
     Reverse: noop.
   - `backend/stores/serializers.py`: add `"is_platform"` (read-only) to `StoreListSerializer`.
   - `backend/stores/views.py`: non-staff querysets add `.filter(is_platform=False)` in `StoreListView.get_queryset` and `StoreDetailView.get_queryset` (GET only for detail — staff/owner writes unaffected; platform row has no tenant so merchant PATCH/DELETE is already dead).
   - `backend/common/views.py:44`: `Store.objects.filter(is_active=True, is_platform=False).order_by("created_at").first()`.
   - `backend/orders/views.py` `perform_create`: after store fetched, `if store and store.is_platform: raise serializers.ValidationError({"store": "Cannot place orders against the platform store."})`.
6. Run stores+common+orders → **EXPECTED: PASS**.
7. Full suite (all labels) → **EXPECTED: PASS**; any other fallout = exclusion audit finding → fix with `is_platform=False` and ledger the ruling.
8. `.venv\Scripts\python.exe backend\manage.py migrate` (live DB) → **EXPECTED: Applying stores.0003... OK**.
9. Commit: `feat: platform store flag, EASYGET platform row, demo rename, store exclusions`

**Test command (task-done):** `$env:DATABASE_URL='sqlite:///db.sqlite3'; .venv\Scripts\python.exe backend\manage.py test stores common orders`

## Task 2: `/storefront/platform/` route + section-item guard

**Goal:** customer app's platform fetch target + spec §4.2 guard relaxation.

### Steps

1. Append to `backend/storefront/tests.py`:
   - `test_platform_route_renders` — GET `/api/v1/storefront/platform/` → 200; `data["store"]["slug"] == "easyget"`; payload shape equals slug-route response for the same store (assert theme/sections keys present).
   - `test_platform_route_404_when_missing` — delete the platform row, GET → 404.
   - `test_platform_section_guard_unit` — unit-call `_product_allowed_for_store(product, platform_store, non_staff_user)`: foreign-tenant **active** product → `True`; **inactive** product → `False`; (merchant store foreign → `False` — already true, pin it).
2. Run storefront tests → **EXPECTED: FAIL** (no `/platform/` route: 404; guard unit fails).
3. Implement:
   - `backend/storefront/urls.py`: `path("platform/", views.PlatformStorefrontView.as_view())` **before** `"<slug:store_slug>/"` (slug pattern would swallow "platform" otherwise — actually `platform` IS a valid slug, so route order matters; put it first).
   - `storefront/views.py`: `PlatformStorefrontView(APIView)` — `permission_classes=[AllowAny]`, `get`: `store = get_object_or_404(Store, is_platform=True, is_active=True)` → `Response(StorefrontRenderSerializer(store).data)`.
   - `_product_allowed_for_store`: insert after the staff short-circuit: `if store.is_platform: return bool(product.is_active)` (spec §4.2: platform links any active product, tenant-agnostic; inactive rejected; merchant path unchanged).
4. Run storefront tests → **EXPECTED: PASS**. Full suite → PASS.
5. Commit: `feat: platform storefront route + platform section-item guard`

**Test command:** `$env:DATABASE_URL='sqlite:///db.sqlite3'; .venv\Scripts\python.exe backend\manage.py test storefront`

## Task 3: cart mixed-seller + seller fields

**Goal:** any active variant joins any cart; cart lines expose grouping fields.

### Steps

1. Flip + add in `backend/cart/tests.py`:
   - Rename `test_add_cross_tenant_variant_rejected` → `test_add_cross_tenant_variant_allowed`: adding tenant-B variant to tenant-A-bound cart → 201/200 (whatever success code the endpoint uses), cart now has both.
   - Rename `test_merge_cross_tenant_carts_rejected` → `..._allowed`: merge succeeds, merged cart holds both tenants' items.
   - `test_cart_item_exposes_seller_fields` — cart item payload contains `tenant_id == product.tenant_id` and `seller_name == <tenant's first active non-platform store name>`.
   - `test_seller_name_fallbacks` — product whose tenant has no store → tenant name; product with `tenant_id=None` → `seller_name == "EasyGet"`, `tenant_id` null.
2. Run cart tests → **EXPECTED: FAIL** (guards still reject; fields missing → `KeyError`/assert fail).
3. Implement:
   - `backend/cart/views.py`: delete the cross-tenant add guard block (lines ~60-71) and the merge-tenant refusal (lines ~122-129). Keep auth/ownership checks.
   - `backend/cart/serializers.py` `CartItemSerializer`: add
     ```python
     tenant_id = serializers.SerializerMethodField()
     seller_name = serializers.SerializerMethodField()
     ```
     `tenant_id` → `obj.variant.product.tenant_id` (None-safe). `seller_name` → tenant's first active non-platform store `.name` (order by name) → tenant `name` → `"EasyGet"`. Add fields to `Meta.fields`.
   - `backend/cart/views.py` cart detail queryset: ensure `items__variant__product__tenant` select/prefetch chain to avoid N+1 (add `tenant__stores` prefetch with `Prefetch` filtered to active non-platform if straightforward; plain chain acceptable).
4. Run cart tests → **EXPECTED: PASS**. Full suite → PASS.
5. Commit: `feat: mixed-seller carts (tenant guards removed) + seller fields on cart lines`

**Test command:** `$env:DATABASE_URL='sqlite:///db.sqlite3'; .venv\Scripts\python.exe backend\manage.py test cart`

## Task 4: order split mode

**Goal:** `POST /orders/` splits by tenant; legacy mode untouched; list serializer gains `store_name`.

### Steps

1. Append to `backend/orders/tests.py` (helpers: two tenants A/B each with one store+product+variant; cart created store-less, both variants added — valid post-Task-3):
   - `test_split_creates_one_order_per_tenant` — POST `{cart_id, delivery_address}` → 201; response keys `== {"orders"}`; `len(orders) == 2`; each order's `store` ∈ its tenant's store; items partitioned correctly; per-order `subtotal`/`total` == group line-total sums; `tenant_id` matches; cart emptied; both orders' `user` = caller.
   - `test_split_single_tenant_group` — cart with only tenant-A items → `len(orders) == 1`.
   - `test_split_rejects_null_tenant_items` — add a `tenant_id=None` product to the cart → 400, error contains "Some items can't be ordered right now.".
   - `test_split_failure_leaves_no_orders` — deactivate tenant-B's only store → POST → 400; `Order.objects.count()` unchanged; cart items intact (all-or-nothing at resolution stage).
   - `test_split_requires_store_omitted_for_split` — with `store` present → legacy path (single object response, existing shape) — pin compat.
   - `test_list_orders_exposes_store_name` — list response includes `store_name`.
2. Run orders tests → **EXPECTED: FAIL** (store required → 400; no `orders` key; no `store_name`).
3. Implement:
   - `backend/orders/serializers.py` `OrderCreateSerializer`: `Meta.extra_kwargs = {"store": {"required": False}}`; add `store_name = serializers.CharField(source="store.name", read_only=True)` to `OrderListSerializer`.
   - `backend/orders/views.py`: override `create(self, request, *args, **kwargs)`:
     - validate serializer (raises 400 on bad cart/empty);
     - if `store` in validated_data → run existing `perform_create` logic verbatim, return single-object response (legacy);
     - else split path (all inside `transaction.atomic()`):
       a. group `cart.items.select_related("variant__product")` by `variant.product.tenant_id`; any `None` group → `ValidationError({"cart_id": "Some items can't be ordered right now."})`;
       b. resolve store per group: `Store.objects.filter(tenant_id=gid, is_active=True, is_platform=False).order_by("name").first()`; missing → same-style 400 error (`{"cart_id": "Some items can't be ordered right now."}`);
       c. per group: create Order (`user`, `store`, `tenant=store.tenant`, `subtotal=sum(line_totals)`, `total=same`, `delivery_address`, `delivery_instructions` from validated data) + its OrderItems (same field mapping as legacy loop);
       d. clear cart once; return `Response({"orders": [OrderListSerializer(o).data for o in orders]}, status=201)`.
     - Legacy `perform_create` keeps the platform-store guard from Task 1.
4. Run orders tests → **EXPECTED: PASS**. Full suite → PASS (legacy tests unchanged).
5. Commit: `feat: split-order creation (one order per seller) with legacy mode preserved`

**Test command:** `$env:DATABASE_URL='sqlite:///db.sqlite3'; .venv\Scripts\python.exe backend\manage.py test orders`

## Task 5: customer-web platform fetch + brand

**Goal:** app always renders the platform storefront, branded EASYGET.

### Steps

1. `customer-web/src/services/api.ts`: add `export const getPlatformStorefront = () => api<StorefrontPayload>("/storefront/platform/");` (keep `getStorefront` — Flutter-irrelevant but other callers? grep at edit time; it becomes unused in web → remove only if unreferenced).
2. `customer-web/src/context/StorefrontContext.tsx`: replace slug machinery — drop `slug`, `setSlug`, `slugFromHash`, localStorage, hash-follow effect; state fetches `getPlatformStorefront()` on mount+tick. Ctx becomes `{ data, loading, error, reload }`. Update default context object.
3. Grep consumers: `App.tsx:37`, `HomePage.tsx:20` use `{data, loading, error}` only → safe. Remove any `slugFromHash` imports if present elsewhere (grep first).
4. Branding: `customer-web/index.html` `<title>` → `EASYGET`; `App.tsx:126` loading text → `EASYGET`; `App.tsx:97` fallback → `EASYGET`; `App.tsx:247` footer `<b>EasyGet</b>` → `<b>EASYGET</b>`.
5. `ProductPage.tsx` seller box (~line 296): read block first; replace hardcoded `EasyGet Retail` with a neutral platform line containing no merchant name (e.g. label `Sold by` value `<b>EASYGET</b>` or plain platform line matching surrounding markup).
6. Clear stale `eg-cust-store` leftovers: add `"eg-cust-store"` removal to `purgeLocalUserData()` in `customer-web/src/utils/history.ts` (one line — keeps logout purge complete).
7. `cd customer-web && npm run build` → **EXPECTED: tsc + vite pass** (RED gate: type errors if Ctx consumers missed — fix any reported).
8. Commit: `feat: customer-web renders the EASYGET platform storefront`

**Test command:** `npm run build` (workdir `customer-web`)

## Task 6: cart grouping + checkout split + orders seller line

**Goal:** seller visible exactly in cart/checkout/orders; checkout places split orders.

### Steps

1. `api.ts`:
   - `CartItem` type += `tenant_id: number | null; seller_name: string;`
   - `OrderCreateInput.store` → `store?: number`
   - `createOrder` return type → `Promise<{ orders?: Order[] } & Partial<OrderDetail>>` (split: `{orders}`; legacy: echo payload).
2. `CartPage.tsx`: group `items` by `tenant_id ?? "__none"`; render per-group header `Sold by {seller_name}` + group subtotal line; keep qty/remove/trash per line; summary panel unchanged (cart subtotal is global). Simple inline grouping (no new deps); add a small style if needed in `styles.css` (reuse `panel`/`summary-line` classes — no new CSS unless necessary).
3. `CheckoutPage.tsx`:
   - Remove `listStores`, `stores` state, `Store` import, the "No active store" branch, and `store:` from the createOrder body.
   - Review panel: derive groups from cart items (`tenant_id`/`seller_name`); when >1 group, render an info line `This will be placed as N orders — one per seller.` above the item list; group items under `Sold by X` headings (mirrors cart).
   - `placeOrder`: POST `{cart_id, delivery_address, delivery_instructions}` → if `res.orders?.length`: toast `"{N} order(s) placed! 🎉"`, `navigate("orders")`; else fall back to old newest-order resolution (defensive).
4. `OrdersPage.tsx`: list meta (line ~56) `o.store_name ?? "Store"` → `Seller: {o.store_name ?? "EASYGET"}`; order detail: add `Seller: {order.store_name}` line in the summary panel.
5. `npm run build` → **EXPECTED: pass**.
6. Commit: `feat: seller grouping in cart/checkout + split order placement UX`

**Test command:** `npm run build` (workdir `customer-web`)

## Task 7: admin-web designer staff-only + platform targeting

**Goal:** designer edits the platform storefront, hidden from merchants.

### Steps

1. Read `admin-web/src/App.tsx` nav/shell (NAV at ~15-22, render ~95, route dispatch ~57). Filter: the `storefront` NAV entry renders only when `role === "ADMIN"`; route dispatch guards `route === "storefront" && role === "ADMIN"` (else fall through to dashboard/blank).
2. Read `admin-web/src/pages/StorefrontPage.tsx` (~51-71, ~259). Change default store resolution: after `listStores()`, prefer the row with `is_platform === true` as the initial slug (fallback: localStorage `eg-store`, then first store). Replace the unguarded "first store" auto-select (lines 64-66) with platform preference. Keep the store selector (staff-only page now).
3. `admin-web/src/services/api.ts:271` `getStoreSlug()` fallback `"rahuls-store"` → `"easyget"`.
4. Confirm `Store` type in admin api includes `is_platform?: boolean` (add if typed).
5. `npm run build` (admin-web) → **EXPECTED: pass**.
6. Commit: `feat: storefront designer is staff-only and targets the platform store`

**Test command:** `npm run build` (workdir `admin-web`)

## Task 8: full verification + live smoke + docs + push

**Goal:** prove the whole feature end-to-end; update workflow docs; push.

### Steps

1. Full backend suite (all labels) → **EXPECTED: all green (221 + new tests; 1 skipped)** — record the exact number.
2. Both builds (`customer-web`, `admin-web`) → pass.
3. Restart backend server; live smoke (PowerShell `Invoke-WebRequest`/`Invoke-RestMethod`):
   - `GET /api/v1/storefront/platform/` → 200, `store.name == "EASYGET"`.
   - `GET /api/v1/storefront/rahuls-store/` → 200 (legacy slug intact), store name now "EasyGet Demo Store".
   - Customer login → `GET /api/v1/stores/` → no `easyget` row.
   - Store-less cart (add any product) → `GET /api/v1/cart/` items carry `tenant_id` + `seller_name == "EasyGet Demo Store"`.
   - Split mode: `POST /api/v1/orders/ {cart_id, delivery_address}` → 201 `{orders:[...]}` length ≥ 1 (single live tenant; multi-tenant proof lives in tests).
   - Legacy mode: fresh cart → `POST {cart_id, store, delivery_address}` → 201 single object echo (Flutter-compat proof).
   - Login as merchant → admin storefront API PATCH on platform store's theme → 403 (staff-only proof).
   - `GET /` customer app → HTML title contains `EASYGET` (vite dev/preview on :3000 or dist served — use whatever serves it; if only dev server, check its index).
4. Docs: `currentUpdate.md` — new `## 0. LATEST — EASYGET platform storefront + split orders` section (decisions D1-D6, what changed, verification numbers); `GitCheck.md` — changelog rows for every commit of this plan.
5. Commit: `docs: record platform-storefront commit hashes + status`; `rtk git push`.
6. Ledger: note push + final counts.

**Test command:** `$env:DATABASE_URL='sqlite:///db.sqlite3'; .venv\Scripts\python.exe backend\manage.py test admin_panel analytics cart categories common delivery inventory notifications orders payments products pwa realtime search storefront stores tenants users webhooks`

## Review Focus (for final reviewer)

Input classes/failure modes this plan's tests do NOT exercise — check each deliberately:

1. **Live multi-tenant split E2E** — tests cover it on sqlite; Supabase Postgres transaction behavior + order_number collision risk (`EZG-YYYYMMDD-XXXX` random, unique, no retry loop) under multi-order creation.
2. **Flutter back-compat reasoning** — no Flutter test runs; verify by code inspection that slug route, legacy `{store}` order mode, and `rahuls-store` slug all remain.
3. **Exclusion audit completeness** — any `Store` queryset reachable by non-staff/order flow that still surfaces the platform row (customer pickers, `?lat&lng` distance branch, admin surfaces for merchants).
4. **Cart legacy residue** — carts that still carry `store`/`tenant` (old rows, legacy Flutter carts) flowing through split mode: grouping ignores `cart.store`; is any validation lost that mattered?
5. **Seller-name resolution N+1 / correctness** — SerializerMethodField per line; multi-store tenants pick first-by-name (stock may live in another store — accepted per spec §7).
6. **Frontend group-key edge** — `tenant_id: null` items (platform products) group under `__none`/null; seller fallback rendering; checkout >1 group UX copy.
7. **Admin deep-link** — `#/storefront` route guard for merchant role; stale localStorage `eg-store` pointing at a merchant store.
