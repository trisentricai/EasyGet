# CURRENT UPDATE — EASYGET

**Last updated:** 2026-09-19
**Phase in progress:** 3 — Store + Product + Inventory (Recommended Build Order) — Phase 2 Auth **✅ done**
**Source of truth:** README.md (whole roadmap) + GitCheck.md (git/github) + docs/phase-1-foundation-spec.md (Phase 1 spec) + this file (live status)

> Read **GitCheck.md FIRST**, then THIS file, then README.md, whenever starting work. This file is the latest snapshot of what exists, what works, what is broken, and what comes next.
> **WORKFLOW RULE:** after every code/commit change, BOTH `currentUpdate.md` and `GitCheck.md` must be updated together.

---

## 0. LAST COMPLETED — Phase 2: Authentication & Users (✅ done on `phase-2-auth`)

**Built & merged to `main` (README Phase 2 checklist passing):**

- Custom `User` model (`AUTH_USER_MODEL = "users.User"`), email login (`USERNAME_FIELD = email`), unique email
- Roles via `User.Role.TextChoices`: `CUSTOMER` (default), `ADMIN`, `STORE_MANAGER`, `DELIVERY_AGENT`; Django `auth.Permission` retained for group perms
- JWT auth (`djangorestframework-simplejwt==5.5.0`) + `token_blacklist` → logout/blacklist verified working
- OTP via `OTPCode` model (6-digit, 10-min expiry, 5-attempt cap); dev email = console backend; verified end-to-end over live HTTP
- Users are active but **must verify email before login** (`is_email_verified`)
- DRF defaults changed: `DEFAULT_AUTHENTICATION_CLASSES = JWTAuthentication`, `DEFAULT_PERMISSION_CLASSES = IsAuthenticated` → **health endpoint made explicitly public** (`@permission_classes([AllowAny])`)
- Tests: **18/18 pass** (was 3 before)

**Verified live (12 checks):** register 201 ✔ OTP verify ✔ login tokens ✔ /users/me GET+PATCH ✔ addresses (1st auto-default, set-default works, exactly 1 default) ✔ admin-only → 403 for CUSTOMER ✔ logout ✔ refresh-after-logout → 401 ✔ pre-verify login → 400 ✔.

**API surface** (all `/api/v1/`): `auth/register|verify-otp|resend-otp|login|refresh|logout`, `users/me`, `users/me/addresses` (+`/set-default/`), `admin/only` (probe).

**Next → Phase 3 per Recommended Build Order: Store + Product + Inventory** — categories, products(+variants), images, and per-store inventory models.

---

## 1. Latest Work (last session)

Verified and repaired the Phase 1 foundation end-to-end:

- Installed Python dependencies into `.venv` (`pip install -r requirements.txt` succeeded after an earlier network failure).
- Confirmed backend passes `manage.py check` with a valid `.env` (created from `.env.example`). Image check → **`System check identified no issues (0 silenced)`**.
- Confirmed all **3 backend tests pass** (`manage.py test`, run from `backend/`):
  - `/api/v1/health/` returns 200 JSON `{"status":"ok","service":"easyget-api"}`
  - CORS allows `http://localhost:5173`
  - CORS blocks unknown origins
- Live-checked the server: `GET /api/v1/health/` → `{"status":"ok","service":"easyget-api"}` over real HTTP.
- Fixed both React apps so CI-style `npm run build` passes (see Errors below).
- `flutter pub get` + `flutter analyze` → **No issues found** (Flutter 3.38.7 stable).
- Set up git + GitHub for `trisentricai/EasyGet` (see GitCheck.md): repo-local identity, branch `master`→`main`, SSH remote `origin`, `.gitignore` now excludes `.kilo/` and `*.log`, initial foundation commit + push to `main`.

## 1a. Git / GitHub state

| Item | Value |
|---|---|
| Branch | `main` (baseline foundation commit `66bc53a` landed 2026-09-19) |
| Remote | `origin = git@github.com:trisentricai/EasyGet.git` (SSH) |
| Auth | SSH verified (`rahulbharathi1921` authenticated successfully) |
| Identity (repo-local) | Rahul Bharathi <mailtorahulbharathi@gmail.com> |
| Working branch model | `main` stable; per-phase branches (`phase-2-auth`, …) merged in when checklist passes |
| Full reference | see `GitCheck.md` |

## 2. Errors Found & Fixed

| # | Error | Root cause | Fix |
|---|---|---|---|
| 1 | `.kilo/pip-install-error.log`: Django download failed (`WinError 32`, read timeouts) | Interrupted network / file-in-use during prior pip install; venv had **no packages** | Re-ran `pip install -r requirements.txt` |
| 2 | `customer-web` build: `Unable to resolve @typescript/typescript-win32-x64` | TypeScript native platform binary (optional dep) missing from `node_modules` | `npm install` (added 2 packages) |
| 3 | `admin-web` build: `'tsc' is not recognized` | `npm install` never ran for `admin-web` (no `node_modules`) | `npm install` (added 24 packages) |
| 4 | Both React builds: `TS2882 Cannot find module or type declarations for side-effect import of './styles.css'` | Missing Vite client type decls (standard `vite-env.d.ts`) | Added `src/vite-env.d.ts` with `/// <reference types="vite/client" />` in **both** apps |

## 3. Known Open Issue (not a code bug)

- **Docker is NOT installed** on this machine, so local PostgreSQL and Redis cannot run via `docker-compose.yml`.
- Because `.env` sets `DATABASE_URL=postgresql://easyget:easyget@localhost:5432/easyget` and Postgres isn't running, any Django command that touches the DB (`runserver`, `test`, `migrate`) **hangs** (psycopg connect stalls instead of failing fast).
- Workaround for pure-backend work: `$env:DATABASE_URL="sqlite:///db.sqlite3"` (this is how the backend was verified).
- Celery worker check remains **blocked** (needs Redis).

## 4. Phase 1 Status Checklist

Source: README.md Phase 1 Manual Test Checklist + docs/phase-1-foundation-spec.md acceptance criteria.

| Check | Status | Evidence |
|---|---|---|
| Four app roots exist (`backend`, `customer-web`, `admin-web`, `customer-app`) | ✅ Done | directory structure below |
| Django dev server starts with no errors | ✅ Done | `manage.py check` + live run |
| Test DRF endpoint returns valid JSON | ✅ Done | 3/3 tests pass, live HTTP check |
| Database connection (PostgreSQL/Supabase) | ⛔ BLOCKED | Docker not installed; Postgres unreachable |
| Redis connection | ⛔ BLOCKED | Docker not installed |
| Celery worker starts, test task executes | ⛔ BLOCKED | needs Redis |
| `.env` loads; values differ dev/staging | ⚠️ Partial | `.env` loads ✅; **no per-env settings split** (only `settings/base.py`) |
| CORS allows local Flutter/React origins, blocks others | ✅ Done | tested in `common/tests.py` |
| Git repo + sensible `.gitignore` | ✅ Done | `.gitignore` good |
| CI pipeline runs on push | ⚠️ NOT YET | `.github/workflows/ci.yml` exists ✅ but repo has **ZERO commits** → no push → CI never ran |
| Flutter app builds/runs | ✅ Done (analyze) | `flutter analyze` clean; device run not tested |
| React apps build/run locally | ✅ Done | `npm run build` passes both |

**Phase 1 remaining before moving to Phase 2:**
1. Initial git commit (and push) so CI actually runs.
2. Decide env split (dev/staging/production settings) — or accept single `settings/base.py` for now.
3. Install Docker locally when access to Postgres/Redis/Celery verification is needed (or run Postgres/Redis another way).

## 5. Clean Architecture — File System

### Repository root
```
EasyGet/
├── README.md                    # Full product roadmap + phases (0–15)
├── currentUpdate.md             # THIS FILE — live status/architecture snapshot
├── requirements.txt             # Python deps (Django 5.2, DRF, simplejwt, cors, environ, celery, redis, psycopg)
├── .env.example                 # Env template — placeholders ONLY, no secrets
├── .env                         # Local env (gitignored, created from example)
├── .gitignore
├── docker-compose.yml           # Local Postgres 16 + Redis 7 (for when Docker is available)
├── .github/workflows/ci.yml     # CI: backend checks+tests, customer-web build, admin-web build
├── .kilo/                       # Install/log artifacts (pip logs)
│
├── backend/                     # Django REST API (modular monolith, split by business domain)
│   ├── manage.py
│   ├── config/                  # Project configuration package
│   │   ├── settings/
│   │   │   ├── __init__.py      # imports * from base
│   │   │   └── base.py          # env, DRF (JWT), CORS, SIMPLE_JWT, email, Celery/Redis
│   │   ├── urls.py              # /admin/ + /api/v1/{auth,users,admin,health}
│   │   ├── wsgi.py / asgi.py
│   │   └── celery.py            # Celery app "easyget", autodiscover_tasks
│   ├── common/                  # Shared/health app
│   │   ├── views.py             # GET /api/v1/health/ (public)
│   │   ├── urls.py
│   │   └── tests.py             # 3 health + CORS tests
│   ├── users/                   # Phase 2 — Auth & Users
│   │   ├── models.py            # User (roles), Address, OTPCode
│   │   ├── admin.py
│   │   ├── permissions.py       # IsVerifiedEmail, role_required, IsAdminOnly
│   │   ├── serializers.py       # Register/Verify/Login/Logout/User/Address
│   │   ├── services.py          # send_otp_email
│   │   ├── auth_views.py        # register/verify-otp/resend-otp/login/logout
│   │   ├── views.py             # MeView, AddressViewSet(+set-default), AdminOnlyView
│   │   ├── urls.py / auth_urls.py / admin_urls.py
│   │   ├── tests.py             # 12 auth + profile/address/RBAC tests
│   │   └── migrations/
│   └── (future domain apps...)  # stores, products, inventory, cart,
│                                # orders, payments, delivery, coupons, notifications, reviews
│
├── customer-web/                # React (Vite+TS) — customer web app
│   ├── package.json             # dev :5173, build = tsc --noEmit && vite build
│   ├── tsconfig.json
│   ├── index.html
│   └── src/
│       ├── main.tsx             # EASYGET starter screen (Phase 2 ready)
│       ├── styles.css
│       └── vite-env.d.ts        # Vite client types (added this session)
│
├── admin-web/                   # React (Vite+TS) — admin dashboard
│   ├── package.json             # dev :5174, build = tsc --noEmit && vite build
│   ├── tsconfig.json
│   ├── index.html
│   └── src/
│       ├── main.tsx             # EASYGET ADMIN starter screen (Phase 8 ready)
│       ├── styles.css
│       └── vite-env.d.ts        # Vite client types (added this session)
│
├── customer-app/                # Flutter — customer mobile app
│   ├── pubspec.yaml             # SDK >=3.3.0, flutter_lints, Material 3
│   └── lib/
│       └── main.dart            # EASYGET starter screen
│
└── docs/
    ├── phase-1-foundation-spec.md   # Phase 1 FR/NFR/acceptance criteria
    └── local-development.md         # First-run + local endpoint reference
```

### Frontend target layout (follow when Phase 2+ UI grows)
```
Flutter lib/                 React src/
├── core/                    ├── components/
├── features/                ├── features/
├── models/                  ├── pages/
├── services/                ├── services/
├── routing/                 ├── hooks/
└── widgets/                 ├── layouts/
                             └── utils/
```

### Backend domain split (already reflected in README, create apps as phases land)
Balance: `users` ✅ (Ph.2) → `stores`/`categories`/`products`/`inventory` (Ph.3) → `cart` (Ph.5) → `orders` (Ph.6) → `payments` (Ph.7) → `delivery`/`coupons`/`notifications`/`reviews` (later).

## 6. Ports & Commands

| Service | Local URL |
|---|---|
| Django API | `http://127.0.0.1:8000/api/v1/` (health → `/health/`) |
| Customer web | `http://localhost:5173` |
| Admin web | `http://localhost:5174` |

```powershell
# Backend (from repo root) — use SQLite override until Docker/Postgres is up:
$env:DATABASE_URL = "sqlite:///db.sqlite3"
& .\.venv\Scripts\python.exe backend\manage.py migrate
& .\.venv\Scripts\python.exe backend\manage.py check
& .\.venv\Scripts\python.exe backend\manage.py test          # note: run from backend/ dir or use --pattern
& .\.venv\Scripts\python.exe backend\manage.py runserver

# Frontends
cd customer-web; npm install; npm run build   # or npm run dev
cd admin-web;    npm install; npm run build   # or npm run dev

# Flutter
cd customer-app; flutter pub get; flutter analyze; flutter run

# Services (when Docker is installed)
docker compose up -d postgres redis
```

## 7. Guardrails / Gotchas (learned)

- **Run `manage.py test`/management commands from `backend/`** (or pass labels); from repo root test discovery finds 0 tests.
- **`.env` is gitignored** but required: without it, `DJANGO_DEBUG` defaults to `false` → `RuntimeError: DJANGO_SECRET_KEY must be set` (safe-fail by design, EC-3). Copy `.env.example` → `.env` and keep `DJANGO_DEBUG=true` locally.
- **Keep `DJANGO_DEBUG=false` in any prod-like env** — SECRET_KEY required there.
- Backend is the source of truth for pricing/payments (Phases 5–7) — never trust client prices.
- `requirements.txt` is at repo root (CI runs `pip install -r ../requirements.txt` from `backend/`).
- DRF now defaults to **JWT + IsAuthenticated**: every view either uses it or explicitly opts out (`authenticate_classes=[]`/`AllowAny` on register/verify/login/logout/health).
- Only `users.*` domain models exist post-Phase 2 — **do not** assume models for stores/products/orders until those phases land.
- Never commit `.env` or secrets; `.env.*` except `.env.example` is gitignored.