# CURRENT UPDATE — EASYGET

**Last updated:** 2026-09-24
**Phase in progress:** Run support — Flutter web enabled (Chrome), products ordering fix; backend served full live journey
**Source of truth:** README.md (whole roadmap) + GitCheck.md (git/github) + docs/phase-1-foundation-spec.md (Phase 1 spec) + this file (live status)

> Read **GitCheck.md FIRST**, then THIS file, then README.md, whenever starting work. This file is the latest snapshot of what exists, what works, what is broken, and what comes next.
> **WORKFLOW RULE:** after every code/commit change, BOTH `currentUpdate.md` and `GitCheck.md` must be updated together.

---

## 0. LATEST — Flutter app (2026-09-23): analyzer zero, APK built ✅

**Stack (latest, researched 2026-09):** `flutter_riverpod ^3.0.0` (resolved 3.3.2 — Notifier/AsyncNotifier, no codegen; 3.4+ needs newer Dart), `go_router 17.5.0`, `dio`, `flutter_secure_storage 10.3.4`, `cached_network_image`, `intl`. Pinned below versions needing a newer SDK than local Flutter 3.38 / Dart 3.10.

**Clean architecture (`lib/src/`):** `core/` (config incl. emulator-aware API_BASE, Dio client with JWT + one-shot 401 refresh, secure TokenStore, Material3 light/dark theme, skeleton/error/empty states, product card, INR/date format) + `routing/` (auth-gated GoRouter, bottom-tab shell with live cart badge, custom fade/rise transitions) + `features/` (auth login/register/OTP, home merchant-themed storefront sections, browse filters + Load-more, search + suggestions + SQLite fallback, product detail carousel + variants + qty, cart swipe-to-delete + steppers, checkout addresses + store picker + place-order, orders + detail timeline + cancel, account + address CRUD).

**Fixes on the way:** 30 analyzer issues → 0 (Riverpod 3 API: `.value` not `.valueOrNull`, `AsyncNotifierProvider.autoDispose`, RadioGroup refactor, unescaped `$` in RegExp); regenerated `android/` scaffold (Gradle mismatch), fixed malformed NDK download; deleted stale scaffold widget test. `flutter build apk --debug` ✅ produces `app-debug.apk`. Not yet click-tested on a live device.

## 0. LATEST — Order Engine (2026-09-23): fulfilment queue + 3 layout fixes

**Stack (latest, researched 2026-09):** `flutter_riverpod ^3.0.0` (Notifier/AsyncNotifier, no codegen), `go_router ^17.0.0` (StatefulShell tabs + custom fade/rise transitions), `dio ^5.7.0` (JWT interceptor + one-shot 401 refresh), `flutter_secure_storage ^10.0.0`, `cached_network_image ^3.4.1`, `intl`. Pinned below Riverpod 3.4/go_router 18 (need newer Dart than the local 3.10.7). `flutter pub get` ✅ resolved.

**Clean architecture (`lib/src/`):** `core/` (config, network(ApiClient+ApiException), storage(TokenStore), theme light/dark Material3, widgets, utils) + `routing/` (auth-gated GoRouter, bottom-tab shell with cart badge) + `features/` (auth, home/storefront-sections, catalog browse+Load-more/search+suggestions/product-detail, cart, checkout addresses+place-order, orders list/detail/cancel+timeline, account/addresses). ~30 files.

**NOT done:** `flutter analyze` reports **30 issues** (real errors: `valueOrNull` isn't on this Riverpod's AsyncValue, `AutoDisposeAsyncNotifier` API shape, one `//`-in-Dart typo already fixed, RadioListTile deprecations, unused imports). Nothing committed — fix analyzer to zero, then `flutter build apk`, then click-test vs Supabase, then commit.

## 0. LATEST — Order Engine (2026-09-23): fulfilment queue + 3 layout fixes

**Admin layout fixes (admin-web):**
1. **Modal off-screen (`#/inventory`):** root cause was NOT `absolute` positioning — `.overlay` was already `position: fixed`. The fragility was rendering the overlay inside `.content` (animated/transformable ancestor), which can re-anchor `fixed` to the document. Fixed by portaling `Modal` to `document.body` (`ui.tsx` via `createPortal`) + body scroll-lock + `overflow-y: auto` on the overlay.
2. **Storefront horizontal overflow:** the board+theme grid used `grid-template-columns: 1fr 300px` — `1fr` has implicit `min-width: auto`, forcing page-wide overflow. Replaced with `.sf-layout` (`minmax(0,1fr) 300px`), collapses to one column under 1100px; section title input `min-width: 140px` → `0` with ellipsis.
3. **Sidebar squish:** same grid blowout pushed the page grid wider than the viewport. Fixed at source (above) + `.main { overflow-x: clip }` guard (clip keeps sticky topbar working, unlike hidden).
4. Product names: stripped trailing `|` from all 200 Supabase products + `shop_stock_checklist.json` source.

**Order Engine (fulfilment queue):** new `OrdersPage` in admin-web (`#/orders`, NAV + Dashboard card link): status filter pills with counts, orders table, detail modal with items + status timeline + advance-status (mirrors backend transition map) + cancel-with-reason. Uses existing `/api/v1/orders/` staff endpoints — no backend change. Verified live: staff sees 1 order. `npm run build` passes.

## 0. LATEST — Phase 3 progress (2026-09-22): Supabase verified + products perf fix

**2026-09-22 (continuation after Freebuff limit):** Supabase `EasyGET` verified live against Django — `health ok`, `admin@easyget.local` created (ADMIN/staff/superuser, `EasyGet!2026`), `dashboard ok (users 3, products 200)`, `stores 1`, `categories 10`, `storefront/rahuls-store 4 sections`, `products 200 in ~3.5s`. Fixed products list N+1 for remote DB: `ProductViewSet.get_queryset` now `prefetch_related("variants","images")`, `ProductListSerializer` uses annotated `min_variant_price` + prefetched images cache for `primary_image` (was per-row `.filter().first()` queries → timeout on Supabase pooler). Affected tests: `products+stores+categories+tenants` → 31 pass (SQLite). Both webs `npm run build` pass. Next: commit Phase-3 chunks, then Cart/Orders tenant-wiring + `/products/` pagination.

## 0. LATEST — Phase 3 progress (2026-09-20): tenancy foundation + catalog seeding

**Baseline inherited this session:** 14 generated apps (`stores`, `categories`, `products`, `inventory`, plus later-phase `cart`/`orders`/`payments`/…) sat untracked on `phase-3-store-product-inventory`, wired into `INSTALLED_APPS`, with **no tenant model anywhere** and `Store` having no owner. Baseline suite: 98 tests, **16 broken**.

### 0.1 Bugs found & fixed in the generated baseline

| # | Symptom | Root cause | Fix |
|---|---|---|---|
| 1 | Every endpoint 500 (incl. `/health/`) | Global DRF throttles + `django_ratelimit` ran on django_redis; local Redis port answers with an incompatible protocol (`unknown command 'HELLO'`) | `IGNORE_EXCEPTIONS: True` on the cache (fail soft → cache miss, not 500); `/health/` explicitly unthrottled |
| 2 | Product API only at `/api/v1/products/products/` | Router registered prefix `"products"` under `/api/v1/products/` | Router now registers `""` |
| 3 | `min_price`/`max_price` filters crashed (`FieldError`) | Filtering on the `base_price` **python property** | `Min()` annotation over active variant prices |
| 4 | `GET /products/{slug}/` would crash | Image serializer referenced `alt_text`; model field is `caption` | `caption` |
| 5 | Any `StockItem` save → 500 | realtime `post_save` signal used non-existent `Store.managers` | Push once to the store's realtime group |
| 6 | `POST /stores/` unusable | All-read-only *list* serializer used for create | Proper write serializer; write responses now include `id`/`slug` |

### 0.2 Multi-tenancy foundation (per PROJECT.md §3.3, with one documented deviation)

- **New `tenants` app**: `Tenant`, `TenantMembership` (roles `OWNER`/`MANAGER`, unique per tenant+user).
- **Deviation from §3.3 step 2 (middleware):** a Django middleware cannot see JWT users (auth happens at DRF view time, `request.user` is anonymous there). The same server-side guarantee — resolve tenant from *verified server-side membership, never client headers* — is implemented as **permission classes + services** (`tenants/permissions.py`: `IsTenantWriter`, `IsTenantObjectAdmin`, `IsTenantObjectMember`; `tenants/services.py`: `is_tenant_member`, `is_tenant_admin`, `resolve_tenant_for_create`, `provision_tenant`).
- **Ownership per model (not a blind FK spray):** direct tenant FK on `Store`, `Product`, `StockItem` (denormalized from `store.tenant`); variants/images **inherit** via product; `Category` stays a shared **platform taxonomy** (deliberate — one taxonomy, many merchants); `User`/memberships stay tenant-free.
- **Merchant onboarding:** `POST /api/v1/stores/` by a verified user auto-provisions a tenant + OWNER membership, or links the creator's existing single membership (multi-store merchants work).
- **Write rules:** store PATCH/DELETE → tenant OWNER or platform staff; product PATCH/DELETE → tenant member or staff; stock create/adjust → member of the item's tenant (cross-tenant store+variant combos → 400; foreign items → **404, no existence leak**).
- **Read rules:** product visibility = own tenant catalog (incl. inactive) ∪ active products stocked by an active store (merchant catalogs stay private until actually sold); inventory/transactions scoped the same way; staff bypasses.
- **Stock adjust** now runs under `select_for_update` row lock, keeps quantity ≥ 0, and writes an `InventoryTransaction` audit row.
- **Migrations:** `tenants.0001`; `stores.0002`, `products.0002`, `inventory.0002` (tenant FKs nullable → legacy rows stay valid); applied to the dev `db.sqlite3`.
- **Tests:** +22 tenancy/isolation tests (Store B can never read/write Store A) → **suite: 120 pass, 1 skipped**.

### 0.3 Catalog seeded from the Shop Stock Checklist

`python manage.py seed_shop_catalog --owner-email manual2@example.com --store-name "Rahul's Store"` → tenant `Rahul's Store` (owner `manual2@example.com`), store `rahuls-store`, **10 categories / 200 products / 200 variants / 200 stock items** from `Shop_Stock_Checklist_README.md`. Idempotent (safe to re-run), `--dry-run` supported. Variant prices are a `0.00` placeholder (`--default-price`) and stock starts at 10 (`--quantity`) until real prices/counts are set.

### 0.4 Admin dashboard UI landed (admin-web, 2026-09-20)

- **Full SPA on React+Vite+TS, zero new dependencies** — hand-rolled router (hash-based), design system in plain CSS.
- **Dual theme (light/dark)** with pre-paint flash prevention, animated toggle, persisted in localStorage.
- **Pages**: Login (JWT, refresh-on-401 with auto-relogin handling), Overview (live stats from `/admin/dashboard/`), Categories (CRUD + search), Products (CRUD + category filter, create adds default variant), Inventory (stock table + adjust modal writing audit-trailed adjustments), **Storefront designer**.
- **Storefront designer = the client's no-code editor**: drag-and-drop reorder of sections and items (native HTML5 DnD → `/reorder/` endpoints), inline rename (contentEditable → PATCH), section Design modal (columns 1–6, size sm/md/lg, effect pills, placeholder text), theme panel (colors, button style, font → PATCH theme), add section/item pickers, hide/show toggles.
- **Backend fixes found during live testing**: `/api/v1/admin/` route order fixed (admin_panel router must precede `users.admin_urls`, else Django 404s and never falls through); refresh endpoint is `/auth/refresh/` (UI had a wrong URL causing silent logouts); dashboard action URL is `/admin/dashboard/`.
- **Dev accounts**: `admin@easyget.local` / `EasyGet!2026` (superuser, created locally); UI runs at `http://localhost:5174`, API at `127.0.0.1:8000`.
- `npm run build` passes (tsc --noEmit + vite build); verified end-to-end in the live preview (login → dashboard → storefront editor drag/rename/theme flows).

### 0.5 Still open for Phase 3

- `cart`/`orders`/`payments`/… apps exist as models+endpoints but are **not tenant-wired yet** — per §3.3 they get ownership in their own phases (model-by-model, with migrations + tests per batch).
- Nothing committed yet — the branch working tree holds this whole change set.
- Redis/Celery/Channels remain blocked (no Docker) — now **fail-soft** instead of fatal.

---

## 0a. PREVIOUSLY COMPLETED — Phase 2: Authentication & Users (✅ done on `phase-2-auth`)

**Built & merged to `main` (README Phase 2 checklist passing):**

- Custom `User` model (`AUTH_USER_MODEL = "users.User"`), email login (`USERNAME_FIELD = email`), unique email
- Roles via `User.Role.TextChoices`: `CUSTOMER` (default), `ADMIN`, `STORE_MANAGER`, `DELIVERY_AGENT`; Django `auth.Permission` retained for group perms
- JWT auth (`djangorestframework-simplejwt==5.5.0`) + `token_blacklist` → logout/blacklist verified working
- OTP via `OTPCode` model (6-digit, 10-min expiry, 5-attempt cap); dev email = console backend; verified end-to-end over live HTTP
- Users are active but **must verify email before login** (`is_email_verified`)
- DRF defaults changed: `DEFAULT_AUTHENTICATION_CLASSES = JWTAuthentication`, `DEFAULT_PERMISSION_CLASSES = IsAuthenticated` → **health endpoint made explicitly public** (`@permission_classes([AllowAny])`)
- Tests: **18/18 pass** (was 3 before)

**Verified live (12 checks):** register 201 ✔ OTP verify ✔ login tokens ✔ /users/me GET+PATCH ✔ addresses (1st auto-default, set-default works, exactly 1 default) ✔ admin-only → 403 for CUSTOMER ✔ logout ✔ refresh-after-logout → 401 ✔ pre-verify login → 400 ✔.

**API surface** (all `/api/v1/`): `auth/register|verify-otp|resend-otp|login|refresh|logout`, `users/me`, `users/me/addresses` (+`/set-default/`), `admin/only` (probe).

**Next → Phase 3 per Recommended Build Order: Store + Product + Inventory** — categories, products(+variants), images, and per-store inventory models.

---

## 1. Latest Work (last session)

Verified and repaired the Phase 1 foundation end-to-end:

- Installed Python dependencies into `.venv` (`pip install -r requirements.txt` succeeded after an earlier network failure).
- Confirmed backend passes `manage.py check` with a valid `.env` (created from `.env.example`). Image check → **`System check identified no issues (0 silenced)`**.
- Confirmed all **3 backend tests pass** (`manage.py test`, run from `backend/`):
  - `/api/v1/health/` returns 200 JSON `{"status":"ok","service":"easyget-api"}`
  - CORS allows `http://localhost:5173`
  - CORS blocks unknown origins
- Live-checked the server: `GET /api/v1/health/` → `{"status":"ok","service":"easyget-api"}` over real HTTP.
- Fixed both React apps so CI-style `npm run build` passes (see Errors below).
- `flutter pub get` + `flutter analyze` → **No issues found** (Flutter 3.38.7 stable).
- Set up git + GitHub for `trisentricai/EasyGet` (see GitCheck.md): repo-local identity, branch `master`→`main`, SSH remote `origin`, `.gitignore` now excludes `.kilo/` and `*.log`, initial foundation commit + push to `main`.

## 1a. Git / GitHub state

| Item | Value |
|---|---|
| Branch | `main` (baseline foundation commit `66bc53a` landed 2026-09-19) |
| Remote | `origin = git@github.com:trisentricai/EasyGet.git` (SSH) |
| Auth | SSH verified (`rahulbharathi1921` authenticated successfully) |
| Identity (repo-local) | Rahul Bharathi <mailtorahulbharathi@gmail.com> |
| Working branch model | `main` stable; per-phase branches (`phase-2-auth`, …) merged in when checklist passes |
| Full reference | see `GitCheck.md` |

## 2. Errors Found & Fixed

| # | Error | Root cause | Fix |
|---|---|---|---|
| 1 | `.kilo/pip-install-error.log`: Django download failed (`WinError 32`, read timeouts) | Interrupted network / file-in-use during prior pip install; venv had **no packages** | Re-ran `pip install -r requirements.txt` |
| 2 | `customer-web` build: `Unable to resolve @typescript/typescript-win32-x64` | TypeScript native platform binary (optional dep) missing from `node_modules` | `npm install` (added 2 packages) |
| 3 | `admin-web` build: `'tsc' is not recognized` | `npm install` never ran for `admin-web` (no `node_modules`) | `npm install` (added 24 packages) |
| 4 | Both React builds: `TS2882 Cannot find module or type declarations for side-effect import of './styles.css'` | Missing Vite client type decls (standard `vite-env.d.ts`) | Added `src/vite-env.d.ts` with `/// <reference types="vite/client" />` in **both** apps |

## 3. Known Open Issue (not a code bug)

- **Docker is NOT installed** on this machine, so local PostgreSQL and Redis cannot run via `docker-compose.yml`.
- Because `.env` sets `DATABASE_URL=postgresql://easyget:easyget@localhost:5432/easyget` and Postgres isn't running, any Django command that touches the DB (`runserver`, `test`, `migrate`) **hangs** (psycopg connect stalls instead of failing fast).
- Workaround for pure-backend work: `$env:DATABASE_URL="sqlite:///db.sqlite3"` (this is how the backend was verified).
- Celery worker check remains **blocked** (needs Redis).

## 4. Phase 1 Status Checklist

Source: README.md Phase 1 Manual Test Checklist + docs/phase-1-foundation-spec.md acceptance criteria.

| Check | Status | Evidence |
|---|---|---|
| Four app roots exist (`backend`, `customer-web`, `admin-web`, `customer-app`) | ✅ Done | directory structure below |
| Django dev server starts with no errors | ✅ Done | `manage.py check` + live run |
| Test DRF endpoint returns valid JSON | ✅ Done | 3/3 tests pass, live HTTP check |
| Database connection (PostgreSQL/Supabase) | ⛔ BLOCKED | Docker not installed; Postgres unreachable |
| Redis connection | ⛔ BLOCKED | Docker not installed |
| Celery worker starts, test task executes | ⛔ BLOCKED | needs Redis |
| `.env` loads; values differ dev/staging | ⚠️ Partial | `.env` loads ✅; **no per-env settings split** (only `settings/base.py`) |
| CORS allows local Flutter/React origins, blocks others | ✅ Done | tested in `common/tests.py` |
| Git repo + sensible `.gitignore` | ✅ Done | `.gitignore` good |
| CI pipeline runs on push | ⚠️ NOT YET | `.github/workflows/ci.yml` exists ✅ but repo has **ZERO commits** → no push → CI never ran |
| Flutter app builds/runs | ✅ Done (analyze) | `flutter analyze` clean; device run not tested |
| React apps build/run locally | ✅ Done | `npm run build` passes both |

**Phase 1 remaining before moving to Phase 2:**
1. Initial git commit (and push) so CI actually runs.
2. Decide env split (dev/staging/production settings) — or accept single `settings/base.py` for now.
3. Install Docker locally when access to Postgres/Redis/Celery verification is needed (or run Postgres/Redis another way).

## 5. Clean Architecture — File System

### Repository root
```
EasyGet/
├── README.md                    # Full product roadmap + phases (0–15)
├── currentUpdate.md             # THIS FILE — live status/architecture snapshot
├── requirements.txt             # Python deps (Django 5.2, DRF, simplejwt, cors, environ, celery, redis, psycopg)
├── .env.example                 # Env template — placeholders ONLY, no secrets
├── .env                         # Local env (gitignored, created from example)
├── .gitignore
├── docker-compose.yml           # Local Postgres 16 + Redis 7 (for when Docker is available)
├── .github/workflows/ci.yml     # CI: backend checks+tests, customer-web build, admin-web build
├── .kilo/                       # Install/log artifacts (pip logs)
│
├── backend/                     # Django REST API (modular monolith, split by business domain)
│   ├── manage.py
│   ├── config/                  # Project configuration package
│   │   ├── settings/
│   │   │   ├── __init__.py      # imports * from base
│   │   │   └── base.py          # env, DRF (JWT), CORS, SIMPLE_JWT, email, Celery/Redis
│   │   ├── urls.py              # /admin/ + /api/v1/{auth,users,admin,health}
│   │   ├── wsgi.py / asgi.py
│   │   └── celery.py            # Celery app "easyget", autodiscover_tasks
│   ├── common/                  # Shared/health app
│   │   ├── views.py             # GET /api/v1/health/ (public)
│   │   ├── urls.py
│   │   └── tests.py             # 3 health + CORS tests
│   ├── users/                   # Phase 2 — Auth & Users
│   │   ├── models.py            # User (roles), Address, OTPCode
│   │   ├── admin.py
│   │   ├── permissions.py       # IsVerifiedEmail, role_required, IsAdminOnly
│   │   ├── serializers.py       # Register/Verify/Login/Logout/User/Address
│   │   ├── services.py          # send_otp_email
│   │   ├── auth_views.py        # register/verify-otp/resend-otp/login/logout
│   │   ├── views.py             # MeView, AddressViewSet(+set-default), AdminOnlyView
│   │   ├── urls.py / auth_urls.py / admin_urls.py
│   │   ├── tests.py             # 12 auth + profile/address/RBAC tests
│   │   └── migrations/
│   └── (future domain apps...)  # stores, products, inventory, cart,
│                                # orders, payments, delivery, coupons, notifications, reviews
│
├── customer-web/                # React (Vite+TS) — customer web app
│   ├── package.json             # dev :5173, build = tsc --noEmit && vite build
│   ├── tsconfig.json
│   ├── index.html
│   └── src/
│       ├── main.tsx             # EASYGET starter screen (Phase 2 ready)
│       ├── styles.css
│       └── vite-env.d.ts        # Vite client types (added this session)
│
├── admin-web/                   # React (Vite+TS) — admin dashboard
│   ├── package.json             # dev :5174, build = tsc --noEmit && vite build
│   ├── tsconfig.json
│   ├── index.html
│   └── src/
│       ├── main.tsx             # EASYGET ADMIN starter screen (Phase 8 ready)
│       ├── styles.css
│       └── vite-env.d.ts        # Vite client types (added this session)
│
├── customer-app/                # Flutter — customer mobile app
│   ├── pubspec.yaml             # SDK >=3.3.0, flutter_lints, Material 3
│   └── lib/
│       └── main.dart            # EASYGET starter screen
│
└── docs/
    ├── phase-1-foundation-spec.md   # Phase 1 FR/NFR/acceptance criteria
    └── local-development.md         # First-run + local endpoint reference
```

### Frontend target layout (follow when Phase 2+ UI grows)
```
Flutter lib/                 React src/
├── core/                    ├── components/
├── features/                ├── features/
├── models/                  ├── pages/
├── services/                ├── services/
├── routing/                 ├── hooks/
└── widgets/                 ├── layouts/
                             └── utils/
```

### Backend domain split (already reflected in README, create apps as phases land)
Balance: `users` ✅ (Ph.2) → `stores`/`categories`/`products`/`inventory` (Ph.3) → `cart` (Ph.5) → `orders` (Ph.6) → `payments` (Ph.7) → `delivery`/`coupons`/`notifications`/`reviews` (later).

## 6. Ports & Commands

| Service | Local URL |
|---|---|
| Django API | `http://127.0.0.1:8000/api/v1/` (health → `/health/`) |
| Customer web | `http://localhost:5173` |
| Admin web | `http://localhost:5174` |

```powershell
# Backend (from repo root) — use SQLite override until Docker/Postgres is up:
$env:DATABASE_URL = "sqlite:///db.sqlite3"
& .\.venv\Scripts\python.exe backend\manage.py migrate
& .\.venv\Scripts\python.exe backend\manage.py check
& .\.venv\Scripts\python.exe backend\manage.py test          # note: run from backend/ dir or use --pattern
& .\.venv\Scripts\python.exe backend\manage.py runserver

# Frontends
cd customer-web; npm install; npm run build   # or npm run dev
cd admin-web;    npm install; npm run build   # or npm run dev

# Flutter
cd customer-app; flutter pub get; flutter analyze; flutter run

# Services (when Docker is installed)
docker compose up -d postgres redis
```

## 7. Guardrails / Gotchas (learned)

- **Run `manage.py test`/management commands from `backend/`** (or pass labels); from repo root test discovery finds 0 tests.
- **`.env` is gitignored** but required: without it, `DJANGO_DEBUG` defaults to `false` → `RuntimeError: DJANGO_SECRET_KEY must be set` (safe-fail by design, EC-3). Copy `.env.example` → `.env` and keep `DJANGO_DEBUG=true` locally.
- **Keep `DJANGO_DEBUG=false` in any prod-like env** — SECRET_KEY required there.
- Backend is the source of truth for pricing/payments (Phases 5–7) — never trust client prices.
- `requirements.txt` is at repo root (CI runs `pip install -r ../requirements.txt` from `backend/`).
- DRF now defaults to **JWT + IsAuthenticated**: every view either uses it or explicitly opts out (`authenticate_classes=[]`/`AllowAny` on register/verify/login/logout/health).
- Only `users.*` domain models exist post-Phase 2 — **do not** assume models for stores/products/orders until those phases land.
- Never commit `.env` or secrets; `.env.*` except `.env.example` is gitignored.