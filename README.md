# EASYGET

> **A quick-commerce (q-commerce) SaaS platform: multi-store marketplace catalog, near-store delivery, and a visual storefront builder — with a Flipkart/Meesho-grade customer experience.**

**Status:** Phases 0–3 foundation ✅ · Discovery + Flipkart look (A/A2) ✅ · Marketplace depth (B1) ✅ · 195 backend tests green · customer-web + admin-web + Flutter app building clean.

---

## Table of Contents

- [Overview](#overview)
- [What works today](#what-works-today)
- [Tech stack](#tech-stack)
- [System architecture](#system-architecture)
- [Repository layout](#repository-layout)
- [Quick start](#quick-start)
- [Logins](#logins)
- [Tests](#tests)
- [Docs map](#docs-map)
- [Roadmap](#roadmap)

---

## Overview

EASYGET gives neighborhood stores an online marketplace presence without giving up their brand:

- **Customers** browse a themed storefront, search/filter/sort, read ratings & reviews, wishlist products, check live pincode delivery ETAs, order, and track.
- **Merchants** get a visual storefront designer (sections, items, theme), catalog + inventory management, and an orders fulfilment queue.
- **Operators** moderate reviews, manage banners/coupons/system config, and assign deliveries.

The customer experience deliberately matches Flipkart/Meesho/Amazon conventions: blue sticky header + wide search, category strip, offer ticker, banner carousel, rating-pill product cards, buy-box PDP with "Available offers" and pincode check, sidebar filters, marketplace footer, mobile bottom nav.

## What works today

**Customer web (Flipkart-grade):**
- Home: auto-rotating banner carousel, deals/category/recommended/recently-viewed rails, offer ticker
- Browse: left filter sidebar (category, brand, discount, price range, featured), sort incl. **Avg. Customer Review**, result count
- Search: suggestions, recent + trending searches, category filters, same sort options
- PDP: gallery + thumbnails, rating pill + distribution bars, variants, **Available offers** (live coupons), **live pincode check** (city + ETA: 2-day same state / 4-day else, fee logic), qty stepper, Add to cart / Buy now, seller box, ratings & reviews with verified-purchase badges + write-review form, similar products
- **Wishlist**: heart anywhere → server-backed (optimistic sync), dedicated `#/wishlist` page, header link
- Cart / checkout / orders / account (addresses) on the standard APIs
- Responsive: mobile bottom nav, touch-friendly, empty states everywhere

**Admin web (`:5174`):** dashboard stats, orders fulfilment queue (status pills, detail + timeline, advance/cancel), categories/products/inventory CRUD, **review moderation** (approve/hide/delete), storefront designer (drag-order sections/items, theme panel with Flipkart palette), coupons/banners via API.

**Backend (Django + DRF + Postgres/Supabase):** auth (JWT + refresh + OTP verify), multi-tenant stores, catalog (variants, images, brands, min-discount & rating sorts), stock per store, cart (guest + merge), orders (state machine + timeline), payments (gateway-agnostic `Payment` model + saved methods), delivery assignments, notifications, full-text search + suggestions + logs, analytics, realtime channels, PWA manifest, storefront templates/sections/items/theme, admin config/audit/coupons/banners/scheduled tasks, **reviews & ratings** (one per user, masked names, verified purchase, moderation), **wishlist**, **pincode ETA service**.

**Flutter app (`customer-app/`):** Riverpod + go_router + Dio clean-architecture customer app — analyzer 0, debug APK builds; not yet click-tested against live APIs.

## Tech stack

| Layer | Choice |
|---|---|
| Backend | Django 5 + Django REST Framework, simplejwt, Channels (realtime), Postgres (Supabase) w/ SQLite fallback for tests |
| Admin web | React 18 + TypeScript + Vite (hash router, dual theme) |
| Customer web | React 18 + TypeScript + Vite (hash router, Flipkart design system) |
| Mobile | Flutter 3 / Dart, Riverpod, go_router, Dio |
| Search | Postgres full-text (SearchQuery/Gin) + ranked suggestions |
| Dev ops | GitHub Actions CI (SQLite test run), `docker-compose.yml` (optional) |

## System architecture

```
customer-web (:3000)  admin-web (:5174)  customer-app (Flutter)
        │                    │                     │
        └──────────┬─────────┴──────────┬──────────┘
                   ▼                    ▼
          Django REST API (:8000)  ── Channels (realtime)
                   │
        Supabase Postgres (data) + Redis (optional cache/throttle)
```

- `api/v1/` versioned routes; JWT access + refresh (rotation + blacklist)
- Public storefront routes are tenant/theme-driven; staff routes under `api/v1/admin/`
- Products expose `rating_avg`/`rating_count` via **subquery annotations** (immune to stock-join row duplication); visibility filters run **before** sorting so sorted lists can't leak inactive catalogs

## Repository layout

```
backend/         Django project (config/ + apps: users, tenants, stores, categories,
                 products, inventory, cart, orders, payments, delivery, notifications,
                 search, analytics, realtime, storefront, admin_panel, pwa, webhooks…)
admin-web/       React admin SPA  → localhost:5174
customer-web/    React storefront → localhost:3000   (NOT 5173)
customer-app/    Flutter customer app
docs/            Phase 1 spec, local development notes
PROJECT.md       WHY / WHAT / HOW capstone
currentUpdate.md Live status snapshot (read after GitCheck.md)
GitCheck.md      Git/GitHub workflow + session changelog
GETTING_STARTED.md  Run the whole stack in 4 terminals
```

## Quick start

Full instructions: **[GETTING_STARTED.md](GETTING_STARTED.md)**. The short version:

```powershell
# 1 — Backend API (leave running)
.venv\Scripts\python.exe backend\manage.py runserver 0.0.0.0:8000 --noreload
# health → http://localhost:8000/api/v1/health/  → {"status":"ok"}
# API docs → http://localhost:8000/api/docs/

# 2 — Admin dashboard
cd admin-web;  npm install;  npm run dev     # → http://localhost:5174

# 3 — Customer shop
cd customer-web; npm install; npm run dev    # → http://localhost:3000

# 4 — Flutter app (optional)
cd customer-app; flutter pub get; flutter run
```

Notes:
- Backend reads `.env` **only at startup** — restart after editing it.
- Vite binds IPv6 `localhost` — use `http://localhost:3000/`, not `127.0.0.1`.
- Tests: run from repo root with `$env:DATABASE_URL='sqlite:///db.sqlite3'` and explicit app labels (see below).

## Logins

| Role | Email | Password |
|---|---|---|
| Admin | `admin@easyget.local` | `EasyGet!2026` |
| Customer | `customer@easyget.app` | `Customer@123` |
| Merchant | `merchant@easyget.app` | `Merchant@123` |
| Delivery agent | `agent@easyget.app` | `Agent@123` |

## Tests

```powershell
# From repo root — SQLite for the DB, explicit labels (bare test finds 0)
$env:DATABASE_URL='sqlite:///db.sqlite3'
.\.venv\Scripts\python.exe backend\manage.py test admin_panel analytics cart `
  categories common delivery inventory notifications orders payments products `
  pwa realtime search storefront stores tenants users webhooks
# → Ran 195 tests — OK (skipped=1)
```

Web builds: `cd customer-web; npm run build` (tsc + vite) and same in `admin-web`.

## Docs map

| Read order | File | Purpose |
|---|---|---|
| 1 | `GitCheck.md` | Git/GitHub rules, session changelog (what changed when) |
| 2 | `currentUpdate.md` | Live status: what exists, what works, what's next |
| 3 | `README.md` (this) | Product overview + roadmap |
| — | `GETTING_STARTED.md` | Run guide (4 terminals, logins, troubleshooting) |
| — | `PROJECT.md` | WHY/WHAT/HOW capstone |
| — | `docs/phase-1-foundation-spec.md` | Phase 1 requirements |

**Workflow rule:** after every change, update `currentUpdate.md` **and** `GitCheck.md` together.

## Roadmap

| Phase | Scope | Status |
|---|---|---|
| 0–1 | Planning, foundation, CI | ✅ |
| 2 | Auth/users (JWT, OTP) | ✅ |
| 3 | Catalog, stores, inventory, cart, orders, tenants | ✅ |
| A | Discovery: rails, filters, working sort, brands, search recents/trending | ✅ |
| A2 | Reviews/ratings API + Flipkart-grade visual overhaul | ✅ |
| B1 | Marketplace depth: wishlist backend + page, `sort=rating`, PDP offers, live pincode ETA, admin review moderation | ✅ |
| C | Checkout depth: coupon apply, gateway-agnostic payments (Razorpay/Stripe/COD template) | ⬜ next |
| D | Post-order: tracking polish, notifications, returns | ⬜ |
| E | Flutter app parity with A2/B1 features | ⬜ |
| 4–15 | Delivery ops, notifications, perf/Redis, security, production, launch | ⬜ |

See `currentUpdate.md` for the detailed state of each area.
