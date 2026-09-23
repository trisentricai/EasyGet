# EASYGET — Run the complete project

> One page: how to run everything, what you will see, what you won't,
> and what is still left to build. Last verified: 2026-09-23.

EASYGET is a quick-commerce SaaS: one Django API serves a customer shop
(web + mobile) and a merchant admin dashboard. The live database is
**Supabase Postgres** (already connected via `.env`) — no Docker needed.

---

## 1. Prerequisites

| Need | Version | Check |
|---|---|---|
| Python + `.venv` | 3.11+ (venv already at repo root) | `.\.venv\Scripts\python.exe --version` |
| Node.js | 22+ | `node --version` |
| Flutter | 3.38 (for mobile only) | `flutter --version` |
| Backend running | — | required before any frontend works |

**Two path rules that fix 90% of run errors:**

1. `.venv` lives at the **repo root** — never inside `backend/`.
2. `manage.py` lives inside **`backend/`** — never at the root.

---

## 2. Run everything (4 terminals)

### Terminal 1 — Backend API (start this first, leave running)

```powershell
cd C:\Users\Rahul\Documents\TRISENTRICS-AI\EasyGet
.\.venv\Scripts\python.exe backend\manage.py runserver
```

| URL | What shows |
|---|---|
| `http://127.0.0.1:8000/api/v1/health/` | `{"status":"ok","service":"easyget-api"}` — proves the API + Supabase link |
| `http://127.0.0.1:8000/api/docs/` | Clickable Swagger docs for every endpoint |
| `http://127.0.0.1:8000/admin/` | Django admin (login below) |
| `http://127.0.0.1:8000/` | **404 — this is NORMAL.** The backend is API-only, it has no homepage. |

### Terminal 2 — Admin dashboard → `http://localhost:5174`

```powershell
cd C:\Users\Rahul\Documents\TRISENTRICS-AI\EasyGet\admin-web
npm install
npm run dev
```

Login: `admin@easyget.local` / `EasyGet!2026`

| Page | What shows |
|---|---|
| Overview `#/dashboard` | Live counts (users, orders, revenue, products), quick actions, fulfilment queue card |
| Orders `#/orders` | Status filter pills, orders table, detail modal (items, timeline, confirm/cancel) + 🛵 delivery section (assign agent, advance delivery) |
| Categories `#/categories` | Category CRUD + search |
| Products `#/products` | Product CRUD (create adds a default variant), category filter |
| Inventory `#/inventory` | Stock table + Adjust-stock modal (writes audit rows) |
| Storefront designer `#/storefront` | Drag-and-drop sections/items, inline rename, design knobs, theme panel — renders instantly on the shop |

### Terminal 3 — Customer shop → `http://localhost:5173`

```powershell
cd C:\Users\Rahul\Documents\TRISENTRICS-AI\EasyGet\customer-web
npm install
npm run dev
```

Login: `customer@easyget.app` / `Customer@123`

| Page | What shows |
|---|---|
| Home | The merchant-designed storefront (hero, banners, category grid, product rows) in the store theme |
| Browse | Filters (category, sort, price, featured) + **Load more** paging (20/page) |
| Search | Full-text search + suggestions (auto-fallback if search backend is down) |
| Product | Image carousel, discount badge, pack-size variants, quantity, add-to-cart |
| Cart | Qty steppers, swipe-style remove, clear, subtotal → checkout |
| Checkout | Address pick/add/default, store picker, place order |
| Orders | Order list, detail with tracking timeline, cancel (PENDING/CONFIRMED only) |
| Account | Profile, address book, sign out |

Merchant login (owns `Rahuls-Store`): `merchant@easyget.app` / `Merchant@123`.
Delivery agent login: `agent@easyget.app` / `Agent@123`.

### Terminal 4 — Flutter mobile app (optional, needs emulator/device)

```powershell
cd C:\Users\Rahul\Documents\TRISENTRICS-AI\EasyGet\customer-app
flutter pub get
flutter run
```

Same screens as the customer shop (Home, Browse, Search, Cart, Checkout,
Orders, Account) with bottom-tab navigation. Network note:

| Target | Command |
|---|---|
| Android emulator (default) | `flutter run` (uses `http://10.0.2.2:8000`) |
| iOS simulator / desktop | `flutter run --dart-define=API_BASE=http://127.0.0.1:8000/api/v1` |
| Physical phone on Wi-Fi | `flutter run --dart-define=API_BASE=http://<your-PC-LAN-IP>:8000/api/v1` |

Gate: `flutter analyze` must print **No issues found** before committing
(currently clean). Debug APK builds via `flutter build apk --debug`.

---

## 3. What works right now (verified live on Supabase)

- Auth end-to-end: register → OTP (printed in backend console) → verify → login → refresh → logout.
- Catalog: 10 categories, 200 products (names cleaned), variants, per-store stock with audit trail.
- Multi-tenancy enforced: Store B can never read/write Store A (carts, orders, payments, stock, deliveries all scoped + tested).
- Cart → checkout → order → payment-record → manual delivery assignment → delivered, mirrored on both sides. Demo order `EZG-20260923-M68B` already ran this full path.
- Storefront designer edits appear instantly on the customer web + app home.
- Backend: 120+ tests pass (SQLite), `manage.py check` clean, both webs `npm run build` clean, Flutter analyzer clean + APK builds.
- GitHub: `phase-3-store-product-inventory` branch pushed (16 commits); `main` still holds only the Phase 1–2 baseline.

## 4. What does NOT show / looks wrong but isn't

| Symptom | Reality |
|---|---|
| `GET /` → 404 page | Normal — API-only backend, no homepage. Use `/api/v1/health/` or `/api/docs/`. |
| Dashboard "0 pending orders" | Normal — the single demo order was delivered during live delivery testing. Place a new order to see the queue fill. |
| Browse shows 20, then Load more | Normal — products are paginated (20/page, 200 total). |
| Product pages take ~2–3s | Known slowness — Supabase region latency; cursor pagination planned. |
| OTP never arrives by email | Normal locally — dev prints the code to the backend console. |
| RLS warnings in Supabase dashboard | Safe to ignore — auth is enforced by Django (JWT), not Supabase RLS. |
| `manage.py test` hangs or asks about `test_postgres` | You ran it against Supabase. Always set `$env:DATABASE_URL='sqlite:///db.sqlite3'` and run **from `backend/`**. |
| `test/widget_test.dart` missing | Deleted on purpose (stale scaffold referencing a deleted widget). |

## 5. Not yet completed — needs to be built

**Must decide now:**
- [ ] Merge `phase-3-store-product-inventory` into `main` (branch is pushed; `main` is 15 commits behind).

**Product gaps (biggest first):**
- [ ] Flutter device click-test (APK exists, never run against live Supabase on a real device).
- [ ] Delivery auto-assignment + live tracking (v1 is manual assign only).
- [ ] Real payment gateway (COD records only; no Razorpay/Stripe webhook flow).
- [ ] Notifications (models only — needs Redis/Celery; blocked without Docker).
- [ ] Email/SMS OTP for real users (console backend only).
- [ ] Production deploy (no hosting, CI exists but never green-lit, no backups, no CDN).

**Polish / hardening:**
- [ ] Products cursor pagination (kill the ~2.7s page loads).
- [ ] Full backend suite in one run (currently verified in per-app batches; whole suite is slow locally).
- [ ] Flutter release build + signing + store listing assets.
- [ ] Security/prod audit (rate limits tuned, webhook signatures, secret rotation).

## 6. Troubleshooting

| Error | Fix |
|---|---|
| `.venv\Scripts\activate` → "cannot find path" | You're inside `backend/`. `cd ..` first — `.venv` is at the root. |
| `can't open file manage.py` | You're at the root. Either `cd backend` first, or run `.\.venv\Scripts\python.exe backend\manage.py …` from root. |
| `DJANGO_SECRET_KEY must be set` | `.env` missing — copy `.env.example` → `.env`, keep `DJANGO_DEBUG=true`. Never commit `.env`. |
| Frontend shows network error | Backend (`:8000`) isn't running — start Terminal 1 first. Both webs call `http://127.0.0.1:8000/api/v1`. |
| Login "email not verified" | Register → copy the 6-digit OTP from the backend console → verify-otp (or Auth page) → login. |
| Port `5173/5174` busy | Another `npm run dev` still running — kill it or use `npm run dev -- --port 5180`. |
| `npm run build` TS errors | Run `npm install` first in that folder. |
| `flutter run` can't reach API | Wrong host for your target — see the `API_BASE` table in §2. Emulator ≠ `127.0.0.1`. |
