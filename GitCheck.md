# GIT CHECK â€” EASYGET (Git & GitHub Reference)

**Last updated:** 2026-09-24
**Read BEFORE working:** together with `README.md` (roadmap) and `currentUpdate.md` (live code status). Update this file after every commit/change.

---

## 1. GitHub Accounts

| Account | URL | Role |
|---|---|---|
| Personal | https://github.com/rahulbharathi1921 | Works as collaborator on the company repo |
| Company (org) | https://github.com/trisentricai | Owns the EASYGET repository |

## 2. Remote Repository

| Item | Value |
|---|---|
| Remote name | `origin` |
| Repository | `trisentricai/EasyGet` (blank at repo creation â€” receives all EASYGET code) |
| SSH URL | `git@github.com:trisentricai/EasyGet.git` |
| HTTPS URL (fallback) | `https://github.com/trisentricai/EasyGet.git` |
| Access | Collaborator access granted to personal account `rahulbharathi1921` |

## 3. Authentication

- Method: **SSH** (chosen; recommended over HTTPS/PAT)
- Key: `~/.ssh/id_ed25519.pub` (private key `id_ed25519`)
- Verified: `ssh -T git@github.com` â†’ `Hi rahulbharathi1921! You've successfully authenticated` (2026-09-19)
- If auth ever fails: confirm key is still listed under GitHub â†’ Settings â†’ SSH and GPG keys.

## 4. Commit Identity (repo-local â€” does NOT touch global config)

| Setting | Value |
|---|---|
| `user.name` | `Rahul Bharathi` |
| `user.email` | `mailtorahulbharathi@gmail.com` |
| Global identity (unchanged) | `decoderz25 <decoders.25@gmail.com>` |

```powershell
# view current identity
git config user.name; git config user.email
```

## 5. Branch Strategy (per current plan)

- `main` â€” stable, shippable baseline. Every phase merges here only after its checklist passes.
- Feature/phase branches: `phase-1-foundation`, `phase-2-auth`, `phase-3-products`, â€¦ (named per README phase)
- Workflow: create branch â†’ build phase â†’ verify against `README.md` manual checklist â†’ merge into `main` â†’ push.

**In progress:** `phase-3-store-product-inventory` â€” all Phase 3+ work committed in logical chunks (see changelog); branch is pushed to `origin`, awaiting merge into `main` after the manual checklist pass. `phase-2-auth` was merged into `main` (2026-09-19).

## 6. Commit-Message Conventions

`type: short imperative summary`

- `feat:` new capability (e.g. `feat: user registration + OTP`)
- `fix:` bug fix (e.g. `fix: CORS block for unknown origins`)
- `chore:` tooling/infra (e.g. `chore: initialize EasyGet Phase 1 foundation`)
- `docs:` README/currentUpdate/GitCheck updates
- `refactor:` / `test:` as usual

Rules: concise, imperative mood, never commit secrets (`.env`, keys).

## 7. PUSH / COMMIT CHECKLIST (run every time code changes)

1. Update **`currentUpdate.md`** (latest work, file-system state) AND **`GitCheck.md`** (this file â€” session changelog below).
2. `git status` + `git diff` â€” stage only intended files, never `.env`/secrets.
3. `git log --oneline -5` â€” confirm working from correct branch.
4. Commit with a convention-abiding message.
5. `git push` (or `git push -u origin main` on first push of a branch).
6. Add a row to the **Session Changelog** table below.

## 8. Session Changelog

| Date | Branch | Commit | Summary |
|---|---|---|---|
| 2026-09-26 | fix/flutter-web-and-ordering | `ab14c95` | Security hardening: full auth/authz review (14 findings) → 13 fixed (VULN-001…013): pwa writes admin-only; inventory cross-tenant create blocked; delivery permission tiers + agents PII scoping; chat message/participant guards; WS order/room access checks; payment webhook staff-only; payment attach ownership; refund validation + `pk` latent-500 fix; storefront product-tenant + inactive-section guards; enumeration-safe OTP errors + resend quota; DRF `ScopedRateThrottle` wired (login 5/min, register 3/min, otp 10/min — scopes were dead) live-verified `401×5→429×2`; password validators (min 10/similarity/common/numeric) + register serializer + signup form minLength; **Redis cache was silently dead** (redis-py 8 `HELLO` vs old server → `protocol=2`) — all throttling was off; + UX: signup grid overflow fix, guest route gate, logout localStorage purge; 221 tests green (+26 security tests), both builds green, 13/13 live-verified |
| 2026-09-26 | fix/flutter-web-and-ordering | `d331319` | Phase B1 marketplace depth: wishlist model + `/products/wishlist/` endpoints + server-synced heart + `#/wishlist` page; `sort=rating` (products+search) + sort-visibility leak fix; PDP offers from active coupons + demo coupons seeded; live pincode `GET /pincode/<6>/` (postal API + UA fix + state alias + fallback + cache); admin `GET/PATCH/DELETE /admin/reviews/` + admin-web ReviewsPage; 195 tests green, both builds green; root junk cleanup (JWT dumps, scratch scripts); docs rewritten (README/GETTING_STARTED/PROJECT/currentUpdate) |
| 2026-09-24 | fix/flutter-web-and-ordering | `bbb2afa` | Phase A discovery (web): deals/category/recent/recommended rails, brand+discount+sort backend filters, brands endpoint, search recents/trending; demo-enriched catalog (20 brands, varied prices/MRP) |
| 2026-09-24 | fix/flutter-web-and-ordering | `b896cd6` | Phase A2 Flipkart look: reviews/ratings API (one-per-user, verified badge, subquery aggregates, 409 dup) + theme palette migration (#2874F0/#FB641B/Inter) + full UI overhaul (header/category strip/offer ticker, carousel, rating-pill cards + wishlist heart, PDP buy box + reviews UI, sidebar filters, 4-col footer, bottom nav); 177 tests green |
| 2026-09-23 | phase-3-store-product-inventory | PR #2 | Closed PR #1 (stale CI history), opened fresh PR #2 â€” same branch, full description; CI restarting clean |
| 2026-09-23 | phase-3-store-product-inventory | â€” (uncommitted) | Fix backend CI: pin missing deps (channels, channels-redis, drf-spectacular, django-ratelimit) + SQLite env for CI tests |
| 2026-09-23 | phase-3-store-product-inventory | â€” (uncommitted) | `GETTING_STARTED.md`: full run guide (4 terminals, logins, per-screen map) + works/quirks/pending lists; README pointer |
| 2026-09-23 | phase-3-store-product-inventory | `ed01af0` | Pushed branch to `origin` (all 14 commits); fixed stale changelog hashes; `origin/phase-3-store-product-inventory` now tracks local |
| 2026-09-23 | phase-3-store-product-inventory | `af251ee` | Flutter app: full customer build (Riverpod 3.3 + go_router 17 + Dio + secure storage, clean arch, all screens); analyzer 0, debug APK built |
| 2026-09-23 | phase-3-store-product-inventory | `0908e75` | Delivery v1: `delivery` app (Assignment model + state machine + order sync), assign/advance/agents APIs (tenant-scoped), admin Orders delivery section; 9 tests; live E2E confirmâ†’assignâ†’delivered; agent `agent@easyget.app` |
| 2026-09-23 | phase-3-store-product-inventory | `efa1efb` | Tenant-wiring: Cart tenant FK + cross-tenant guards, Order tenant FK + scoped querysets, Payments inherit-via-order + scoped refunds, refunds-router order fix; products pagination (20/page, Load-more browse, listAll helpers); 58 tests pass |
| 2026-09-23 | phase-3-store-product-inventory | `6fa9d12` | Customer-web polish (icons/branding/fonts, UUID order ids) + CORS :3000 |
| 2026-09-23 | phase-3-store-product-inventory | `b24419b` | Docs refresh: README build-order statuses + Quick Start (run/logins/tests), local-development venv paths + logins + test instructions |
|---|---|---|---|
| 2026-09-23 | phase-3-store-product-inventory | `f72a14c` | Order Engine: admin `OrdersPage` (#/orders, filters, detail+timeline, advance/cancel) + Dashboard fulfilment link; fixed modal portal, storefront `.sf-layout` grid, sidebar overflow guard; stripped trailing `|` from 200 products + seed JSON |
| 2026-09-22 | phase-3-store-product-inventory | `0283bd4`+`23ea54d`+`6ba7cc7` | Supabase live verify (health/admin-login/dashboard/stores/categories/storefront/products-200), created `admin@easyget.local` in Supabase, fixed products N+1 (`prefetch_related` + annotated `min_variant_price` + prefetched `primary_image`); 31 tests pass (products/stores/categories/tenants); both webs build pass |
| 2026-09-20 | phase-3-store-product-inventory | â€” (uncommitted) | Admin dashboard UI (admin-web): dual-theme SPA, login/JWT+refresh, dashboard stats, categories/products/inventory CRUD, drag-and-drop storefront designer (sections+items, design knobs, theme panel); backend fixes: `/api/v1/admin/` route order, storefront template backend (`storefront` app: theme/sections/items + render API, 21 tests) â€” suite 141âœ… |
| 2026-09-20 | phase-3-store-product-inventory | â€” (uncommitted) | Phase 3: new `tenants` app (Tenant/TenantMembership/permissions/services), tenant FKs on Store/Product/StockItem + migrations, merchant onboarding flow, tenant-scoped products/inventory, 22 isolation tests (suite 120âœ…); fixed 6 generated-baseline bugs (Redis fail-soft throttle cache, product routes/filters, realtime signal); `seed_shop_catalog` â†’ 10 categories / 200 products / 200 stock items from Shop Stock Checklist |
| 2026-09-19 | main | `66bc53a` | Phase 1 foundation baseline: Django API + health endpoint + CI + React/Flutter scaffolds; git/SSH setup; docs (README, currentUpdate.md, GitCheck.md) |

## 9. Gotchas

- Run `manage.py test` and management commands **from `backend/`** (discovery finds 0 tests otherwise).
- `.env` is gitignored, required locally; copy from `.env.example` and keep `DJANGO_DEBUG=true` in dev.
- No Docker on dev machine â†’ DB-touching Django commands hang with the Postgres URL; override `$env:DATABASE_URL="sqlite:///db.sqlite3"`.
- `git branch -m main` already applied locally â€” branch is `main`, not `master`.
- Windows CRLF: commit LF-normalized files; avoid editing line endings across platforms.
- Prefix terminal commands with `rtk` for token savings (see `~/.claude/CLAUDE.md`).

## 10. Quick Reference Commands

```powershell
git status                        # what's changed
git diff                          # uncommitted changes
git log --oneline -10             # recent history
git branch -a                     # branches
git fetch origin                  # refresh remote refs
git checkout -b phase-2-auth      # new phase branch (from main)
git merge --no-ff phase-2-auth    # merge a phase into main
git push origin main              # push a branch
git remote -v                     # verify origin URL
```
