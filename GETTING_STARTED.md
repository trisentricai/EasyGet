# EASYGET — Run the complete project

Four services: Django backend, admin SPA, customer storefront, Flutter app (optional).

## 1. Prerequisites

- **Python 3.11** (venv at `.venv/` — recreate with `python -m venv .venv; .venv\Scripts\pip install -r requirements.txt` if missing)
- **Node 18+** (`node_modules` per web app; `npm install` in each on first run)
- **Flutter 3.38 / Dart 3.10** (only for `customer-app/`)
- **`.env`** at repo root (copy `.env.example`) — Django reads it **only at startup**; restart after edits
- No Docker needed: the dev DB is Supabase (from `.env`); tests use SQLite

## 2. Run everything (4 terminals)

### Terminal 1 — Backend API (start this first, leave running)

```powershell
# from repo root
.\.venv\Scripts\python.exe backend\manage.py runserver 0.0.0.0:8000 --noreload
```

- Health: <http://localhost:8000/api/v1/health/> → `{"status":"ok"}`
- API docs: <http://localhost:8000/api/docs/>
- Run `manage.py` commands **from the repo root** and pass explicit app labels for tests (see §5).
- If the port is occupied by a stale process: `Get-NetTCPConnection -LocalPort 8000 -State Listen` then `Stop-Process -Id <pid> -Force`.

### Terminal 2 — Admin dashboard → <http://localhost:5174>

```powershell
cd admin-web
npm install        # first time only
npm run dev
```

Screens: Dashboard, Orders (fulfilment queue), Categories, Products, **Reviews (moderation)**, Inventory, Storefront designer.

### Terminal 3 — Customer shop → <http://localhost:3000>

```powershell
cd customer-web
npm install        # first time only
npm run dev
```

> **Port is 3000** (vite config), NOT 5173. Vite binds IPv6 `localhost` — open <http://localhost:3000/> (not `127.0.0.1`).

### Terminal 4 — Flutter mobile app (optional, needs emulator/device)

```powershell
cd customer-app
flutter pub get
flutter run
```

Build check: `flutter build apk --debug` → `app-debug.apk`.

## 3. Logins

| Role | Email | Password | Where |
|---|---|---|---|
| Admin | `admin@easyget.local` | `EasyGet!2026` | admin-web |
| Customer | `customer@easyget.app` | `Customer@123` | customer-web / app |
| Merchant | `merchant@easyget.app` | `Merchant@123` | app |
| Delivery agent | `agent@easyget.app` | `Agent@123` | app |

## 4. What works right now (verified live)

- **Discovery**: home rails (deals, categories, recommended, recently viewed), banner carousel, brand/discount/price filters, sorts (price/newest/**rating**), brands endpoint, search suggestions + recents/trending
- **Reviews**: post/list (one per user, 409 on duplicate), masked names, verified-purchase badges, aggregates on list/detail; admin moderation (approve/hide/delete)
- **Wishlist**: heart on cards + PDP (server-backed, optimistic), `#/wishlist` page, header link
- **Offers**: PDP "Available offers" from active coupons (`WELCOME10`, `FLAT50`, `FREESHIP` seeded)
- **Pincode**: live lookup (city/state from postal API), ETA 2-day same state / 4-day else (state codes normalized), ₹29 fee < ₹499 / free above, offline fallback, 404 for undeliverable pins
- **Cart/checkout/orders**: guest cart + merge, order state machine + timeline, address book, delivery assignment
- **Theme**: Flipkart palette (`#2874F0` / `#FB641B` / Inter / square buttons) on the demo store
- **Admin**: dashboard stats, orders queue, category/product/inventory CRUD, storefront designer, config/audit/coupons/banners

## 5. Tests

Bare `manage.py test` from `backend/` discovers **0 tests**. From **repo root**:

```powershell
$env:DATABASE_URL='sqlite:///db.sqlite3'
.\.venv\Scripts\python.exe backend\manage.py test admin_panel analytics cart `
  categories common delivery inventory notifications orders payments products `
  pwa realtime search storefront stores tenants users webhooks
```

Expected: `Ran 195 tests ... OK (skipped=1)`.

Web builds (both must pass):

```powershell
cd customer-web; npm run build   # tsc --noEmit && vite build
cd admin-web;    npm run build
```

## 6. Troubleshooting

| Symptom | Fix |
|---|---|
| Backend won't see `.env` changes | Restart it — env is read once at startup |
| Tests find 0 | Wrong cwd or missing `$env:DATABASE_URL` — see §5 |
| `:8000` in use by a zombie | `Get-NetTCPConnection -LocalPort 8000 -State Listen` → kill the PID |
| Frontend can't reach `127.0.0.1:3000` | Use `http://localhost:3000/` (vite listens on IPv6 localhost) |
| DB-touching command hangs (Docker on machine) | Override `$env:DATABASE_URL="sqlite:///db.sqlite3"` |
| Product missing in shop | Needs an **active** `StockItem` in an active store |
| Pincode check says "couldn't check" | The postal API is unreachable — endpoint still answers via offline fallback on the next attempt; server logs show the exception |
| Wishlist heart doesn't persist | You're signed out — heart falls back to device-local until login |

## 7. Housekeeping rules

- After every change: update **`currentUpdate.md` + `GitCheck.md` together**, then commit (see GitCheck.md §7–8).
- Don't commit: `.env`, `node_modules`, `.venv`, `dist`, scratch scripts, token/log dumps.
