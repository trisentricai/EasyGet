# EASYGET

A quick-commerce (q-commerce) platform — customer mobile app (Flutter), customer web app (React), and admin dashboard (React), backed by a single Django REST API.

---

## Table of Contents

- [EASYGET](#easyget)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Tech Stack](#tech-stack)
  - [System Architecture](#system-architecture)
  - [Backend Folder Structure](#backend-folder-structure)
  - [How to Use This Document](#how-to-use-this-document)
  - [Development Phases](#development-phases)
    - [Phase 0 — Business \& System Planning](#phase-0--business--system-planning)
    - [Phase 1 — Project Foundation](#phase-1--project-foundation)
    - [Phase 2 — Authentication \& Users](#phase-2--authentication--users)
    - [Phase 3 — Product Catalog](#phase-3--product-catalog)
    - [Phase 4 — Store \& Inventory](#phase-4--store--inventory)
    - [Phase 5 — Cart](#phase-5--cart)
    - [Phase 6 — Order System](#phase-6--order-system)
    - [Phase 7 — Payment](#phase-7--payment)
    - [Phase 8 — Admin Dashboard](#phase-8--admin-dashboard)
    - [Phase 9 — Delivery System](#phase-9--delivery-system)
    - [Phase 10 — Notifications](#phase-10--notifications)
    - [Phase 11 — Search, Performance \& Redis](#phase-11--search-performance--redis)
    - [Phase 12 — Testing \& Security](#phase-12--testing--security)
    - [Phase 13 — Production Deployment](#phase-13--production-deployment)
    - [Phase 14 — Launch MVP](#phase-14--launch-mvp)
    - [Phase 15 — Version 2](#phase-15--version-2)
  - [Recommended Build Order](#recommended-build-order)
  - [Key Architectural Decisions](#key-architectural-decisions)
  - [Reference: Order State Machine](#reference-order-state-machine)
  - [Reference: User Roles](#reference-user-roles)

---

## Overview

EASYGET is built as a **modular monolith first**, not microservices — microservices would be unnecessary complexity at this stage. One Django REST API serves both the Flutter customer app and the React web/admin apps, so there is a single business-logic layer, a single authentication system, and a single source of truth.

## Tech Stack

| Layer | Technology |
|---|---|
| Customer mobile app | Flutter |
| Customer web app | React |
| Admin dashboard | React |
| API | Django + Django REST Framework |
| Database | PostgreSQL (Supabase) |
| Cache / Queue broker | Redis |
| Background jobs | Celery |

## System Architecture

```text
                         EASYGET
                            │
              ┌─────────────┴─────────────┐
              │                           │
        Customer App                 Customer Web
           Flutter                      React
              │                           │
              └─────────────┬─────────────┘
                            │
                         HTTPS
                            │
                            ▼
                 ┌─────────────────────┐
                 │     Django API      │
                 │   Django REST API   │
                 └──────────┬──────────┘
                            │
            ┌───────────────┼────────────────┐
            │               │                │
            ▼               ▼                ▼
       PostgreSQL         Redis            Celery
       (Supabase)         Cache/          Background
                          Queue             Jobs
            │
            ▼
       EASYGET Data
```

```text
Flutter ─────┐
             │
React ───────┼──→ Django REST API
             │
Admin ───────┘
```

## Backend Folder Structure

Split Django by **business domain**, not by technical function:

```text
backend/
│
├── config/
│   ├── settings/
│   ├── urls.py
│   └── celery.py
│
├── users/
├── stores/
├── products/
├── categories/
├── inventory/
├── cart/
├── orders/
├── payments/
├── delivery/
├── coupons/
├── notifications/
├── reviews/
└── common/
```

Frontend structures:

```text
Flutter                          React
lib/                             src/
├── core/                        ├── components/
├── features/                    ├── features/
├── models/                      ├── pages/
├── services/                    ├── services/
├── routing/                     ├── hooks/
└── widgets/                     ├── layouts/
                                  └── utils/
```

---

## How to Use This Document

This README is written to be worked through **one phase at a time** with an AI coding assistant:

1. Open a phase below and give the assistant its **Goal**, **Scope**, and **Deliverables** as the task for that session.
2. Let the assistant build only that phase — don't jump ahead.
3. Once it's built, work through the **Manual Test Checklist** for that phase yourself before moving on.
4. Only start the next phase once the current one passes its checklist. Fixing something at Phase 4 is cheap; fixing the same thing after Phase 10 is built on top of it is not.
5. Track progress by checking off phases in the [Recommended Build Order](#recommended-build-order) table.

---

## Development Phases

### Phase 0 — Business & System Planning

**Do this before any code is written.**

**Scope — define:**
- What EASYGET sells
- Delivery area
- Store / dark-store model
- Delivery radius
- Minimum order value
- Delivery fee structure
- Payment methods
- Cancellation / refund rules
- Inventory rules
- Customer types
- Admin roles
- Delivery-agent workflow

**Deliverable:** A written EASYGET Product Requirement Document + system architecture doc.

**Manual Test Checklist:**
- [ ] Every bullet above has a concrete, written answer (no "TBD")
- [ ] Delivery area and radius are specific enough to code a serviceability check
- [ ] Cancellation/refund rules are unambiguous (who can cancel, until what order state, refund method)
- [ ] Admin roles list matches what Phase 8 will need to build permissions for

---

### Phase 1 — Project Foundation

**Scope:**
- **Backend:** Django, DRF, PostgreSQL/Supabase, Redis, Celery, environment config, API versioning, logging, error handling, CORS, auth foundation
- **Frontend:** Flutter and React project scaffolding (see folder structures above)
- **DevOps:** Git repo, dev/staging/production environments, `.env` handling, CI/CD, basic deployment

**Manual Test Checklist:**
- [ ] Django dev server starts with no errors
- [ ] A test DRF endpoint returns a valid JSON response
- [ ] Database connection (PostgreSQL/Supabase) succeeds
- [ ] Redis connection succeeds
- [ ] Celery worker starts and connects to the broker; a test task executes
- [ ] `.env` values load correctly and differ correctly between dev/staging
- [ ] CORS allows requests from the local Flutter and React dev URLs, blocks others
- [ ] Git repo is initialized with a sensible `.gitignore`; CI pipeline runs on push
- [ ] Flutter app builds and runs on an emulator/device
- [ ] React app builds and runs locally

---

### Phase 2 — Authentication & Users

**Scope:**
- Customer registration, login, logout, OTP/email verification
- Profile, multiple addresses, default address
- Backend models: `User`, `Address`, `Role`, `Permission`
- Roles: `CUSTOMER`, `ADMIN`, `STORE_MANAGER`, `DELIVERY_AGENT`
- **One Django auth system serves both Flutter and React** — no separate systems.

**Manual Test Checklist:**
- [ ] Register a new customer via API → 201, user created
- [ ] OTP/email verification flow works end to end
- [ ] Login returns a valid token/session
- [ ] Logout invalidates the token/session
- [ ] Profile fields can be updated
- [ ] Multiple addresses can be added; exactly one is marked default at a time
- [ ] A `CUSTOMER` token hitting an admin-only endpoint gets a 403
- [ ] The same login works from both the Flutter app and the React app against the same backend

---

### Phase 3 — Product Catalog

**Scope:**
```text
Category → Subcategory → Product → Product Variant
```
Example: Beverages → Soft Drinks → Coca-Cola → 500ml / 1.25L

- Categories, products, variants, images, prices, MRP, discounts, descriptions
- Search, filters, featured products

**Manual Test Checklist:**
- [ ] Create a category and subcategory
- [ ] Create a product with at least two variants
- [ ] Upload and display product images correctly
- [ ] Price, MRP, and discount display and calculate correctly
- [ ] Search returns relevant results for partial/misspelled queries
- [ ] Filters (category, price range) narrow results correctly
- [ ] Featured-products endpoint returns the expected list

---

### Phase 4 — Store & Inventory

**This is one of the most important parts of a quick-commerce app.**

Inventory is **per store**, not global:
```text
Store A                    Store B
 ├── Product X → 20         ├── Product X → 5
 ├── Product Y → 15         ├── Product Y → 40
 └── Product Z → 0          └── Product Z → 12
```

**Scope:** `Store`, `Inventory`, `InventoryTransaction` models, built to support multiple stores from day one.

**Manual Test Checklist:**
- [ ] Create two or more stores
- [ ] Same product has independent stock levels per store
- [ ] Every stock change writes an `InventoryTransaction` record
- [ ] A product with stock = 0 at a store is correctly marked unavailable there
- [ ] Low-stock threshold logic triggers correctly, if implemented at this stage

---

### Phase 5 — Cart

**Scope:**
- Add/remove product, increase/decrease quantity
- View subtotal, apply coupon, see delivery fee, see final amount

**Important rule: never trust the frontend's price.** The backend always recalculates:
```text
(Product price × quantity) + discount + delivery fee = final amount
```

**Manual Test Checklist:**
- [ ] Add, remove, and change quantity of cart items
- [ ] Subtotal is correct after each change
- [ ] Valid coupon applies the correct discount
- [ ] Invalid/expired coupon is rejected with a clear error
- [ ] Delivery fee is calculated and shown correctly
- [ ] **Tamper test:** manually edit the price/amount field in the API request payload and confirm the backend ignores it and recalculates from source data

---

### Phase 6 — Order System

**Scope:**
```text
Cart → Checkout → Order → Payment → Order Confirmation → Store Processing → Delivery → Completed
```

Order states:
```text
PENDING → CONFIRMED → PROCESSING → READY_FOR_PICKUP → OUT_FOR_DELIVERY → DELIVERED
                                                                        → CANCELLED
                                                                        → REFUNDED
```
Design the exact state machine before implementation.

**Manual Test Checklist:**
- [ ] Checkout correctly converts a Cart into an Order
- [ ] Order moves through states in the defined sequence only
- [ ] Cancellation is only allowed from valid states (per Phase 0 rules)
- [ ] Invalid transitions are rejected (e.g. `DELIVERED → PENDING` fails)
- [ ] Customer can view their order history with correct statuses

---

### Phase 7 — Payment

**Scope:** Online payment integration, and cash on delivery if the business supports it.

**Critical rule: payment success must be confirmed server-side**, never trusted from the frontend:
```text
Payment Provider → Webhook → Django → Verify payment → Confirm Order
```

**Manual Test Checklist:**
- [ ] Online payment completes successfully in sandbox/test mode
- [ ] Order stays unconfirmed until the payment webhook is received and verified (test by blocking/delaying the webhook)
- [ ] COD flow works correctly if enabled
- [ ] A failed payment does not create/confirm an order
- [ ] Webhook with an invalid signature is rejected, not processed

---

### Phase 8 — Admin Dashboard

**Scope (React admin panel):**
- **Products:** add, edit, delete, pricing, images, categories
- **Inventory:** stock, stock adjustments, low-stock alerts
- **Orders:** new, processing, completed, cancelled, refunds
- **Customers:** info, addresses, order history
- **Stores:** stores, store inventory, service areas

**Manual Test Checklist:**
- [ ] Admin can add, edit, and delete a product
- [ ] Stock adjustment from admin reflects immediately in inventory
- [ ] Low-stock alerts appear in the dashboard
- [ ] Orders list filters correctly by status
- [ ] Refund action updates the order and triggers the correct backend logic
- [ ] Customer view shows correct addresses and order history
- [ ] Store management: create/edit a store and its service area

---

### Phase 9 — Delivery System

**Scope:**
```text
Order confirmed → Find suitable store → Prepare order → Assign delivery agent
→ Pickup → Out for delivery → Delivered
```
Delivery agent needs: assigned orders, customer address, order details, navigation, status updates, delivery confirmation.

**For v1, manual/admin assignment is enough — don't build automatic delivery optimization yet.**

**Manual Test Checklist:**
- [ ] A confirmed order routes to the correct nearby store
- [ ] Admin can manually assign a delivery agent to an order
- [ ] Delivery agent view shows assigned orders and customer address
- [ ] Status updates (picked up → out for delivery → delivered) reflect on the customer side
- [ ] Delivery confirmation step (signature/OTP/photo, per Phase 0 rules) works

---

### Phase 10 — Notifications

**Scope:** Introduce Celery + Redis properly here.
```text
Order placed → Celery → Push notification / Email / SMS-WhatsApp (if required)
```
Other background tasks: low-stock alerts, payment verification, refund processing, scheduled cleanup, promotional notifications.

**Manual Test Checklist:**
- [ ] Placing an order triggers a Celery task
- [ ] Push notification is received on a test device
- [ ] Email is sent and received
- [ ] SMS/WhatsApp sent correctly, if implemented
- [ ] Low-stock alert notification fires correctly
- [ ] A failing Celery task retries or logs failure instead of failing silently

---

### Phase 11 — Search, Performance & Redis

**Only start this after the core system works end to end.**

Redis can handle: popular products, categories, store/serviceability data, frequently requested API responses, rate limiting, temporary data, the Celery queue. **The database remains authoritative — don't cache everything.**

**Manual Test Checklist:**
- [ ] Popular-product queries hit Redis cache (confirm via logs/metrics)
- [ ] Cache invalidates correctly when underlying data changes
- [ ] Rate limiting blocks excessive requests from the same client
- [ ] Cached endpoints show a measurable response-time improvement over uncached

---

### Phase 12 — Testing & Security

**Not optional.**

**Backend to test:** authentication, permissions, cart, inventory, orders, payments, coupons, refunds
**Security to test:** authentication, authorization, API rate limiting, input validation, SQL injection protection, CORS, secret management, payment webhook verification
**Frontend to test:** mobile, web, responsive UI, network failures, empty states, loading states

**Manual Test Checklist:**
- [ ] Auth/permission tests pass for every role (`CUSTOMER`, `ADMIN`, `STORE_MANAGER`, `DELIVERY_AGENT`)
- [ ] SQL injection attempts on search/filter inputs are blocked
- [ ] Exceeding the rate limit gets blocked correctly
- [ ] CORS blocks requests from unauthorized origins
- [ ] No secrets appear in the repo, logs, or client-side bundle
- [ ] Payment webhook rejects unverified/tampered requests
- [ ] UI handles poor/no network gracefully (loading, empty, and error states all present)

---

### Phase 13 — Production Deployment

```text
                 Internet
                    │
              CDN / HTTPS
                    │
          ┌─────────┴─────────┐
          │                   │
       React Web          Flutter App
          │                   │
          └─────────┬─────────┘
                    │
                 Django
                    │
        ┌───────────┼───────────┐
        │           │           │
   PostgreSQL     Redis       Celery
   Supabase
```

**Scope:** monitoring, error tracking, database backups, logging, uptime monitoring, deployment pipeline.

**Manual Test Checklist:**
- [ ] Production deploy succeeds via CI/CD pipeline
- [ ] HTTPS is enforced; static assets served via CDN
- [ ] Database backups are scheduled and a restore has been test-run at least once
- [ ] Monitoring/error tracking is receiving real events
- [ ] Uptime monitoring is configured and its alert has been test-triggered

---

### Phase 14 — Launch MVP

**Keep the first production version much smaller than the full spec:**
```text
Auth → Location/address → Products → Search/categories → Cart → Checkout
→ Payment/COD → Order → Admin → Delivery → Notifications
```
That's enough to operate the business.

**Manual Test Checklist:**
- [ ] Full customer journey works end to end in production: register → browse → cart → checkout → pay → order → delivery → notification
- [ ] Admin can manage the complete order lifecycle in production
- [ ] A real (or realistic test) transaction has been completed successfully

---

### Phase 15 — Version 2

After real customers use the MVP, add:
- Live delivery tracking
- Automatic delivery assignment
- Advanced coupons
- Loyalty points
- Wallet
- Referral system
- Product recommendations
- Advanced search
- Reviews/ratings
- Subscription orders
- Scheduled delivery
- Multiple warehouses
- Advanced analytics

*(No test checklist yet — this phase is planning-only until MVP feedback comes in.)*

---

## Recommended Build Order

> **Live status:** this table is the roadmap — the ground truth of what works
> *right now* is `currentUpdate.md` (updated every session).

| # | Phase | Status |
|---|---|---|
| 1 | Foundation | ✅ done |
| 2 | Auth & Users | ✅ done (merged to `main`) |
| 3 | Store + Product + Inventory | ✅ done — tenancy (`tenants` app), 200 seeded products, Supabase live |
| 4 | Customer web app | ✅ built (Home/Browse/Search/Product/Cart/Checkout/Orders/Account) |
| 4b | Customer Flutter app | ✅ built (Riverpod 3, go_router, Dio, clean arch, all screens; analyzer 0, debug APK built) — device click-test pending |
| 5 | Cart (backend) | ✅ endpoints built · ☐ tenant-wiring pending |
| 6 | Orders (backend) + admin fulfilment UI | ✅ built — `admin-web/#/orders` live, 1 order in queue · ☐ tenant-wiring pending |
| 7 | Payments (backend) | ✅ endpoints built · ☐ tenant-wiring + provider gateway pending |
| 8 | Admin dashboard | ✅ built (Overview, Orders, Categories, Products, Inventory, Storefront designer) |
| 9 | Delivery | ✅ v1 built — manual assignment API + admin UI + agent flow, verified live end-to-end |
| 10 | Notifications | ☐ models only, no live flow yet |
| 11 | Search, Performance & Redis | ⚠️ partial — search API works (+SQLite fallback); Redis fail-soft, no Docker locally |
| 12 | Testing & Security | ⚠️ partial — 120+ backend tests pass; no prod audit yet |
| 13 | Production Deployment | ☐ not started |

Next up per `PROJECT.md` §3.3: **Cart/Orders/Payments tenant-wiring** (model-by-model, migrations + isolation tests per batch), then **`/products/` pagination** (200 items ≈ 3.5s on Supabase).

---

## Quick Start (run it)

> **New here? Start with [`GETTING_STARTED.md`](GETTING_STARTED.md)** —
> exact commands, logins, what each screen shows, known quirks, and the
> not-yet-built list. The short version is below.

Prerequisites: Python 3.11+ (`.venv` at repo root), Node 22+. No Docker needed — the live DB is Supabase (see `.env`).

```powershell
# 1 — Backend API (leave running)
cd C:\Users\Rahul\Documents\TRISENTRICS-AI\EasyGet
.\.venv\Scripts\python.exe backend\manage.py runserver
# health → http://127.0.0.1:8000/api/v1/health/   ({"status":"ok"})
# docs   → http://127.0.0.1:8000/api/docs/

# 2 — Admin dashboard (new terminal)
cd admin-web; npm install; npm run dev      # http://localhost:5174

# 3 — Customer shop (new terminal)
cd customer-web; npm install; npm run dev   # http://localhost:5173

# 4 — Customer mobile app (needs Android emulator or device)
cd customer-app; flutter pub get; flutter run
# Emulator reaches the backend via http://10.0.2.2:8000 (default).
# Physical device on LAN: flutter run --dart-define=API_BASE=http://<your-pc-ip>:8000/api/v1
```

Notes:
- `.venv` lives at the **repo root**, `manage.py` inside **`backend/`** — the combo above is the correct one.
- `GET /` → 404 is **normal**: the backend is API-only, it has no homepage.
- Seeded logins (Supabase): admin `admin@easyget.local` / `EasyGet!2026` → `:5174`; customer `customer@easyget.app` / `Customer@123` → `:5173`; merchant `merchant@easyget.app` / `Merchant@123`.
- Backend tests must run **from `backend/`** with the SQLite override (Supabase can't create test DBs):
```powershell
cd backend
$env:DATABASE_URL='sqlite:///db.sqlite3'
& 'C:\Users\Rahul\Documents\TRISENTRICS-AI\EasyGet\.venv\Scripts\python.exe' manage.py test -v 1
```

---

## Key Architectural Decisions

1. **Modular monolith, not microservices** — right-sized for this stage; split by business domain inside one Django project.
2. **One API for everyone** — Flutter, React web, and React admin all talk to the same Django REST API. No parallel auth systems, no duplicated business logic.
3. **Inventory is per-store**, never a single global stock number, so multi-store support isn't a rewrite later.
4. **Backend is the source of truth for price** — cart/checkout totals are always recalculated server-side, never trusted from the client.
5. **Payment confirmation is server-side only**, driven by verified provider webhooks, never by a frontend "success" callback.
6. **Redis caches, it doesn't replace, the database** — Postgres/Supabase remains authoritative.
7. **Manual delivery assignment for v1** — automatic optimization is a Version 2 feature, not an MVP blocker.

## Reference: Order State Machine

```text
PENDING
CONFIRMED
PROCESSING
READY_FOR_PICKUP
OUT_FOR_DELIVERY
DELIVERED
CANCELLED
REFUNDED
```

## Reference: User Roles

```text
CUSTOMER
ADMIN
STORE_MANAGER
DELIVERY_AGENT
```
