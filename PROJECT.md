# EASYGET — Project Overview & Development Record

> **A quick-commerce (q-commerce) SaaS platform: multi-store catalog, near-store delivery, visual website builder.**

This is the **capstone** reference for the EASYGET repository. It answers three questions:

1. **WHY** does EASYGET exist?
2. **WHAT** is EASYGET?
3. **HOW** was EASYGET created?

`PROJECT.md` complements the other repository docs:

| File | Purpose |
| --- | --- |
| `README.md` | The full product roadmap + phase-by-phase checklist (Phases 0-15) |
| `currentUpdate.md` | Live, day-by-day status of what exists / what works / what is broken |
| `GitCheck.md` | Git & GitHub workflow reference (branches, commits, SSH) |
| `docs/phase-1-foundation-spec.md` | Phase 1 functional requirements, NFRs and acceptance criteria |

---

## 1. WHY does EASYGET exist?

### 1.1 The problem

Shopping essentials in dense cities has a hard trade-off:

- **Supermarkets / big-box merchants** have great prices and wide selection, but they are *far away*, slow, and wasteful (bulk minimums, 2-hour+ delivery).
- **Local neighborhood stores / kirana / mom-and-pop shops** are *near*, but their catalog is not online. Customers cannot browse or pre-order; discovery is word-of-mouth; they lose sales when a customer cannot find them online.
- **Marketplaces (Amazon / Flipkart / big quick-commerce apps)** give discovery and speed but charge heavy commissions legendary margins, bury small stores behind their brand, and do not let a merchant own their storefront.
- **Building a custom store is technically hard.** A small merchant does not have the money or skill to build a website, an app, an inventory system, and a delivery fleet.

### 1.2 The EASYGET answer

EASYGET gives every neighborhood store a **turnkey online presence** without forcing them to become a tech company:

- A **multi-store catalog** — many independent merchants on one platform, each owning their storefront.
- **Near-store delivery** — q-commerce speed (minutes, not hours) by leveraging each store's *physical proximity* to its customers.
- **A visual website builder** — merchants design a storefront (choose theme, colors, layout) with zero code, the way Wix/Shopify let anyone build a site.

EASYGET is a **SaaS**: merchants subscribe, design their store, list products, track inventory, receive and fulfill orders, and deliver — all from one accountcottage. Customers get a single app/web where nearby stores and their real-time availability are visible.

### 1.3 The brand / name

The user-facing product is branded **EASYGET** (repo folders use `easyget`; the API service id is `easyget-api`). The company/org shipping it is **TRISENTRICS AI**, publishing under the GitHub org `trisentricai`.

### 1.4 Product principles (non-negotiable)

- **Multi-tenancy**: every merchant is isolated. Order A must never be visible to Merchant B buying a seat from us. This is the platform's core trust promise.
- **Modular monolith**: one Django service split by business domain, not a fragile microservice zoo — so the team (and CI) ships faster while staying coherent.
- **Vision as the genuine product, builder as the wedge**: the *visual storefront builder* is what differentiates EASYGET from a plain marketplace.
- **Backend is the source of truth** for pricing, payments, inventory, and ownership — never trust the client.

---

## 2. WHAT is EASYGET?

### 2.1 Platform overview

EASYGET is a four-part system:

| Component | Path | Tech | Role |
| --- | --- | --- | --- |
| **Backend API** | `backend/` | Django 5.2, DRF, JWT, Celery, Redis, PostgreSQL | The single source of truth for all business logic |
| **Customer web** | `customer-web/` | React (Vite + TypeScript) | Customer-facing storefront + buy-flow UI |
| **Customer app** | `customer-app/` | Flutter | iOS/Android customer app |
| **Admin web** | `admin-web/` | React (Vite + TypeScript) | Merchant/admin dashboard + **visual store builder** |

All four share one backend. The backend is a **modular monolith** of Django "apps", one per business domain.

### 2.2 Domain apps (backend)

| App | Purpose |
| --- | --- |
| `common` | Health endpoint, shared helpers, CORS policy |
| `users` | Custom User, roles (Customer/Admin/StoreManager/DeliveryAgent), addresses, OTP email verification, JWT auth |
| `admin_panel` | Admin/dashboard-related models & Meta support |
| `webhooks` | Outbound webhook delivery models |
| `pwa` | PWA/manifest app metadata models |
| `stores` | Store entity (the merchant's storefront) |
| `categories` | Product categories within a store |
| `products` | Products + variants + images |
| `inventory` | Per-store live stock levels |
| `cart` | Customer cart |
| `orders` | Orders + line items + status lifecycle |
| `payments` | Payment intents / transactions |
| `notifications` | In-app notifications (emails, in-app) |
| `search` | Product / store search |
| `analytics` | Merchant & platform analytics |
| `realtime` | Live channel layer (ASGI) for pushed updates |

### 2.3 Top-level feature map (roadmap Phases 0-15)

- **Phase 0** — Project init, contracts, tooling (repo, git, docs).
- **Phase 1** — Foundation: 4 app roots scaffolded, /health/, CORS, env config, CI. *(done)*
- **Phase 2** — Auth & Users: custom User, roles, JWT, OTP email verification, addresses. *(done)*
- **Phase 3** — Store + Product + Inventory: multi-store catalog, categories, products, variants, images, per-store inventory.
- **Phase 4** — Cart, checkout pre-work.
- **Phase 5** — Orders & Payments: order lifecycle, payment intents.
- **Phase 6** — Delivery: near-store delivery flow, delivery agents.
- **Phase 7** — Notifications & Search & Analytics & Realtime.
- **Phase 8** — Admin dashboard: analytics, inventory management UI.
- **Phase 9** — **Visual website builder** (customer storefront builder for merchants).
- **Phase 10** — Customer app web + mobile polish.
- **Phases 11-15** — SaaS hardening: webhooks (done as model), PWA (done as model), coupons, reviews, production SAAS (billing, seats), scale.

Note: several domain *models* (webhooks, pwa, admin_panel, notifications, search, analytics, realtime) already exist at the model level; their live business logic/UI lands in the corresponding later phases.

### 2.4 Current capabilities (verified working)

> Updated 2026-09-26 — covers foundation through Phase B1 (marketplace depth).
- **Health endpoint** `GET /api/v1/health/` → `{ "status": "ok", "service": "easyget-api" }` (public).
- **Authentication** (JWT via SimpleJWT, blacklist on logout): register, OTP verify/resend, login, refresh, logout; email-verification gate; profile + addresses (one default enforced); role-based access (CUSTOMER/ADMIN/STORE_MANAGER/DELIVERY_AGENT).
- **Multi-tenancy IS implemented** (`tenants` app: Tenant/TenantMembership, server-side permission classes + services; direct FK on Store/Product/StockItem/Cart/Order/DeliveryAssignment, inheritance for line items/variants/images; User/payment-methods stay platform-level). Cross-tenant reads/writes covered by isolation tests.
- **Catalog**: 200+ products live in Supabase (20 brands, discounted MRPs); products paginated (20/page); filters (category/brand/min-discount/price), sorts incl. **rating**, brands endpoint; search with suggestions + recents/trending + SQLite fallback; admin CRUD; storefront designer (sections/items DnD, theme).
- **Marketplace experience (Flipkart/Meesho-grade)**: themed customer-web (blue header, category strip, offer ticker, banner carousel, rating-pill cards, buy-box PDP, sidebar filters, marketplace footer, mobile bottom nav); **reviews & ratings API** (one per user, masked names, verified-purchase, moderation flags, aggregates); **server-backed wishlist** + `#/wishlist` page; **PDP "Available offers"** from live coupons; **live pincode ETA** (postal API + offline fallback, 2-day same-state heuristic); **admin review moderation** page.
- **Cart → Orders → Payments → Delivery**: full flow verified live on Supabase (confirm → assign agent → accept → pickup → out-for-delivery → delivered, order mirrored). Admin fulfilment queue at `#/orders`.
- **Frontends**: customer-web (`:3000`) and admin-web (`:5174`) — both `npm run build` clean (tsc + vite). Flutter customer app builds (analyzer 0, debug APK); not click-tested on device.
- **Tests: 195 pass** across backend apps (SQLite, 1 skipped); `manage.py check` 0 issues; Redis/Celery fail-soft without Docker.

### 2.5 What is NOT built yet (honest status)

- **No production deployment, no load tests, no verified backups, no SMS/email prod backend, no media CDN.**
- **Coupon apply at checkout**: coupons exist, are displayed on PDPs, but the discount is not yet applied to cart/order totals (Phase C).
- **Payment gateways**: `Payment` model + saved methods are gateway-agnostic but no live Razorpay/Stripe integration; COD is manual (Phase C).
- **Notifications**: models only, no live flow (needs Redis/Celery + Docker).
- **Delivery**: manual assignment only (no auto-assign, no live tracking); returns/refunds UI absent.
- Flutter app not yet click-tested on device; no signed release build; does not yet ship the A2/B1 marketplace features (Phase E).

Do not confuse *model existence* with *feature readiness*: e.g. `webhooks`/`pwa` models exist, but their endpoints, UI, and operations do not yet.

---

## 3. HOW was EASYGET created?

### 3.1 Constraints of the dev environment

The whole build assumes a **single Windows (PowerShell) machine** with these realities:

- **Python** via a virtualenv at `EasyGet/.venv` (packages installed from `requirements.txt`).
- **Node.js** for the two React apps (`npm install`/`npm run build`/`npm run dev`).
- **Flutter SDK** for the customer app (`flutter pub get`, `flutter analyze`, `flutter run`).
- **Docker is NOT installed** on this machine. So PostgreSQL/Redis are unreachable. Workaround: override `DATABASE_URL=sqlite:///db.sqlite3` and `DJANGO_DEBUG=true` for local backend work, or run Django from `backend/` so test discovery works.
- Because `.env` defaults to a Postgres URL and Postgres is not running, any Django command that touches the DB will **hang** (psycopg connect stalls). Use the SQLite override when dependencies are down.

### 3.2 Recommended build order (as planned & executed)

The phases are designed so each leaves the repo in a **working, testable** state:

1. **Phase 0 — Foundation assignment**: repo, Git+GitHub (SSH), `.gitignore`, docs, branch model (`main` + per-phase branches).
2. **Phase 1 — Foundation app**: `backend` (Django + DRF + SimpleJWT + Celery + Redis config + CORS + `/health/`), `customer-web` + `admin-web` (React/Vite/TS starters), `customer-app` (Flutter starter). CI workflow. Env config from `.env` (gitignored, example committed).
3. **Phase 2 — Auth & Users**: custom `User` (email login), roles, OTP email verification, JWT + token blacklist, addresses, RBAC permissions, 18→80 tests. *Merged to `main`.*
4. **Phase 3 — Store + Product + Inventory** ✅: multi-store catalog, per-store inventory — this is where the **multi-tenancy foundation** was designed in (see 3.3).
5. Phases 4-15 as per the roadmap (cart, orders, payments, delivery, notifications/search/analytics/realtime, admin dashboard, builder, SaaS) — cart/orders/payments/delivery/search/admin/dashboard are built; marketplace UX waves A/A2/B1 shipped 2026-09-24..26.

### 3.3 The multi-tenancy sequencing decision (important)

Phase A audit concluded: **do NOT blindly add a `tenant` FK to every model.** Instead ownership must be per-model:

- **Direct tenant-owned** models (e.g. products, inventory, orders) get a tenant FK.
- **Inherited ownership** models (e.g. line items) inherit tenant via their parent.
- **Platform-level** models (e.g. User, Tenant membership, meta/app-update) stay tenant-free.

Recommended order before Phase B migrations:
1. Create a `Tenant` model + `TenantMembership` (who belongs to which tenant) in the new `tenants` app.
2. Tenant **middleware** to resolve the current tenant from the authenticated request (server-side membership verification — never trust client headers alone).
3. Tenant **permission classes** (`IsTenantMember`, `IsTenantAdmin`).
4. Add tenant FKs **model-by-model** (not one mass migration), backfilling ownership per store, with `makemigrations`/`migrate` and per-app tests after each batch.
5. Tenant-isolation tests ensuring Store B can never read Store A data.

### 3.4 Architecture & engineering decisions

- **Modular monolith**, one repo, one CI. Apps map 1:1 to business domains.
- **DRF + SimpleJWT** for auth; `DEFAULT_AUTHENTICATION_CLASSES = JWTAuthentication`, `DEFAULT_PERMISSION_CLASSES = IsAuthenticated`; health endpoint explicitly `AllowAny`.
- **Custom User** with `AUTH_USER_MODEL = "users.User"`, `USERNAME_FIELD = email`; roles as `TextChoices`; Django `auth.Permission` retained for fine-grained group perms.
- **OTP** flow for email verification: 6-digit code, 10-min expiry, 5-attempt cap; console email backend locally, locmem in tests.
- **Celery + Redis** configured for async tasks; **Channels/ASGI** for the realtime layer (blocked until Redis available).
- **CORS** locked to configured origins; unknown origins rejected (tested).
- **env-based config** with `django-environ`; `.env` gitignored; `.env.example` only placeholders; `SECRET_KEY` required when `DJANGO_DEBUG=false` (safe-fail by design).

### 3.5 Conventions used across the codebase

- **Commit style**: `type: short imperative summary` (`feat:` / `fix:` / `chore:` / `docs:` / `refactor:` / `test:`).
- **Branch model**: `main` stable; per-phase branches (`phase-2-auth`, ...) are merged into `main` when their manual checklist passes.
- **Git identity** is repo-local (`Rahul Bharathi <mailtorahulbharathi@gmail.com>`), not global.
- **Docs are the source of truth**: README (roadmap), currentUpdate.md (live status), GitCheck.md (git), this file (overview). Workflow rule: after every code/commit change, BOTH `currentUpdate.md` and `GitCheck.md` must be updated together.
- **Never commit secrets** (`.env`, keys); `.env.*` except `.env.example` is gitignored.

### 3.6 How to run the project (correct commands)

```powershell
# ---- Backend ----
# From repo root. Live DB = Supabase (from .env); use the SQLite override for
# local/migration work if Postgres is unreachable:
$env:DATABASE_URL = "sqlite:///db.sqlite3"
& .\.venv\Scripts\python.exe backend\manage.py migrate      # apply migrations
& .\.venv\Scripts\python.exe backend\manage.py check        # system checks (0 issues)
& .\.venv\Scripts\python.exe backend\manage.py runserver 0.0.0.0:8000 --noreload
# health → http://localhost:8000/api/v1/health/

# ---- Frontends ----
cd customer-web; npm install; npm run dev   # http://localhost:3000  (NOT 5173)
cd admin-web;    npm install; npm run dev   # http://localhost:5174

# ---- Flutter ----
cd customer-app; flutter pub get; flutter analyze; flutter run

# ---- Services (when Docker is installed) ----
docker compose up -d postgres redis
```

Test discovery gotcha: from repo root pass **explicit app labels** and the SQLite override (`$env:DATABASE_URL="sqlite:///db.sqlite3"; .\.venv\Scripts\python.exe backend\manage.py test products common ...`) — a bare `manage.py test` finds 0 tests. Python used is in the venv: `& .\.venv\Scripts\python.exe ...`.

### 3.7 Known open issues

- Docker not installed → PostgreSQL/Redis/Celery/Channels checks are blocked; DB-touching commands hang with the Postgres URL → use SQLite override.
- CI workflow `.github/workflows/ci.yml` runs backend checks + both React builds on push.
- vite binds IPv6 `localhost` — probe `http://localhost:3000/`, not `127.0.0.1`.
- Coupon apply at checkout, live payment gateways, production deploy, and load testing remain TODO (see section 2.5).

---

## 4. Definitions & Index

| Term | Meaning |
| --- | --- |
| q-commerce | Quick commerce — delivery in minutes using stores near the customer |
| Multi-tenant | Many isolated merchants on one platform; data must be strictly separated |
| Modular monolith | One deployable service split into domain modules (Django apps) |
| Tenant | A merchant/customer organization; owns its stores, products, orders |
| Builder | The visual tool merchants use to design their storefront without code |

Final note: **EASYGET is a long build.** Foundation, auth, tenancy, cart/orders/delivery, and the Flipkart-grade marketplace UX (discovery, reviews, wishlist, offers, pincode ETA, moderation) are done and tested — 195 backend tests green. The next proving ground is **Phase C** (coupon apply at checkout + gateway-agnostic payment template), then post-order polish (D) and Flutter parity (E).
