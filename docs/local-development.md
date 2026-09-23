# Local development

## Prerequisites

- Python 3.11+
- Node.js 22+
- Flutter SDK 3.3+
- Docker Desktop (recommended for PostgreSQL and Redis)

## First run

> Paths matter (the common trip-up): `.venv` lives at the **repo root**,
> `manage.py` lives inside **`backend/`**. All commands below assume
> PowerShell.

1. Copy `.env.example` to `.env`. Keep `DJANGO_DEBUG=true` locally.
   The committed `.env` already points at the live Supabase Postgres —
   **no Docker needed** for normal work (Docker is only required if you
   want local Postgres/Redis via `docker compose up -d postgres redis`).
2. From the **repo root**, install Python deps once:
   `.\.venv\Scripts\python.exe -m pip install -r requirements.txt`.
3. From the **repo root**, run the backend:
   `.\.venv\Scripts\python.exe backend\manage.py runserver`.
4. Confirm `http://127.0.0.1:8000/api/v1/health/` returns the health JSON.
   (`GET /` → 404 is **normal** — the backend is API-only, no homepage.)
5. In `customer-web` and `admin-web`, run `npm install` then `npm run dev`.
6. In `customer-app`, run `flutter pub get` then `flutter run`.
   The app defaults to `http://10.0.2.2:8000/api/v1` (Android emulator
   loopback). iOS simulator/desktop use host loopback automatically only
   if you override: `flutter run
   --dart-define=API_BASE=http://127.0.0.1:8000/api/v1`. Physical device:
   `--dart-define=API_BASE=http://<your-pc-lan-ip>:8000/api/v1`.
   Gate: `flutter analyze` must report zero issues before committing.

## Local endpoints

| Service | URL | Login |
| --- | --- | --- |
| Django API | `http://127.0.0.1:8000/api/v1/` | — (health + `/api/docs/` are public) |
| Django admin | `http://127.0.0.1:8000/admin/` | `admin@easyget.local` / `EasyGet!2026` |
| Customer web | `http://localhost:5173` | `customer@easyget.app` / `Customer@123` |
| Admin web | `http://localhost:5174` | `admin@easyget.local` / `EasyGet!2026` |

Merchant account (owns `Rahuls-Store` tenant): `merchant@easyget.app` / `Merchant@123`.

## Backend tests

Run **from `backend/`** with the SQLite override — Supabase cannot host
throwaway test databases, so the suite always runs on SQLite:

```powershell
cd backend
$env:DATABASE_URL='sqlite:///db.sqlite3'
& 'C:\Users\Rahul\Documents\TRISENTRICS-AI\EasyGet\.venv\Scripts\python.exe' manage.py test -v 1
```

## Auth API quick reference (Phase 2)

| Method | Path | Notes |
| --- | --- | --- |
| POST | `/api/v1/auth/register/` | `email`, `password` (min 8), `first_name`, `last_name`, `phone` → 201 + emails OTP |
| POST | `/api/v1/auth/verify-otp/` | `email`, `code` (6-digit) → marks email verified |
| POST | `/api/v1/auth/resend-otp/` | `email` → emails a fresh OTP |
| POST | `/api/v1/auth/login/` | verified-only; returns `access` + `refresh` + `user` |
| POST | `/api/v1/auth/refresh/` | `refresh` → new tokens |
| POST | `/api/v1/auth/logout/` | `refresh` → blacklists it |
| GET/PATCH | `/api/v1/users/me/` | profile (JWT required, verified email required) |
| GET/POST | `/api/v1/users/me/addresses/` | first address auto-becomes default |
| POST | `/api/v1/users/me/addresses/{id}/set-default/` | exactly one default at a time |

Dev only: OTP prints to the Django console (console email backend); in tests it is captured via the locmem backend.

## Background worker

After Redis is running, start a worker from `backend`:

```powershell
..\.venv\Scripts\celery.exe -A config.celery worker --loglevel=info
```

No domain task exists yet; the worker connection is the Phase 1 check.
