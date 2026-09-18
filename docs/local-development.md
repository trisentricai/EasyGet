# Local development

## Prerequisites

- Python 3.11+
- Node.js 22+
- Flutter SDK 3.3+
- Docker Desktop (recommended for PostgreSQL and Redis)

## First run

1. Copy `.env.example` to `.env`. Keep `DJANGO_DEBUG=true` locally.
2. Start local dependencies with `docker compose up -d postgres redis`.
3. Create and activate a virtual environment, then run `pip install -r requirements.txt`.
4. From `backend`, run `python manage.py migrate` and `python manage.py runserver`.
5. Confirm `http://127.0.0.1:8000/api/v1/health/` returns the health JSON.
6. In `customer-web` and `admin-web`, run `npm install` then `npm run dev`.
7. In `customer-app`, run `flutter pub get` then `flutter run`.

## Local endpoints

| Service | URL |
| --- | --- |
| Django API | `http://127.0.0.1:8000/api/v1/` |
| Customer web | `http://localhost:5173` |
| Admin web | `http://localhost:5174` |

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
