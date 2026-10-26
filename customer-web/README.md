# EASYGET — customer-web README

> The customer storefront: the shop every shopper sees.
> Status as of **2026-10-12**. If you are a junior developer, read top to
> bottom once — this file takes you from zero to productive.
> Companion files: `admin-web/README.md` (merchant dashboard),
> `backend/README.md` (the API), repo-root `GETTING_STARTED.md` (run
> everything), `CONTEXT.md` (frozen API contracts), `DESIGN.md` (visual
> tokens — law, not suggestion).

---

## 0. One-paragraph summary

`customer-web/` is a React + TypeScript single-page app (Vite) that renders
the EASYGET marketplace: home rails, category browse, search, product pages,
wishlist, cart, checkout, orders, and account. It talks to exactly one thing —
the Django API at `VITE_API_URL` (`/api/v1/…`) — and it uses **hash routing**
(`#/home`, `#/product/<slug>`), so there is no server-side routing to
configure anywhere it is hosted. Live at
`https://easyget-customer.pages.dev/#/home`.

---

## 1. WHAT — what this app is

### 1.1 Who uses it
Guests (browse, search, view products) and signed-in customers (cart,
checkout, orders, wishlist, addresses, reviews). Guests who try a personal
page are bounced to `#/login` before anything renders.

### 1.2 Every route (all hash routes, see `src/App.tsx` → `Shell`)

| Hash | Page file | What it does |
|---|---|---|
| `#/home` | `pages/HomePage.tsx` | Storefront: banners, designed sections, discovery rails, full catalog tail |
| `#/browse?category=<slug>` | `pages/BrowsePage.tsx` | Filterable catalog (category, brand, discount, price, featured, 5 sorts), infinite scroll |
| `#/product/<slug>` | `pages/ProductPage.tsx` | Gallery, price, offers, variants, pincode, qty, buy box, similar, reviews |
| `#/search?q=<text>` | `pages/SearchPage.tsx` | Backend search with offline client-side fallback |
| `#/categories` | `pages/CategoriesPage.tsx` | All categories |
| `#/cart` | `pages/CartPage.tsx` | Signed-in cart, seller grouping |
| `#/checkout` | `pages/CheckoutPage.tsx` | Address + split checkout (one order per seller) |
| `#/orders` / `#/order/<id>` | `pages/OrdersPage.tsx` | Order list + detail with status timeline |
| `#/account` | `pages/AccountPage.tsx` | Profile + address book |
| `#/wishlist` | `pages/WishlistPage.tsx` | Saved products (server list, device cache) |
| `#/login` | `pages/AuthPage.tsx` | Login, register, email OTP (legacy), Google sign-in |

Unknown hashes fall through to `HomePage` (never a blank screen).

### 1.3 Home page order (top → bottom, `HomePage.tsx`)
1. `BannerCarousel` — HERO/BANNER sections from the platform storefront.
2. Designed sections in admin order (`CATEGORY_GRID`, `PRODUCT_ROW`, `IMAGE_GALLERY`, `RICH_TEXT`).
3. `DealsRail` — "Deals of the Day" (top discounts, midnight countdown).
4. `RecommendedRail` — "More in \<TopCategory\>" from your recent views.
5. `RecentlyViewedRail` — device-local history.
6. `AllProductsGrid` (added 2026-10-12) — **every visible product**,
   paginated 20/page with infinite scroll + "Load more (N left)", so the
   page scrolls until the catalog ends.

### 1.4 Key shopper features and where they live
- Product cards (`components/ui.tsx` → `ProductCard`): image w/ display
  effects, deal/featured/**Out of stock** chips, wishlist heart, rating
  pill, price block, free-delivery line.
- Product page: variant picker (active variants only), image gallery w/
  focal/zoom/hover effects, "Available offers" coupon chips, pincode ETA
  checker, qty stepper, Add to cart / Buy now (disabled when out of
  stock), Similar products rail, Ratings & Reviews (post form when signed
  in, 409 message on duplicate).
- Search: debounced suggestions (`/search/suggestions/`), full search
  POST with graceful fallback to client-side filtering of the whole
  catalog if `/search/` is down (`searchWithFallback`).
- Cart: signed-in only (guests are asked to sign in); guest→user merge on
  login; qty rewrite = DELETE + re-POST (PATCH 405s on the live API).
- Checkout: one order per seller tenant ("N orders placed!"), address
  book, delivery instructions.
- Wishlist: server-backed heart (optimistic, rolls back on failure);
  signed-out hearts live in device cache only.
- Theming: merchant theme from the storefront API becomes CSS variables
  at runtime; light + dark via `data-theme`; pre-paint without flash
  (see §3.6).

---

## 2. HOW — stack, setup, and internals

### 2.1 Stack (exactly what `package.json` installs)
- `react`, `react-dom`, `@vitejs/plugin-react`, `vite` (all `latest`).
- `@tanstack/react-query` ^5 — all server state. No Redux/Zustand: local
  UI state is `useState`, cross-screen server data is React Query, device
  memory is `localStorage` helpers (`utils/history.ts`).
- `@tailwindcss/vite` + `tailwindcss` ^4 (dev) — plus hand-written
  `styles.css` / `showcase.css` where the design system lives.
- `@fontsource/geist-mono` — tabular numerals (prices, ETAs).
- `@playwright/test` (dev) — `screenshots/` holds capture output.
- TypeScript strict; build = `tsc --noEmit && vite build` (type errors
  fail the build AND CI — never commit with red `tsc`).

> `CONTEXT.md` describes a *target* stack (Radix, motion, Zustand…).
> Reality today: none of those are installed. Do not import them.

### 2.2 Run it from scratch
```powershell
cd customer-web
npm install        # first time only
npm run dev        # → http://localhost:3000/  (NOT 127.0.0.1, NOT 5173)
npm run build      # typecheck + production build → dist/
npm run preview    # serve dist/ locally
```
Backend must run first (repo root):
`.\.venv\Scripts\python.exe backend\manage.py runserver 0.0.0.0:8000 --noreload`.
Vite proxies `/api` → `http://localhost:8000`, but `services/api.ts`
prefers `VITE_API_URL` when set (deploys set
`VITE_API_URL=https://easyget-api.onrender.com`).

### 2.3 Folder map (`src/`)
```
App.tsx                 Shell: providers, header, category strip, ticker,
                        route switch, footer, bottom nav, theme toggle
main.tsx                React mount + index.html theme pre-paint read
flags.ts                NEXT_UI feature flag (query param > localStorage > env)
hooks/useHashRoute.ts   Hash router: parse(), navigate(), href(), useHashRoute()
services/api.ts         THE backend client (auth, storefront, catalog, cart…)
context/                AuthContext, CartContext, StorefrontContext, ToastContext
components/             ui.tsx (design system), marketplace.tsx (rails),
                        icons.tsx, ticker.tsx, category-tiles.tsx
pages/                  one file per route (see §1.2)
utils/                  history.ts (recent views/searches/wishlist cache),
                        imageFx.ts (display-effect → class/style mapping)
theme/                  theme application helpers
styles.css              app styles, tokens, chips, grids, buybox, rails
showcase.css            hero/carousel/marketplace presentational styles
preview.tsx + preview.html   NEXT_UI sandbox (flag-gated, live data)
privacy.html            static privacy page (build input)
```

### 2.4 The API client (`services/api.ts`) — read this file first
- `ORIGIN`/`BASE`: `VITE_API_URL` (trimmed) or `http://127.0.0.1:8000`,
  plus `/api/v1`. `img(path)` resolves relative media to absolute URLs.
- Auth: tokens in `localStorage["eg-cust-tokens"]` (`{access, refresh}`).
  Every request tries refresh on 401; if still 401, tokens are purged,
  the global 401 handler signs out, and the request retries **anonymously**
  so public browsing keeps working with a stale token stored.
- Errors: `ApiError(status, payload)`; `errText()` renders DRF payloads
  (including nested JWT `messages` and legacy `ErrorDetail(...)` reprs)
  into human strings; `fieldErrors()` flattens `{field: [msgs]}`.
- Catalog: `listProductsPaged(params)` (page_size max 20 server-side),
  `listAllProducts()` (follows `next`, capped 10×100 for fallbacks),
  `getProduct(slug)` → `ProductDetail`.
- **Stock contract (2026-10-12): every product carries
  `in_stock?: boolean | null`** (true = qty > 0 in an active store).
  `in_stock === false` ⇒ render Out-of-Stock UI, never a 404 page.
- Search: `searchWithFallback({q, sort})` — tries `POST /search/`, else
  tokenized client-side match over the full catalog (same "black board"→
  "Blackboard" contract as the backend).
- Cart: `addToCart`, `updateCartItem` (unused live — PATCH 405s; Browse
  uses DELETE + re-POST), `removeCartItem`, `clearCart`, `getCart`.
- `asArray()` normalizes DRF's bare-array-vs-`{results}` shapes. Use it
  for every list endpoint.
- React Query conventions: `staleTime` 30s default (2 min rails, 5 min
  categories); shared `["categories"]` key fetched once per visit;
  `useInfiniteQuery` + 1px sentinel + 200px rootMargin for infinite
  scroll (copy `BrowsePage`/`AllProductsGrid` when adding a new feed).

### 2.5 Routing & guards
- `useHashRoute()` parses `#/name/params?query`. `href("browse?...")`
  builds links; `navigate(path, {replace})` moves.
- Personal routes (`cart, checkout, orders, order, account, wishlist`)
  render `<Spinner/>` until auth resolves, then bounce guests to login.
- `key={...}` on route components forces remount on slug/query change
  (e.g. switching products re-runs gallery/variant state).

### 2.6 Theme & design tokens (LAW — `DESIGN.md` §1)
- Zero hardcoded hex/px in new code: use `var(--primary)`,
  `var(--danger)`, `var(--surface)`, `var(--border)`, `var(--ink)`,
  `var(--muted)`, `var(--ok)`, `var(--radius)`, text scale vars, 8pt
  spacing. Both light and dark (`[data-theme="dark"]`) must look right.
- Merchant theme: `getPlatformStorefront()` caches theme into
  `localStorage["eg-store-theme"]`; `index.html` applies it **before
  first paint** (no default-color flash); `App.tsx` then sets live CSS
  vars (`--primary/--secondary/--bg/--font/--radius-btn`).
- Image display knobs (`align_x/align_y/zoom/effect/transition_ms`) flow
  through `fxClass()`/`fxStyle()` — never style images ad hoc.
- Chips: `.chip-deal` (≥50% off), `.chip-featured`, `.chip-out`
  (Out of stock, token-colored, no hardcoded hex). Card delivery line
  turns danger-colored "Out of stock" when `in_stock === false`.
- Every list needs loading + empty + error states (`CardSkeletonGrid`,
  `EmptyState`). This is a hard project rule, not polish.

### 2.7 localStorage keys (all `eg-*`, all fail-safe)
`eg-cust-tokens`, `eg-store-theme`, `eg-theme`, `eg-next-ui`,
`eg-recent-views` (12), `eg-recent-searches` (8), `eg-wishlist`.
`purgeLocalUserData()` wipes them on logout/global-401.

### 2.8 Build inputs & deploy
- `vite.config.ts`: port **3000**, `/api` proxy, multi-page build
  (`index.html`, `preview.html`, `privacy.html`).
- Deploy: GitHub Actions `deploy-cloudflare.yml` — on push to
  `fix/flutter-web-and-ordering` or `main` touching `customer-web/**`,
  builds (`npm ci && npm run build`) and ships `dist/` to Cloudflare
  Pages project **`easyget-customer`** with `VITE_API_URL` baked in.
  CI (`ci.yml`) also runs `npm run build` on every push/PR.

---

## 3. WHY — decisions and incident history

### 3.1 Why hash routing
Static hosting (Cloudflare Pages) with zero server config: `#/...`
never hits the network, deep links always boot `index.html`. Cost: URLs
look like `#/product/<slug>` — accepted.

### 3.2 Why the anonymous-retry dance (`api.ts`)
Stale tokens used to hard-break public browsing after expiry. Now a dead
token degrades to guest mode for public endpoints while truly protected
calls still 401. Do not "simplify" this away.

### 3.3 The October 2026 "Product not found" saga (read before touching visibility)
Symptom: searching "jasmine" found `jasmine-gold-hair-oil`, clicking it
showed "Product not found / No Product matches the given query."
Root causes found 2026-10-12:
1. `ProductViewSet` hid every product without a `StockItem` in an active
   store (both list AND detail → 404). Jasmine had 3 active variants but
   **zero stock rows**.
2. `POST /search/` had **no** stock filter — so search advertised
   products the detail endpoint then 404'd. Classic contract mismatch.
3. Admin (staff) bypasses the filter and badges "Live" from `is_active`
   alone — so merchants thought broken products were live.
4. 14 of 216 active products were affected (all platform-owned,
   `tenant = null`); all 202 stocked ones lived in `EasyGet Demo Store`.
Fix shipped: platform products stay public when active and carry
`in_stock` (qty > 0 in an active store); storefront renders Out-of-Stock
with disabled buying instead of 404; **merchant** unstocked catalogs stay
private (see backend README §3.2 for the test matrix). Lesson: list,
search, and detail must share one visibility contract — check all three
whenever you touch any of them.

### 3.4 Why `in_stock` is injected in backend *views* (not serializers)
Frozen rule: never modify backend models/serializers/tests. The flag is
added to list/retrieve/search responses inside `views.py` with one extra
query per page. If you need richer availability (per-variant qty, ETA),
propose a contract change first — do not hack around it in the frontend
by guessing.

### 3.5 Why qty rewrite is DELETE + re-POST
`PATCH /cart/items/:id/` returns 405 on the live backend (probed
2026-10-11). `updateCartItem` exists in `api.ts` but flows must not rely
on it until the backend supports it.

### 3.6 Why index.html reads the theme before paint
First visit flashed default colors before the storefront API answered.
Caching the merchant theme in localStorage and applying it synchronously
in `index.html` killed the flash. Keep that script tag first and tiny.

### 3.7 Why search has a client fallback
`/search/` depends on Postgres FTS + a search index that can lag. The
fallback (`listAllProducts` + tokenized match) keeps search usable
offline/degraded with the same matching contract. Keep both paths'
tokenizers in sync (`_normalize_query` backend ↔ `searchWithFallback`).

### 3.8 Why `NEXT_UI` exists (`flags.ts`, `preview.html`)
Redesigns ship behind `?next_ui=1` (persisted) or `VITE_NEXT_UI=1` until
client approval. One screen per AI session, never batch — project rule.

---

## 4. REMAINING — known gaps and TODOs (2026-10-12)

1. **Flutter parity**: the mobile app still 404-handles unstocked
   products; add the same `in_stock` badge/disable flow there.
2. **`mens-footwear`**: active platform product with **zero variants**
   (no price, nothing to buy). Decide: add a variant + stock, or
   deactivate. It currently renders as a permanent Out-of-Stock card.
3. **Cart has no stock gate**: adding an out-of-stock variant is only
   blocked in UI; `POST /cart/items/` accepts anything. Backend should
   validate stock at add/checkout (needs contract discussion).
4. **Wishlist rail**: `WishlistView` responses now include `in_stock` too
   (same list serializer path) — `WishlistPage` doesn't badge it yet.
5. **Storefront `PRODUCT_ROW` guard**: admins can feature an unstocked
   merchant product; its card opens a page that 404s for customers.
   Filter or warn at design time.
6. **Suggestions endpoint** (`/search/suggestions/`) has no stock
   context — acceptable today (names only), revisit if counts are shown.
7. **Home `ProductRowSection`** builds synthetic products without
   `in_stock` — no badge there yet; wire the flag through section items.
8. **Footer/policy links** are placeholders pointing at `#/home`.
9. **Playwright**: dep installed, no committed specs yet — add PDP +
   out-of-stock + checkout smoke tests.
10. **Old `eg-*` caches**: `RecentView`s stored before 2026-10-12 lack
    `inStock` — treated as in-stock until revisited. Harmless; no
    migration needed.

---

## 5. Junior-dev cheat sheet

| I want to… | Do this |
|---|---|
| Add a page | New file in `pages/`, route case in `App.tsx` `Shell`, guard in `personal` if signed-in-only |
| Fetch data | `useQuery`/`useInfiniteQuery` in the page; shared keys (`["categories"]`, `["products", …]`); `asArray()` every list |
| Call the API | Add a function in `services/api.ts` using `api<T>("/path/")`; never `fetch` directly |
| Show a product | Use `<ProductCard product={p}/>` — badges/prices stay consistent |
| Make a product go live | Backend needs `is_active=true` AND (platform product, or a `StockItem` qty ≥ 0 in an active store); buying needs qty > 0 |
| Debug "Product not found" | Check `GET /products/<slug>/` status: 404 + `in_stock` absent = visibility (merchant unstocked/inactive); 200 + `in_stock:false` = badge path working |
| Style something | Tokens only (`DESIGN.md` §1); test light + dark; loading/empty/error states mandatory |
| Ship a redesign | Behind `isNextUi()` + `preview.html` sandbox until approved |
| Verify before push | `npx tsc --noEmit -p tsconfig.json` (or `npm run build`); backend tests per backend README |

Logins (dev): customer `customer@easyget.app` / `Customer@123`.
URLs (local): shop `http://localhost:3000/`, API `http://localhost:8000/api/docs/`.
