# EASYGET — backend README

> The Django API behind the shop, the dashboard, and the mobile app.
> Status as of **2026-10-12** (293 tests green). Junior dev path: §1 for
> the map, §2.5–§2.6 before writing any endpoint code, §3 before changing
> visibility/search/cart behavior, §5 for daily commands.
> Companions: `customer-web/README.md`, `admin-web/README.md`, repo-root
> `GETTING_STARTED.md`, `CONTEXT.md` (frozen contracts), `DESIGN.md`.

---

## 0. One-paragraph summary

`backend/` is Django 5.2 + Django REST Framework serving `/api/v1/…`
(JWT auth, Postgres on Supabase in dev/prod, SQLite for tests, Channels
websockets, Celery+Redis with inline fallback). Twenty feature apps own
one domain each (users, catalog, cart, orders…). It is deployed on Render
as `easyget-api.onrender.com`; interactive docs live at `/api/docs/`
(Swagger) and `/api/schema/`. **Frozen law: never modify models,
serializers, or tests; never invent endpoints — ask first.**

---

## 1. WHAT — what this backend is

### 1.1 App map (`backend/<app>/` — one domain per app)

| App | Owns |
|---|---|
| `users` | Auth (login/refresh/logout/register/Google/OTP-legacy), `/users/me/`, address book, admin user lists |
| `tenants` | Merchant organizations, membership, `IsTenant*` permissions, provisioning |
| `stores` | Store rows (platform + merchant), incl. `is_platform`, `is_active` |
| `categories` | Category tree, icons, product counts |
| `products` | Catalog list/detail (slug lookup), brands, images, reviews, wishlist |
| `inventory` | `StockItem` (store×variant qty), adjustments + audit transactions, low-stock |
| `cart` | Per-user cart, items add/merge/clear |
| `orders` | Order create (split per seller), detail + timeline, cancel, invoice |
| `payments` | Direct-create payments (no intent/confirm), methods, refunds |
| `delivery` | Pincode serviceability/ETA/fee (+postal-API lookup w/ fallback) |
| `search` | Full-text product search, suggestions, popular/query logs |
| `storefront` | Platform + per-store renders, sections/items, themes, ticker, 1h cache |
| `admin_panel` | Staff: dashboard summary, banners, coupons (+validate), reviews mod, tasks, config, audit |
| `notifications` | List, mark-read, unread count, preferences |
| `realtime` | Device registration, Channels WS (`/ws/orders/`, `/ws/notifications/`) |
| `analytics` | Event ingest (+batch) |
| `pwa` | Update checks (`/pwa/updates/check/`) |
| `webhooks` | Gateway callbacks |
| `common` | Health, cache helpers, exception envelope |
| `config` | Settings (per-env modules), URL root, ASGI/WSGI, Celery app |

### 1.2 Full API contract (base `/api/v1/`, verified against `urls.py`)

**Auth / Users**
```
POST /auth/login/            {email, password} → {access, refresh, user}
POST /auth/refresh/          {refresh} → {access}            (no rotation)
POST /auth/logout/           {refresh} → blacklists it
POST /auth/register/         {email, password, first_name, last_name, phone, role}
                             role ∈ CUSTOMER/MERCHANT/DELIVERY_AGENT; email auto-verified
POST /auth/google/           {id_token} → tokens (503 if no client IDs configured)
POST /auth/verify-otp/       {email, code}      (legacy; register auto-verifies)
POST /auth/resend-otp/       {email}
GET/PATCH /users/me/         profile
GET/POST /users/me/addresses/ · PATCH/DELETE .../addresses/:id/
                             POST .../addresses/:id/set-default/
```

**Catalog**
```
GET /products/               ?category&brand&min_price&max_price&min_discount
                             &is_featured&sort&page&page_size(≤20)
                             sort ∈ price_asc/price_desc/newest/rating (default -updated_at,-id)
                             → {count, next, previous, results[]}
                             result += in_stock (see §2.5)
GET /products/:slug/         detail + offers[≤5] + variants[] + images[] + in_stock
GET /categories/             flat list (product_count, has_children)
GET /products/brands/        distinct non-empty brands
GET /products/wishlist/      (auth)     POST/DELETE /products/wishlist/:slug/ → {added, slug, count}
GET/POST /products/:slug/reviews/   (paged 10; POST 409 on duplicate)
GET/POST /products/:slug/images/  ·  PATCH/DELETE /products/images/:id/
```

**Search / Cart / Orders / Payments / Pincode / Coupons / Banners**
```
POST /search/                {q, category, min_price, max_price, is_featured, sort, page, page_size≤20}
                             sort ∈ relevance/price_asc/price_desc/newest/popular/rating
                             → {results(+in_stock, highlight, score), total, page, page_size, took_ms, query}
GET  /search/suggestions/?q= (min 2 chars) → [strings]
GET  /cart/                  → {id, store, items[{id, variant{}, quantity, line_total, tenant_id, seller_name}], total_items, subtotal}
POST /cart/items/            {variant_id, quantity} (upsert-increment; NO stock check — see §4.3)
DELETE /cart/items/:id/      (qty rewrite = DELETE + re-POST; PATCH 405s)
POST /cart/merge/ {session_key} · DELETE /cart/clear/
POST /orders/                {cart_id, store?, delivery_address, delivery_instructions}
                             store omitted → {orders:[...]} (one per seller)
GET  /orders/ → list(+item_count) · GET /orders/:id/ → detail+items[]+status_history[]
POST /orders/:id/cancel/ {reason} (PENDING/CONFIRMED only) · GET /orders/:id/invoice/
GET  /payments/methods/ · POST /payments/ {order, gateway∈RAZORPAY/STRIPE/PHONEPE/COD, amount, payment_method_id?}
GET  /payments/refunds/ · POST /payments/:id/refund/ {amount, reason}
GET  /pincode/:code/         → {valid, pincode, city, state, eta_days, delivery_fee, free_delivery_over, source}
                             (fee/free-over are STRINGS; 404 = not serviceable)
POST /admin/coupons/validate/ {code, order_value} → {valid, discount, …} | 400 {valid:false, message}
GET  /banners/              paginated active (CAROUSEL|POPUP|BANNER)
```

**Storefront (public) / Engagement / Admin**
```
GET /storefront/platform/    platform (EASYGET) render {store, theme, sections[], ticker}
GET /storefront/:store_slug/ {store, theme, sections[], ticker}
    section types: HERO·BANNER·CATEGORY_GRID·PRODUCT_ROW·IMAGE_GALLERY·RICH_TEXT
GET /notifications/ · POST .../:id/mark_read/ · POST .../mark_all_read/
GET /notifications/unread_count/ · GET .../preferences/ (+/all_preferences/ +/bulk_update/)
POST /realtime/devices/ {platform:IOS|ANDROID|WEB, device_token, user_agent}
POST /analytics/events/ {event_type, session_id, properties} · POST .../events/batch/
POST /pwa/updates/check/ {platform, current_version} → {update_available, …}
ws  /ws/orders/ · /ws/notifications/ (Channels)
GET /admin/dashboard/ (NOT /stats/) · GET/PATCH /admin/orders/… · GET/POST /admin/products/…
GET /admin/inventory/… · GET/PATCH/DELETE /admin/reviews/… · GET/PUT /admin/storefront/:store_id/
GET/POST /admin/coupons/ · GET/POST /admin/banners/
GET /api/v1/health/ → {"status":"ok"} · /api/docs/ (Swagger) · /api/schema/
```

### 1.3 Data model sketch (reference — DO NOT modify)
`User{id,email,phone,name,role,is_verified}` · `Tenant{id,name,owner}` ·
`Store{id,tenant,slug,name,theme,address,is_active,is_platform}` ·
`Category{id,parent,name,slug,image}` · `Product{id,tenant→null=platform,
category,name,slug,description,brand,mrp,is_active,is_featured,tags}` ·
`ProductVariant{id,product,name,sku,attributes,price,is_active}` ·
`ProductImage{id,product,image,caption,is_primary,sort_order + display
knobs}` · `StockItem{tenant(denormalized),store,variant,quantity,
low_stock_threshold}` (unique store×variant) · `InventoryTransaction{}`
· `Cart/CartItem` · `Order/OrderItem/OrderEvent` ·
`Payment/Coupon/Banner/StorefrontSection/StorefrontItem/
ProductReview/WishlistItem`. Rating aggregates are **annotated
subqueries, never stored** (can't drift).

---

## 2. HOW — stack, setup, internals

### 2.1 Stack (`requirements.txt`, Python 3.11)
Django 5.2 · DRF 3.18 · SimpleJWT 5.5 · cors-headers · django-environ ·
celery + redis (+django-celery-beat) · channels + channels-redis ·
drf-spectacular (docs) · django-ratelimit · python-json-logger ·
django-redis · requests · Pillow (image uploads → WebP ≤800px) ·
psycopg · gunicorn + whitenoise (prod) · django-storages[s3] ·
google-auth. Dev DB: **Supabase Postgres** (from root `.env`); tests:
**SQLite** (hermetic, CI-identical).

### 2.2 Run from scratch (repo root, 1 terminal for API)
```powershell
python -m venv .venv; .\.venv\Scripts\pip install -r requirements.txt
copy .env.example .env            # then fill secrets; Django reads it ONLY at startup
.\.venv\Scripts\python.exe backend\manage.py runserver 0.0.0.0:8000 --noreload
# health: http://localhost:8000/api/v1/health/   docs: http://localhost:8000/api/docs/
```
Port busy? `Get-NetTCPConnection -LocalPort 8000 -State Listen` →
`Stop-Process -Id <pid> -Force`. `.env` edits need a restart.

### 2.3 Env vars (root `.env`; see `.env.example`)
`DJANGO_SECRET_KEY` · `DJANGO_DEBUG` · `DJANGO_ALLOWED_HOSTS` ·
`DJANGO_CORS_ALLOWED_ORIGINS` · `DATABASE_URL` (Supabase Postgres;
override with `sqlite:///db.sqlite3` for hermetic local work) ·
`REDIS_URL`/`CELERY_BROKER_URL`/`CELERY_RESULT_BACKEND` ·
`DJANGO_EMAIL_BACKEND` (+FROM) · `GOOGLE_OAUTH_CLIENT_IDS` (empty ⇒
`/auth/google/` answers 503, everything else works).

### 2.4 Folder map
```
backend/manage.py        entry (ALWAYS run from repo root, NOT backend/)
backend/config/          settings/ (per-env), urls.py (mount table), asgi/wsgi/celery
backend/<app>/           models.py views.py serializers.py urls.py tests.py admin.py
backend/<app>/migrations/  schema (frozen — new model fields need migrations + review)
media/ (repo root)       uploaded images (ImageField upload_to=products/)
```

### 2.5 THE visibility + `in_stock` contract (2026-10-12 — memorize)
`ProductViewSet.get_queryset` (`products/views.py`):
- **staff**: everything (dashboard truth).
- **tenant members**: own catalog (even inactive) + active platform
  products + stocked active products.
- **everyone else** (customers, guests): `is_active=True` AND
  (**platform** `tenant IS NULL` **OR** stocked by an **active** store).
- Every list/retrieve/search row carries **`in_stock`** (qty > 0 in an
  active store), injected in `views.py` via `stocked_product_ids()` —
  **one extra query per page, zero serializer/model changes** (frozen
  law). `in_stock:false` ⇒ frontends show Out-of-Stock + disabled
  buying; merchant unstocked items stay invisible (404) by design.
- Guards (all verified live + covered by tests): foreign unstocked
  merchant item → 404 for customers AND other merchants, 200 for owner;
  inactive → 404/invisible everywhere public; search↔list↔detail share
  the contract (the Oct 2026 mismatch is fixed — see §3.2).

### 2.6 Conventions you must follow
- Pagination: `page_size` default 20, **max 20 everywhere**; explicit
  stable ordering (`-updated_at,-id` etc. — required for correct pages).
- Errors: uniform envelope `{error:{code,message,details}}`; detail-404
  message is literally "No Product matches the given query." (frontends
  render it — don't reword lightly).
- Slugs auto-generate (`slugify(name)`, suffixed on collision); variant
  SKUs auto-generate (`UPPER(name[:8])-N`); product `base_price` =
  min active-variant price; `discount_percent` guards zero/NULL MRP
  (no divide-by-zero on Postgres).
- Uploads compress to WebP ≤800px on save; first image becomes primary;
  `is_primary=true` demotes rest; deleting primary promotes next.
- Reviews: approved-only reads, one/user/product (409), verified badge
  derived from DELIVERED orders server-side, masked names ("Rahul B.").
- Coupons on PDP: active window + applies_to (ALL/CATEGORY/PRODUCT),
  newest 5, display-only (`validate` is the applying path).
- Storefront renders cached 1h (Redis, cache-aside), invalidated by
  post_save signals; lookup platform by `is_platform` flag, never slug.
- Wishlist POST/DELETE idempotent; cart writes authenticated;
  `PATCH /cart/items/` 405s live — clients DELETE + re-POST.
- Throttles: anon search/suggestions rate-limited (anti-scrape).
- N+1 discipline: `select_related`/`prefetch_related`/annotations on
  every list (remote Supabase punishes lazy queries — the 20/page cap
  exists because unpaginated catalogs took ~3.5s).

### 2.7 Tests (293 green, 1 skipped — 2026-10-12)
```powershell
# EXACT CI form. cwd MUST be backend/ (root discovers 0), hermetic SQLite:
cd backend
$env:DATABASE_URL='sqlite:///db.sqlite3'; $env:DJANGO_DEBUG='true'
python manage.py test -v 1          # full suite (~3 min)
python manage.py test products tenants search -v 1   # catalog slice (~1 min)
```
Key regression tests (do not weaken): product sort-hides-ghost,
guest-browse-public/guest-writes-rejected, review one-per-user +
unapproved-hidden + verified-purchase, wishlist idempotency,
rating-sort nulls-last, image primary rotation + tenant isolation +
platform-requires-staff, search compound-word contract (3 unstocked
platform fixtures!), tenant product binding + foreign-hidden +
own-visible + customer-only-stocked, inventory tenant binding +
cross-tenant 400 + adjust locking/audit. `manage.py check` also runs
in CI.

---

## 3. WHY — decisions and incident history

### 3.1 Why one app per domain + staff router ordering
`config/urls.py` mounts ~20 apps; `admin_panel` is included **twice**
(before `users.admin_urls` — Django doesn't fall through on miss, order
is load-bearing). Keep mounts alphabetical-ish but never reorder the
admin pair without reading the comment.

### 3.2 The October 2026 404 saga (why `in_stock` exists)
Search (`is_active` only) advertised 14 unstocked platform products
(e.g. `jasmine-gold-hair-oil`: 3 variants, 0 stock rows) that
`ProductViewSet` (stock-required) 404'd — dead links from search,
rails, and storefront rows; admin showed them "Live". Chosen fix
(§2.5): platform-active ⇒ public + `in_stock` flag; merchant privacy
preserved; views-only injection to honor the models/serializers freeze.
Rejected alternatives: auto-creating zero-qty rows (lies to buyers,
oversell risk), full visibility for merchants (leaks private catalogs,
breaks 3 tests), frontend guessing (no data — worse).

### 3.3 Why ratings are subqueries, not columns
Join-row duplication from stock/store joins skews naive AVG; the
`with_rating_stats()` subquery is immune, and non-stored aggregates
can't drift. Copy the pattern for any new per-product stat.

### 3.4 Why search has two engines
Postgres FTS (`websearch`, OR-tokens + rank) + ILIKE safety net across
name/brand/tags/description/category/index-text (catches "black board"→
"Blackboard" and stale indexes); SQLite gets ILIKE-only with identical
matching contract. Suggestions mix popular-prefix + name/tag matches.

### 3.5 Why cart ignores stock (for now) and checkout splits
Marketplace carts mix sellers freely; the per-seller split happens at
order creation (`store` omitted ⇒ N orders). Stock validation at
add-time was never built — UI gates exist, server gate is a known gap
(§4.3). Don't "fix" by blocking in the view without a contract change.

### 3.6 Why Celery tasks run inline locally
No broker on dev machines: `enqueue()` falls back to synchronous
execution (search logging, popular bumps) with a warning — analytics
still recorded. Prod uses Redis.

### 3.7 Why JWT doesn't rotate
`ROTATE_REFRESH_TOKENS=False`, `BLACKLIST_AFTER_ROTATION=True`; logout
blacklists the presented refresh. Frontends refresh-then-retry, then
purge-to-guest (see customer README §2.4).

---

## 4. REMAINING — gaps and TODOs (2026-10-12)

1. **Server-side stock gate**: `POST /cart/items/` and order creation
   accept out-of-stock variants (UI-only blocking). Needs contract +
   tests before enabling.
2. **`mens-footwear`**: active platform product, zero variants — add a
   variant or deactivate; permanent Out-of-Stock card until then.
3. **Suggestions/stock**: suggestions lack `in_stock` (names only —
   fine today; revisit if counts/badges appear).
4. **Wishlist visibility**: wishlist endpoints bypass catalog filters
   (saved merchant-unstocked items stay reachable) — decide if intended.
5. **Pincode fee types**: `delivery_fee`/`free_delivery_over` are
   strings; TypedDict/serializer cleanup would help clients.
6. **`min_price`/`max_price` on search** filter a non-existent
   `base_price` ORM field (latent 500 on filtered search — verify and
   fix to `min_variant_price`).
7. **Google auth in tests**: `/auth/google/` 503 path covered only by
   error log assertions; add explicit no-IDs test.
8. **Storefront guard**: `PRODUCT_ROW` accepts unstocked merchant
   products (customer 404 on click) — validate at item creation.
9. **Docs drift**: this README + `CONTEXT.md` must be updated together
   whenever contracts/folders change (CONTEXT is frozen otherwise).

---

## 5. Junior-dev cheat sheet

| I want to… | Do this |
|---|---|
| Add an endpoint | New view + `urls.py` mount + contract entry in `CONTEXT.md` + tests. ASK FIRST (rule). Never alter models/serializers to do it |
| Expose a new product field | Propose it — serializers are frozen; the `in_stock` views-injection is the approved pattern for additive flags |
| Debug invisible product | Check `is_active`, variant count/activity, `StockItem` rows (store active? qty?), `tenant` (platform vs merchant) — §2.5 decides |
| Debug search≠detail | Both must apply §2.5; check FTS index freshness + ILIKE fallback parity |
| Run things | `runserver` (API), `manage.py check`, `manage.py test` (backend cwd + SQLite env), `/api/docs/` to click-test |
| Deploy | Push to watched branch → Render rebuilds API (migrations run per Render config — confirm before schema changes) |
| Never commit | `.env`, `db.sqlite3`, `media/` uploads, token/log dumps, scratch scripts |
