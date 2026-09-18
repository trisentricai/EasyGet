# Phase 1 — Project Foundation Specification

**Status:** Draft — implementation baseline  
**Date:** 2026-09-16  
**Scope:** EASYGET local development foundation

## Context

EASYGET needs one reliable backend for the Flutter customer application, React customer web application, and React admin dashboard. This phase creates runnable local projects and shared operational conventions before business features are introduced.

The system is a modular monolith. PostgreSQL is the authoritative database, Redis supports caching and background work, and Celery executes asynchronous tasks. Production-provider credentials are deliberately external configuration, not source code.

## Functional Requirements

- **FR-1:** The repository MUST contain independent `backend`, `customer-web`, `admin-web`, and `customer-app` applications.
- **FR-2:** The Django API MUST expose a versioned health endpoint at `GET /api/v1/health/`.
- **FR-3:** The API MUST read environment-specific configuration from environment variables and MUST NOT commit secrets.
- **FR-4:** The API MUST permit local development origins for the two React applications and reject unconfigured origins.
- **FR-5:** The backend MUST be configurable for PostgreSQL, Redis, and Celery without changing source code.
- **FR-6:** The React applications and Flutter application MUST provide a runnable starter screen.
- **FR-7:** A continuous-integration workflow MUST run backend checks and frontend builds on pushes and pull requests.

## Non-Functional Requirements

- **NFR-1:** `GET /api/v1/health/` MUST return JSON with HTTP 200 in local development within 500 ms when dependencies are reachable.
- **NFR-2:** Debug mode MUST default to disabled unless explicitly enabled by environment configuration.
- **NFR-3:** Configuration examples MUST contain placeholders only; no credentials, tokens, or private URLs.
- **NFR-4:** Backend code MUST pass Django system checks before Phase 2 begins.

## Acceptance Criteria

- **AC-1 (FR-1):** Given a fresh checkout, when dependencies are installed, then all four application roots exist with their standard manifests.
- **AC-2 (FR-2, NFR-1):** Given the Django server is running, when `GET /api/v1/health/` is requested, then it returns `200` and `{ "status": "ok" }`.
- **AC-3 (FR-3, NFR-2, NFR-3):** Given a local `.env` copied from the example, when configuration is loaded, then local settings work and no secret is present in tracked files.
- **AC-4 (FR-4):** Given a request from an allowed local React origin, when it calls the API, then CORS permits it; an unlisted origin is not permitted.
- **AC-5 (FR-5):** Given PostgreSQL and Redis environment variables, when backend services start, then the settings select those configured services.
- **AC-6 (FR-6):** Given each client project is run, when its root route opens, then it displays an EASYGET starter view.
- **AC-7 (FR-7):** Given a push or pull request, when CI runs, then Django checks and both React builds execute.

## Edge Cases

- **EC-1:** Missing optional Redis configuration MUST not prevent Django health checks in local development.
- **EC-2:** Invalid `DATABASE_URL` MUST produce a clear startup configuration error.
- **EC-3:** A production environment with `SECRET_KEY` unset MUST fail safely rather than use an insecure default.
- **EC-4:** A failed Celery task MUST be logged and eligible for retry once domain tasks are added.

## API Contract

```ts
type HealthResponse = { status: "ok"; service: "easyget-api" };
// GET /api/v1/health/ -> 200 HealthResponse
```

## Data Models

N/A — Phase 1 defines infrastructure only. User, product, store, and order models begin in later approved phases.

## Out of Scope

- Authentication and user records (Phase 2)
- Product, inventory, cart, order, delivery, and payment functionality
- Production cloud account provisioning and credentials
- Automated deployment; CI validation is included, provider deployment setup is deferred until provider selection
