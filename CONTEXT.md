# EASYGET — CONTEXT.md

> Frozen project facts. Paste into every AI prompt alongside `DESIGN.md`.
> Update ONLY when API contracts or folder structure change.

---

## 1. Project Summary

EASYGET = multi-store q-commerce SaaS (marketplace catalog, near-store
delivery, visual storefront builder).

**Surfaces:**
- `customer-web/`  → React 18 + TS + Vite + hash router → localhost:3000
- `admin-web/`     → React 18 + TS + Vite + hash router → localhost:5174
- `customer-app/`  → Flutter 3 + Riverpod + go_router + Dio
- `backend/`       → Django 5 + DRF + Postgres (Supabase) + Channels

---

## 2. API Contracts (reconciled 2026-10-11 against the live backend)

> Verified against `backend/**/urls.py`. Supersedes the original frozen
> draft — paths below are what the deployed API actually serves.
> Removed (do not call): `/auth/otp/*` (phone), `/auth/me/`, `/brands/`,
> `/wishlist/`, `/addresses/`, `/search/trending/`, `/coupons/active/`,
> `/payments/intent|confirm/`, `/orders/:id/track/`, `/products/:slug/rating-distribution/`.

Base: `/api/v1/` — JWT access + refresh (`ROTATE_REFRESH_TOKENS=False`;
`BLACKLIST_AFTER_ROTATION=True`; logout blacklists the presented refresh).

### Auth / Users
```
POST  /auth/login/           { email, password } → { access, refresh, user }
POST  /auth/refresh/         { refresh } → { access }
POST  /auth/logout/          { refresh } → blacklist
POST  /auth/register/        { email, password, first_name, last_name, phone, role }
                             role ∈ [CUSTOMER, MERCHANT, DELIVERY_AGENT]; email auto-verified
POST  /auth/google/          { id_token } → { access, refresh, user }
POST  /auth/verify-otp/      { email, code }   (email OTP, legacy; register auto-verifies)
POST  /auth/resend-otp/      { email }
GET   /users/me/             → User   ·  PATCH { first_name, last_name, phone }
GET   /users/me/addresses/   ·  POST { label, line1, line2, city, state, postal_code, country, phone, is_default }
PATCH/DELETE /users/me/addresses/:id/  ·  POST /users/me/addresses/:id/set-default/
```

### Catalog
```
GET   /products/             ?category&brand&min_price&max_price&min_discount&is_featured&sort&page
                             sort ∈ [price_asc, price_desc, newest, rating]; default -updated_at
                             → { id, name, slug, category, brand, mrp, base_price,
                                 discount_percent, is_featured, primary_image,
                                 primary_image_display, rating_avg, rating_count }
GET   /products/:slug/       → + description, offers[] (top-5 coupons), variants[], images[]
GET   /categories/           → flat list (product_count, has_children; children on detail)
GET   /products/brands/      → distinct brands (NOT /brands/)
GET   /products/wishlist/    ·  POST/DELETE /products/wishlist/:slug/ → { added, slug, count }
GET   /products/:slug/reviews/   GET (paged 10) · POST { rating, title, body } (409 duplicate)
```

### Search
```
POST  /search/               { q, category, min_price, max_price, is_featured, sort, page }
                             sort ∈ [relevance, price_asc, price_desc, newest, popular, rating]
                             → { results, total, page, page_size, took_ms, query }
GET   /search/suggestions/?q=   (min 2 chars) → [strings]
```

### Cart
```
GET   /cart/                 → { id, store, items[{ id, variant{}, quantity,
                                 line_total, tenant_id, seller_name }], total_items, subtotal }
POST  /cart/items/           { variant_id, quantity }   (upsert-increment)
PATCH/DELETE /cart/items/:id/  { quantity }
POST  /cart/merge/           { session_key }   (guest cart → user cart)
DELETE /cart/clear/
```

### Orders
```
POST  /orders/               { cart_id, store?, delivery_address, delivery_instructions }
                             store omitted → one order per seller tenant: { "orders": [...] }
GET   /orders/               → list (+ item_count)
GET   /orders/:id/           → detail + items[] + status_history[] timeline
POST  /orders/:id/cancel/    { reason }   (PENDING/CONFIRMED only)
GET   /orders/:id/invoice/
                             status ∈ [PENDING, CONFIRMED, PREPARING, READY,
                                       OUT_FOR_DELIVERY, DELIVERED, CANCELLED, REFUNDED]
```

### Payments (direct create — no intent/confirm)
```
GET   /payments/methods/     → saved methods (CARD | UPI | WALLET | COD)
POST  /payments/             { order, gateway, amount, payment_method_id? }
                             gateway ∈ [RAZORPAY, STRIPE, PHONEPE, COD]
GET   /payments/refunds/     ·  POST /payments/:id/refund/ { amount, reason }
```

### Pincode / Delivery
```
GET   /pincode/:code/        → { valid, pincode, city, state, eta_days,
                                 delivery_fee, free_delivery_over, source }
                             (fee/free-over are strings; 404 → not serviceable)
```

### Coupons / Banners
```
POST  /admin/coupons/validate/  { code, order_value } (any authenticated user)
                                → { valid: true, discount, discount_type, coupon }
                                | 400 { valid: false, message }
GET   /banners/              → paginated active banners (CAROUSEL | POPUP | BANNER)
```

### Storefront (public)
```
GET   /storefront/platform/              → platform (EASYGET) render
GET   /storefront/:store_slug/           → { store, theme, sections[], ticker }
     section types: HERO · BANNER · CATEGORY_GRID · PRODUCT_ROW · IMAGE_GALLERY · RICH_TEXT
```

### Engagement
```
GET   /notifications/        ·  POST /notifications/:id/mark_read/
POST  /notifications/mark_all_read/  ·  GET /notifications/unread_count/
GET   /notifications/preferences/ (+/all_preferences/ +/bulk_update/)
POST  /realtime/devices/     { platform: IOS|ANDROID|WEB, device_token, user_agent }
POST  /analytics/events/     { event_type, session_id, properties }
POST  /analytics/events/batch/
POST  /pwa/updates/check/    { platform, current_version } → { update_available, ... }
ws    /ws/orders/ · /ws/notifications/   (Channels; Phase 5)
```

### Admin (`/api/v1/admin/` — staff only; unchanged surface)
```
GET   /admin/dashboard/      (actual path; originally drafted as /stats/)
GET /admin/orders/ · PATCH /admin/orders/:id/status/
GET/POST /admin/products/ · PATCH /admin/products/:id/
GET /admin/inventory/ · PATCH /admin/inventory/:id/
GET /admin/reviews/ · PATCH /admin/reviews/:id/ · DELETE /admin/reviews/:id/
GET /admin/storefront/:store_id/ · PUT /admin/storefront/:store_id/
GET/POST /admin/coupons/ · GET/POST /admin/banners/
```

---

## 3. Data Models (reference only — DO NOT modify)

```
User          { id, email, phone, name, role, is_verified }
Store         { id, tenant, slug, name, theme, address, is_active }
Tenant        { id, name, owner }
Category      { id, parent, name, slug, image }
Brand         { id, name, slug, logo }
Product       { id, store, category, brand, name, slug, description,
                rating_avg, rating_count, is_active }
Variant       { id, product, name, sku, price, mrp, attributes }
ProductImage  { id, product, url, is_primary, focal_x, focal_y, zoom, hover_effect }
Inventory     { id, store, variant, quantity, reserved }
CartItem      { id, cart, variant, qty }
Order         { id, user, store, status, subtotal, discount, total, address,
                payment_method, created_at }
OrderItem     { id, order, variant, qty, unit_price }
OrderEvent    { id, order, status, note, created_at }
Payment       { id, order, gateway, status, amount, reference }
WishlistItem  { id, user, product }
Review        { id, user, product, rating, title, body, verified, status }
Coupon        { id, code, type, value, min_subtotal, expires_at, is_active }
Banner        { id, title, image, link, position, is_active }
StorefrontSection { id, store, type, order, config }
StorefrontItem    { id, section, product_id, order, style }
```

---

## 4. Folder Structure

```
backend/
  config/
  apps/
    users/ tenants/ stores/ categories/ products/ inventory/
    cart/ orders/ payments/ delivery/ notifications/
    search/ analytics/ realtime/ storefront/ admin_panel/
    pwa/ webhooks/

admin-web/
  src/
    components/  pages/  hooks/  api/  theme/  styles/

customer-web/
  src/
    components/  pages/  hooks/  api/  theme/  styles/

customer-app/
  lib/
    features/  core/  shared/  theme/  router/

docs/
  design-direction.md
  phase-1-foundation-spec.md
```

---

## 5. Frontend Stack (target after redesign)

### customer-web + admin-web
- React 18 + TypeScript (strict)
- Vite
- Tailwind CSS v4 (with custom tokens from DESIGN.md)
- Radix UI primitives (behavior only — visuals replaced)
- `motion` (Framer Motion) for animation
- TanStack Query for data
- Zustand for local state
- Hash router (keep existing)

### Flutter
- Riverpod (state)
- go_router (navigation)
- Dio (HTTP)
- `flutter_animate` (motion)
- `shimmer` (skeletons)
- `google_fonts` (type)
- Haptics via `HapticFeedback`

---

## 6. Design System Components (target)

### Primitives
```
Button, IconButton, Input, Select, Checkbox, Radio, Switch,
Badge, Tag, Tooltip, Popover, Modal, Sheet, Toast, Skeleton,
Spinner, Avatar, Tabs, Accordion
```

### Commerce
```
ProductCard (3 densities), RatingPill, PriceBlock, QtyStepper,
VariantSwatch, FilterPanel, SortMenu, OfferCard, CouponChip,
PincodeChecker, CartLineItem, AddressCard, OrderTimeline,
ReviewCard, StarDistribution
```

### Layout
```
AppShell, StickyHeader (scroll-aware blur), BottomNav (safe-area),
Rail/Carousel, BentoGrid, SectionHeader, EmptyState, ErrorState,
OfflineState
```

---

## 7. Logins (dev)

| Role     | Email                     | Password       |
|----------|---------------------------|----------------|
| Admin    | admin@easyget.local       | EasyGet!2026   |
| Customer | customer@easyget.app      | Customer@123   |
| Merchant | merchant@easyget.app      | Merchant@123   |
| Agent    | agent@easyget.app         | Agent@123      |

---

## 8. Hard Rules

1. NEVER modify backend models, serializers, or tests (195 must stay green).
2. NEVER invent API endpoints. If an endpoint isn't listed above, ask first.
3. ALWAYS use tokens from DESIGN.md §1. Zero hardcoded hex/px.
4. ALWAYS ship light + dark.
5. ALWAYS cover loading + empty + error on lists.
6. ALWAYS respect the Forbidden List (DESIGN.md §2).
7. One component or screen per AI session. Never batch.
8. Ship behind `NEXT_UI` feature flag until client approves.