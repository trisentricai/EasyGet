# GIT CHECK — EASYGET (Git & GitHub Reference)

**Last updated:** 2026-09-22
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
| Repository | `trisentricai/EasyGet` (blank at repo creation — receives all EASYGET code) |
| SSH URL | `git@github.com:trisentricai/EasyGet.git` |
| HTTPS URL (fallback) | `https://github.com/trisentricai/EasyGet.git` |
| Access | Collaborator access granted to personal account `rahulbharathi1921` |

## 3. Authentication

- Method: **SSH** (chosen; recommended over HTTPS/PAT)
- Key: `~/.ssh/id_ed25519.pub` (private key `id_ed25519`)
- Verified: `ssh -T git@github.com` → `Hi rahulbharathi1921! You've successfully authenticated` (2026-09-19)
- If auth ever fails: confirm key is still listed under GitHub → Settings → SSH and GPG keys.

## 4. Commit Identity (repo-local — does NOT touch global config)

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

- `main` — stable, shippable baseline. Every phase merges here only after its checklist passes.
- Feature/phase branches: `phase-1-foundation`, `phase-2-auth`, `phase-3-products`, … (named per README phase)
- Workflow: create branch → build phase → verify against `README.md` manual checklist → merge into `main` → push.

**In progress:** `phase-3-store-product-inventory` — tenancy foundation (`tenants` app + tenant FKs on Store/Product/StockItem + isolation tests), Phase 3 bug fixes, and the `seed_shop_catalog` command all sit **uncommitted** in the working tree (2026-09-20). Review with `git status` / `git diff`, then commit in logical chunks (see §7 checklist). `phase-2-auth` was merged into `main` (2026-09-19).

## 6. Commit-Message Conventions

`type: short imperative summary`

- `feat:` new capability (e.g. `feat: user registration + OTP`)
- `fix:` bug fix (e.g. `fix: CORS block for unknown origins`)
- `chore:` tooling/infra (e.g. `chore: initialize EasyGet Phase 1 foundation`)
- `docs:` README/currentUpdate/GitCheck updates
- `refactor:` / `test:` as usual

Rules: concise, imperative mood, never commit secrets (`.env`, keys).

## 7. PUSH / COMMIT CHECKLIST (run every time code changes)

1. Update **`currentUpdate.md`** (latest work, file-system state) AND **`GitCheck.md`** (this file — session changelog below).
2. `git status` + `git diff` — stage only intended files, never `.env`/secrets.
3. `git log --oneline -5` — confirm working from correct branch.
4. Commit with a convention-abiding message.
5. `git push` (or `git push -u origin main` on first push of a branch).
6. Add a row to the **Session Changelog** table below.

## 8. Session Changelog

| Date | Branch | Commit | Summary |
|---|---|---|---|
| 2026-09-22 | phase-3-store-product-inventory | — (in progress) | Supabase live verify (health/admin-login/dashboard/stores/categories/storefront/products-200), created `admin@easyget.local` in Supabase, fixed products N+1 (`prefetch_related` + annotated `min_variant_price` + prefetched `primary_image`); 31 tests pass (products/stores/categories/tenants); both webs build pass |
| 2026-09-20 | phase-3-store-product-inventory | — (uncommitted) | Admin dashboard UI (admin-web): dual-theme SPA, login/JWT+refresh, dashboard stats, categories/products/inventory CRUD, drag-and-drop storefront designer (sections+items, design knobs, theme panel); backend fixes: `/api/v1/admin/` route order, storefront template backend (`storefront` app: theme/sections/items + render API, 21 tests) — suite 141✅ |
| 2026-09-20 | phase-3-store-product-inventory | — (uncommitted) | Phase 3: new `tenants` app (Tenant/TenantMembership/permissions/services), tenant FKs on Store/Product/StockItem + migrations, merchant onboarding flow, tenant-scoped products/inventory, 22 isolation tests (suite 120✅); fixed 6 generated-baseline bugs (Redis fail-soft throttle cache, product routes/filters, realtime signal); `seed_shop_catalog` → 10 categories / 200 products / 200 stock items from Shop Stock Checklist |
| 2026-09-19 | main | `66bc53a` | Phase 1 foundation baseline: Django API + health endpoint + CI + React/Flutter scaffolds; git/SSH setup; docs (README, currentUpdate.md, GitCheck.md) |

## 9. Gotchas

- Run `manage.py test` and management commands **from `backend/`** (discovery finds 0 tests otherwise).
- `.env` is gitignored, required locally; copy from `.env.example` and keep `DJANGO_DEBUG=true` in dev.
- No Docker on dev machine → DB-touching Django commands hang with the Postgres URL; override `$env:DATABASE_URL="sqlite:///db.sqlite3"`.
- `git branch -m main` already applied locally — branch is `main`, not `master`.
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