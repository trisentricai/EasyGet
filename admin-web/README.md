# EASYGET — admin-web README

> The merchant/staff dashboard: everything that makes the shop run.
> Status as of **2026-10-12**. Junior dev path: read §1–§2 to operate it,
> §3 to understand why it behaves the way it does, §4 before picking up
> any TODO.
> Companions: `customer-web/README.md`, `backend/README.md`, repo-root
> `GETTING_STARTED.md`, `CONTEXT.md` (contracts), `DESIGN.md` (tokens).

---

## 0. One-paragraph summary

`admin-web/` is a React + TypeScript SPA (Vite, hash-routed) for staff and
merchants: sales overview, order fulfilment, catalog (categories/products/
images/variants), review moderation, inventory adjustments with audit,
users, and a visual storefront designer. It consumes the same Django API
as the shop (`/api/v1/…`, staff-scoped endpoints under `/api/v1/admin/`),
sees the *unfiltered* catalog (staff bypass product visibility), and
deploys to Cloudflare Pages project **`easyget-admin`**.

---

## 1. WHAT — what this app is

### 1.1 Who uses it
- **ADMIN (staff)**: everything, incl. Users and Storefront designer.
- **Merchant (tenant member)**: dashboard, orders, categories, products,
  reviews, inventory — scoped to their tenant; Users and Storefront
  designer fall back to Dashboard for non-admins.
Login: `admin-web` login page → JWT in local storage; dev admin is
`admin@easyget.local` / `EasyGet!2026`.

### 1.2 Every screen (`src/App.tsx` NAV + route switch)

| Route | File | What you do there |
|---|---|---|
| `#/dashboard` | `pages/DashboardPage.tsx` | Users/orders/revenue/products stats, low-stock count |
| `#/orders` | `pages/OrdersPage.tsx` | Fulfilment queue, order detail, `PATCH …/status/` transitions |
| `#/categories` | `pages/CategoriesPage.tsx` | Category CRUD (name/slug/icon/sort/active) |
| `#/products` | `pages/ProductsPage.tsx` | Product CRUD + variants + image gallery + display editor |
| `#/reviews` | `pages/ReviewsPage.tsx` | Approve/hide (PATCH) / delete reviews, filter by product/approval |
| `#/inventory` | `pages/InventoryPage.tsx` | Stock table, Adjust-stock modal (+audit row), status badges |
| `#/users` | `pages/UsersPage.tsx` | User list (ADMIN only) |
| `#/storefront` | `pages/StorefrontPage.tsx` | Designer: sections/items/theme for the platform store (ADMIN only) |

Unknown routes → Dashboard. Sidebar collapses; topbar shows live clock,
role badge, theme toggle (see `ThemeContext`, `shell-collapse.css`).

### 1.3 Screen-by-screen essentials

**Products (`ProductsPage.tsx`)** — the most complex screen; learn it well.
- Toolbar: text search (client-side over loaded list) + category filter
  + "+ New product" (disabled until categories load).
- Table columns: Product (name/slug), Category, MRP, Selling price,
  Flags, actions (Edit/Delete).
- Flags: `Hidden` (`is_active=false`), **`No stock`** (active but
  `in_stock === false` — added 2026-10-12; hover explains customers see
  Out of Stock), `Featured`, `Live`.
- Create/edit modal (`Draft` + `VariantRow[]`): name, category, MRP,
  brand, description, Active/Featured toggles; variant rows (name/price/
  Live) with quick-add presets (`250g, 500g, 1kg, 150ml, 300ml, 500ml,
  1L, Pack of 2`); empty-price rows are skipped, never sent; edits
  round-trip variants **by id** (update-in-place; unknown id → 400).
- Images: on create, files are *staged* then uploaded after the product
  saves; on edit, uploads are instant (compressed to WebP ≤800px
  server-side); ★ sets primary (demotes rest); ✎ opens
  `ImageDisplayEditor` (focal point/zoom/hover-effect/caption);
  deleting the primary promotes the next by sort order.
- Delete uses `ConfirmDialog` ("removes the product everywhere").

**Inventory (`InventoryPage.tsx`)** — lists `StockItem`s (variant SKU,
store, price, qty vs threshold, Healthy/Low/Out badges). `AdjustModal`
applies signed deltas with quick buttons (−10/−1/+1/+10/+50), reason
(RESTOCK/SALE/ADJUSTMENT/DAMAGE/RETURN), note; result < 0 is blocked;
every adjustment writes an `InventoryTransaction` audit row
(`performed_by` = you).

**Storefront designer (`StorefrontPage.tsx`, ADMIN)** — edits the
**platform (EASYGET)** store's sections: HERO/BANNER/CATEGORY_GRID/
PRODUCT_ROW/IMAGE_GALLERY/RICH_TEXT with positions (drag-and-drop calls
the reorder endpoints), item pickers (product/category/custom + link),
and theme (colors, font, button style, hero image). Public home renders
whatever is active here — preview in the shop before announcing changes.
Edits invalidate the 1h storefront cache via signals automatically.

**Orders** — queue + detail; status advance via
`PATCH /admin/orders/:id/status/`; cancel only in PENDING/CONFIRMED.

**Reviews** — moderation queue; hiding sets `is_approved=false`
(removes from aggregates and public list immediately).

---

## 2. HOW — stack, setup, internals

### 2.1 Stack (exactly `package.json`)
`react`, `react-dom`, `@vitejs/plugin-react`, `vite` (`latest`);
`@tanstack/react-query` ^5 for server state; TypeScript strict.
No UI kit, no router lib, no state lib — contexts + React Query +
`services/api.ts`, same philosophy as customer-web. Build =
`tsc --noEmit && vite build` (red `tsc` fails build and CI).

### 2.2 Run from scratch
```powershell
cd admin-web
npm install        # first time only
npm run dev        # → http://localhost:5174/
npm run build      # typecheck + build → dist/
```
Backend first (repo root):
`.\.venv\Scripts\python.exe backend\manage.py runserver 0.0.0.0:8000 --noreload`.
Same `VITE_API_URL` rule as the shop (deploys bake
`https://easyget-api.onrender.com`).

### 2.3 Folder map (`src/`)
```
App.tsx               Auth gate → Shell (sidebar/topbar) → route switch
main.tsx              React mount
hooks/useHashRoute.ts Hash router (string routes: "dashboard", "products"…)
services/api.ts       Backend client: api(), errText, product/inventory/
                      CRUD, image endpoints, display helpers, types
context/              AuthContext (user/ready/signOut), ThemeContext
                      (light/dark), ToastContext (push notifications)
components/           ui.tsx (Card, Modal, ConfirmDialog, Spinner,
                      EmptyState, badges), ImageDisplayEditor.tsx
pages/                one file per screen (§1.2)
styles.css            admin theme + tables + badges + gallery tiles
shell-collapse.css    collapsed-sidebar rules
```

### 2.4 The API client (`services/api.ts`) — key points
- Same JWT pattern as the shop (own storage key/handler — the two apps
  never share tokens).
- Products ride the **staff view** of `/products/`: no visibility
  filter, so you see drafts, inactive, and unstocked items the shop
  hides. `in_stock` is present on rows — **read the Flags column, not
  your gut**: `Live` no longer means "customers can buy it".
- `listAllProducts()` paginates the whole catalog for the table filter.
- `getProduct(slug)` detail feeds the edit modal (images + variants).
- Images: `uploadProductImage(slug, file)` (multipart, first becomes
  primary), `setPrimaryProductImage(id)`, `updateProductImage(id,
  {caption, align_x, align_y, zoom, effect, transition_ms})`,
  `deleteProductImage(id)`; `mediaSrc()` resolves URLs;
  `toImageDisplay()`/`DEFAULT_IMAGE_DISPLAY` normalize knobs.
- Inventory: `GET /inventory/` (tenant-scoped server-side),
  `POST /inventory/<id>/adjust/ {change, reason, note}`.
- To add a screen: new `pages/X.tsx` + `NAV` entry + route case in
  `App.tsx` + role check if ADMIN-only + client fns in `services/api.ts`.
  Copy `InventoryPage` for tables, `ProductsPage` for modals.

### 2.5 The golden rule of merchandising (memorize this)
A product is **buyable in the shop** iff ALL hold:
1. `is_active = true`, 2. it has ≥1 **active variant** with a price,
3. `in_stock = true` (some variant has qty > 0 in an **active** store).
Platform products (`tenant = null`) with 1+2 but not 3 show as
**Out of Stock** (visible, not buyable). Merchant products missing 3
are **invisible** to customers entirely. Creating a product in this
dashboard satisfies only #1 (+#2 if you add variants) — **you must then
add stock in Inventory**, or shoppers will never see/buy it. This exact
gap caused the Oct 2026 "Product not found" incident (14 products).

### 2.6 Tokens & states (LAW)
Same `DESIGN.md` §1 regime as the shop: token vars only, light + dark,
loading/empty/error on every list (`Spinner`/`EmptyState`). One
component or screen per AI session — never batch.

### 2.7 Deploy
Workflow `deploy-cloudflare.yml`: push to `fix/flutter-web-and-ordering`
or `main` touching `admin-web/**` → `npm ci && npm run build` → `dist/`
to Cloudflare Pages **`easyget-admin`**. CI builds on every push/PR.

---

## 3. WHY — decisions and history

### 3.1 Why staff see everything
Merchants must manage drafts, inactive items, and zero-stock products.
The backend skips visibility filtering for `is_staff`; tenant members
additionally see their own catalog incl. inactive. The dashboard is the
*only* place the full truth is visible — which is why its badges must
tell the truth (see §3.2).

### 3.2 Why the "No stock" badge exists (Oct 2026 incident)
The Flags column used to show green `Live` for any active product. 14
active products had no stock rows, so the shop 404'd them while admin
insisted they were live — maximum confusion. Now active + `in_stock ===
false` shows amber `No stock` (with explanatory tooltip) and `Live`
requires stock. When merchandising complaints arrive, check Flags first.

### 3.3 Why variants round-trip by id
Early edits duplicated variants on every save. Rows carry `id: number |
null`; `null` = create, present = update in place, missing rows are left
alone (never auto-deleted — explicit ✕ removes the row client-side
before save; the backend 400s unknown ids to catch cross-product bugs).

### 3.4 Why images are instant on edit but staged on create
A new product has no slug yet, and image endpoints are slug-addressed —
so create must save first, then upload staged files (counts reported in
the toast). On edit the product exists, so uploads apply immediately and
the gallery is the source of truth (with primary-promotion fallback).

### 3.5 Why stock adjusts are deltas + reasons, never absolute sets
Concurrent restocks/sales race; `select_for_update` + signed `change`
plus an audit row (`reason`, `note`, `performed_by`) keeps quantity
correct and every movement attributable. Quantity can never go below
zero (400). This is an audit trail — do not add a "set quantity"
shortcut.

### 3.6 Why Users/Storefront are ADMIN-only in the UI
Routes render Dashboard as fallback for non-admins, but the real gate is
backend (`IsAdminOnly`) — UI hiding is convenience, never security.
Same for all write buttons: server decides.

---

## 4. REMAINING — gaps and TODOs (2026-10-12)

1. **Zero-variant products**: nothing stops saving a product with all
   variant rows empty (e.g. `mens-footwear` — live, price "—",
   permanently Out of Stock). Add a save-time warning or block.
2. **No "missing stock" view**: Inventory lists only existing rows; a
   product with no rows at all is findable only via the `No stock`
   badge. Consider an Inventory "Unstocked products" tab linking to
   quick-create stock rows.
3. **Storefront dead-link guard**: `PRODUCT_ROW` can feature an
   unstocked *merchant* product whose page 404s for shoppers. Warn at
   design time (or filter to buyable/platform items).
4. **No bulk tools**: no CSV import, bulk price edit, or bulk
   activate/deactivate — painful past ~200 SKUs (catalog is at 216).
5. **No image alt-text field**: `caption` doubles as gallery caption;
   accessibility text is the product name fallback.
6. **Audit surface**: `AdminAction` log exists backend-side but has no
   dashboard screen; stock has per-item history via transactions only.
7. **Order refunds/returns flow** lives backend-side
   (`/payments/:id/refund/`); dashboard has no refund button yet.
8. **Coupon/banner CRUD** screens are thin — validate coverage against
   `admin_panel` endpoints before campaigns.
9. **Collapse CSS** (`shell-collapse.css`) is a separate file — merge
   into `styles.css` on next sidebar work to stop drift.

---

## 5. Junior-dev cheat sheet

| I want to… | Do this |
|---|---|
| Make a new product buyable | Products → New → variants with prices → Save → Inventory → create/adjust stock qty > 0 in an active store → verify `Live` badge (not `No stock`) |
| Debug "customers can't see it" | Check Flags: `Hidden` = inactive; `No stock` = add stock; neither + still invisible = merchant product needing active-store stock, or wrong store |
| Add a dashboard screen | `pages/`, `NAV` + route case + role rule, API fns in `services/api.ts` |
| Moderate a review | Reviews → filter → approve/hide/delete; hides apply instantly to shop aggregates |
| Feature products on home | Storefront designer → platform store → PRODUCT_ROW → add items → check shop home (cache clears itself) |
| Verify before push | `npm run build` (tsc + vite); backend tests per backend README |
