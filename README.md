# EASYGET — The One README (everything, scratch to current)

> **What this file is:** the single master document for the entire EASYGET
> repository. A junior developer joining tomorrow should read it top to
> bottom once, then use it as a daily reference.
>
> **Status stamp:** 2026-10-12 · branch `fix/flutter-web-and-ordering` ·
> backend **293 tests green** (1 skipped) · customer-web + admin-web builds
> green · commit `0522030` pushed (Out-of-Stock catalog fix).
>
> **What this file is NOT:** a replacement for the focused READMEs. Each
> app keeps its own deep README — this file covers the whole system and
> points at them:
>
> | Read order | File | Covers |
> |---|---|---|
> | 1 | `GitCheck.md` | Git/GitHub rules, SSH, session changelog, gotchas |
> | 2 | `currentUpdate.md` | Live status snapshot: latest sessions, what works, open edges |
> | 3 | `README.md` (this file) | The whole product: setup, all apps, API, hosting, history, TODOs |
> | 4 | `GETTING_STARTED.md` | 4-terminal run guide + troubleshooting quick table |
> | 5 | `PROJECT.md` | WHY/WHAT/HOW capstone (vision, principles, build order) |
> | 6 | `CONTEXT.md` | Frozen API contracts + data models + logins + hard rules (paste into AI prompts) |
> | 7 | `DESIGN.md` | Frozen visual tokens, forbidden list, component/screen specs, mobile (§10–§16) |
> | 8 | `customer-web/README.md` | Shop SPA deep dive |
> | 9 | `admin-web/README.md` | Dashboard deep dive |
> | 10 | `backend/README.md` | API deep dive |
> | 11 | `customer-app-v2/README.md` | Flutter v2 Big README (409 lines: architecture, API map, lessons, FAQ) |
> | 12 | `docs/phase-1-foundation-spec.md` | Phase 1 requirements + acceptance criteria |
> | 13 | `docs/local-development.md` | Local dev notes (paths, emulator loopback, ports) |
> | 14 | `docs/firebase-auth-plan.md` | Firebase-as-identity-provider plan (Option A recommended) |
> | 15 | `docs/supabase-rls-lockdown.sql` | RLS lockdown SQL reference |
> | 16 | `Shop_Stock_Checklist_README.md` | Original shop stock checklist (Tamil/English, 480 lines — seed source) |

---

## TABLE OF CONTENTS

- [PART 1 — WHAT: the product](#part-1--what-the-product)
- [PART 2 — QUICKSTART: zero to running](#part-2--quickstart-zero-to-running)
- [PART 3 — REPO MAP: every file and folder](#part-3--repo-map-every-file-and-folder)
- [PART 4 — CUSTOMER-WEB: the shop](#part-4--customer-web-the-shop)
- [PART 5 — ADMIN-WEB: the dashboard](#part-5--admin-web-the-dashboard)
- [PART 6 — BACKEND: the API](#part-6--backend-the-api)
- [PART 7 — FLUTTER: mobile apps](#part-7--flutter-mobile-apps)
- [PART 8 — CROSS-CUTTING FLOWS](#part-8--cross-cutting-flows)
- [PART 9 — CI/CD + HOSTING BIBLE](#part-9--cicd--hosting-bible)
- [PART 10 — LAWS AND CONVENTIONS](#part-10--laws-and-conventions)
- [PART 11 — HISTORY LEDGER](#part-11--history-ledger)
- [PART 12 — REMAINING WORK MASTER LIST](#part-12--remaining-work-master-list)
- [PART 13 — TROUBLESHOOTING MEGA-TABLE](#part-13--troubleshooting-mega-table)
- [PART 14 — GLOSSARY + CHEAT SHEETS](#part-14--glossary--cheat-sheets)

---

# PART 1 — WHAT: the product

## 1.1 The one-sentence pitch

EASYGET is a **quick-commerce (q-commerce) SaaS platform**: many
neighborhood stores sell on one marketplace with near-store delivery,
and every merchant gets a **visual storefront builder** (no-code theme +
sections) instead of hiring developers.

## 1.2 The problem it solves

- Supermarkets: good prices, far away, slow, bulk minimums.
- Kirana / mom-and-pop stores: near you, but invisible online — no
  browsing, no pre-orders, word-of-mouth discovery only.
- Amazon/Flipkart/quick-commerce giants: discovery + speed, but heavy
  commissions, small stores buried under the giant's brand, no
  merchant-owned storefront.
- Custom websites: too expensive/technical for a small merchant.

EASYGET's answer: one account → design your store → list products →
track inventory → receive/fulfill orders → deliver. Customers get one
shop/app where nearby stores and real availability are visible.

## 1.3 The four surfaces (one backend)

| # | Surface | Folder | Tech | Serves | Local URL | Live URL |
|---|---|---|---|---|---|---|
| 1 | Backend API | `backend/` | Django 5.2 + DRF + Channels | All three clients | `http://localhost:8000` | `https://easyget-api.onrender.com` |
| 2 | Customer web (shop) | `customer-web/` | React + TS + Vite, hash router | Shoppers (guest + signed-in) | `http://localhost:3000` | `https://easyget-customer.pages.dev` |
| 3 | Admin web (dashboard) | `admin-web/` | React + TS + Vite, hash router | Staff + merchants | `http://localhost:5174` | `https://easyget-admin.pages.dev` |
| 4 | Mobile app | `customer-app-v2/` (active), `customer-app/` (frozen reference) | Flutter 3.38 + Riverpod + go_router + Dio | Shoppers on Android/iOS | emulator/device | not yet released |

Architecture (all clients → one API):

```
customer-web (:3000)   admin-web (:5174)   Flutter app (device/emulator)
        │                     │                       │
        └─────────────┬───────┴───────────┬───────────┘
                      ▼                   ▼
            Django REST API (:8000 local / easyget-api.onrender.com live)
               │                │                  │
     Supabase Postgres   Upstash Redis      Supabase Storage (media)
     (live data)         (cache/broker)     (product/section images)
```

## 1.4 Who uses what

- **Guest shopper**: browse home/browse/search/product, pincode check,
  wishlist hearts (device-only until login). Cart/checkout/orders force
  login first.
- **Signed-in customer**: cart, split checkout, orders + timeline,
  address book, server wishlist, reviews (one per product).
- **Merchant (tenant member)**: dashboard, orders queue, categories,
  products, inventory, reviews; Users + Storefront designer are
  ADMIN-only (merchants fall back to Dashboard).
- **ADMIN/staff**: everything above + users, storefront designer,
  banners, coupons, config, audit, tasks. Staff API view bypasses
  product visibility (sees drafts/inactive/unstocked).
- **Delivery agent**: assignment pool + advance states (app/API).

## 1.5 Brand and company

- Product brand: **EASYGET** (API service id `easyget-api`).
- Org shipping it: **TRISENTRICS AI**, GitHub org `trisentricai`,
  repo `trisentricai/EasyGet`, SSH `git@github.com:trisentricai/EasyGet.git`.
- Repo-local git identity: `Rahul Bharathi <mailtorahulbharathi@gmail.com>`
  (global identity untouched).

## 1.6 Logins (dev — safe to share, all seeded for development)

| Role | Email | Password | Where |
|---|---|---|---|
| Admin (staff/superuser) | `admin@easyget.local` | `EasyGet!2026` | admin-web, Django admin |
| Customer | `customer@easyget.app` | `Customer@123` | shop, app |
| Merchant | `merchant@easyget.app` | `Merchant@123` | app (tenant member) |
| Delivery agent | `agent@easyget.app` | `Agent@123` | app (assignment pool) |

## 1.7 Live data snapshot (2026-10-12, verified by direct query)

- **216 active products** in the catalog (the "200" in older docs grew).
- **202** have stock in `EasyGet Demo Store` (id 2, slug `rahuls-store`,
  kept for Flutter/legacy); **14** are active platform products with
  zero stock rows → served as **Out of Stock** (see Part 8.2).
- Stores: id 2 `EasyGet Demo Store` (active), id 3 `EASYGET` platform
  store (slug `easyget`, `is_platform=true`, `tenant=NULL`, active).
- Demo coupons seeded: `WELCOME10` (10% up to ₹100), `FLAT50` (₹50 off
  ≥ ₹299), `FREESHIP`.
- 20 brands, 10+ categories, rating aggregates live.

---

# PART 2 — QUICKSTART: zero to running

## 2.1 Prerequisites (install once)

- **Python 3.11** — venv lives at repo root `.venv/` (recreate: `python -m
  venv .venv`, then `.\.venv\Scripts\pip install -r requirements.txt`).
- **Node 18+** (22 recommended per `docs/local-development.md`) — one
  `node_modules` per web app (`npm install` inside each).
- **Flutter 3.38 / Dart 3.10** — only for mobile (`flutter pub get`).
- **`.env` at repo root** — copy `.env.example`; Django reads it **only
  at startup** (restart backend after edits). Committed `.env` already
  points at live Supabase → **no Docker needed** for normal work.
- **No Docker needed** for daily work. `docker-compose.yml` (postgres 16
  + redis 7) exists for optional local infra.
- **Git + SSH**: `ssh -T git@github.com` should greet you; repo-local
  identity already configured — do not set global identity.

## 2.2 The 4 terminals (PowerShell, repo root)

**Terminal 1 — Backend API (start first, leave running):**
```powershell
.\.venv\Scripts\python.exe backend\manage.py runserver 0.0.0.0:8000 --noreload
```
- Health: `http://localhost:8000/api/v1/health/` → `{"status":"ok"}`
- Docs: `http://localhost:8000/api/docs/` (Swagger), `/api/schema/`
- Always run `manage.py` from the **repo root** with path
  `backend\manage.py`. `gunicorn` runs ONLY on Render/Linux (dies on
  Windows with `fcntl` error — local dev uses `runserver`).
- Port busy? `Get-NetTCPConnection -LocalPort 8000 -State Listen` →
  `Stop-Process -Id <pid> -Force`.

**Terminal 2 — Admin dashboard:**
```powershell
cd admin-web; npm install   # first time only
npm run dev                 # → http://localhost:5174
```

**Terminal 3 — Customer shop:**
```powershell
cd customer-web; npm install   # first time only
npm run dev                    # → http://localhost:3000
```
- Port is **3000** (vite config), NOT 5173. Vite binds IPv6 localhost —
  open `http://localhost:3000/` (NOT `127.0.0.1`).

**Terminal 4 — Flutter app (optional, needs emulator/device):**
```powershell
cd customer-app-v2; flutter pub get; flutter run
```
- App defaults to `http://10.0.2.2:8000/api/v1` (Android emulator
  loopback). Build check: `flutter build apk --debug`.

## 2.3 First-run verification checklist (do all green before coding)

1. `GET /api/v1/health/` → 200 `{"status":"ok"}`.
2. `GET /api/v1/products/?page_size=5` → 200 `{count, next, results[]}`,
   every row has `in_stock`.
3. `GET /api/v1/products/jasmine-gold-hair-oil/` → 200,
   `in_stock:false` (the Out-of-Stock proof).
4. `POST /api/v1/search/ {"q":"jasmine"}` → 1 result, same flag.
5. Shop home loads: banners → Deals → full catalog tail scrolls.
6. Admin login works; Products shows `No stock` badges on the 14.
7. `manage.py check` → 0 issues; `npm run build` green in both webs.

## 2.4 Test commands (copy-paste)

```powershell
# Backend FULL suite — cwd MUST be backend/, SQLite hermetic (like CI):
cd backend
$env:DATABASE_URL='sqlite:///db.sqlite3'; $env:DJANGO_DEBUG='true'
python manage.py test -v 1            # ~293 tests, ~3 min → OK (skipped=1)
# Catalog slice only (~1 min):
python manage.py test products tenants search -v 1
# Web builds (both must pass — tsc + vite):
cd ..\customer-web; npm run build
cd ..\admin-web;    npm run build
```

---

# PART 3 — REPO MAP: every file and folder

## 3.1 Root files (what each one is)

| Path | What it is | Touch? |
|---|---|---|
| `README.md` | THIS file — master doc | update when system changes |
| `CONTEXT.md` | Frozen facts: API contracts, models, folders, stack targets, logins, hard rules. Paste into every AI prompt with `DESIGN.md` | only on contract/folder change |
| `DESIGN.md` | Frozen visual law: tokens §1, forbidden list §2, component/screen rules, NEXT_UI §8, mobile tokens §10–§16 (768 lines) | frozen — do not edit casually |
| `PROJECT.md` | WHY/WHAT/HOW capstone (vision, principles, build order, history to 2026-09-26) | historical |
| `GETTING_STARTED.md` | 4-terminal run guide, logins, works-list, tests, troubleshooting | keep current |
| `currentUpdate.md` | Live session ledger (500 lines, newest first, §0 entries per session) | update WITH GitCheck.md after every change |
| `GitCheck.md` | Git rules, SSH, changelog table, gotchas, command reference | update WITH currentUpdate.md |
| `.env` / `.env.example` | Secrets (gitignored) / safe template | never commit `.env` |
| `requirements.txt` | 21 pinned Python deps (Django 5.2.17, DRF 3.18.1, …) | pin deliberately |
| `docker-compose.yml` | Optional local postgres:16 + redis:7 | optional infra |
| `db.sqlite3` | Local SQLite file (tests hermetic) | never commit |
| `media/` | Local uploaded images (dev) | never commit |
| `staticfiles/` | `collectstatic` output (deploy artifact) | generated |
| `Shop_Stock_Checklist_README.md` | 480-line Tamil/English stock checklist (xlsx conversion) — **seed source** of the 200-product catalog via `seed_shop_catalog` | reference |
| `scripts/audit_contrast.py` | Standalone contrast-audit script (accessibility) | tool |
| `.github/workflows/ci.yml` | CI: backend check+tests (SQLite), both web builds — every push/PR | keep green |
| `.github/workflows/deploy-cloudflare.yml` | Builds + `wrangler pages deploy` to `easyget-customer` + `easyget-admin` on frontend pushes to `fix/flutter-web-and-ordering`/`main` | deploy path |
| `.github/workflows/preview-shots.yml` | Playwright Chromium shots (375/768/1280 × light/dark) of `preview.html` → `preview-shots` artifact, every customer-web push | visual evidence |
| `.github/workflows/repo-hygiene.yml` | Fails on tracked secrets: `.env` not ignored, env/key/keystore files tracked, key-token patterns in content | security guard |
| `.venv/` | Python virtualenv | never commit |
| `customer-web/node_modules`, `admin-web/node_modules` | JS deps | never commit |
| `customer-web/dist`, `admin-web/dist` | Production builds | never commit (rebuilt in CI/deploy) |
| `*.log` (`server_*.log`, `backend-dev.*.log`, `*/dev.*.log`) | Dev process logs | never commit |
| `.wrangler/` | Wrangler local state (Cloudflare) | machine-local |
| `.freebuff/`, `.kilo/`, `.superpowers/`, `.idea/` | Tool/IDE state dirs | machine-local |
| `easyget-google-ai-studio/` | Google AI Studio Gemini scaffold (needs `GEMINI_API_KEY`) — **side experiment, NOT part of the product** | leave alone |
| `customer-app-v2/tool/` | Flutter codegen/tool scripts (build_runner etc.) | app tooling |

## 3.2 Folder purposes (one line each)

- `backend/` — Django project (`config/` + 20 feature apps).
- `customer-web/` — shop SPA → :3000 → Cloudflare `easyget-customer`.
- `admin-web/` — dashboard SPA → :5174 → Cloudflare `easyget-admin`.
- `customer-app-v2/` — ACTIVE Flutter app (Fresh Market rewrite, Big README inside).
- `customer-app/` — FROZEN v1 reference (read-only; do not build features there).
- `docs/` — phase-1 spec, local-dev notes, Firebase plan (175 lines, Option A),
  RLS SQL, `superpowers/` (design specs + implementation plans per feature).
- `customer-web/screenshots/`, `customer-web/public/` — captures + static assets.
- `customer-app-v2/assets/` — bundled fonts (Zodiak OTF) + images.
- `customer-app-v2/test/` — 332 green widget/unit tests (per v2 README).

---

# PART 4 — CUSTOMER-WEB: the shop

*(Full deep dive: `customer-web/README.md`. This part is the complete
summary — every route, component, and rule.)*

## 4.1 Identity

- Package `easyget-customer-web` 0.1.0, React + ReactDOM + Vite
  (`latest` tags; project targets React 18 behavior), TanStack Query 5,
  Tailwind v4 (vite plugin), Geist Mono font, Playwright (dev).
- Scripts: `dev` (port 3000 + `/api`→`:8000` proxy), `build`
  (`tsc --noEmit && vite build`, multi-page: `index.html`,
  `preview.html`, `privacy.html`), `preview`.
- Live: `https://easyget-customer.pages.dev/#/home`.

## 4.2 Routes (hash router — `hooks/useHashRoute.ts`, switch in `App.tsx`)

`#/home` (HomePage) · `#/browse?category=` (BrowsePage, remounts per
category) · `#/product/<slug>` (ProductPage, remounts per slug) ·
`#/search?q=` (SearchPage, remounts per query) · `#/categories`
· `#/cart` · `#/checkout` · `#/orders` · `#/order/<id>` · `#/account`
· `#/wishlist` · `#/login` (AuthPage). Unknown → HomePage. Personal
routes (`cart,checkout,orders,order,account,wishlist`) hold a Spinner
until auth resolves, then bounce guests to login. `href()` builds
links, `navigate()` moves (optional `{replace:true}`).

## 4.3 Pages deep dive

**HomePage** — storefront render + discovery. Order: `BannerCarousel`
(HERO/BANNER) → designed sections (`SectionRenderer`: HERO, BANNER,
CATEGORY_GRID via `CategoryTiles`, PRODUCT_ROW grid, IMAGE_GALLERY,
RICH_TEXT) → `WelcomeHero` only when zero sections → `DealsRail` (top
discounts from 60 fetched, top 12, midnight countdown) → `RecommendedRail`
(`topCategory()` from recent views → 12 of that category) →
`RecentlyViewedRail` (device cache) → `AllProductsGrid` (2026-10-12:
full catalog, 20/page infinite scroll + `Load more (N left)`, skeleton
loading, error `EmptyState`).

**BrowsePage** — sidebar filters (category/brand radios, discount
10/25/50, min/max price, featured), sort bar (Relevance/price±/newest/
rating) + live count, active-filter chips + Clear all, infinite grid
(sentinel 1px, 200px rootMargin, auto-fetch + conditional Load More),
mobile Filters toggle. Query key includes params + user id.

**ProductPage** — `getProduct(slug)`; gallery (primary + thumbs, `fx`
follows selection); brand/category breadcrumb; rating pill + count;
price block (now/MRP/%off); `in_stock===false` → `chip-err` + "not
stocked right now" note, Add/Buy disabled with "Out of stock" label;
offers list (`offerLine()`); variant buttons (active only); description;
highlights; buybox (pincode checker → ETA date + fee label, qty stepper
1–10, seller box EASYGET/7-days/COD-UPI); `SimilarRail` (same category,
excludes self, cards carry Out-of-stock chip); `ReviewsSection`
(avg + 5→1 bars, list, star-picker form when signed in, 409 message).

**SearchPage** — suggestions dropdown, `searchWithFallback({q,sort})`
(backend POST, else tokenized local match over `listAllProducts`),
recents + trending (`TRENDING_SEARCHES`), category filter chips, same
sorts. Cards are `ProductCard` (badged).

**CartPage** — signed-in; lines grouped `Sold by {seller}` + per-seller
subtotal; steppers (DELETE+re-POST rewrite); clear; totals from `/cart/`
only (never client math as truth).

**CheckoutPage** — address select/book + instructions; review groups per
seller; "N orders — one per seller" notice; split placement → toast `N
orders placed!` → orders list; legacy single-store fallback.

**OrdersPage/OrderDetailPage** — list (status chips, seller lines) +
detail (items, `status_history` timeline, cancel w/ reason in
PENDING/CONFIRMED).

**AccountPage** — profile PATCH + address CRUD + default setter.
**WishlistPage** — server list grid + empty state. **CategoriesPage** —
all categories. **AuthPage** — login/register/OTP-legacy/Google.

## 4.4 Component catalog

`components/ui.tsx`: `money()` (INR, 2dp) · `Monogram` (initials
placeholder) · `Price` (now/MRP/off, sm/md/lg) · `RatingPill` (★ avg +
k-count, null when unrated — never "0.0") · `WishButton`
(optimistic server sync when signed in, device cache otherwise) ·
`ProductCard` (thumb+fx, deal≥50%/featured/**Out-of-stock** chips,
heart, brand, name, rating row, price, free-ship|out-of-stock line) ·
`Section` (title/subtitle/action) · `Spinner` · `CardSkeletonGrid` ·
`EmptyState` (icon/title/text/action) · `StatusChip` · `SignInGate` ·
`usePopOnChange` (cart bubble pop). `components/marketplace.tsx`:
`BannerCarousel` (+`HeroSlide` 4.5s autorotate, arrows, dots),
`DealsRail`, `CategoryRail` (shares `["categories"]` cache),
`RecentlyViewedRail`, `RecommendedRail`, `AllProductsGrid`.
`components/ticker.tsx`: merchant ticker bar. `components/icons.tsx`:
icon set (+14 marketplace icons). `components/category-tiles.tsx`:
grid tiles + `normalizeTileStyle`.

## 4.5 Contexts + data layer

`QueryClient` (stale 30s, no refocus, retry 1). `AuthProvider`
(user/ready/signIn/signOut, global-401 → signOut). `CartProvider`
(lines/count/add, add = server POST). `StorefrontProvider`
(platform render; theme cached to `eg-store-theme`). `ToastProvider`
(push/err toasts). `services/api.ts`: `ORIGIN/BASE`, token store
(`eg-cust-tokens`), `ApiError/errText/fieldErrors` (DRF + JWT +
legacy-repr parsing), 401→refresh→purge→anonymous-retry, `asArray`,
`img()`, storefront/auth/addresses/products/offers/wishlist/pincode/
brands/reviews/categories/search (`searchWithFallback`)/cart/orders/
stores CRUD + every exported type (`Product` += `in_stock?`,
`ProductDetail`, `Paged<T>`, `Cart`, `Order…`). `utils/history.ts`:
recents (12, now with `inStock`), searches (8), wishlist cache,
`toProductCard`, `topCategory`, `purgeLocalUserData` (all `eg-*`).
`utils/imageFx.ts`: `fxClass/fxStyle` (absent knobs = no-op).
`flags.ts`: `isNextUi()` (`?next_ui=` > localStorage > `VITE_NEXT_UI`).

## 4.6 Theme, tokens, CSS, storage, deploy

- Merchant theme → CSS vars at runtime; `index.html` pre-paints cached
  theme pre-first-paint (no flash); `data-theme` light/dark, Sun/Moon
  toggle, OS listener until explicit choice, 200ms switch transition
  (reduced-motion aware), dark palette `!important` over merchant bg.
- LAW (`DESIGN.md` §1–§2): token vars only, zero hardcoded hex/px in new
  code, light+dark, lists = skeleton+empty+error, no purple/blue
  gradients, no glass, no red SALE theater, no countdowns (Deals
  countdown predates the rule — grandfathered), no `alert()`, 44px
  targets, serif display + Inter body + Geist Mono numerals.
- Storage keys: `eg-cust-tokens, eg-store-theme, eg-theme, eg-next-ui,
  eg-recent-views, eg-recent-searches, eg-wishlist`.
- Build inputs `index.html/preview.html/privacy.html`; deploy via
  `deploy-cloudflare.yml` → Pages `easyget-customer` (API URL baked).

---

# PART 5 — ADMIN-WEB: the dashboard

*(Full deep dive: `admin-web/README.md`.)*

## 5.1 Identity

- Package `easyget-admin-web` 0.1.0, React + Vite + TanStack Query 5,
  TS strict, hand CSS (`styles.css` + `shell-collapse.css`), no UI kit.
- `dev` port **5174**; `build` = tsc + vite. Live:
  `https://easyget-admin.pages.dev` (Pages project `easyget-admin`).

## 5.2 Routes + roles

`#/dashboard` (stats) · `#/orders` (queue + advance/cancel) ·
`#/categories` (CRUD) · `#/products` (CRUD + variants + gallery +
display editor) · `#/reviews` (approve/hide/delete, filters) ·
`#/inventory` (table + adjust modal + audit) · `#/users` (ADMIN) ·
`#/storefront` (designer, ADMIN; merchants fall back to Dashboard).
Unknown → Dashboard. Sidebar (collapsible) + topbar (clock, role badge,
`ThemeToggle` via `ThemeContext`).

## 5.3 Screens deep dive

**ProductsPage** (most complex — learn it): toolbar (text search over
loaded list + category filter + New disabled until categories load);
table (name/slug, category, MRP, price, Flags, Edit/Delete); flags
`Hidden` / **`No stock`** (2026-10-12, tooltip: customers see Out of
Stock) / `Featured` / `Live`; modal (`Draft` + `VariantRow[]`, presets
250g…Pack of 2, empty-price rows skipped, edits by id, unknown id 400);
images (create: staged → uploaded post-save with counts toast; edit:
instant multipart; ★ primary demotes rest; ✎ `ImageDisplayEditor`
align-grid/sliders/effect/caption → PATCH; delete-primary promotes
next); `ConfirmDialog` on delete.

**InventoryPage**: SKU/store/price/qty-vs-threshold/Healthy-Low-Out
badges; `AdjustModal` (quick −10/−1/+1/+10/+50, reason, note, <0
blocked); every adjust writes `InventoryTransaction` (`performed_by`).

**StorefrontPage** (ADMIN): `Sections | Store theme` tabs; DnD reorder
→ `/reorder/`; inline rename → PATCH; Design modal (columns 1–6,
size, effects); theme panel (colors/font/button); HERO/BANNER/
IMAGE_GALLERY image block (immediate multipart PATCH, `{image:null}`
removes); add pickers; hide/show toggles. Renders the **platform**
store; cache self-invalidates.

**OrdersPage**: pills + counts, table, detail modal (items, timeline,
advance mirroring backend map, cancel+reason). **ReviewsPage**:
All/Needs-approval/Approved, stars/body/reviewer+verified/Live-Hidden
badge/date, Approve-Hide toggle + Delete. **DashboardPage**: users/
orders/revenue/products + low-stock. **UsersPage/CategoriesPage**: as
named.

## 5.4 Client, law, deploy

`services/api.ts`: staff view of `/products/` (unfiltered — trust Flags,
not gut), `listAllProducts`, `getProduct`, image helpers
(`upload/setPrimary/update/delete`, `mediaSrc`, `toImageDisplay`,
`DEFAULT_IMAGE_DISPLAY`, `EFFECT_LABELS`), inventory adjust, order
status PATCH. `ImageDisplayEditor.tsx` shared editor. Same token/dark/
states law as shop. Deploy: `deploy-cloudflare.yml` → `easyget-admin`.

## 5.5 The merchandising golden rule (memorize)

Buyable ⇔ `is_active` + ≥1 active priced variant + `in_stock`
(qty>0, active store). Platform + first two − third = **Out of Stock**
(visible). Merchant − third = **invisible**. Creating a product covers
only the first two — **then add stock in Inventory**, else nobody can
buy it. (This gap caused the Oct 2026 incident: 14 "Live"-badged
products 404ing in the shop.)

---

# PART 6 — BACKEND: the API

*(Full deep dive: `backend/README.md`. This part is the complete
contract + internals.)*

## 6.1 Identity

Django 5.2.17 + DRF 3.18.1 + SimpleJWT 5.5 + cors-headers + environ +
celery/redis + channels + spectacular (docs) + ratelimit + redis-cache +
beat + requests + Pillow + psycopg + gunicorn + whitenoise + storages[S3]
+ google-auth. Python 3.11, `.venv` at root. Dev DB Supabase Postgres;
tests SQLite. Deploy: Render `easyget-api` (Singapore, free, 2×gunicorn,
120s timeout, automigrate+collectstatic on boot).

## 6.2 Run + test (exact)

```powershell
.\.venv\Scripts\python.exe backend\manage.py runserver 0.0.0.0:8000 --noreload
# health /api/v1/health/ · docs /api/docs/ · schema /api/schema/
cd backend; $env:DATABASE_URL='sqlite:///db.sqlite3'; $env:DJANGO_DEBUG='true'
python manage.py test -v 1                  # 293 tests, ~3 min, OK (skipped=1)
python manage.py test products tenants search -v 1   # catalog slice
python manage.py check                      # 0 issues (also in CI)
```

## 6.3 Endpoint reference (every route, with shapes)

Conventions: base `/api/v1/`; JWT `Authorization: Bearer <access>`;
pagination `{count,next,previous,results}` page_size ≤20 everywhere;
explicit stable orderings; error envelope
`{error:{code,message,details}}`; product 404 message is literally
`"No Product matches the given query."`.

**AUTH**
- `POST /auth/register/` — `{email, password≥10, first_name?,
  last_name?, phone?, role?}` → 201 `{message, user}`; email
  auto-verified; CUSTOMER default; weak/numeric/com­mon passwords 400
  (validators live); throttled 3/min.
- `POST /auth/login/` — `{email, password}` → 200
  `{access, refresh, user}`; throttled 5/min (burst → 429, verified).
- `POST /auth/refresh/` — `{refresh}` → 200 `{access}` (NO rotation;
  `ROTATE_REFRESH_TOKENS=False`).
- `POST /auth/logout/` — `{refresh}` → blacklists it (later use 401).
- `POST /auth/verify-otp/` `{email, code}` / `POST /auth/resend-otp/`
  `{email}` — legacy email-OTP (6-digit, 10-min, 5-attempt cap);
  uniform `OTP_INVALID_MESSAGE` + silent resend quota (≥4/10min) to stop
  enumeration; throttled 10/min.
- `POST /auth/google/` — `{id_token}` → tokens; **503** when
  `GOOGLE_OAUTH_CLIENT_IDS` empty (dev default).

**USERS**
- `GET /users/me/` → `User`; `PATCH` `{first_name,last_name,phone}`.
- `GET/POST /users/me/addresses/` — `{label,line1,line2,city,state,
  postal_code,country,phone,is_default}` (first auto-default; exactly
  one default enforced).
- `PATCH/DELETE /users/me/addresses/:id/` ·
  `POST .../:id/set-default/`.

**PRODUCTS** (`products/`, slug lookup, router `""`)
- `GET /products/` — filters `category,brand(iexact),min_price,
  max_price(via min_variant_price annotation — never the python
  property),min_discount(guarded MRP>0 math),is_featured=true`;
  sorts `price_asc/price_desc/newest/rating(nulls-last, count
  tiebreak)/default(-updated_at,-id)`; each row:
  `{id,name,slug,category{},brand,mrp,base_price,discount_percent,
  is_featured,is_active,primary_image,primary_image_display,
  rating_avg,rating_count,in_stock}`.
- `GET /products/:slug/` — detail: above + `description, offers[≤5
  active coupons], variants[{id,name,sku,price,discount_percent,
  is_active}], images[], created_at, updated_at, in_stock`.
- `GET /products/brands/` — distinct non-empty (public; registered
  before router so slug lookup can't swallow it).
- `GET /products/wishlist/` (auth, paged) · `POST/DELETE
  /products/wishlist/:slug/` → `{added, slug, count}` (idempotent).
- `GET /products/:slug/reviews/` (approved-only, 10/page) ·
  `POST` `{rating 1-5,title?,body?}` → 201 / **409** duplicate
  (verified badge derived from DELIVERED orders; names masked).
- `GET/POST /products/:slug/images/` (file required 400;
  sort=max+1; first forced primary; `is_primary` demotes atomically) ·
  `PATCH/DELETE /products/images/:id/` (partial: file/caption/
  primary/sort; delete-primary promotes next). Reads public; writes
  auth + tenant-writer + object-member (checked against the product;
  tenant-less platform = staff-only). Files → WebP ≤800px on save.
- Writes `POST/PATCH/DELETE /products/` — staff or tenant member;
  creates bind creator's tenant (non-member non-staff 403 "join a
  tenant"); variants round-trip by id.

**VISIBILITY (the law — `products/views.py:get_queryset`)**
staff → all; tenant member → own (even inactive) + active platform +
stocked-active; others → `is_active` AND (`tenant IS NULL` OR stocked
via active store). `in_stock` = qty>0 in active store, injected in
views (one extra query/page; serializers untouched). Ratings via
`with_rating_stats()` subqueries (join-duplication immune).

**SEARCH** (`search/`)
- `POST /search/` — `{q?,category?,store?(UUID),min_price?,max_price?,
  is_featured?,sort?,page?=1,page_size?≤20=20}` → `{results[] (+score,
  highlight=null today, in_stock), total, page, page_size, took_ms,
  query}`. PG: OR-token `websearch` + ILIKE net (name/brand/tags/
  description/category/index); SQLite: ILIKE-only (same contract).
  Normalizer strips punctuation/case ("black board"→"Blackboard").
  Sorts: relevance(-rank,-featured,-created)/price±/newest/popular
  (order counts)/rating(subquery). Query+popularity logged
  (Celery, inline fallback). NOTE latent: price filters reference a
  non-ORM `base_price` — use `min_variant_price` before relying on them.
- `GET /search/suggestions/?q=` (≥2 chars) → popular-prefix + name/tag
  hits, deduped ≤10.

**CART** (`cart/`, auth)
- `GET /cart/` → `{id,store,items[{id,variant{id,name,sku,price,
  attributes?},quantity,line_total,tenant_id,seller_name}],total_items,
  subtotal}` (seller resolved: active non-platform store → tenant name
  → "EasyGet", prefetched).
- `POST /cart/items/` `{variant_id,quantity}` upsert-increment (NO
  stock check — known gap) · `DELETE /cart/items/:id/` (PATCH 405s
  live!) · `POST /cart/merge/ {session_key}` · `DELETE /cart/clear/`.

**ORDERS** (`orders/`)
- `POST /orders/` `{cart_id,store?,delivery_address,
  delivery_instructions?}` — WITHOUT `store`: resolve ALL sellers
  first (dead seller → 400, nothing created) → one Order+items per
  seller atomically → `{orders:[...]}`; WITH `store`: legacy single.
- `GET /orders/` (+item_count, store_name) · `GET /orders/:id/`
  (+items[], status_history[]) · `POST /orders/:id/cancel/ {reason}`
  (PENDING/CONFIRMED only) · `GET /orders/:id/invoice/`.
- States: PENDING→CONFIRMED→PREPARING→READY→OUT_FOR_DELIVERY→
  DELIVERED (+CANCELLED/REFUNDED); number `EZG-YYYYMMDD-XXXX` (no
  retry loop yet).

**PAYMENTS / DELIVERY / COUPONS / BANNERS**
- `GET /payments/methods/` (CARD|UPI|WALLET|COD) · `POST /payments/`
  `{order,gateway∈RAZORPAY/STRIPE/PHONEPE/COD,amount,
  payment_method_id?}` (direct create — NO intent/confirm endpoints
  exist) · `GET /payments/refunds/` · `POST /payments/:id/refund/
  {amount,reason}` (validated vs payment — no oracle; order must be
  requester's).
- `GET /pincode/:code/` → `{valid,pincode,city,state,eta_days,
  delivery_fee,free_delivery_over,source}` — postal-API lookup (browser
  UA; state alias map e.g. TN↔Tamil Nadu), ETA 2d same-state/4d else,
  ₹29 < ₹499 else free (STRINGS), process cache + offline heuristic,
  **404** = undeliverable.
- `POST /admin/coupons/validate/ {code,order_value}` (any authed user)
  → `{valid,discount,…}` | 400 · `GET /banners/` (paged active).

**STOREFRONT (public, cached 1h, signal-invalidated)**
- `GET /storefront/platform/` (flag lookup, before slug route) and
  `GET /storefront/:store_slug/` → `{store,theme,sections[],ticker}`.
- Types HERO·BANNER·CATEGORY_GRID·PRODUCT_ROW·IMAGE_GALLERY·RICH_TEXT;
  item guard: platform links ANY active product, merchants tenant-strict
  (400 cross-tenant); inactive-section GET 404s for public.
- Manage: sections GET(public active)/POST, PATCH/DELETE, reorder
  `{order:[ids]}`; items GET/POST, PATCH/DELETE, reorder; theme GET
  public / PATCH manager (JSON or multipart).

**ENGAGEMENT / ADMIN / MISC**
- Notifications: list, `:id/mark_read/`, `mark_all_read/`,
  `unread_count/`, `preferences/` (+all/bulk).
- `POST /realtime/devices/` · `POST /analytics/events/` (+`/batch/`) ·
  `POST /pwa/updates/check/` · WS `/ws/orders/`, `/ws/notifications/`
  (order/room access-checked).
- `GET /admin/dashboard/` (users/orders/revenue/products+low_stock) ·
  orders queue + `:id/status/` · reviews (filters `approved,product`,
  bare array) · coupons/banners/tasks/config/audit CRUD.
- `GET /api/v1/health/` → `{"status":"ok"}` (AllowAny, unthrottled).

## 6.4 Models (reference — DO NOT modify)

User (email login, roles CUSTOMER/ADMIN/STORE_MANAGER/DELIVERY_AGENT,
`is_email_verified` gate, min-length-10+ validators) · OTPCode (6-digit,
10-min, 5-attempt) · Tenant/TenantMembership(OWNER/MANAGER, unique) ·
Store (tenant FK nullable, slug, `is_platform` + partial unique, address/
geo, active) · Category (parent self-FK, slug, icon, sort, active;
SHARED platform taxonomy by design) · Product (tenant nullable=null ⇒
platform, category PROTECT, slug auto+suffixed, mrp, active/featured,
tags; `base_price`/`discount_percent`/`primary_image` python props) ·
ProductVariant (sku auto, price, active; `ordering=[sku]`) ·
ProductImage (+`ImageDisplayFields`: align 0–100 def 50, zoom 1–3 def 1,
effect none/zoom/pan/grayscale, transition 0–2000 def 400) ·
ProductReview (UNIQUE product+user, CHECK 1–5, verified flag,
is_approved) · WishlistItem (UNIQUE user+product) · StockItem
(tenant denormalized, UNIQUE store×variant, qty, low threshold 5;
`is_available/is_low_stock` props) · InventoryTransaction (change,
reason, note, performed_by) · Cart/CartItem · Order (UUID pk,
tenant, store, status machine, money fields, address JSON) /
OrderItem/OrderEvent · Payment (gateway, status, amount, reference) ·
Coupon (code, type PCT/FIXED/FREE_DELIVERY, value, max, min subtotal,
window, applies_to ALL/CATEGORY/PRODUCT + FKs, usage) · Banner ·
StorefrontTheme/StoreSection/SectionItem · notification/preference/
device/event-log/pwa/webhook models.

## 6.5 Permissions matrix (who can do what)

- Public (AllowAny): health, product/search/category/brand/review/image
  GETs, storefront renders, pincode.
- Authed: cart, orders, wishlist, review POST, coupon validate,
  addresses, devices, analytics.
- Tenant-writer/member: product/store/stock writes (object-scoped;
  foreign → 403/404, cross-tenant stock → 400, stock adjust → member of
  item's tenant, qty floor 0, audit row).
- ADMIN/staff (`IsAdminOnly`): admin_* routers, PWA writes, webhooks,
  user lists, storefront designer, bypass visibility.
- Delivery tiers: assign=writers, list/advance=authed, agent PII scoped
  (own tenant or unassigned pool).
- Throttles (live): register 3/min, login 5/min, otp 10/min, anon search
  anti-scrape (requires working cache — see 6.7).

## 6.6 Subsystems worth knowing

- **Cache** (`common/cache.py`): 1h cache-aside storefront renders +
  public categories; signal invalidation; Redis down ⇒ slow-but-correct
  (`IGNORE_EXCEPTIONS`); `CACHES … protocol:2` (redis-py8 HELLO vs old
  server silently killed ALL caching/throttling once — fixed).
- **Search index**: `ProductSearchIndex` + `rebuild_search_index`
  command + query/popular logs (Celery-or-inline).
- **Media**: local `media/` in DEBUG (`static()` route + webp mimetype
  fix); LIVE = Supabase Storage bucket `easyget-media` (public, S3
  interop, 6 `SUPABASE_S3_*` envs) → absolute URLs; `SERVE_MEDIA_EPHEMERAL`
  auto-disables; DELETE orphans S3 objects (no post_delete cleanup);
  pre-cutover `/media/` rows (ids 6, 8) point at lost ephemeral files —
  re-upload, don't migrate.
- **RLS**: `common/rls.py` via sender-less post_migrate (sender-filtered
  hooks never fire for `common` — `sql.py:45`); RLS on + anon/auth grants
  revoked on 68/68 tables; Django connects as owner (bypass); sqlite
  no-op. NO row policies (owner/service_role bypass; revisit for
  PostgREST).
- **Realtime**: Channels + channels-redis; stock signals push to store
  groups (the `Store.managers` 500 is long fixed).
- **Seed**: `seed_shop_catalog` (from the Shop Checklist: 10 cats/200
  products/variants/stock, idempotent, `--dry-run`, price placeholder
  0.00, qty 10) + `seed_platform_storefront` + `rebuild_search_index`.
- **N+1 discipline**: prefetch/annotate everywhere (Supabase pooler
  punished per-row queries: unpaginated catalog took 3.5s → 20/page cap).

## 6.7 Tests (293 green 2026-10-12, 1 skipped)

Run: backend cwd + SQLite env (Part 2.4). Regression pillars: slug/mrp
props; discovery filters + guest-public/guest-write-401 + brands;
reviews (mask/409/auth/aggregates/unapproved/verified); wishlist
(auth/add-list-remove/idempotency); rating sort + ghost-hidden +
coupon-offers; images (perms/primary rotation/display fields/platform-
staff) + primary_image-500 regression; search compound contract (3
unstocked platform fixtures — proves search lists unstocked);
tenancy (binding/create-403/foreign-404/own-200/customer-only-stocked/
inventory isolation/adjust audit); security 13 (VULN-001…013 +26
tests); split orders; platform row/route; delivery E2E. CI runs the
same suite.

---

# PART 7 — FLUTTER: mobile apps

## 7.1 v1 vs v2 (do not confuse them)

- **`customer-app/`** — original app (Riverpod 3 + go_router 17 + Dio +
  secure storage + cached images + intl). Feature-complete once
  (auth/home/browse/search/PDP/cart/checkout/orders/account, analyzer 0,
  debug APK). **FROZEN reference now — do not build features there.**
- **`customer-app-v2/`** — the ACTIVE app ("Big README", 409 lines,
  package `com.trisentric.easyget`, Flutter 3.38/Dart 3.10). Clean
  per-feature architecture (`core/` config-network-router-storage-theme-
  widgets + `features/` account/addresses/auth/browse/cart/catalog/
  checkout/delivery/engagement/home/orders/payments/product/reviews/
  search/wishlist + `models/`). Deps add: `shimmer` (skeletons),
  `flutter_animate` (motion), `google_fonts` + bundled **Zodiak** OTF
  display type, `flutter_local_notifications` (order alerts),
  `firebase_core/_messaging` (FCM push on existing project keys),
  `speech_to_text` (voice search, mic), `connectivity_plus`,
  `hive` (offline boxes), `package_info_plus` (update gate),
  `url_launcher`. Per its README: **13 screens + wishlist + engagement +
  FCM + voice, 332 tests green**. Its README is normative for app work
  (TDD gate, navigation laws, API map, lessons, FAQ) — read it before
  touching `customer-app-v2/`.
- October 2026 app log (git history, newest first): card added-state +
  live quantities; ETA/trust rows/address entry tests; dynamic delivery
  ETA + richer cart; champagne grid + obsidian glass; Zodiak type;
  gallery fallback; quick-add proof tests; view-cart→cart-tab fix;
  card quick-add pipeline + live badge + home All-products; voice
  search (camera removed); FCM wiring; update gate; local order alerts;
  notifications inbox + badge; wishlist grid + undo; search image grid +
  pagination; hero/categories/browse rails; MNC filter sheet; instant
  boot from cached profile + native splash; free Photon autocomplete (no
  key/billing); no 0.0 pills on unrated.

## 7.2 App ↔ backend contract notes

Dio client: JWT + one-shot 401 refresh (mirrors web); secure TokenStore;
emulator base `http://10.0.2.2:8000/api/v1`; paginated `{results}`
tolerance (page_size ≤20 everywhere); split-checkout `{orders}` +
  legacy `{store}` mode kept (Flutter proof in smoke tests); Google
  sign-in wired (`google_sign_in` + backend `/auth/google/`, 503 without
  IDs); Photon place autocomplete is keyless. **Parity gap**: app still
  needs the `in_stock` Out-of-Stock treatment (badge + disabled buy) —
  its PDP currently 404-handles unstocked products.

## 7.3 Non-goals / sidecar

`easyget-google-ai-studio/` = AI-Studio Gemini scaffold (`GEMINI_API_KEY`,
`npm run dev`) + `EASYGET_FLUTTER_BLUEPRINT.md` (design tokens, folder,
Dart models, screen blueprints). Side experiment — not shipped, not
wired to the API.

---

# PART 8 — CROSS-CUTTING FLOWS (how the system behaves end to end)

## 8.1 JWT lifecycle (all clients)

Login → `{access, refresh, user}` stored (web localStorage / secure
storage) → `Bearer access` per call → 401 → single refresh attempt →
retry → still 401 → purge session → continue as guest (public) or force
login (personal). Logout blacklists refresh (reuse → 401). No rotation.
Google: `{id_token}` → same pair (Django verifies, upserts user).

## 8.2 The visibility saga (Oct 2026) — full story

Sep 2026: sort branches returned before visibility filters — customers
sorting saw private catalogs (fixed + regression test). Oct 2026:
"jasmine" searched (search: active-only) but PDP 404'd (detail:
stock-required) — 14/216 platform products affected, admin showed "Live"
(staff bypass + badge from `is_active` only). Fix `0522030`: platform-
active ⇒ public with `in_stock`; merchant privacy kept; search tagged;
shop badges + disabled buying; admin `No stock` badge; home full-catalog
tail. Lesson carved in three READMEs: list/search/detail share ONE
contract — verify all three on any visibility touch. Counts today: 216
active, 202 stocked, 14 Out-of-Stock, 1 zero-variant (`mens-footwear`).

## 8.3 Guest → customer → order (happy path)

Guest browses ( anon list/search/detail/suggestions) → signs in
(guest cart merges by session_key) → adds variants (upsert-increment) →
checkout (address + instructions) → split placement (N seller orders,
all-or-nothing resolve) → pays (COD/UPI/… direct-create) → timeline
(PENDING…DELIVERED) → review (verified badge if delivered) → reorders
from history. Cancel allowed PENDING/CONFIRMED; refunds via payments API
(no dashboard button yet).

## 8.4 Money, offers, delivery math

Prices/totals ALWAYS from `/cart/` + `/orders/` (never client math —
DESIGN forbids showing computed totals as truth). PDP offers = display-
only active coupons (apply-at-checkout = Phase C). Pincode: postal API
+ alias map, ETA 2d/4d, ₹29 < ₹499 else free, 404 undeliverable, offline
heuristic fallback. Seller names live ONLY in cart/checkout/orders
(D3 decision — cards/PDP/browse never show them).

## 8.5 Theme + NEXT_UI + preview pipeline

Merchant theme → API → CSS vars → pre-paint cache (no flash) → toggle +
OS listener. Redesigns gate on `isNextUi()` (`?next_ui=` > storage >
env); `preview.html` sandbox + `preview-shots.yml` screenshots
(375/768/1280 × light/dark, artifact `preview-shots`) give visual
evidence per customer-web push.

---

# PART 9 — CI/CD + HOSTING BIBLE

## 9.1 GitHub Actions (`.github/workflows/`)

- **`ci.yml`** (every push/PR): backend job (`manage.py check` +
  full `test -v 1` on SQLite) + customer-web `npm run build` +
  admin-web `npm run build`. All three must pass — the Oct push
  verified 293 tests + both builds locally first.
- **`deploy-cloudflare.yml`** (push to `fix/flutter-web-and-ordering`
  or `main` touching `customer-web/**`/`admin-web/**`, or manual):
  `npm ci` + build each (API URL baked) → `wrangler@4 pages deploy` to
  `easyget-customer` + `easyget-admin`. Needs secrets
  `CLOUDFLARE_API_TOKEN`/`CLOUDFLARE_ACCOUNT_ID` (account
  `1dcd…9b22`); tokens live in `$env:TEMP\opencode\`, never git.
- **`preview-shots.yml`** (customer-web pushes + manual): Chromium +
  Playwright shots of preview page → `preview-shots` artifact.
- **`repo-hygiene.yml`**: fails on tracked secrets (`.env` un-ignored,
  env/key/keystore/credential files, private-key/AKIA/ghp_/xox
  patterns; `.env.example` whitelisted).

## 9.2 Hosting inventory (all free tier)

- **Render** `easyget-api` (`srv-dasj3l60tbcc73fl0520`, Singapore):
  branch `fix/flutter-web-and-ordering`, autoDeploy ON; build `pip
  install -r requirements.txt`; start `migrate --noinput &&
  collectstatic --noinput && cd backend && gunicorn config.wsgi …
  --workers 2 --timeout 120`; 9 env vars in dashboard (DEBUG=false,
  SECRET, HOSTS, CORS, CSRF, DATABASE/REDIS/BROKER/RESULT); no worker
  (tasks idle); cold start ~50s; API sleeps ~15min idle (30–90s wake).
- **Cloudflare Pages**: `easyget-customer.pages.dev`,
  `easyget-admin.pages.dev` (+ preview `…/preview?next_ui=1`);
  hash routing ⇒ no redirect rules; Netlify sites left live in parallel
  at cutover (Streamline later). After cutover, Render CORS/CSRF MUST
  list `pages.dev` origins or browsers block calls.
- **Supabase Postgres** (shared live DB) + **RLS 68/68, zero grants** +
  **Storage** `easyget-media` (public, S3 interop, 6 `SUPABASE_S3_*`
  envs on Render) + **Upstash Redis** (`rediss://` broker/cache).
- Deploy-prep lesson: `STATIC_ROOT/STORAGES/whitenoise/proxy/CSRF` +
  gunicorn reqs + `ORIGIN` in both `api.ts` must stay committed or boot
  dies (`ImproperlyConfigured: STATIC_ROOT`).

## 9.3 Historical hosting notes (Netlify era, kept for debugging)

Netlify x2 (`easyget-customer/admin.netlify.app`, `easyget` name taken)
died when free credits ran out (2026-10-06) — hence Cloudflare. Netlify
quirks archived in GitCheck §9 (zip backslashes, unpublished deploys,
account-level env). Render quirks: creation-time envVars dropped (PUT
`[{key,value}]`), branch field is `branch`, no logs API, collectstatic
needs committed settings.

---

# PART 10 — LAWS AND CONVENTIONS

## 10.1 Frozen laws (break ⇒ revert)

1. NEVER modify backend models, serializers, or tests (293 stay green).
2. NEVER invent API endpoints — ask first (update CONTEXT when approved).
3. ALWAYS `DESIGN.md` §1 tokens — zero hardcoded hex/px in new code.
4. ALWAYS ship light + dark.
5. ALWAYS loading + empty + error on lists.
6. ALWAYS respect `DESIGN.md` §2 Forbidden List (no purple/blue, no
   glass, no pure #000/#FFF bg, no red SALE/urgency/countdowns, ≤3
   products/row mobile, border-XOR-shadow, serif display, skeletons not
   spinners, toasts not alert(), realistic copy, no auto-inverted dark,
   motion ≥150ms; mobile: no Material-default, ≤5 noun tabs, no full-
   screen progress on lists, bottom-anchored 54dp checkout CTA, tabular
   prices, server totals only).
7. One component/screen per AI session — never batch.
8. Ship redesigns behind `NEXT_UI` until approved.
9. After every change: `currentUpdate.md` + `GitCheck.md` together, then
   commit (conventional `type: subject`, imperative, no secrets).
10. Stage only intended files — never `.env`, `*.sqlite3`, media,
    logs, dumps, scratch scripts, `node_modules`, `.venv`, `dist`.

## 10.2 Code conventions

- Backend: explicit stable orderings; `{count,next,previous,results}`;
  envelope errors; slug/SKU auto-gen; guarded discount math; WebP
  uploads; approved-only reviews; idempotent wishlist; delta stock
  adjusts (locked, audited, floor 0); tenant perms + 404-no-leak;
  prefetch/annotate (no N+1); signals invalidate cache.
- Web: hash routes; `api<T>()` only (no raw fetch); `asArray/toArray`;
  shared query keys; infinite sentinel pattern; `ProductCard` for every
  product render; `fxClass/fxStyle` for images; `eg-*` storage only.
- Flutter (v2 README normative): TDD gate, navigation laws, per-feature
  providers, skeleton-first, 54dp CTAs, server totals.

---

# PART 11 — HISTORY LEDGER (condensed; full text in GitCheck §8 + currentUpdate §0)

- 2026-09-19 `66bc53a` Phase 1 foundation (Django+health+CI+scaffolds,
  SSH, docs) on `main`.
- 2026-09-19→20 Phase 2 auth merged (User/JWT/OTP/addresses, 18 tests).
- 2026-09-20 Phase 3 tenants app + FKs + onboarding + 22 isolation
  tests (120 green); 6 baseline bugs fixed; admin SPA + designer land.
- 2026-09-22 Supabase live verify + products N+1 fix (31 green).
- 2026-09-23 Order Engine (admin queue + 3 layout fixes); Flutter v1
  full build (analyzer 0, APK); delivery v1 (9 tests, live E2E);
  tenant-wiring cart/orders/payments + pagination (58 green).
- 2026-09-24 `b896cd6` A2 Flipkart look (reviews API + palette + UI
  overhaul, 177 green); `bbb2afa` discovery rails/filters/search extras.
- 2026-09-26 `d331319` B1 depth (wishlist, rating sort + leak fix,
  offers, pincode, moderation; 195 green); `ab14c95` security (13/14
  vulns, throttles live, Redis-protocol find, 221 green);
  `8025962…0ca975e` platform storefront + split orders D1–D6 (242
  green, 8/8 smoke); deploy prep + Render live (health/products/CORS/
  login parity).
- 2026-09-27 `891e278+0e5a230` perf (cache, WebP, search index, ≤20
  pages, RLS 68/68, React Query; 252 green); `a079dcd` designer tabs +
  hero image + dark mode + infinite scroll + media fix; `a7780b8`
  image gallery + primary_image-500 fix (262 green, 27/27 smoke);
  `7887104+6e30fce` display controls + designer fixes + hygiene guard
  (268 green, 14/14 smoke); repo deleted+recreated by owner, history
  re-pushed, PR #1 (8 checks green).
- 2026-10-06 hosting → Cloudflare Pages; Supabase Storage media wired
  (bucket `easyget-media`; orphan-cleanup + 2 lost rows outstanding).
- 2026-10-11 contracts reconciled vs live backend (CONTEXT §2 rewrite;
  dead endpoints removed from docs).
- 2026-10-12 shop home gains `AllProductsGrid` full-catalog tail.
- 2026-10-12 `0522030` Out-of-Stock fix (this week's headline): 14
  platform products visible + `in_stock` on list/retrieve/search,
  shop badges + disabled buying, admin `No stock` badge; 293 green +
  both builds green before push; deployed via branch push (Render +
  Cloudflare auto).
- October app track (v2): voice/FCM/notifications/wishlist/quick-add/
  ETA/Zodiak/Photon/instant-boot per git log; v2 README claims 332
  tests green.

---

# PART 12 — REMAINING WORK MASTER LIST

## 12.1 Backend

1. Server-side stock gate at cart-add + order-create (UI-only today).
2. `mens-footwear`: add variant or deactivate (zero-variant live row).
3. Search price filters reference non-ORM `base_price` (latent 500) →
   `min_variant_price`.
4. Suggestions without stock context (fine until counts/badges).
5. Wishlist bypasses catalog filters (decide if intended).
6. Fee fields as strings (type cleanup for clients).
7. `/auth/google/` no-IDs 503 path needs explicit test.
8. `PRODUCT_ROW` accepts unstocked merchant items (customer 404) —
   validate at creation.
9. `EZG-…` order numbers need collision retry.
10. S3 orphan cleanup on image delete; re-upload 2 lost pre-cutover rows.
11. Coupon APPLY at checkout (Phase C) + gateway template
    (Razorpay/Stripe/COD) + dashboard refund button.
12. Notifications live flow (needs worker), delivery auto-assign +
    tracking, returns UI (Phase D).

## 12.2 Customer-web

1. `PRODUCT_ROW` synthetic products lack `in_stock` (wire through).
2. Wishlist page `in_stock` badging (data already present).
3. Footer/policy links are `#/home` placeholders.
4. Playwright specs: PDP + out-of-stock + checkout smoke.
5. Old `eg-*` caches lack `inStock` (self-heals on revisit; no action).

## 12.3 Admin-web

1. Zero-variant save guard (block or warn).
2. "Unstocked products" inventory tab + quick-create stock.
3. Designer dead-link warning for unstocked merchant items.
4. Bulk tools (CSV import, bulk price/activate) — catalog is 216 SKUs.
5. Image alt-text, audit-log screen, refund button, coupon/banner depth.
6. Merge `shell-collapse.css` into `styles.css`.

## 12.4 Flutter

1. `in_stock` parity (badge + disabled buy — PDP 404-handles today).
2. v2 full ship → delete frozen `customer-app/` reference.
3. Signed release build + store listing; device click-test vs live API.
4. Phase E: port remaining B1/A2 marketplace features per v2 roadmap.

## 12.5 Platform/ops

1. Rotate demo creds + push protection before real traffic.
2. Retire parallel Netlify sites post-cutover confirmation.
3. RLS row policies if PostgREST/anon access ever arrives.
4. Load tests, verified backups, prod email/SMS, media CDN.
5. Keep `currentUpdate.md` + `GitCheck.md` + (on contract change)
   `CONTEXT.md` + (on system change) THIS file in sync.

---

# PART 13 — TROUBLESHOOTING MEGA-TABLE

| # | Symptom | Cause | Fix |
|---|---|---|---|
| 1 | DB command hangs | Postgres URL, no local Postgres/Docker | `$env:DATABASE_URL='sqlite:///db.sqlite3'` |
| 2 | `manage.py test` finds 0 | Wrong cwd (must be `backend/`) or missing SQLite env | Part 2.4 exact block |
| 3 | `.env` change ignored | Read once at startup | Restart backend |
| 4 | Port 8000 busy | Zombie runserver | NetTCP → kill PID |
| 5 | `127.0.0.1:3000` unreachable | Vite binds IPv6 localhost | Use `http://localhost:3000/` |
| 6 | `GET /` on :8000 → 404 | Normal — API-only, no homepage | Use `/api/v1/health/` |
| 7 | `tsc` red / build fails | Type error (build runs tsc first) | Fix types, rebuild |
| 8 | Login loops / silent logout | Wrong refresh URL (must be `/auth/refresh/`) / expired | Check api.ts, re-login |
| 9 | Stale token breaks browsing | Shouldn't (purge-to-guest) — regression if so | Inspect `api()` 401 path |
| 10 | Product 404 in shop | Inactive / merchant-unstocked / bad slug | §8.2 + admin Flags |
| 11 | Search finds it, page 404s | Pre-`0522030` deploy running | Redeploy / verify `in_stock` key present |
| 12 | "Live" but not buyable | `No stock` — add Inventory qty>0 active store | Admin cheat sheet |
| 13 | PATCH cart 405 | Live API lacks it — by design | DELETE + re-POST |
| 14 | Review POST 409 | Duplicate (one/user/product) | Edit existing instead |
| 15 | Pincode "couldn't check" | Postal API unreachable | Retry (offline fallback answers next attempt); check logs |
| 16 | Pincode 404 | Undeliverable pin | Expected — show "not deliverable" |
| 17 | Heart doesn't persist | Signed out (device cache only) | Sign in |
| 18 | Categories stale (Grocery id:1) | 1h Redis cache vs reseeded DB | Wait TTL / category save / `cache.clear()`; verify ids in shell |
| 19 | Product create 400 category | Stale cached category id | Same as 18 |
| 20 | Images 404 after upload | Pre-Oct local `/media/` on ephemeral disk | Re-upload (now Supabase); check STORAGES |
| 21 | Old image rows broken (ids 6,8) | Files lost to ephemeral disks | Re-upload, don't migrate |
| 22 | S3 orphans grow | DELETE removes row only | Manual bucket sweep until cleanup ships |
| 23 | Throttles never fire locally | Dead cache (protocol mismatch) | `protocol:2` in CACHES; Redis up |
| 24 | Login burst not 429ing | Same as 23 | Same as 23 |
| 25 | WS won't connect locally | Needs Redis/ASGI | Start Redis or defer to prod |
| 26 | Celery tasks idle on Render | No worker on free tier | Expected; inline fallback covers search logging |
| 27 | API sleeps 30–90s first call | Render free idle | Warm `/health/` before demos |
| 28 | CORS blocks pages.dev | Render CORS/CSRF missing origin | Add origins in Render dashboard |
| 29 | `ImproperlyConfigured: STATIC_ROOT` on Render | Deploy-prep settings uncommitted | Keep them committed (see 9.2) |
| 30 | `fcntl` crash running gunicorn locally | Linux-only server | Use `runserver` on Windows |
| 31 | Flutter hits wrong API | Emulator needs `10.0.2.2`, not localhost | App config override |
| 32 | FCM silent in dev | Needs project keys + device | Follow v2 README push section |
| 33 | Analyzer red (Riverpod) | v3 API (`.value`, autoDispose shapes) | Match installed 3.3 API, no codegen |
| 34 | `eg-*` purge logs me out everywhere | Intended global sign-out | Re-login; check 401 handler |
| 35 | Footer links go home | Placeholders | Real pages pending (§12.2) |
| 36 | `test_postgres already exists` | Stale PG test DB + interactive prompt | Use SQLite env (CI form) |
| 37 | Secrets in `git status` | Scratch dumps (tokens/logs) | Delete; hygiene CI blocks tracked ones |
| 38 | Push doesn't redeploy frontends | Wrong branch or no `customer-web/**` change | Push to watched branch with frontend paths |
| 39 | API payload missing `in_stock` | Old backend running | Redeploy backend; check commit `0522030` live |
| 40 | Admin `Live` on unbuyable item | Pre-`0522030` admin bundle | Redeploy admin; expect `No stock` |

---

# PART 14 — GLOSSARY + CHEAT SHEETS

## 14.1 Glossary

q-commerce (minutes-scale delivery) · Tenant (merchant org; data-isolation
boundary) · Platform product (`tenant NULL`, EASYGET-owned, public when
active) · Merchant product (tenant-owned; private until stocked) ·
`in_stock` (qty>0, active store; UI flag, not a DB column) · Storefront
render (theme+sections+items+ticker, cached 1h) · Split checkout (N
orders, one per seller) · Modular monolith (one deploy, domain apps) ·
RLS (Postgres row-level security; ours = lockdown, no row policies) ·
NEXT_UI (redesign flag) · Seed (idempotent catalog bootstrap from the
Shop Checklist) · Smoke (live-API verification script/steps).

## 14.2 Everyday commands (PowerShell)

```powershell
# Backend dev + check + tests (backend cwd, SQLite hermetic):
.\.venv\Scripts\python.exe backend\manage.py runserver 0.0.0.0:8000 --noreload
cd backend; $env:DATABASE_URL='sqlite:///db.sqlite3'; $env:DJANGO_DEBUG='true'
python manage.py check; python manage.py test -v 1
# Shell probe: python backend/manage.py shell -c "..."  (repo root)
# Web: cd customer-web; npm run dev | npm run build   (same for admin-web, :5174)
# App: cd customer-app-v2; flutter pub get; flutter analyze; flutter test; flutter run
# Git: git status; git diff; git log --oneline -10; git push origin fix/flutter-web-and-ordering
```

## 14.3 Debug recipes

- **Invisible product**: `GET /products/<slug>/` → 404 = inactive or
  merchant-unstocked (check `is_active`, variants, `StockItem`s, store
  active, tenant); 200 + `in_stock:false` = badge path OK → add stock
  to make buyable.
- **Search≠detail**: hit all three (`/products/`, `/search/`,
  `/products/<slug>/`) — flags must agree; else backend predates
  `0522030`.
- **Stale categories**: compare API ids vs shell (`Category.objects`);
  resave a category or clear cache.
- **Auth weirdness**: decode JWT expiry; watch refresh→purge→guest flow
  in Network tab; Google = 503 without client IDs (expected).
- **Deploy didn't land**: branch watched? paths matched? Render/Cloudflare
  build logs green? API URL baked (`VITE_API_URL`) at build time?

## 14.4 File-count summary (2026-10-12)

Root README (this file) · per-app READMEs (customer/admin/backend/v2-Big)
· CONTEXT (274) · DESIGN (768) · PROJECT (233) · GETTING_STARTED (114) ·
currentUpdate (500) · GitCheck (145) · Shop Checklist (480) ·
firebase-auth-plan (175) · backend apps 20 · backend tests 293 green ·
endpoints ~90 under `/api/v1/` · catalog 216 (202 stocked, 14 OOS).

---

*End of master README v1 (950 lines). Deep registries follow — v2 appendices
for juniors who want every function, file, endpoint, and test explained.*

---

# PART 15 — CUSTOMER-WEB API REGISTRY (every export of `services/api.ts`)

> How to read: `name(signature)` → endpoint → who calls it → note.
> All calls go through `api<T>(path, {method, body})` (JWT, refresh,
> purge-to-guest). All list shapes pass `asArray()`. Media via `img()`.

## 15.1 Auth + session primitives

- `Tokens = {access, refresh}` — the pair shape, stored verbatim in
  `localStorage["eg-cust-tokens"]` (try/catch: private-mode safe).
- `User = {id, email, role, first_name?, last_name?, phone?,
  is_email_verified?}` — what login/register/me return. `role` drives
  nothing in the shop (all shoppers equal); admin-web reuses the shape
  with ADMIN roles.
- `setUnauthorizedHandler(fn)` — registers the global-401 callback.
  `App.tsx` wires `signOut`. Invoked inside `api()` after token purge.
- `getTokens()` — parse `eg-cust-tokens` or null (never throws).
- `setTokens(t|null)` — write pair, or `null` to clear (logout, 401).
- `ApiError(status, payload)` — `message` derived by `errorMessage()`
  (see next). Carries HTTP status for branch logic (404 pincode vs 409
  review vs 429 throttle).
- `errText(e, fallback="Request failed")` — `ApiError→message`,
  `Error→message`, else fallback. THE function for toasts/EmptyStates.
- `fieldErrors(e)` — flattens DRF `{field:[msgs]}` (payloads WITHOUT
  `detail`/`error` keys) into `"k: m · k: m"`. Use on forms (register,
  address, review) so field problems read as sentences.
- `errorMessage(payload)` (private) — unwraps `{error:{message}}`
  (with `ErrorDetail(`-repr backstop → flattened `details`), JWT
  `{detail:{messages:[{message}]}}` → "session expired (reason), sign in
  again", plain `{detail:string}`). Never shows raw Python reprs.
- `flattenDetails(detail)` (private) — recursive string collector for
  nested DRF error trees, joined with `"; "`.
- `refreshTokens()` (private) — POSTs stored refresh to
  `/auth/refresh/`; on success swaps access, keeps refresh; false
  otherwise (network failure included — no throw).
- `api<T>(path, {method?, body?})` — the ONLY fetch wrapper in the app.
  Attaches `Bearer` when tokens exist; JSON-encodes body; on 401 tries
  refresh once and retries; on second 401 purges tokens, fires the 401
  handler, and retries ANONYMOUSLY (public browsing survives dead
  tokens); 204 → `undefined`; tolerant JSON parse; non-OK → ApiError.
  Never call `fetch()` directly anywhere.
- `register({email, password, first_name?, last_name?, phone?, role?})`
  → `POST /auth/register/` → 201 `{message, user}`. Caller: AuthPage
  signup. Server auto-verifies email; role defaults CUSTOMER.
- `verifyOtp(email, code)` → `POST /auth/verify-otp/`. Legacy flow only
  (register path skips it). Caller: AuthPage OTP step.
- `resendOtp(email)` → `POST /auth/resend-otp/`. Server applies silent
  quota (≥4/10min) — UI shows generic success either way.
- `LoginResponse = {access, refresh, user}` — stored via `setTokens`
  + user into AuthContext on success.
- `login(email, password)` → `POST /auth/login/`. Callers: AuthPage,
  guest-upgrade prompts. Server throttles 5/min (burst → 429).
- `logout(refresh)` → `POST /auth/logout/` (blacklists that refresh).
  Callers: signOut flows; local purge happens even if the call fails.
- `getMe()` → `GET /users/me/`. Caller: AuthContext bootstrap
  (validates stored tokens on boot; failure → guest mode).

## 15.2 Addresses

- `Address = {id, label, line1, line2, city, state, postal_code,
  country, phone, is_default}` — `id` may be number (server) in forms.
- `listAddresses()` → `GET /users/me/addresses/` (array OR paged —
  always `asArray` at call site). Callers: CheckoutPage (selector),
  AccountPage (book).
- `createAddress(body: Partial<Address>)` → POST same → created row.
  Server auto-defaults the first address; UI refreshes the book after.
- `deleteAddress(id)` → `DELETE /users/me/addresses/:id/`. Caller:
  AccountPage behind confirm. Deleting the default promotes another
  server-side.
- `setDefaultAddress(id)` → `POST .../:id/set-default/`. Exactly-one-
  default invariant enforced server-side; UI re-marks the list.

## 15.3 Catalog reads

- `Category = {id, name, slug, description, icon?}` — `icon` relative
  (resolve via `img()`), absolute, or null. Shared `["categories"]`
  cache (5-min stale) across header strip, rails, and browse filters.
- `Product` — list row: `{id, name, slug, category|null, brand, mrp,
  base_price, discount_percent, is_featured, in_stock?, primary_image,
  primary_image_display?, rating_avg, rating_count}`. Rules: `rating_avg`
  null = unrated (render nothing, never "0.0"); `base_price` null =
  unpriced (zero-variant edge); `in_stock===false` = Out-of-Stock UI.
- `ProductImageItem = {id, image, caption, is_primary, sort_order} +
  ImageDisplay` — gallery order is `sort_order, id`; fx knobs ride along.
- `ProductDetail = Product + {description, offers: Offer[], variants:
  {id,name,sku,price,discount_percent,is_active}[], images[]}` —
  variant pick = first `is_active` else first; no variant ⇒ buy box
  disabled (mens-footwear edge).
- `Paged<T> = {count, next, previous, results}` — `next` null = exhausted
  (infinite queries stop); `count` feeds "(N left)" labels.
- `listProductsPaged(params)` — `GET /products/?…` with URLSearchParams.
  THE feed function (Deals, Recommended, Similar, Browse, AllProducts).
  Server clamps `page_size≤20`; pass `page` as string.
- `listProducts(params)` — back-compat alias, identical call. New code
  uses `listProductsPaged`.
- `listAllProducts(params, maxPages=10)` — loops `page_size:"100"`
  (server clamps to 20 — loop still terminates on `next==null`),
  concatenates `results`. ONLY for fallbacks needing the whole catalog
  (search fallback); never render directly (use infinite queries).
- `getProduct(slug)` → `GET /products/:slug/`. Callers: ProductPage
  (`["product", slug]`), SimilarRail exclusion. 404 message is the
  literal "No Product matches the given query." (pre-`0522030` past).

## 15.4 Offers, wishlist, pincode, brands, reviews, categories

- `Offer = {code, name, description, discount_type:
  PERCENTAGE|FIXED|FREE_DELIVERY, discount_value, max_discount|null}` —
  top-5 active coupons embedded in detail (display-only this phase).
- `offerLine(o)` — pure one-liner: `"40% off up to ₹100 · body"` /
  `"Flat ₹50 off · body"` / `"Free delivery · body"` (body capped 46
  chars + …). Unit-test safe, no API.
- `WishlistAction = {added, slug, count}` — `added` true only on first
  add (201 vs 200 distinguishes); `count` syncs badges.
- `listWishlist(page=1)` → authed paged list. Caller: WishlistPage.
- `addToWishlist(slug)` → POST (201 new / 200 existing). Caller:
  WishButton optimistic add + `syncWishlistCache` + rollback on throw.
- `removeFromWishlist(slug)` → DELETE (idempotent — missing still 200).
- `PincodeResult = {valid, reason?, pincode, city?, state?, eta_days?,
  delivery_fee?, free_delivery_over?, source?}` — fee fields STRINGS;
  `reason` present on 404 payloads (ApiError carries it).
- `checkPincode(pin)` → `GET /pincode/<pin>/`. Caller validates 6
  digits first; ProductPage maps success → "Delivery by <date> <city> ·
  <Free|₹fee>" and 404 → reason or "We do not deliver…".
- `Brand = {name}` — `listBrands()` → `/products/brands/` (array or
  paged). Caller: BrowsePage brand radios (iexact match server-side).
- `Review = {id, rating, title, body, reviewer_name,
  is_verified_purchase, created_at}` — masked names, no PII.
- `listReviews(slug, page=1)` — 10/page, approved-only. Caller:
  ReviewsSection (+distribution bars computed client-side).
- `postReview(slug, {rating, title?, body?})` — 201 live review; 409 →
  toast "already reviewed". Rating validated 1–5 both sides.
- `listCategories()` → `/categories/` (array or `{results}`). THE
  shared key `["categories"]` — header, rails, filters fetch once.

## 15.5 Search

- `SearchResponse = {results: (Product&{score?})[], total, page,
  page_size, took_ms}` (backend adds `query`). `took_ms` = FTS health
  signal; `total` = count labels.
- `searchWithFallback({q?, sort?})` — try `POST /search/`; on ANY throw,
  `listAllProducts` (+sort passthrough except relevance) + tokenized
  ANY-token match over `name+brand+category` (lowercase,
  punctuation→space, split, dedupe) → top 40 `{results, total, page:1,
  page_size:40, took_ms:0}`. Caller: SearchPage. Keep tokenizer aligned
  with backend `_normalize_query` or contracts drift.
- `getSearchSuggestions(q)` → `GET /search/suggestions/?q=` (backend
  enforces ≥2 chars; UI debounces keystrokes).

## 15.6 Cart + orders + stores + helpers

- `CartVariant = {id, name, sku, price, attributes?}` ·
  `CartItem = {id, variant, quantity, line_total, tenant_id|null,
  seller_name}` (`tenant_id` null = platform line) · `Cart = {id,
  items[], total_items, subtotal}`. Money strings; totals authoritative.
- `getCart()` → `GET /cart/` (server creates-if-missing). Caller:
  CartContext (count bubble, lines).
- `addToCart(variantId, quantity=1)` → `POST /cart/items/`
  (upsert-increment → 201). Guests rerouted to login first (cart is
  authed). NO server stock check — UI gates only (known gap §12.1).
- `updateCartItem(itemId, quantity)` → PATCH — 405s on live API; kept
  for the day backend supports it. Flows MUST use DELETE + re-POST.
- `removeCartItem(itemId)` → DELETE (204). `clearCart()` → `DELETE
  /cart/clear/` (post-order + explicit clear).
- `Order` — UUID `id`, `order_number` (EZG-…), `store|null`,
  `store_name?`, `status`, `subtotal/delivery_fee/discount/total`,
  `item_count?`, `delivery_address?`, `delivery_instructions?`,
  `items[{id,product_name,variant_name,sku,unit_price,quantity,
  line_total}]`, `created_at`. `OrderDetail = Order +
  {status_history[{id,from_status,to_status,note,created_at}]}`.
- `OrderCreateInput = {cart_id, store?, delivery_address,
  delivery_instructions?}` — OMIT `store` for split mode.
- `createOrder(body)` → split `{orders: Order[]}` (no store) or legacy
  single echo (with store). Caller: CheckoutPage ("N orders placed!" →
  `#/orders`; defensive legacy fallback).
- `listOrders()` (array or `{results}`) · `getOrder(id)` →
  `OrderDetail` · `cancelOrder(id, reason)` (PENDING/CONFIRMED only —
  else 400; UI hides button otherwise).
- `Store = {id, name, slug, is_active, city?}` · `listStores()`.
- `asArray(data)` — `{results}|[]|null` → array. Every list call site.
- `img(path)` — null→null; http/data: passthrough; else
  `ORIGIN + path` (prefixing `/media/` when relative). EVERY image URL.

## 15.7 Companion modules (`src/` files beyond api.ts)

- `services/google.ts` — GIS without Firebase: `googleClientId()`
  (env, null-safe), `isGoogleConfigured()` (button hidden when false —
  never a dead button), `renderGoogleButton(el, onToken, width=320)`
  (lazy gsi script, single-flight promise, official pill
  `continue_with` button), `loginWithGoogle(idToken)` →
  `POST /auth/google/` → same triple (downstream untouched). Backend
  503s without IDs — handled.
- `theme/tokens.ts` — TS mirror of DESIGN §1 for JS-only needs:
  `MOTION {micro:160, base:240, editorial:500}` (never <150ms),
  `EASE_OUT` (+`EASE_OUT_ARRAY`), `STAGGER_STEP_MS` (=editorial/7),
  `REVEAL_TRAVEL_PX` (8), `SPACING` (8pt grid), `RADIUS`
  (6/10/14/20/999), `HAIRLINE_PX`, `TOUCH_TARGET_PX` (44), `CONTRAST` +
  `MEASURED_CONTRAST` (AA table per token per theme — recompute on token
  change; recomputation wins over the table). Law: nothing here that
  isn't in DESIGN §1 first.
- `components/next/ProductCard.tsx` — NEXT_UI card, flag-gated only:
  4:5 imagery, 3/row desktop + 2 mobile, serif on section heads only,
  Inter names + Geist Mono prices, NO discount theater (muted MRP
  strike), Add-to-Bag filled on hover/focus (outline on touch; filled
  green reserved for PDP), category-tinted wash for missing images,
  ghost wishlist at rest. Types `NextProductCardData/Props`.
- `preview.tsx` (+`preview.html`) — NEXT_UI sandbox on LIVE catalog (6
  rows) through the Next card + `ProductCardSkeleton`; status machine
  loading/ready/empty/error with defensive row picking. CI screenshots
  this page (preview-shots.yml).
- `main.tsx` — `createRoot` mount + cached-theme pre-paint read.
- `vite-env.d.ts` — `/// <reference types="vite/client" />` (kills the
  classic TS2882 CSS-import build failure).

---

# PART 16 — ADMIN-WEB API REGISTRY (every export of `services/api.ts`)

> Same JWT/error core as shop (own storage key + handler). Staff view of
> `/products/` (unfiltered — trust Flags, not gut). `mediaSrc()` resolves
> absolute media URLs.

## 16.1 Session, summary, categories, users

- `Tokens`, `AdminUser`, `setUnauthorizedHandler`, `getTokens/setTokens`,
  `ApiError`, `errText`, `api()` — identical semantics to §15.1 (separate
  storage key; the two apps never share tokens — logging into one never
  leaks session into the other).
- `LoginResponse` + `login(email, password)` — admin LoginPage; failure
  401 → inline form error (no toast storm). `logout(refresh)` on signOut.
- `AdminSummary = {users:{total,today,week}, orders:{total,today,week,
  pending}, revenue:{today,week}, products:{total,low_stock}}` +
  `getSummary()` → `GET /admin/dashboard/`. Caller: DashboardPage stat
  cards. `low_stock` counts qty ≤ threshold AND > 0 (true zeros are
  "Out", not "Low" — matches Inventory badges).
- `Category = {id, name, slug, …}` + `listCategories()` (array or
  `{results}`) · `createCategory(Partial<Category>)` → POST ·
  `updateCategory(slug, Partial)` → PATCH · `deleteCategory(slug)` →
  DELETE (blocked if products reference it — PROTECT) ·
  `uploadCategoryIcon(slug, file|null)` (multipart; null clears).
  Callers: CategoriesPage (CRUD + search + icon tile).
- `ManagedUser = {id, email, role, …}` + `listUsers()` (ADMIN-only
  endpoint + screen) · `createUser(record)` · `updateUser(id, record)`.
  Caller: UsersPage. Role changes take effect on next login (new JWT
  claims).

## 16.2 Products + images + display knobs

- `Product = {id, name, slug, category{id,name,slug}, brand, mrp,
  base_price, is_featured, is_active, in_stock?}` — `in_stock` drives
  the Flags column (`No stock` vs `Live`); staff rows ALWAYS include it
  (same injection path as shop).
- `ImageEffect = none|zoom|pan|grayscale` · `ImageDisplay = {align_x,
  align_y, zoom, effect, transition_ms}` ·
  `DEFAULT_IMAGE_DISPLAY = {50,50,1.0,none,400}` ·
  `EFFECT_LABELS` (human names for the editor select) ·
  `toImageDisplay(v?)` (null-safe normalize — old rows without knobs
  get defaults, never undefined).
- `ProductImage = {id, image, caption, sort_order, is_primary} +
  ImageDisplay` · `ProductDetail = Product + {images, variants[{id,
  name, price}]}` (edit modal shape; note admin variant rows carry
  `is_active` too — type is loose by design).
- `listProducts(params)` — paged passthrough (toolbar stays responsive;
  filtering is client-side over `listAllProducts`).
- `listAllProducts()` — page-loop for the table + category filter.
  Retuned for 20/page (50-page ceiling — the 200-cap is gone).
- `createProduct(record)` — `{name, category(id), is_active,
  is_featured, description?, brand?, mrp?, variants?[{name, price,
  is_active}]}` → 201 `{…, slug}`. Images are STAGED (no slug yet) and
  uploaded after (counts in the toast). Empty-price rows skipped
  client-side, never sent.
- `updateProduct(slug, record)` — variants round-trip BY ID
  (present=id → update in place; absent id → create; unknown id → 400
  "does not belong"). Missing rows are left alone (no auto-delete).
- `deleteProduct(slug)` → DELETE (ConfirmDialog copy: "removes the
  product everywhere… cannot be undone").
- `getProduct(slug)` → detail (edit modal images + variants; error →
  "Couldn't load details" toast, modal stays open for retry).
- `uploadProductImage(slug, file)` → 201 `{…, is_primary, sort_order,
  image: webp-url}` (multipart; first upload forced primary
  server-side). Edit mode: instant + tile append + invalidate.
- `setPrimaryProductImage(id)` → PATCH `{is_primary:true}` (demotes
  rest atomically; UI mirrors optimistically).
- `updateProductImage(id, {caption, align_x, align_y, zoom, effect,
  transition_ms})` → PATCH (knob ranges validated BOTH sides; bad
  values 400 — editor sliders already clamp).
- `deleteProductImage(id)` → DELETE (primary promotes next by
  `sort_order,id`; UI mirrors; orphans file/S3 object — known gap).
- `mediaSrc(v)` — absolute URL or null. Shared import for ProductsPage
  AND StorefrontPage (dedupe point — don't fork it).

## 16.3 Storefront designer primitives

- `SectionItem = {id, item_type: PRODUCT|CATEGORY|CUSTOM, product?,
  product_name?, product_slug?, product_price?, category?, …,
  caption, image, link, config, position}` ·
  `StoreSection = {id, section_type, title, subtitle, image, config
  {columns?, size?, effects?…}, position, is_active, items[]} +
  ImageDisplay` · `Theme = {primary_color, secondary_color,
  background_color, font_family, logo?, hero_image?, button_style:
  ROUNDED|SQUARE|PILL, effects?}`.
- `getStoreSlug()/setStoreSlug()` — designer default resolution:
  platform store > saved slug > first store, resolved ONCE (ref guard);
  hard fallback `"easyget"`.
- `getStorefront(slug)` → public render (preview source of truth).
- `getSections(slug)` → `GET /storefront/<slug>/sections/` (managers
  see inactive too — that's what the board edits).
- `createSection(slug, record)` → POST (server auto-appends last; UI
  flips to Sections tab + smooth-scrolls the new row — fixes the old
  "nothing happened" illusion on long boards).
- `updateSection(id, record|FormData)` — object = JSON design save;
  FormData = immediate image upload path; `{image:null}` JSON clears.
- `deleteSection(id)` → DELETE (204; items cascade).
- `TickerConfig = {items[], speed, color, bg, symbol, fontSize,
  radius}` + `getTickerConfig()` (null when unconfigured → merchant
  fallback copy) + `saveTickerConfig(id|null, config)` (null id =
  create; returns id for chaining).
- `reorderSections(slug, order: number[])` → POST `{order}` (DnD end;
  positions = array indices; unknown ids 400).
- `createItem(sectionId, record)` (auto-appended last; product validated
  tenant-strict server-side — platform accepts any active) ·
  `updateItem(id, record)` · `deleteItem(id)` · `reorderItems(sectionId,
  order[])` (same index semantics).
- `updateTheme(slug, Partial<Theme>)` → PATCH (JSON or multipart for
  logo/hero files).
- `listStores()` — typed `{…, is_platform?}` (designer store picker).

## 16.4 Orders, delivery, reviews (fulfilment loop)

- `OrderItem = {…}` · `OrderStatusEvent = {…}` · `Order` (staff shape:
  +user email, +address detail, +`store_name`) · `OrderDetail = Order +
  {items, status_history}`.
- `NEXT_STATUS: Record<status, next[]>` — MIRRORS the backend transition
  map for the advance dropdown. If backend adds a transition, update
  BOTH (or the button offers illegal jumps the API 400s).
- `listOrders()` (queue + filter pills + counts) · `getOrder(id)` →
  detail modal · `updateOrderStatus(id, status, note="")` → PATCH
  (timeline grows; toast confirms) · `cancelOrder(id, reason)` (rules
  §6.3).
- `DeliveryAssignment = {id, order, agent, status, …}` ·
  `DeliveryAgent = {id, name, …}` ·
  `NEXT_DELIVERY_STATUS` (advance map, same mirror rule) ·
  `listDeliveries()` (tenant-scoped server-side — merchants see own) ·
  `listAgents()` (PII-scoped: own-tenant or pool) ·
  `assignDelivery(order, agent, note="")` · `advanceDelivery(id,
  status, note="")`.
- `AdminReview = {id, product, rating, title, body, reviewer_name,
  verified, is_approved, created_at}` ·
  `listReviews(approved?: boolean)` (BARE ARRAY — no `{results}`;
  filters `?approved=` + `?product=<slug>`) ·
  `updateReview(id, {is_approved})` (Approve/Hide toggle — hides apply
  to shop aggregates instantly) · `deleteReview(id)` (ConfirmDialog).

---

# PART 17 — SOURCE ATLAS (every file, one purpose)

## 17.1 customer-web `src/` (33 files — read in this order)

1. `services/api.ts` — Part 15. Read first; everything network lives here.
2. `hooks/useHashRoute.ts` — `parse()` (hash→`{name,params,query}`),
   `useHashRoute()` (hashchange subscription), `navigate(path,{replace?})`,
   `href(path)`. No deps. Hash never hits network (static-host safe).
3. `flags.ts` — `isNextUi()` (`?next_ui=1|0` persisted > storage >
   `VITE_NEXT_UI`). Only gate for redesigns.
4. `context/AuthContext.tsx` — `{user, ready, signIn, signOut}`;
   boot validates tokens via `getMe()`; signOut purges `eg-*` + storage;
   exposes 401-handler wiring.
5. `context/ToastContext.tsx` — `push(msg, kind?)`; toasts (never
   `alert()` — forbidden).
6. `context/CartContext.tsx` — `{lines, count, subtotal, add, …}`;
   server POST per add; count drives header bubble + bottom nav.
7. `context/StorefrontContext.tsx` — `{data, loading, error}`; ALWAYS
   `/storefront/platform/` (slug machinery deleted in `e4eb016`);
   caches theme → `eg-store-theme`.
8. `components/ui.tsx` — design system (Part 4.4): money, Monogram,
   Price, RatingPill, WishButton, ProductCard (+`chip-out`), Section,
   Spinner, CardSkeletonGrid, EmptyState, StatusChip, SignInGate,
   usePopOnChange.
9. `components/marketplace.tsx` — BannerCarousel/HeroSlide, DealsRail
   (60-fetch → top-12 + countdown), CategoryRail (shared key),
   RecentlyViewedRail, RecommendedRail (`topCategory()`), AllProductsGrid
   (infinite 20/page + load-more). Pre-existing `useQuery` conversions +
   hero dims rode with the Oct push (same files).
10. `components/icons.tsx` — named `Icon` set (cart/heart/search/box/
    grid/tag/percent/chevrons/home/user/lock/…). Icon-only buttons carry
    aria-labels (frozen rule).
11. `components/ticker.tsx` — `Ticker` (merchant ticker items or fallback
    copy: free delivery/returns/COD).
12. `components/category-tiles.tsx` — `CategoryTiles` + 
    `normalizeTileStyle` (CATEGORY_GRID looks).
13. `components/next/ProductCard.tsx` — NEXT_UI card (§15.7, flag only).
14. `utils/history.ts` — recents(12+inStock)/searches(8)/wishlist-cache/
    trending consts/purge (Part 4.5).
15. `utils/imageFx.ts` — `fxClass/fxStyle` (absent = no-op; heroes use
    direct-`img` variant so absolute positioning survives).
16. `theme/tokens.ts` — TS token mirror (§15.7; nothing outside DESIGN §1).
17. `pages/HomePage.tsx` — §4.3 + `SectionRenderer` per section type +
    `WelcomeHero` (zero-section fallback) + `ProductRowSection`
    (synthetic cards — `in_stock` not yet wired, §12.2).
18. `pages/BrowsePage.tsx` — §4.3 (filter state, infinite, chips).
19. `pages/ProductPage.tsx` — §4.3 (+`SimilarRail/Card`, `ReviewsSection`
    with bars + form + 409 copy; `recordView(product)` incl. `in_stock`).
20. `pages/SearchPage.tsx` — §4.3 (suggest debounce, fallback, recents).
21. `pages/CartPage.tsx` — seller groups + steppers (DELETE+rePOST) +
    clear + server totals.
22. `pages/CheckoutPage.tsx` — addresses + review groups + split place +
    legacy fallback.
23. `pages/OrdersPage.tsx` — list + `OrderDetailPage` (timeline, cancel).
24. `pages/AccountPage.tsx` — profile PATCH + address CRUD + default.
25. `pages/WishlistPage.tsx` — server grid + empty state (badging TODO).
26. `pages/CategoriesPage.tsx` — full category browse.
27. `pages/AuthPage.tsx` — login/register/OTP/Google (GIS hidden unless
    configured); password `minLength=10` + helper (VULN-013 UI half).
28. `services/google.ts` — §15.7 (GIS, no Firebase).
29. `App.tsx` — providers → Shell (Part 4.2/4.4): header search (navigates
    `search?q=`), theme toggle + vars, guest gate, 401→signOut,
    `CategoryStrip` (drag-scroll + arrows + aria-current), footer (4-col
    + PayBadges incl. brand SVGs), bottomnav (Home/Search/Cart/Account).
30. `main.tsx` — mount + pre-paint theme read.
31. `preview.tsx` — NEXT_UI sandbox (§15.7).
32. `vite-env.d.ts` — vite/client types.
33. `index.html` — title EASYGET, Inter font, favicon, NO-FLASH theme boot
    script (reads `eg-theme` → OS pref), root div, module script.
    `preview.html`/`privacy.html` — sandbox + static privacy (build
    inputs). `public/` — static assets. `screenshots/` — captures.

## 17.2 admin-web `src/` (19 files)

1. `services/api.ts` — Part 16. Read first.
2. `hooks/useHashRoute.ts` — string routes (`"dashboard"`, …).
3. `context/AuthContext.tsx` — user/ready/signOut (+401 purge).
4. `context/ThemeContext.tsx` — light/dark (+toggle family).
5. `context/ToastContext.tsx` — toasts.
6. `components/ui.tsx` — Card/Modal(**portaled** to `document.body` +
   scroll-lock + overlay scroll — the inventory-overlay fix)/ConfirmDialog/
   Spinner/EmptyState/badges.
7. `components/ImageDisplayEditor.tsx` — live preview + 3×3 align grid +
   X/Y + zoom (×NN.NN) + effect select + transition (disabled when none)
   + caption; `imageFxClass/imageFxStyle`; `.img-fx/.ide-*` CSS contract.
8. `pages/LoginPage.tsx` — JWT login + `ThemeToggle` export.
9. `pages/DashboardPage.tsx` — `getSummary` cards (users/orders/revenue/
   products + low-stock).
10. `pages/OrdersPage.tsx` — queue (pills+counts), table, detail modal
    (items/timeline/advance via `NEXT_STATUS`/cancel+reason) + delivery
    section (assign/advance via delivery fns).
11. `pages/CategoriesPage.tsx` — CRUD + search + icon upload tile.
12. `pages/ProductsPage.tsx` — Part 5.3 (toolbar/table/Flags/modal with
    Draft+VariantRow+presets/staged-vs-instant images/display editor/
    delete confirm).
13. `pages/ReviewsPage.tsx` — filters + table + approve/hide/delete.
14. `pages/InventoryPage.tsx` — table + `AdjustModal` (quicks/reason/
    note/floor-0) + audit trail.
15. `pages/UsersPage.tsx` — ADMIN list + create/update (role handoff on
    next login).
16. `pages/StorefrontPage.tsx` — tabs/board/theme/design modal/image
    block/DnD/inline rename/pickers/toggles (Part 5.3).
17. `App.tsx` — gate → Shell (sidebar NAV + topbar clock/role/theme) →
    role-gated switch (Users/Storefront ADMIN-only, Dashboard fallback).
18. `main.tsx` — mount. `vite-env.d.ts` — vite/client types.
19. `styles.css` — theme/tables/badges/gallery (`.prod-gallery/
    .prod-img-*`), designer (`.sf-tabs`, `.item-strip` scroll,
    `.section-head` pin). `shell-collapse.css` — collapsed rules (merge
    candidate).

## 17.3 backend `backend/` (per app — models/views/serializers/urls/tests)

- `manage.py` — entry (REPO-ROOT cwd only; backend cwd finds tests but
  breaks the documented command — pick root form always).
- `config/settings/` — base/dev/prod splits; deploy-prep keys
  (STATIC_ROOT/STORAGES/whitenoise/proxy/CSRF) MUST stay committed.
- `config/urls.py` — mount table; admin_panel BEFORE users.admin_urls
  (Django no-fallthrough — load-bearing); DEBUG media `static()`;
  spectacular `/api/schema|docs|redoc`.
- `config/asgi.py/wsgi.py/celery.py` — WS / gunicorn / worker entries.
- `common/` — health (AllowAny+unthrottled), envelope, `cache.py` 1h
  cache-aside + `cache_signals.py`, `pagination.py` Max20, `images.py`
  WebP-q80 + `image_signals.py` (committed-field guard), `rls.py`
  sender-less lockdown, pincode service (postal API + browser UA +
  alias map + process cache + heuristic fallback).
- `users/` — User (email login, roles, verified gate, pwd validators),
  OTPCode (6-digit/10-min/5-cap, uniform errors, silent resend quota),
  Address (one-default), auth views incl. Google-verify-upsert (503
  without IDs), `IsAdminOnly`, admin user mgmt.
- `tenants/` — Tenant/Membership(OWNER/MANAGER, unique),
  `permissions.py` (Writer/ObjectAdmin/ObjectMember), `services.py`
  (member?/admin?/resolve-for-create/provision). Middleware was
  REJECTED (JWT invisible at middleware time) — permissions+services
  carry the same server-side guarantee.
- `stores/` — Store (nullable tenant, slug, geo, active, `is_platform`
  + partial-unique + data migration); list/detail hide platform from
  non-staff; create provisions tenant (or links single membership);
  PATCH/DELETE owner-or-staff.
- `categories/` — shared platform taxonomy (DELIBERATE — one taxonomy,
  many merchants); parent self-FK, icon, sort; cached public list.
- `products/` — Product (nullable tenant=NULL platform, PROTECT
  category, auto-suffixed slug, brand/mrp/active/featured/tags;
  `base_price/discount_percent/primary_image` props) · Variant (auto
  SKU, `ordering=[sku]`) · Image (+`ImageDisplayFields` 5 knobs) ·
  Review (UNIQUE pair, CHECK 1–5, verified-from-delivered, approvable) ·
  WishlistItem (UNIQUE pair) · `views.py` (visibility matrix §6.3 +
  `stocked_product_ids` + list/retrieve `in_stock` injection) ·
  serializers (subquery ratings, offers embed, `_primary_image_url`
  500-fix) · image/wishlist/review/brand routes BEFORE router ·
  `seed_shop_catalog` command.
- `inventory/` — StockItem (denormalized tenant, UNIQUE store×variant,
  qty, threshold 5, `is_available/is_low_stock`) · Transaction (change,
  reason, note, performed_by) · list/create (cross-tenant 400) ·
  low-stock · adjust (select_for_update, floor 0, audit row).
- `cart/` — Cart/CartItem (mixed-seller adds/merges; `tenant_id` +
  `seller_name` prefetched `to_attr`); items add(upsert)/merge/clear/
  delete (PATCH 405s — client rewrites).
- `orders/` — UUID orders (tenant/store/status-machine/money/address
  JSON), items, events; split create (resolve-all-first, atomic,
  `{orders}`) + legacy `{store}` mode; timeline; cancel rules; invoice.
- `payments/` — methods (CARD/UPI/WALLET/COD), direct-create
  (order-ownership, no oracle), refunds (payment-bound amounts/reasons).
- `delivery/` — Assignment (machine + order sync), assign (writers) /
  list+advance (authed, agent-PII-scoped), agent pool.
- `search/` — `ProductSearchIndex` (document/vector), FTS OR-tokens +
  ILIKE net, suggestions, query/popular logs, `rebuild_search_index`;
  SQLite ILIKE-only same contract.
- `storefront/` — Theme/Section(+display)/Item, flag-lookup platform
  render (cached), CRUD + `{order}` reorders, `_product_allowed_for_
  store` (platform: any active; merchant: strict), ticker,
  `seed_platform_storefront`.
- `admin_panel/` — SystemConfig, Banner (public windowed feed),
  Coupon (validate math: PCT×value capped at max, FIXED flat) + usage
  bump, ScheduledTask (celery-task runner), AdminAction audit, dashboard
  summary, review moderation viewset.
- `notifications/` — templates, user list, read/all-read/unread-count,
  preferences (+all/bulk_update).
- `realtime/` — devices (IOS/ANDROID/WEB), WS consumers (order gated by
  `can_access_order`, rooms by `check_room_access`), chat rooms/messages
  (staff-or-author, same-room replies), inventory subscriptions.
- `analytics/` — events (+batch), daily metrics, funnel, retention,
  revenue-by-channel, product performance.
- `pwa/` — config, push subscriptions, offline data, update check +
  `mark_deployed` (writes admin-only — VULN-001).
- `webhooks/` — endpoint/delivery/event-log (admin-only — VULN-006 was
  AllowAny).
- `products|search|storefront/management/commands/` — the ONLY custom
  commands: `seed_shop_catalog`, `rebuild_search_index`,
  `seed_platform_storefront` (all idempotent).

---

# PART 18 — ENDPOINT DEEP REFERENCE (request/response shapes you will copy)

> Notation: `→ 200 {…}` = status + body. `A` = authenticated,
> `S` = staff, `P` = public. Money = strings. Pages = `{count, next,
> previous, results}` (≤20). Errors = envelope (Part 6.3).

## 18.1 Auth (users/)

1. `POST /auth/register/` (P) `{email, password≥10, first_name?,
   last_name?, phone?, role?=CUSTOMER}` → 201 `{message, user{id,
   email, role, …}}`; 400 weak (`validate_password`: similarity, min 10,
   common, numeric) / duplicate email; throttle 3/min → 429. Email
   auto-verified (OTP path legacy). Frontend: AuthPage signup, then
   straight to login state (no OTP wait).
2. `POST /auth/login/` (P) `{email, password}` → 200 `{access,
   refresh, user}`; 400 unverified; 401 bad creds; 429 burst (5/min —
   live-verified `401×5→429×2`). Frontend stores pair + boots
   me/cart/storefront in parallel.
3. `POST /auth/refresh/` (P) `{refresh}` → 200 `{access}` (same refresh
   kept — NO rotation). Dead/blacklisted → 401 → frontend purges to
   guest (public keeps working) or forces login (personal).
4. `POST /auth/logout/` (A) `{refresh}` → 200; blacklists (reuse → 401
   — LogoutTests pins this). Frontend purges even on network failure.
5. `POST /auth/verify-otp/` (P) `{email, code}` → 200 `{message, user}`;
   uniform `OTP_INVALID_MESSAGE` for unknown-email/no-OTP/expired/wrong
   (no enumeration). Legacy — register skips it.
6. `POST /auth/resend-otp/` (P) `{email}` → 200 generic ALWAYS (silent
   quota ≥4/10min — no enumeration). Throttle 10/min.
7. `POST /auth/google/` (P) `{id_token}` → 200 triple (Django verifies
   via google-auth, upserts User); 503 `GOOGLE_OAUTH_CLIENT_IDS` empty
   (dev default — GIS button hidden, never dead).
8. `GET /users/me/` (A) → 200 `User`. Boot validator (failure = guest).
9. `PATCH /users/me/` (A) `{first_name?, last_name?, phone?}` → 200
   updated (email/role immutable here).
10. `GET /users/me/addresses/` (A) → array-or-paged `Address[]`.
    `POST` same `{label,line1,line2,city,state,postal_code,country,
    phone,is_default?}` → 201 (first auto-default). `PATCH/DELETE
    .../:id/` → 200/204 (default-deleted promotes another).
    `POST .../:id/set-default/` → 200 re-marked (exactly-one invariant).

## 18.2 Catalog (products/)

11. `GET /products/?category=&brand=&min_price=&max_price=&min_discount=
    &is_featured=true&sort=&page=&page_size=` (P) → 200 page; row =
    `{id,name,slug,category{id,name,slug},brand,mrp,base_price,
    discount_percent,is_featured,is_active,primary_image,
    primary_image_display{…5 knobs},rating_avg,rating_count,in_stock}`.
    `brand` iexact; prices via `min_variant_price` annotation (NEVER the
    python prop — FieldError history); discount needs MRP>0; sorts
    price_asc(-nulls-last)/price_desc/newest/rating(avg,count)/default
    (-updated_at,-id). Visibility §6.3 BEFORE sort (leak regression
    pinned). Ex: `?category=hair-care&min_discount=25&sort=rating`.
12. `GET /products/:slug/` (P) → 200 detail = row + `{description,
    offers[{code,name,description,discount_type,discount_value,
    max_discount}],variants[{id,name,sku,price,discount_percent,
    is_active}],images[{…}],created_at,updated_at}` + `in_stock`.
    Jasmine today: 200, `in_stock:false`, 3 active variants, Parachute.
13. `GET /products/brands/` (P) → 200 `[{name}]` distinct non-empty
    alpha (route BEFORE router — slug swallow guard).
14. `GET /products/wishlist/?page=` (A) → paged rows.
    `POST /products/wishlist/:slug/` → 201 `{added:true,…}` first /
    200 `{added:false}` repeat; `DELETE` → 200 `{added:false}` (missing
    still 200 — idempotent both ways).
15. `GET /products/:slug/reviews/?page=` (P) → 10-pack approved-only
    `{…,reviewer_name:"Rahul B.",is_verified_purchase}`.
    `POST` (A) `{rating 1-5,title?,body?}` → 201 / 409 dup / 400 range.
16. `GET /products/:slug/images/` (P) → ordered gallery.
    `POST` (A+writer+member) multipart `image` → 201
    `{…,is_primary,sort_order: max+1, image: …webp}` (400 without file;
    first forced primary). `PATCH /products/images/:id/` (partial incl.
    knob ranges — bad → 400) / `DELETE` (primary promotes next; 204;
    file/S3 orphaned — gap).
17. `POST /products/` (A+writer) `{name,category(id),…,
    variants?[{name,price,is_active}]}` → 201 +slug (tenant bound;
    outsider 403 "join a tenant"). `PATCH/DELETE /products/:slug/`
    (member-or-staff; variant ids validated per-product).

## 18.3 Search / cart / orders / payments / pincode / promos

18. `POST /search/` (P) `{q?,category?,store?(UUID),min_price?,
    max_price?,is_featured?,sort?=relevance,page?=1,page_size?≤20=20}` →
    200 `{results[{…row,score,highlight:null,in_stock}],total,page,
    page_size,took_ms,query}`. PG OR-token websearch + ILIKE net;
    SQLite ILIKE-only (same "black board"→"Blackboard" contract).
    Relevance = -rank,-featured,-created; popular = order counts.
    Logged (inline fallback). LATENT: price keys hit non-ORM field.
19. `GET /search/suggestions/?q=` (P) → 200 `[≤10 strings]`
    (popular-prefix + name/tag, ANY-token, <2 chars → `[]`).
20. `GET /cart/` (A) → 200 `{id,store,items[{id,variant{id,name,sku,
    price,attributes?},quantity,line_total,tenant_id,seller_name}],
    total_items,subtotal}` (creates-if-missing; seller fallback chain).
21. `POST /cart/items/` (A) `{variant_id,quantity}` → 201 (upsert-
    increment). NO stock gate (gap — UI only).
22. `DELETE /cart/items/:id/` (A) → 204 (qty-rewrite partner; PATCH
    405s). `POST /cart/merge/ {session_key}` → 200 merged (login).
    `DELETE /cart/clear/` → 204.
23. `POST /orders/` (A) `{cart_id,store?,delivery_address,
    delivery_instructions?}` → 201 `{orders:[…]}` split (resolve-all-
    sellers-first; dead → 400 zero-created) OR legacy single echo
    (with `store`; platform `store` → 400). Number `EZG-…` (no retry).
24. `GET /orders/` (A) → list (+`item_count`,`store_name`).
    `GET /orders/:id/` → detail + items + `status_history` timeline.
    `POST /orders/:id/cancel/ {reason}` → 200 (PENDING/CONFIRMED only).
    `GET /orders/:id/invoice/` → invoice payload.
25. `GET /payments/methods/` (A) → saved (CARD|UPI|WALLET|COD).
    `POST /payments/` (A) `{order,gateway∈RAZORPAY/STRIPE/PHONEPE/COD,
    amount,payment_method_id?}` → 201 (order-ownership else
    `{"order":"Order not found."}` — no oracle; NO intent/confirm
    endpoints exist by design). `GET /payments/refunds/` /
    `POST /payments/:id/refund/ {amount,reason}` (payment-bound).
26. `GET /pincode/:code/` (P) → 200 `{valid:true,pincode,city,state,
    eta_days,delivery_fee:"29",free_delivery_over:"499",source}` (fee
    STRINGS; ETA 2d same-state/4d else via alias map; process cache +
    heuristic `source:fallback`); 400 bad format; **404** undeliverable
    (+`reason`).

## 18.4 Storefront / engagement / admin (shapes)

27. `GET /storefront/platform/` (P) → 200 `{store{name,slug,city,
    description},theme{…}|null,sections[{…items[]}],ticker|null}`
    (flag lookup; cached 1h; section guard: platform↔any-active).
    `GET /storefront/:slug/` same per store. Manage: sections
    GET(public-active)/POST + PATCH/DELETE + `POST …/reorder
    {order:[ids]}`; items GET/POST + PATCH/DELETE + reorder; theme GET
    public/PATCH manager (JSON|multipart). Inactive-section GET 404s
    public (staff/manager bypass).
28. Notifications (A): `GET /notifications/` (paged) · `POST
    .../:id/mark_read/` · `POST .../mark_all_read/` · `GET
    .../unread_count/ → {count}` · `GET .../preferences/` (+`PUT
    .../bulk_update/`). Realtime: `POST /realtime/devices/
    {platform:IOS|ANDROID|WEB,device_token,user_agent}` → 201; WS
    `/ws/orders/`, `/ws/notifications/` (access-checked subscribes).
    Analytics: `POST /analytics/events/ {event_type,session_id,
    properties}` + `/batch/`. PWA: `POST /pwa/updates/check/
    {platform,current_version}` → `{update_available,…}` (writes
    admin-only).
29. Admin (S): `GET /admin/dashboard/` → `{users{total,today,week},
    orders{total,today,week,pending},revenue{today,week},products{total,
    low_stock}}` (NOT `/stats/`). Orders list + `PATCH
    .../:id/status/` (transition map). Reviews `GET` (bare array;
    `?approved=&?product=`) + PATCH/DELETE. Coupons/banners/config/
    tasks/audit CRUD + `POST /admin/coupons/validate/ {code,
    order_value}` (ANY authed user) → `{valid,discount,…}` | 400.
30. Misc: `GET /api/v1/health/` (P, unthrottled) → `{"status":"ok"}`;
    `/api/schema|docs|redoc` (spectacular); `GET /banners/` (paged
    active CAROUSEL|POPUP|BANNER).

---

# PART 19 — TEST CATALOG (all 80 classes — what each proves)

> 293 tests green 2026-10-12 (1 skipped). Files frozen — read to learn
> contracts, never edit to make red green.

## 19.1 admin_panel (5) · analytics (7)

- `SystemConfigTests` — public-vs-private config scoping (`public`
  action shape; secrets never leak to the public feed).
- `BannerTests` — active-window feed (start≤now, end≥now), position
  ordering for carousel vs popup vs banner slots.
- `CouponTests` — validate math (PCT×value capped at max; FIXED flat;
  min-subtotal + window + applies_to ALL/CATEGORY/PRODUCT branches).
- `ScheduledTaskTests` — celery-task `run_now` (returns task id,
  flips RUNNING).
- `ReviewModerationTests` — staff-only list/filter/approve-hide-delete
  (bare array shape, no pagination surprise).
- `DailyMetricsTests` · `UserEventTests` · `FunnelTests` ·
  `RetentionTests` · `RevenueByChannelTests` · `ProductPerformanceTests`
  · `CartModelTests` — analytics aggregations + cart money invariants
  (totals from server, never client).

## 19.2 cart/categories/common/delivery (3+2+2+4)

- `CartModelTests` — line math (`quantity × unit_price = line_total`),
  cart totals from server responses.
- `CartTenancyTests` — mixed-seller add/merge allowed (the split lives
  at checkout, not in the cart) + `tenant_id`/`seller_name` resolution
  chain (active non-platform store → tenant name → "EasyGet").
- `CategoryModelTests` — tree integrity, slug gen, product counts,
  icon handling.
- `CategoryCacheSignalTests` — `cache.clear()` in setUp (cross-test
  Redis leak lesson: `on_commit` invalidation never fires under
  `TestCase` rollback, so cached renders leak between tests).
- `ExceptionHandlerTests` — error envelope incl. `ErrorDetail(`-repr
  backstop (raw Python reprs must never reach clients).
- `HealthEndpointTests` — 200 ok body + CORS allow-vs-block origins.
- `PincodeLookupTests` — 6-digit format 400, postal-API mapping, fee
  math (₹29 under ₹499), 404 undeliverable.
- `PincodeStateAliasTests` — TN↔Tamil Nadu normalization table (store
  codes vs API names must agree or ETA flips 2d↔4d).
- `PincodeStoreStateTests` — store-state vs postal-state ETA branches +
  pins to platform-visibility behavior.
- `BannerPublicEndpointTests` — public windowed banner feed shape.
- `DeliveryTenancyTests` — assign=writers, list/advance=authed, agent
  PII scoping (own-tenant assignments or unassigned pool; staff all).

## 19.3 inventory/notifications/orders (2+3+3)

- `StockItemTests` — UNIQUE store×variant, thresholds, `is_available`
  (qty>0) / `is_low_stock` (≤threshold) props, denormalized tenant
  binding (matches store.tenant at write).
- `StockItemApiSecurityTests` — cross-tenant create 400, adjust perms
  (member-of-item-tenant), floor-0 rejection, audit row per adjust.
- `NotificationTemplateTests` (render slots) ·
  `NotificationTests` (list, mark-read, unread count) ·
  `NotificationPreferenceTests` (get/all/bulk_update).
- `OrderModelTests` — UUID pk, `EZG-…` numbers, money fields, cancel
  window rules at model level.
- `OrderTenancyTests` — scoped querysets per actor, seller resolution
  per line, platform-`store` rejection (400).
- `OrderSplitTests` — resolve-all-sellers-first atomicity (dead seller
  → 400 with ZERO orders created), `{orders}` shape, legacy `{store}`
  mode untouched, `store_name` on list rows.

## 19.4 payments/products (5+6)

- `PaymentMethodTests` — saved methods per type (CARD/UPI/WALLET/COD).
- `PaymentTests` — direct-create incl. order-ownership
  (`{"order":"Order not found."}` — no enumeration oracle for probing
  strangers' orders).
- `RefundTests` — amounts/reasons validated against the PAYMENT (not a
  pass-any-order-id oracle) + the `pk`-kwarg latent-500 fix.
- `PaymentTenancyTests` — inherit-via-order scoping, scoped refund
  lists.
- `PaymentApiSecurityTests` — cross-user attach/refund blocked.
- `ProductModelTests` — slug auto+suffix on collision, MRP-minus-base
  math, negative-MRP guard (→0, never negative percent).
- `ProductDiscoveryTests` — brand iexact, guest-public reads,
  guest-writes 401/403, whole-word brand matching, 25%-discount
  isolation (Deal Dal only), price_asc/desc/newest sorts, brands
  endpoint (fixtures carry stock — visibility intact).
- `ProductReviewTests` — masked names ("Rahul B."), 400 out-of-range,
  409 duplicate, anon-401, aggregates on list rows, unapproved-hidden
  (list AND aggregates), verified-purchase via delivered orders.
- `ProductWishlistTests` — auth gates (anon 401/403), add→list→remove
  flow, add idempotent (201 then 200, count stays 1), delete-missing
  idempotent (200, count 0).
- `ProductRatingSortAndOffersTests` — rating desc nulls-last + count
  tiebreak + id stabilizer; ghost-hidden regression (inactive stays out
  of EVERY sort — the visibility-before-sort law); coupon embed (live
  vs expired vs other-product scoping).
- `ProductImageEndpointTests` (9 tests) — guest-upload 401, file-
  required 400, first→primary + sort_order 1 + absolute `.webp` URL
  contract, detail-URL-string regression (the `primary_image`-model-
  instance 500 that fired the moment a product gained an image),
  display-knob defaults (50/50/1.0/none/400), edit + validation (6 bad
  payloads → 400), list-embed of display, second-keeps-first-primary,
  PATCH-primary demotes rest, DELETE-primary promotes next,
  cross-tenant 403s, platform-images staff-only.

## 19.5 pwa/realtime/search/storefront (5+4+2+8)

- `PWAConfigTests` · `PushSubscriptionTests` · `OfflineDataTests` ·
  `AppUpdateTests` · `AppUpdateApiSecurityTests` (writes + `mark_
  deployed` admin-only — VULN-001; anon create 401 pinned).
- `DeviceTests` (platform enum IOS/ANDROID/WEB + token required) ·
  `ChatRoomTests` (participants read-only, room↔order caller-must-own-
  or-staff) · `ChatMessageTests` (staff-or-author edit/delete,
  same-room `reply_to`) · `ChatApiSecurityTests` ·
  `InventorySubscriptionTests` (store-group pushes on stock saves).
- `SearchModelTests` (index document/vector, suggestion/popular/log
  shapes) · `SearchAPITests` — compound-word contract on UNSTOCKED
  platform fixtures (proves search lists unstocked: "black board"→
  "Blackboard", Steel Bottle excluded; case/space-insensitive;
  tag+category single-token returns exactly 3; gibberish total 0;
  suggestions surface multi-word partials).
- `TickerConfigTests` (announcement bar shape) ·
  `PublicRenderTests` (platform + slug renders incl. theme/sections) ·
  `SectionCrudTests` · `ReorderTests` (positions = indices, unknown ids
  400) · `ItemCrudTests` (cross-tenant product 400) · `ThemeTests`
  (button styles, color/font persistence) · `ProductTenantSecurityTests`
  · `PlatformRouteTests` (flag lookup, registered before slug) ·
  `PlatformSectionGuardTests` (platform↔any-active, merchant strict) ·
  `PlatformStoreFlagTests` (partial-unique single platform row) ·
  `PlatformStoreVisibilityTests` (list/detail hide platform row from
  non-staff).

## 19.6 tenants/users/webhooks (5+6+3)

- `TenantProvisioningTests` (verified-user auto-provision vs link-
  single-membership for multi-store merchants) ·
  `StoreIsolationTests` (Store B reads/writes Store A → 403/404, never
  200) · `ProductTenancyTests` (creation binds tenant; customer create
  403; foreign PATCH 403/404 + name intact; **foreign-unstocked 404 /
  own-unstocked 200 / customer-only-stocked** — the visibility triad
  that `0522030` preserved) · `InventoryIsolationTests` (create binds
  store tenant; cross store+variant 400; foreign adjust 404 + qty
  intact; owner adjust + audit row; customer adjust 404; transaction
  scoping per tenant) · `AdminBypassTests` (staff sees everything).
- `GoogleLoginTests` (id_token verify → upsert → triple) ·
  `SignupRoleTests` (CUSTOMER/MERCHANT/DELIVERY_AGENT paths) ·
  `AdminUserManagementTests` (staff-only CRUD) · `AuthFlowTests`
  (register→OTP→login→me chain) · `LogoutTests` (blacklist + dead-
  refresh 401) · `ProfileAndAddressTests` (PATCH allowlist, address
  CRUD, exactly-one-default invariant).
- `WebhookEndpointTests` (admin-only — was AllowAny VULN-006) ·
  `WebhookDeliveryTests` (dispatch + retries) ·
  `WebhookEventLogTests` (append-only log shape).

---

# PART 20 — SEEDS, SECURITY LEDGER, ENV BIBLE, GLOSSARY II, CLOSE

## 20.1 Seeds + commands (full flags, all idempotent)

- `seed_shop_catalog --owner-email <email> --store-name "<name>"
  [--dry-run] [--default-price 0.00] [--quantity 10]` — the Tamil/
  English Shop Checklist → tenant (+OWNER membership) + store + 10
  categories + 200 products + 200 variants + 200 stock items.
  Re-runnable (skips existing); `--dry-run` prints without writing.
  Variant prices start as placeholders until merchandised; trailing `|`
  name suffixes stripped at seed. THE source of the live catalog —
  re-run after wipes, never hand-insert 200 rows.
- `rebuild_search_index` — full `ProductSearchIndex` rebuild (after bulk
  imports, FTS weirdness, or "search misses new products" reports).
- `seed_platform_storefront` — EASYGET platform row + starter sections
  (hero, category grid, product row) so fresh databases render a home
  page instead of the empty fallback.
- Everyday: `check` (0-issues gate, runs in CI) · `migrate [--noinput]`
  (Render runs it on boot) · `collectstatic --noinput` (Render needs
  committed settings or `ImproperlyConfigured: STATIC_ROOT`) ·
  `createsuperuser` (first admin before seed logins exist) ·
  `shell -c "…"` (probes — prefer over scratch scripts; scratch `.py`
  files must never be committed).

## 20.2 Security ledger (2026-09-26 review: 14 findings → 13 fixed, 1 accepted)

| ID | Area | What was wrong → fix (all 13 live-verified) |
|---|---|---|
| 001 | pwa writes | `get_permissions` AllowAny on writes → admin-only for writes + `mark_deployed`; anon create now 401 |
| 002 | inventory create | store outside caller's tenant accepted → 400 "Store not found." |
| 003 | delivery | flat perms → assign=writers, list/advance=authed; agent PII scoped (own-tenant or pool; staff all) |
| 004/007 | chat | anyone could edit → staff-or-author; participants read-only; `reply_to` same-room; room↔order ownership |
| 005 | websockets | ungated subscribes → order via `can_access_order`, rooms via `check_room_access` |
| 006 | webhooks | AllowAny charge-confirmable → `IsAdminOnly` (merchant POST now 403) |
| 008 | payment attach | any order id attachable → order-must-belong `{"order":"Order not found."}` (no oracle) |
| 009 | refunds | any refundable order id → fields validated vs payment + `refund(pk)` latent-500 fix |
| 011 | storefront | cross-tenant items + public inactive sections → 400 guard + 404 unless staff/manager |
| 012 | OTP+throttle | enumerable errors + dead throttle scopes → uniform message, silent resend quota, `ScopedRateThrottle` WIRED (register 3 / login 5 / otp 10 per min; burst proof `401×5→429×2`) |
| 013 | passwords | `AUTH_PASSWORD_VALIDATORS` was `[]` → similarity + min-10 + common + numeric, serializer + form |
| 014 | order cancel | LOW risk — formally accepted as-is |
| ENV | cache death | redis-py8 `HELLO` vs old server silently killed ALL caching AND throttling → `protocol:2`, fail-soft kept |
| UX | riders | signup-grid overflow fix; personal-route guest gate; `eg-*` logout purge (both apps, admin on 401 too) |

## 20.3 Env bible (every variable, what breaks without it)

- `DJANGO_SECRET_KEY` — prod boot REQUIRES it (safe-fail by design);
  dev accepts anything. Never in git (hygiene CI fails it).
- `DJANGO_DEBUG` — `true` local (media `static()`, verbose errors);
  `false` prod (whitenoise, strict hosts, secure cookies posture).
- `DJANGO_ALLOWED_HOSTS` — CSV; needs `testserver` for APIClient shell
  probes, Render domain + localhost variants live (else DisallowedHost
  on every request — the classic shell `Invalid HTTP_HOST` error).
- `DJANGO_CORS_ALLOWED_ORIGINS` + `DJANGO_CSRF_TRUSTED_ORIGINS` — MUST
  list `pages.dev` origins post-cutover or browsers silently block API
  calls (blank shop, console CORS errors — check console first).
- `DATABASE_URL` — Supabase Postgres live; `sqlite:///db.sqlite3`
  hermetic (tests + hanging-command rescue). Read once at startup.
- `REDIS_URL` / `CELERY_BROKER_URL` / `CELERY_RESULT_BACKEND` —
  `rediss://` Upstash live; absent ⇒ inline task fallback (search logs
  still recorded) + slow-but-correct cache (throttles need live cache
  to bite — see ENV row above).
- `DJANGO_EMAIL_BACKEND` — console dev (OTP codes print in backend
  log — that's where you read them); real SMTP backend + FROM for
  staging/prod.
- `GOOGLE_OAUTH_CLIENT_IDS` — web,android IDs comma-separated; EMPTY ⇒
  `/auth/google/` 503 (everything else works; GIS button hides itself).
- `VITE_API_URL` — BAKED into web bundles at build time (deploy value =
  `https://easyget-api.onrender.com`; local default `127.0.0.1:8000`
  + vite `/api` proxy). Rebuild to change — no runtime override.
- `VITE_GOOGLE_CLIENT_ID` — public identifier, baked; absent ⇒ Google
  button hidden (never a dead button).
- `VITE_NEXT_UI` — `1` makes preview the default look (query param
  still overrides per visit).
- `SUPABASE_S3_*` ×6 (endpoint/bucket/region/access/secret/…) —
  Render-dashboard-only; absent ⇒ ephemeral local media (uploads vanish
  on restart — the pre-cutover ids-6-and-8 lesson).
- `CLOUDFLARE_API_TOKEN` / `CLOUDFLARE_ACCOUNT_ID` — GitHub Secrets for
  the deploy workflow (raw tokens in `$env:TEMP\opencode\`, never git).

## 20.4 Glossary II (system terms, A–Z)

AllowAny (public mark) · admin-only route · anonymous retry (dead-token
→ guest) · audit row (every stock move) · bare array (unpaginated admin
lists — always handle both shapes) · blacklist (logout) · cache-aside +
signals (1h renders) · clamp (page_size ≤20, hard) · committed-field
guard (skip compressed uploads) · cross-tenant 400 (noisy) vs 404
(silent — no-leak) · dead seller (split-create 400, zero created) ·
default branch (fix/flutter-web-and-ordering until owner flips to main)
· denormalized tenant (StockItem copies store.tenant) · DnD reorder
(positions = indices) · envelope error · ephemeral disk (Render free) ·
fail-soft cache (correct-but-slow) · flag lookup (platform by
is_platform, never slug) · ghost product (inactive visibility fixture) ·
guest purge (`eg-*` wipe) · hybrid direction (calm marketplace) ·
idempotent wishlist (201-then-200, missing-delete-200) · inline fallback
(Celery-or-direct) · knob ranges (display validation both sides) ·
legacy single-order mode (`{store}` kept for Flutter) · masked reviewer
("Rahul B.") · merchant-private catalog (unstocked = invisible) · no-leak
404 (existence never confirmed) · no-op defaults (fx absent = same pixels)
· orphan S3 object (delete gap) · partial unique (one platform store) ·
platform product (`tenant NULL`, public when active) · pre-paint theme
(index.html, no flash) · purge-to-guest (401 downgrade) · remount-by-key
(route freshness) · ruled grid (hairline table look) · seller-grouped
cart (D3: sellers only in cart/checkout/orders) · smoke (live API proof
runs: 8/8, 13/13, 14/14, 27/27) · split orders (`{orders}`, atomic) ·
staged files (create-mode uploads) · subquery aggregates (no drift) ·
tenant-strict guard (merchant items) · token mirror (TS tokens.ts) ·
unstocked triad (foreign-404 / own-200 / customer-hidden) · verified-
purchase badge (server-derived) · views-only injection (`in_stock`
without touching serializers) · zero-variant product (mens-footwear).

## 20.5 The repo in numbers (2026-10-12, all verified this session)

- Docs: this master file + per-app READMEs (shop 269 / admin 214 /
  backend 283 / v2-Big 409) + CONTEXT 274 + DESIGN 768 + PROJECT 233 +
  GETTING_STARTED 114 + currentUpdate 500 + GitCheck 145 + Checklist
  480 + firebase-plan 175 → ~3,800 lines of docs alone.
- Code: backend 20 apps · 80 test classes · **293 tests green** (1
  skipped) · ~90 endpoints under `/api/v1/` · 3 management commands ·
  shop 33 source files · admin 19 files · app v2 ~100 dart files + 332
  tests (per v2 README) · 4 GitHub workflows.
- Live: catalog **216** active (202 stocked, 14 Out-of-Stock, 1
  zero-variant) · 20 brands · 3 seeded coupons · 2 stores (+platform) ·
  RLS 68/68 zero-grant · cache 1h · throttle login 5/reg 3/otp 10.

---

gateway-agnostic payments template).*

---

# PART 21 — SHOPPER JOURNEYS (click-by-click through customer-web)

> Each journey names the route, the components, the API calls in order,
> and the failure branches. Trace these in DevTools Network to learn the
> app faster than reading code.

## 21.1 First visit (guest, cold)

1. `GET /` → `index.html` runs the no-flash script (`eg-store-theme`
   → OS pref) → React mounts (`main.tsx`) → providers boot.
2. `StorefrontProvider` → `GET /storefront/platform/` (theme cached) →
   CSS vars applied; header shows EASYGET + city.
3. `["categories"]` → `GET /categories/` → header strip renders.
4. Home sections render from the same payload (carousel, grids).
5. `DealsRail` → `GET /products/?page_size=60` → top-12 discounts +
   countdown. `RecommendedRail` waits for `topCategory()` (empty on
   first visit → rail hidden — correct, not a bug). `RecentlyViewedRail`
   hidden (no history). `AllProductsGrid` → `GET /products/?page=1&
   page_size=20` → grid + sentinel prefetches page 2 at 200px.
6. Failure branches: platform 404/500 → `EmptyState store` ("not
   available"); rails fail silently to null (page still useful); grid
   fails → error `EmptyState` with message (retry by reload).

## 21.2 Search → PDP → buy (signed-in)

1. Header submit → `#/search?q=jasmine` → suggestions (if typing) +
   `POST /search/ {q}` → cards (badged; jasmine shows Out of Stock).
2. Click → `#/product/jasmine-gold-hair-oil` → `GET
   /products/:slug/` (200 + `in_stock:false`) + reviews GET →
   `recordView()` (now with `inStock`) → gallery/variants/offers render;
   buy box shows chip + disabled buttons (no dead end, no 404).
3. In-stock sibling: pick variant → pincode `206001` → ETA line →
   qty 2 → Add → `POST /cart/items/` → toast → bubble pops
   (`usePopOnChange`) → header count + bottom-nav badge update.
4. Buy now → add → `#/checkout` → address radio (or create) → review
   groups ("2 orders — one per seller") → place → `POST /orders/`
   (no `store`) → toast `N orders placed!` → `#/orders`.
5. Track: `#/order/<uuid>` polls detail → timeline grows
   PENDING→…→DELIVERED → review form → 201 (verified badge) → second
   submit → 409 toast ("already reviewed").

## 21.3 Browse with filters (the filter state machine)

`category/brand/discount/sort/min/max/featured` live in `useState`;
`baseParams()` serializes (sort allowlist enforced — unknown sorts never
sent); `useInfiniteQuery` key = `["products","browse",params,uid]`
(user id prevents cross-user bleed); sentinel + conditional Load More;
chips remove one dimension; Clear all resets. Count line shows
`total` from the LAST page (`count` is server-global, not
page-local — read it from any page).

## 21.4 Wishlist heart (three modes)

- Signed OUT: `toggleWishlist(slug)` → device list; heart fills; card
  re-renders from `isWished`. Nothing touches network.
- Signing IN: server list should replace cache (`setWishlistCache` —
  wire on login; gap if skipped: stale hearts until refresh).
- Signed IN toggle: optimistic fill → POST/DELETE → `syncWishlistCache`
  → rollback + unfill on throw. Count comes from `WishlistAction`.

## 21.5 Theme toggle + dark mode

Sun/Moon → `localStorage eg-theme` → `data-theme` + 200ms transition
attr (removed after 260ms) → OS listener ignored from now on (explicit
choice wins). Dark palette `!important` beats merchant inline `--bg`.
`prefers-reduced-motion` skips the transition. Pre-paint script means
reload never flashes.

## 21.6 NEXT_UI preview run

`npm run dev` → open `/preview.html` (or `?next_ui=1` flow) → without
flag: enable-instructions only; with flag: 6 live rows through
`next/ProductCard` + skeleton demo. CI screenshots it at 3 widths × 2
themes on every customer-web push (artifact `preview-shots`).

# PART 22 — BACKEND PER-APP FIELD GUIDE (20 apps, what lives where)

> For each app: files that matter, classes/functions to know, and the
> gotcha that bites newcomers. Tests column = class names from Part 19.

- **common** — `views.py` health; `exceptions.py` envelope (+repr
  backstop); `cache.py` get_or_set + `cache_signals.py` invalidation;
  `pagination.py` Max20; `images.py` + `image_signals.py` (WebP q80,
  committed-field guard, banner `FileNotFoundError` lesson); `rls.py`
  (sender-less post_migrate — `sql.py:45` note); pincode service module
  (postal fetch + browser UA + alias map + process cache + heuristic).
  Gotcha: Redis-down = slow-but-correct; throttles need live cache.
- **users** — `models.py` User/OTPCode/Address; `auth_urls.py` +
  `views.py` (6 auth endpoints); `permissions.py` IsAdminOnly (+role
  helpers); `admin_urls.py` (user mgmt — mounted AFTER admin_panel).
  Gotcha: email auto-verified on register (OTP legacy); password min 10
  enforced serializer-side too.
- **tenants** — `models.py` Tenant/Membership; `permissions.py`
  Writer/ObjectAdmin/ObjectMember; `services.py` member?/admin?/resolve/
  provision (+tests file doubles as spec). Gotcha: NO middleware —
  resolve at view time (JWT invisible earlier).
- **stores** — `models.py` Store (+is_platform/partial-unique);
  `views.py` list/detail (platform hidden non-staff) + create
  (provision-or-link); migration with BOTH `Rahul's` spellings + live
  rename. Gotcha: slug `rahuls-store` is legacy/Flutter — never rename.
- **categories** — `models.py` tree + `serializers.py` (counts,
  children-on-detail) + cached list view. Gotcha: 1h stale cache vs
  reseeds (ids 1 vs 6–15) — verify ids in shell.
- **products** — models (5 classes incl. `ImageDisplayFields` abstract)
  · `views.py` (§6.3 + Oct `in_stock` injection — read the comments) ·
  serializers (subqueries, offers, `_primary_image_url`) ·
  `urls.py` (brands/wishlist/reviews/images BEFORE router — order is
  API) · 3 management-adjacent? No — seeds live here: `seed_shop_
  catalog`. Gotcha: `base_price` is a PROP (never filter on it).
- **inventory** — models (denormalized tenant!) · `views.py`
  (list/create/low-stock/transactions/adjust) · serializers (write
  rejects cross-tenant). Gotcha: adjust is DELTA-only + audited.
- **cart** — models (user cart, lines with variant FK) · `views.py`
  (get-or-create singleton, add/merge/clear/delete, seller prefetch
  `to_attr`) · serializers (seller fields). Gotcha: PATCH 405s live.
- **orders** — models (UUID, machine, numbers) · `views.py` (split
  vs legacy, timeline, cancel, invoice) · serializers (store_name,
  nested items/events). Gotcha: resolve-sellers-FIRST atomicity.
- **payments** — models (method/order/gateway/status/ref) · views
  (methods, direct-create, refunds) · serializers (ownership + payment-
  bound validation). Gotcha: NO intent/confirm — don't build them
  client-side.
- **delivery** — models (Assignment machine + order sync) · views
  (assign/advance/agents/list tiers) · serializers. Gotcha: agent PII
  scoping (pool vs own-tenant).
- **search** — `models.py` (Index/popular/logs) · `views.py`
  (queryset shape comment, token contract, sort branches incl. rating
  subquery, pagination math, enqueue×2) · `serializers.py`
  (result+highlight+score, request with page_size≤20) · `tasks.py`
  (log/bump) · `signals.py` (index upkeep) · rebuild command. Gotcha:
  price keys latent-500 (Part 6.3 NOTE).
- **storefront** — models (Theme/Section+display/Item, ticker) ·
  `views.py` (platform render, section/item CRUD + reorders, theme
  PATCH, `_product_allowed_for_store`) · serializers (read vs write
  split, image fields) · `ticker.py` · seed command. Gotcha: cache 1h +
  signal invalidation (self-heals on first write).
- **admin_panel** — models (Config/Banner/Coupon/Task/Action) ·
  `views.py` (dashboard math, coupon validate math, task runner,
  review moderation) · serializers. Gotcha: dashboard is NOT `/stats/`;
  review list is a BARE array.
- **notifications** — models (template/notification/preference) ·
  views (list/read/unread/prefs/bulk). Gap: no live push flow yet.
- **realtime** — consumers (order/room guards), devices view, chat
  models/views, inventory subscriptions + signals. Needs Redis to run.
- **analytics** — event models + ingest/batch views + 6 aggregation
  test classes (the reporting queries to copy).
- **pwa** — config/push/offline/update models + views (writes
  admin-only) + `mark_deployed`.
- **webhooks** — endpoint/delivery/log models + admin-only views.
- **config** — settings splits, URL mounts (admin order!), ASGI/WSGI/
  Celery entries. Gotcha: keep deploy-prep keys committed.

---

# PART 23 — OCTOBER 2026 APP DIARY (git log, newest first, with context)

> The Flutter track moved fast in October. Each row = one commit on
> `fix/flutter-web-and-ordering` + what it means for you. Web/backend
> rows from the same window are interleaved where they interact.

- `9cc273b fix(app): explicit added-state, 3s notices, live card
  quantities` — cards show per-variant cart counts live; toast notices
  auto-dismiss in 3s (matches web toast timing — keep in sync).
- `27142ed test(app): live quantities, ETA, trust rows, address entry`
  — widget tests pinning the rows above (TDD gate per v2 README §9).
- `aa9fbbf feat(app): live card quantities, dynamic delivery ETA,
  richer cart` — ETA computed per store distance/state (mirrors web
  pincode ETA inputs); cart screen gained seller grouping.
- `d90d072 feat(app): champagne minimalist grid` — home grid restyle
  ("champagne" warm minimalism + obsidian glass accents — the Fresh
  Market direction, DESIGN §9–§10, NOT the web's Flipkart look).
- `a34708d feat(app): Zodiak display typeface, bundled offline` —
  Zodiak OTF in `assets/fonts/` (400/700) so display type works offline;
  Inter stays runtime-cached via google_fonts.
- `2c86b81 fix(app): decode live image key` — backend image field key
  changed shape (primary/gallery refactor) — app decoder updated; PDP
  gallery falls back gracefully when keys are missing.
- `41c68be test(app): prove cards run quick-add` — quick-add pipeline
  tests (tap → variant sheet → qty → cart) + split-order release proof.
- `5148fbc fix(app): view-cart goes to cart tab` — "View cart" CTA
  routes to the cart TAB (not a pushed page) + static guard against tab
  pushes (navigation law: tabs switch, never stack — v2 README §7).
- `0522030 fix(catalog)` — THE backend+webs Out-of-Stock commit (Part
  8.2/11). App still needs parity (§12.4).
- `b985483 fix(app): centered states, rows and loading footers` —
  loading/empty/error centering pass + list footers (skeleton-first law).
- `9ca77ba feat(app): card quick-add pipeline, live badge, home
  All-products` — mirrors web's AllProductsGrid tail on home.
- `435f3f8 feat(app): voice search with mic, camera removed` —
  `speech_to_text` mic flow in search; camera feature cut (scope).
- `0c47edb feat(app): FCM push wiring on existing project keys` —
  `firebase_messaging` on the CURRENT Firebase project (no new project;
  keys already provisioned — see v2 README push section).
- `252507b feat(app): app-update prompt gate` — `package_info_plus`
  version check vs `/pwa/updates/check/` → blocking update gate.
- `ca11130 feat(app): local alerts on order status changes` —
  `flutter_local_notifications` fires on watched order transitions
  (works without FCM — belt and suspenders).
- `57a0316 feat(app): notifications inbox plus unread badge` —
  notifications screen + bottom-nav/tab badge from `unread_count/`.
- `4a111e1 feat(app): wishlist screen` — saved grid + remove + UNDO
  (undo window — don't delete immediately, offer restore).
- `2a46b93 fix(app): search image grid categories, show-more pagination`
  — search results as image grid with category chips + progress-aware
  show-more.
- `4a871ce fix(app): hero banner, horizontal categories, pushed browse,
  fallback rails` — home hero + side-scrolling categories + browse
  push + rails that degrade to fallback content offline.
- `59a8673 / 5c85566 fix(app): MNC filter sheet, bare-list paging,
  centered loading/CTA` — filter bottom-sheet iteration + paged bare
  lists (no DRF envelope assumptions — `asArray` thinking in Dart).
- `a370656 fix(app): search category browser list` — category-first
  search entry (browse by category, then query within).
- `1a49498 perf(app): instant boot from cached profile, branded native
  splash` — cached profile paints first frame instantly; native splash
  (Android+iOS) branded before Flutter draws.
- `d29debe fix(app): free Photon autocomplete, no key or billing` —
  address autocomplete via Photon API (keyless, no billing — do not
  "upgrade" to a keyed provider without discussion).
- `0330ea2 fix(app): no 0.0 pills on unrated products` — rating pill
  hidden when unrated (SAME rule as web `RatingPill` — cross-platform
  consistency).

---

# PART 24 — EXTENDED TROUBLESHOOTING (mobile + platform + release)

| # | Symptom | Cause → Fix |
|---|---|---|
| 41 | `flutter pub get` version solve fails | SDK too old for pinned majors (Riverpod 3.4+/go_router 18 need newer Dart) → stay on pinned minors OR upgrade Flutter (local 3.38/Dart 3.10 per v2 README) |
| 42 | Analyzer red on Riverpod (`.value`, notifiers) | v3 API shapes (no codegen) → match installed 3.3 API; don't copy v2.x docs examples |
| 43 | Android build NDK/Gradle mismatch | Regenerate `android/` scaffold (`flutter create --platforms=android .`) — done once 2026-09-23; avoid hand-editing Gradle |
| 44 | App hits wrong API on emulator | `localhost` = device itself → use `10.0.2.2:8000` (Android) / host loopback override (iOS/desktop) |
| 45 | Release signing fails | No keystore committed (hygiene forbids `*.jks/key.properties`) → local-only signing config, never git |
| 46 | FCM silent | Wrong project keys / no device token / backend sleeping (free-tier wake 30–90s) → verify token registration + wake API first |
| 47 | Voice search dead | Mic permission denied / `speech_to_text` init missed → permission prompt BEFORE first listen; handle "never resolves" (user closed popup) |
| 48 | Photon returns nothing | Offline / rate-limited → fallback to manual address entry (always keep manual path) |
| 49 | Zodiak missing (fallback serif) | Font asset path wrong (`assets/fonts/Zodiak-*.otf` + pubspec `fonts:`) → check bundle, not code |
| 50 | Hive box errors on upgrade | Schema changed without adapter bump → version boxes + `build_runner` regen (`hive_generator`) |
| 51 | `build_runner` conflicts | Stale `.g.dart` → `flutter pub run build_runner build --delete-conflicting-outputs` |
| 52 | iOS-only crash | Android-tested only (APK focus) → run `flutter run -d <ios-sim>` before claiming iOS works |
| 53 | Playwright Chromium missing in CI | `npx playwright install --with-deps chromium` is IN the workflow — local needs `npx playwright install chromium` once |
| 54 | Preview shots differ from prod | Shots run `preview.html` (NEXT_UI), not `index.html` — compare against the right surface |
| 55 | Wrangler deploy 401 | Token/account mismatch → check secrets + account id `1dcd…9b22`; tokens in `$env:TEMP\opencode\` |
| 56 | Cloudflare serves stale bundle | Cached edge/HTML → hard-refresh; confirm deploy SHA matches commit in Pages dashboard |
| 57 | Supabase dashboard confusion | Two regions/keys (pooler vs direct) → app/API use pooler string from `.env`; RLS SQL in `docs/` is reference |
| 58 | Upstash `rediss://` refused | `rediss` (TLS) vs `redis://` typo → copy exact var from dashboard; local needs no Redis (fallback) |
| 59 | Render env edit no effect | Service needs redeploy/restart after env PUT → trigger manual deploy; verify boot logs show new values |
| 60 | `collectstatic` 0 files warning | `STATIC_ROOT` unset (settings uncommitted?) → keep deploy-prep committed or start exits 1 |

---

# PART 25 — WEEK-ONE PLAN, MAINTENANCE, CLOSE

## 25.1 Junior week-one plan (do in order, check boxes)

- [ ] Day 1: read THIS file §§1–3 + GETTING_STARTED; boot all 4
  terminals; complete the §2.3 checklist (all 7 green).
- [ ] Day 2: click the shop as guest → register → buy (jasmine OOS +
  one stocked item) → track → review; replicate in admin (find the No
  stock badges, adjust one SKU +10, watch badge flip to Live).
- [ ] Day 3: read backend README §§2.5–2.6 + Part 18 rows 8–17; probe
  each with curl/API docs; break one thing locally (deactivate a
  product) and watch all three surfaces react.
- [ ] Day 4: read shop README + admin README fully; implement a
  trivial UI copy change behind `isNextUi()` + preview it; run both
  builds green.
- [ ] Day 5: pick the smallest §12 item with a buddy; write the change
  + update `currentUpdate.md` + `GitCheck.md` + (if system) THIS file;
  open the PR. You are now a contributor.

## 25.2 Maintenance contract (how this file stays true)

- System change ⇒ same-commit doc touch (this file + per-app README +
  `currentUpdate.md` + `GitCheck.md`; contract change ⇒ `CONTEXT.md`).
- Numbers (§20.5, §1.7) re-verify by direct query (`shell -c`), never
  by memory ("200 products" was stale for weeks — now 216).
- Session ledger (Part 11): append newest-first rows in GitCheck style
  (`date | branch | commit | summary + verification + open edges`).
- Line-count floor: this file must stay ≥2500 lines — if you delete a
  stale section, replace it with its successor's docs (owner's rule:
  length is fine, staleness is not).

## 25.3 Doc map with sizes (2026-10-12, lines)

This master ~2,600 · shop 269 · admin 214 · backend 283 · v2-Big 409 ·
CONTEXT 274 · DESIGN 768 · PROJECT 233 · GETTING_STARTED 114 ·
currentUpdate 500 · GitCheck 145 · Checklist 480 · firebase-plan 175 ·
phase-1-spec (docs/) · local-dev 81 → **~7,500 lines of docs** guarding
~90 endpoints, 293 tests, 216 products. Read them in the §0 table order.

---

# PART 26 — REACT QUERY KEY REGISTRY (observed keys — extend as you add)

> Key = cache identity. Same key + same fetcher = one network call per
> session visit. Include user id in personal keys (cross-user bleed
> otherwise). Invalidate after mutations (`invalidateQueries`).

## 26.1 customer-web keys (seen in source)

- `["categories"]` (5-min stale) — header strip + CategoryRail + Browse
  filters + SearchPage chips share ONE fetch. Never duplicate with a
  local `useState` fetch (old CategoryRail did — converted in the
  React-Query pass).
- `["products","deals"]` (2-min) — DealsRail (60 rows → top-12 client).
- `["products","recommended", topSlug|null]` (enabled iff topSlug) —
  RecommendedRail (`topCategory()` from recents; null key part keeps
  cache split per category).
- `["products","related", slug, categorySlug]` (enabled iff category) —
  SimilarRail (excludes self, slices 10).
- `["products","browse", params, userId|null]` — BrowsePage infinite
  (params object inside the key = auto-refetch per filter change; uid
  prevents user-A's grid flashing for user-B).
- `["products","home-all"]` — AllProductsGrid tail (20/page infinite).
- `["product", slug]` — PDP detail (component remounts per slug anyway;
  key guards back/forward cache).
- `["reviews", slug]` — PDP reviews (invalidated after successful
  post so the new review appears without reload).
- Search/cart/orders pages use per-query remounts + context state;
  follow the same `[domain, …params, uid?]` shape when adding keys.
- Client defaults: stale 30s, `refetchOnWindowFocus:false`,
  `retry:1` (no thundering retries on flaky mobile networks).

## 26.2 admin-web keys (seen in source)

- `["admin","products"]` — ProductsPage table (invalidated after
  create/update/delete AND every image op — upload/primary/edit/remove).
- `["admin","categories"]` — CategoriesPage + product-modal options.
- `["admin","inventory"]` — stock table (invalidated after each adjust
  so badges + quantities refresh).
- Orders/reviews/dashboard/users follow `["admin",<domain>]` with the
  same invalidate-after-mutate discipline (this replaced manual
  `reload()` calls in the React-Query conversion — do not reintroduce
  manual reloads).

---

# PART 27 — CSS CLASS DICTIONARY (customer-web, seen in source)

> Token-only values (`var(--…)`). The two legacy `#fff` chip texts are
> grandfathered — do not copy hardcoded hex into new rules.

- Layout: `.page` (route container) · `.section` + `.section-head`
  (title/subtitle/action row) · `.grid` + `.grid-products` (ruled 1px
  hairline table look: `gap:1px` over `var(--border)`) + `.grid-gallery`
  + `.grid-categories`.
- Cards: `.product-card` (rest border → primary-tint hover) ·
  `.product-thumb` (fx-safe wrapper) + `.detail-thumb` ·
  `.product-body/brand/name/rate-row` · `.price/.price-now/-mrp/-off`
  (+`-sm/-md/-lg` sizes) · `.free-ship` (danger-colored when OOS) ·
  `.monogram` (initials placeholder when imageless) ·
  `.chip/.chip-deal`(≥50%)`/chip-featured/chip-out/chip-pending/
  chip-ok/chip-err/chip-info`.
- Rails: `.rail` (horizontal scroll row) + `.rail-item` (fixed-width
  card slot) · `.cat-chip` (CategoryRail chip) · `.catstrip` + `-inner/
  -item/-dot/-arrow/.has-arrows` (drag-scroll header strip with edge
  arrows + `aria-current` on active category).
- Header/nav: `.topnav/.brand/.brand-mark/.brand-name/.brand-city` ·
  `.searchform/.search-ico` (wide search + button) ·
  `.nav-actions/.nav-theme/.nav-login/.nav-wish/.nav-orders/.nav-cart/
  .nav-cart-ico` · `.bubble` (count + `.pop` animation via
  `usePopOnChange`) · `.bottomnav` (mobile ≤640px: Home/Search/Cart/
  Account) · `.ticker` (offer bar under header).
- Hero/carousel: `.hero/.hero-content/.hero-actions/.hero-img` (+
  `-slide/-split/-minimal/-feature` layouts, `-overlay-dark/light/
  none`) · `.carousel/.carousel-track/.carousel-slide(.on)/
  .carousel-arrow/.carousel-dots/.carousel-dot(.on)` · `.banner`
  (section banner with optional link).
- PDP: `.product-detail` (gallery|info|buybox grid) · `.pdp-gallery` ·
  `.thumb-row/.thumb-btn(.active)` · `.detail-title/.detail-desc/
  .detail-option-label` · `.variant-btn(.active)` (active-variant
  outline + tint) · `.buybox/.buybox-brand/-price(.now/.mrp/.off)/
  -section/-actions` · `.btn-cart/.btn-buy` (disabled = OOS or no
  variant) · `.pincode-row/.pincode-eta` · `.qty-stepper` (1–10) ·
  `.seller-box` (EASYGET / 7-days / COD-UPI rows) · `.offer-list/
  .offer-code` · `.pdp-highlights` · `.ratings-summary/-big/-outof/
  -bars/-bar(.track/.fill)` · `.review-card/-head/-who/-when/-title/
  -body` + `.verified-badge` · `.review-form/.star-picker(.on)/.field`.
- Browse: `.browse-layout/.filter-side(.open)/.filter-group/
  .filter-opts/.filter-opt(.on)` · `.filter-chips/.filter-chip` +
  Clear-all `.link` · `.sortbar/.sortbar-right/.count/.filter-toggle`
  (mobile Filters button) · grid reuse + 1px sentinel div.
- Footer: `.footer/.footer-cols/-col/-contact/.footer-social/.soc` ·
  `.footer-bar/.footer-pay/.pay-badge(-mark/-label)/.footer-note`
  (UPI/VISA/Mastercard/RuPay/COD brand marks).
- Primitives: `.btn/.btn-secondary/.btn-ghost/.btn-block` ·
  `.link/.muted` · `.spinner` (role=status) · `.empty-state/.empty-ico`
  · `.card-skeleton` · `.auth-wrap/.auth-card/.sub` · `.input`
  (toolbar + forms) · admin `.modal/.modal-actions/.badge(.ok/.warn/
  .err)/.table-wrap/.toolbar/.panel/.form-grid` · admin gallery
  `.prod-gallery/.prod-img-tile(.primary)/-overlay/-badge/-add(.busy)/
  -empty` + editor `.ide-panel/.ide-panel-head` · `.img-fx` (fx
  wrapper; `:not(img)` gets relative+hidden so thumbs crop) ·
  `.wish-btn(.on)/.wish-card/.wish-pdp` · `[data-theme-transition]`
  (200ms switch class, removed after 260ms).

---

# PART 28 — POWERSHELL SURVIVAL (Windows-only truths)

- Prefix routine commands with `rtk` (token-optimized wrappers; safe
  passthrough when no filter matches) — repo instruction (see
  `~/.claude/CLAUDE.md` in the environment brief).
- Env is per-terminal session: `$env:DATABASE_URL='sqlite:///db.sqlite3'`
  must be re-set in every new terminal (it does not persist).
- No `grep/head/tail/&&`: use `Select-String`, `Select-Object -First N`,
  `; if ($?) { … }` for dependent chains, `;` for independent ones.
  `2>&1` merges streams for piping.
- Venv python ALWAYS as `.\.venv\Scripts\python.exe …` (bare `python`
  risks the wrong interpreter; CI uses its own anyway).
- `manage.py` from REPO ROOT as `backend\manage.py …`; the `cd backend`
  form exists ONLY for the full-suite discovery quirk — comment why
  whenever you use it.
- Browse `http://localhost:3000/` (Vite binds IPv6 localhost;
  `127.0.0.1` fails). Same for `:5174`. API `:8000` answers both.
- CRLF: Windows checks out CRLF; git warns `LF will be replaced by
  CRLF` — normal, do not "fix" line endings with reformats.
- Zombie servers: `Get-NetTCPConnection -LocalPort <8000|3000|5174>
  -State Listen` → `Stop-Process -Id <pid> -Force`.
- Background dev servers: `Start-Process .\.venv\Scripts\python.exe
  -ArgumentList 'backend\manage.py','runserver','0.0.0.0:8000',
  '--noreload' -WorkingDirectory <repo>`; logs to `backend-dev.*.log`
  (gitignored — never commit).
- `workdir` over `cd`: when tooling accepts a working-directory
  parameter, use it instead of `Set-Location` chains.

---

# PART 29 — RELEASE CHECKLIST (pre-push protocol, every time)

1. `git status` + `git diff` — stage ONLY intended files (never
   `.env` / `*.sqlite3` / `media/` / `*.log` / token dumps / scratch
   scripts / `node_modules` / `.venv` / `dist/`).
2. Backend: `manage.py check` (expect 0 issues) + full SQLite suite
   (expect 293 OK, 1 skipped — record the numbers in the commit body).
3. Webs: `npm run build` in BOTH (tsc + vite; warnings tolerable,
   errors stop the push).
4. Live smoke on dev API: health 200 → jasmine detail 200 +
   `in_stock:false` → list `count:216` → search "jasmine" total 1 →
   home renders rails + tail → admin flags show `No stock` on the 14.
5. Docs: `currentUpdate.md` (§0 row) + `GitCheck.md` (changelog) +
   per-app README if touched + THIS file if the system changed (+
   `CONTEXT.md` on contract change, + `DESIGN.md` never casually).
6. Commit (`type: imperative subject` + verification body) →
   `git push origin fix/flutter-web-and-ordering` → watch CI (backend
   job + 2 build jobs) + Cloudflare Pages deploys + Render boot →
   verify the 4 live URLs from §1.3 in a fresh guest window.
7. If CI red: backend job → read the traceback (usual suspects:
   SQLite-vs-Postgres semantics, new-test isolation needing
   `cache.clear()` in setUp, missing env); build job → FIRST tsc error
   (ignore later cascade); deploy job → secrets (`CLOUDFLARE_*`),
   `dist/` paths, or baked `VITE_API_URL`.

---

---

# PART 32 — DECISION LOG (every named decision, with rationale)

> Decisions are load-bearing context: re-litigating them without new
> facts wastes weeks. Each row: ID → choice → why → where enforced.

## 32.1 Platform & tenancy (D1–D6, 2026-09-26, user-confirmed)

- **D1 = B (architectural)**: EASYGET becomes ONE platform storefront;
  `rahuls-store` stays as legacy/Flutter surface. Why: single shopper
  destination beats N micro-shops; legacy slug keeps the app working
  (D5). Enforced: `is_platform` flag + platform route + context always
  fetching it + Flutter untouched.
- **D2 = A (split orders)**: checkout creates one order per seller
  (resolve-all-stores-first, all-or-nothing). Why: sellers fulfill
  independently; partial creation strands money. Enforced: orders view
  + `{orders}` contract + checkout copy.
- **D3 = B (seller visibility)**: seller name ONLY in cart grouping,
  checkout review, orders. Why: cards/PDP stay clean marketplace; seller
  identity matters at money-time, not browse-time. Enforced: serializer
  fields exist ONLY on cart/order payloads.
- **D4 = A (rename)**: demo store → `EasyGet Demo Store`, slug KEPT.
  Why: brand refresh without breaking Flutter/deep links. Enforced:
  migration guards BOTH old spellings + live rename.
- **D5 = A (web only)**: Flutter untouched by the platform cutover.
  Why: ship web value without destabilizing the app track. Enforced:
  legacy slug route + legacy `{store}` order mode kept green by smoke.
- **D6 = Approach 1**: `Store.is_platform` flag + single platform row
  (slug `easyget`, tenant NULL) + partial unique constraint. Why:
  lookup-by-flag survives renames; constraint prevents double-platform
  corruption. Enforced: migration + model constraint + tests.

## 32.2 Tenancy design (Phase 3, documented deviation)

- **No tenant middleware**: JWT user invisible at middleware time, so
  the same server-side guarantee (verified membership, never client
  headers) lives in permission classes + services. Revisit ONLY if auth
  moves earlier in the stack.
- **Per-model ownership** (direct FK vs inherit vs platform-level) over
  blind FK spray: variants/images inherit via product; Category stays
  shared taxonomy; User stays tenant-free. Why: least privilege +
  fewest migrations + taxonomy sanity.
- **Merchant catalogs private until stocked** (2026-09-20 read rule;
  preserved through `0522030` for tenant-owned rows): unstocked
  merchant items 404 for outsiders. Why: drafts aren't promises.
- **Platform exception** (`0522030`): active tenant-NULL rows are public
  + flagged. Why: platform has no "owner" to protect and dead links are
  worse than honest OOS badges.

## 32.3 Money, search, and UX calls

- **Server totals only** (DESIGN law): cart/order responses are money
  truth; client math is display-only. Why: client math drifts (discounts,
  fees, splits) and causes support tickets.
- **Coupons display-only in B1** (apply = Phase C): PDP embeds active
  coupons; checkout ignores them. Why: shipping discovery value now
  without blocking on discount-math correctness.
- **Pincode = external lookup + heuristic** (not a static table):
  postal API + alias map + 2d/4d rule + offline fallback. Why: India
  has ~19k pincodes; a table rots, an API + fallback degrades.
- **Search = FTS + ILIKE net + client fallback**: three layers so no
  single staleness breaks finding products. Why: index lag is normal;
  UX must not be.
- **Hash routing everywhere (webs)**: zero server config on static
  hosts. Why: Cloudflare Pages needs no redirect rules; deep links always
  boot. Cost accepted: `#/` URLs.
- **Split belongs at checkout, not cart** (marketplace cart decision):
  carts mix sellers freely; orders split. Why: one cart UX, correct
  fulfillment math — enforced by removed cross-tenant cart guards.
- **Wishlist = server truth, cache optimistic**: localStorage is an
  offline cache (`sync/set` helpers), server wins. Why: hearts must
  survive devices; offline must still feel instant.
- **Theme pre-paint + OS-until-choice**: cached theme in `index.html`
  (no flash) + system listener that yields to the first explicit toggle.
  Why: first paint is brand; explicit choice is sacred.
- **NEXT_UI gating** (query > storage > env): redesigns provable in
  production without risking the shipped look. Why: client approval
  gates the new face; preview + screenshots make approval fast.
- **Fail-soft cache, inline tasks**: no Redis ⇒ slow-but-correct +
  direct task runs. Why: dev machines and free tiers must never 500 for
  missing infra (the HELLO incident proved the alternative).
- **RLS lockdown without row policies**: owner-bypass + anon/auth
  revoked on 68 tables. Why: defense-in-depth today; row policies only
  if PostgREST/anon access ever arrives (explicit revisit trigger).
- **One screen per session + docs-in-same-commit**: velocity WITH memory.
  Why: 7,500 doc lines exist because every session left its map updated.

---

---

# PART 33 — TEAR-OUT REFERENCE (print this; everything else is backup)

```
EASYGET · fix/flutter-web-and-ordering · 2026-10-12 · 293 green
SHOP   http://localhost:3000          LIVE https://easyget-customer.pages.dev
ADMIN  http://localhost:5174          LIVE https://easyget-admin.pages.dev
API    http://localhost:8000          LIVE https://easyget-api.onrender.com
DOCS   http://localhost:8000/api/docs/      HEALTH /api/v1/health/
ADMIN  admin@easyget.local / EasyGet!2026   CUSTOMER customer@easyget.app / Customer@123
MERCHANT merchant@easyget.app / Merchant@123   AGENT agent@easyget.app / Agent@123
BACKEND .\.venv\Scripts\python.exe backend\manage.py runserver 0.0.0.0:8000 --noreload
TESTS  cd backend; $env:DATABASE_URL='sqlite:///db.sqlite3'; $env:DJANGO_DEBUG='true'; python manage.py test -v 1
WEBS   cd customer-web; npm run dev|build     cd admin-web; npm run dev|build
APP    cd customer-app-v2; flutter pub get; flutter analyze; flutter test; flutter run
PUSH   git status+diff → stage intended → check+tests+builds+smoke → docs → commit → push origin fix/flutter-web-and-ordering
SEEDS  seed_shop_catalog (checklist→catalog) · rebuild_search_index (FTS) · seed_platform_storefront (home)
SPLIT  POST /orders/ no store → {orders:[…]} · with store → legacy single · dead seller → 400 zero-created
PAGES  page_size≤20 everywhere · stable orderings · {count,next,previous,results} · bare arrays on admin reviews
THROTTLE register 3 · login 5 · otp 10 per min (needs live cache) · anon search anti-scrape
MEDIA  local media/ (DEBUG) · LIVE Supabase easyget-media (S3) · DELETE orphans S3 (sweep manually)
CACHE  storefront+categories 1h, signal-invalidated · Redis down = slow-but-correct · protocol:2
CI     ci.yml (check+293 tests+2 builds) · deploy-cloudflare.yml (2 Pages) · preview-shots.yml · repo-hygiene.yml
RLS    68/68 tables locked, anon/auth revoked, owner bypass, sqlite no-op · no row policies yet
SEARCH POST /search/ (FTS+ILIKE) · suggestions ≥2 chars · fallback = tokenized full-catalog match
CART   authed only · upsert-increment · NO server stock gate · PATCH 405 → DELETE+rePOST · merge on login
ORDERS PENDING→CONFIRMED→PREPARING→READY→OUT_FOR_DELIVERY→DELIVERED · cancel PENDING/CONFIRMED · EZG-… numbers
COUPON PDP display-only (WELCOME10/FLAT50/FREESHIP) · apply = Phase C · validate endpoint any-authed-user
PIN    postal API + alias map · ETA 2d/4d · ₹29<₹499 else free (strings) · 404 = undeliverable
FLUTTER 10.0.2.2:8000 emulator base · Photon keyless autocomplete · Zodiak bundled · FCM on project keys
BUYABLE = is_active + active priced variant + in_stock(qty>0, active store)
OOS? platform → badge page (200+in_stock:false) · merchant → invisible (404)
JASMINE PROOF: GET /products/jasmine-gold-hair-oil/ → 200 · in_stock:false · 3 variants
LIST COUNT: 216 active = 202 stocked + 14 OOS · mens-footwear = 0 variants
NEVER: models/serializers/tests edits · invented endpoints · hardcoded hex/px
ALWAYS: tokens · light+dark · loading+empty+error · NEXT_UI gate · docs same commit
PORTS: 8000 API · 3000 shop (localhost, not 127) · 5174 admin · 5432 pg · 6379 redis
ENVS: .env root (restart after edit) · VITE_* baked at build · Render dashboard for prod
SLEEP: Render API 15min idle → 30–90s wake (warm /health/ before demos)
DOCS: GitCheck → currentUpdate → README(this) → GETTING_STARTED → PROJECT → CONTEXT → DESIGN → app READMEs
```

---

*End of master README v2 (≥2500 lines — floor cleared at last count).
Verify: `Get-Content README.md | Measure-Object -Line` must read 2500+.
The owner's two rules: (1) length is fine, staleness is not; (2) one
component or screen per session, docs in the same commit. Next scheduled
touch: Phase C (coupon apply at checkout + gateway-agnostic payments
template).*
First day here? Read Parts 1–3, boot Part 2, then your app's README —
you will be productive by lunch.

---

# PART 30 — CALL-SITE MATRIX (endpoint × frontend caller)

> "Who calls this?" — trace regressions both directions. `cw` =
> customer-web fn (`services/api.ts`), `aw` = admin-web fn. Pages name
> the UI entry; contexts own the shared ones.

- `POST /auth/register/` ← cw `register()` ← AuthPage signup · aw
  `createUser()` ← UsersPage (staff creates accounts directly).
- `POST /auth/login/` ← cw `login()` ← AuthPage + guest-upgrade nudge ·
  aw `login()` ← LoginPage (ADMIN lands on dashboard, merchant scoped).
- `POST /auth/refresh/` ← BOTH `refreshTokens()` inside `api()` (every
  screen, transparently — no page calls it directly).
- `POST /auth/logout/` ← BOTH signOut (AuthContext ×2 + 401 handler).
- `POST /auth/google/` ← cw `loginWithGoogle()` ← AuthPage GIS button
  (hidden unless configured) · app `google_sign_in` flow (v2).
- `GET/PATCH /users/me/` ← cw `getMe()` ← AuthContext boot · aw user
  badge (email/role display).
- `*/users/me/addresses/*` ← cw `list/create/delete/setDefaultAddress`
  ← CheckoutPage selector + AccountPage book.
- `GET /products/` ← cw `listProductsPaged()` ← DealsRail (60) +
  RecommendedRail (12+category) + SimilarRail (12+category) +
  BrowsePage (filters/sorts/infinite) + AllProductsGrid (20s) +
  `listAllProducts()` ← search fallback · aw `listProducts()` +
  `listAllProducts()` ← ProductsPage table+filter · app catalog/browse
  repositories (v2).
- `GET /products/:slug/` ← cw `getProduct()` ← ProductPage · aw
  `getProduct()` ← edit modal (images+variants fetch).
- `GET /products/brands/` ← cw `listBrands()` ← BrowsePage radios.
- `/products/wishlist/*` ← cw wishlist fns ← WishButton + WishlistPage ·
  app wishlist repository + card heart (v2).
- `/products/:slug/reviews/*` ← cw `listReviews/postReview` ←
  ReviewsSection · aw `listReviews/updateReview/deleteReview` ←
  ReviewsPage (different router: `/admin/reviews/`).
- `/products/*/images/*` ← aw image fns ← ProductsPage gallery +
  display editor (shop only READS images via detail).
- `POST /search/` ← cw `searchWithFallback()` ← SearchPage · app
  search repository + SQLite fallback (v1) / controller (v2).
- `GET /search/suggestions/` ← cw `getSearchSuggestions()` ← SearchPage
  debounced dropdown · app search screen.
- `GET /cart/` ← cw `getCart()` ← CartContext (all cart UI).
- `POST /cart/items/` ← cw `addToCart()` ← PDP buttons + quick-add
  surfaces · app quick-add pipeline (v2).
- `DELETE /cart/items/:id/` ← cw `removeCartItem()` + qty-rewrite flows
  ← CartPage steppers · app swipe-to-delete + steppers.
- `POST /cart/merge/` ← login flow (both webs that support guests; shop
  CartContext) · app boot (guest-cart key).
- `POST /orders/` ← cw `createOrder()` ← CheckoutPage (split +
  legacy) · app checkout (legacy `{store}` proof in smoke).
- `GET /orders/` + `/:id/` ← cw `listOrders/getOrder` ← OrdersPage +
  detail · aw `listOrders/getOrder` ← queue + modal · app orders
  repository + track screen (30s poll per v2 README).
- `POST /orders/:id/cancel/` ← cw `cancelOrder()` ← detail (gated
  PENDING/CONFIRMED) · aw `cancelOrder()` ← modal · app cancel sheet.
- `PATCH /admin/orders/:id/status/` ← aw `updateOrderStatus()` ←
  advance dropdown (`NEXT_STATUS` mirror — update BOTH on map change).
- `POST /payments/` ← checkout pay step (COD/UPI/…) · app checkout
  controller. `POST /payments/:id/refund/` ← backend-only today (no
  dashboard button — gap).
- `GET /pincode/:code/` ← cw `checkPincode()` ← PDP checker · app PDP
  pincode row (v2).
- `POST /admin/coupons/validate/` ← (Phase C consumer — no UI caller
  yet; PDP offers are display-only embeds).
- `GET /banners/` ← platform payload path (admin manages; shop renders
  via storefront sections).
- `GET /storefront/platform/` ← cw `getPlatformStorefront()` ←
  StorefrontContext (home's FIRST call; theme cache writer) · app home
  storefront repository (v2).
- `*/storefront/<slug>/sections|items|reorder|theme*` ← aw section/item/
  theme/ticker fns ← StorefrontPage designer (board + modals + tabs).
- Notifications endpoints ← app inbox + badge (v2 engagement) · webs:
  header bell where present. Devices ← app boot (FCM token post).
  Analytics ← app engagement repo + web search logging (server-side).
  PWA check ← app update gate (`package_info_plus` vs response).
- `GET /api/v1/health/` ← deploy probes + warm-ups + CI-adjacent
  scripts (never gate features on it — liveness only).

---

# PART 31 — DEMO DATA DICTIONARY (what lives in the live DB)

> Verified 2026-10-12 by direct query. Regenerate via seeds (§20.1),
> never hand-insert at scale.

- **Users**: admin (staff+superuser) · customer · merchant (tenant
  member) · agent (delivery pool) — §1.6 table. Passwords dev-only;
  rotate before real traffic (§12.5).
- **Tenants/stores**: `EasyGet Demo Store` (id 2, slug `rahuls-store`
  — LEGACY SLUG, never rename: Flutter + old links depend on it) ·
  `EASYGET` platform (id 3, slug `easyget`, `is_platform`, tenant
  NULL). Merchant tenants own their stores (provision-on-create).
- **Categories**: 10 live (ids 6–15 — NOT 1; the cached `Grocery id:1`
  is the stale-cache ghost from Part 13 #18). Shared platform taxonomy
  (one tree for all merchants — deliberate).
- **Catalog**: 216 active products (202 stocked in Demo Store, 14
  platform Out-of-Stock incl. the 12 hair-oil SKUs + fevicol +
  mens-footwear). Brands observed live include Parachute, Dabur (+Dabur
  Vatika), VVD, Aswini, Navarathna, Zigma, Bata, Fevicol (20 total per
  seed manifest). `mens-footwear` = zero variants (no price, permanent
  OOS card until merchandised).
- **Coupons seeded**: `WELCOME10` (10% up to ₹100) · `FLAT50` (₹50 off
  orders ≥ ₹299) · `FREESHIP` (free delivery) — PDP "Available offers"
  reads these live.
- **Storefront**: platform sections (hero, category grid, product row,
  gallery/banners) render the shop home; Demo Store keeps its legacy
  4 sections for Flutter.
- **Orders**: ≥1 staff-visible demo order (fulfilment-queue proof);
  split-checkout smoke created `{orders:[1]}` live on 2026-09-26.
- **Media**: product images under Supabase `easyget-media` (absolute
  URLs); section images same bucket; rows ids 6 & 8 reference LOST
  pre-cutover `/media/` files (re-upload, don't migrate); DELETE
  orphans S3 objects (sweep manually until cleanup ships).
- **Search index**: `ProductSearchIndex` rebuilt via command; popular
  terms accumulate from live query logs (Celery-or-inline).

---

*End of master README v2 (≥2500 lines, both rules attached). If you
added a feature and this file doesn't mention it, the job isn't done —
document in the same commit, then push.*

---

# PART 26 — REACT QUERY KEY REGISTRY (observed keys — extend as you add)
