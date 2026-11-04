# Firebase Auth — Google + Email/Password sign-in

**Goal:** let shoppers sign in with **Google** or **email + password** via Firebase,
while the existing Django + SimpleJWT backend keeps owning accounts, roles,
carts, orders and every existing `/api/v1/...` endpoint.

**Chosen shape (Option A — recommended):** Firebase is the *identity provider*
only. The browser gets a Firebase **ID token**, posts it to a new Django
endpoint, Django verifies it with `firebase-admin`, upserts the `users.User`
row, and returns the **same SimpleJWT `access`/`refresh` pair** the app already
uses. Nothing downstream changes.

---

## 1. What I need from you (checklist)

### A. Firebase Console — project setup
| # | Task | Where |
|---|------|-------|
| 1 | Create (or pick) a Firebase project, e.g. `easyget-prod` | console.firebase.google.com |
| 2 | Add a **Web app** (`</>` icon) to the project | Project settings → Your apps |
| 3 | Copy the **`firebaseConfig`** object it shows | same screen |
| 4 | Enable **Google** provider (set support email) | Authentication → Sign-in method |
| 5 | Enable **Email/Password** provider | Authentication → Sign-in method |
| 6 | Add **Authorized domains**: `localhost`, `127.0.0.1`, your Netlify/admin domains | Authentication → Settings → Authorized domains |
| 7 | Configure the OAuth consent screen (app name, logo, support email, privacy URL, authorized domains + publish state) | Google Cloud Console → APIs & Services → OAuth consent screen |
| 8 | Set the **password policy minimum to 10 characters** (Django's validator is 10; Firebase defaults to 6) | Authentication → Settings → Password policy |
| 9 | (Optional, prod polish) Customize the verification / password-reset email templates | Authentication → Templates |

> **#7 matters:** while the consent screen is in **Testing**, only listed *test
> users* can complete Google sign-in. Publish it (or add testers) before QA.

### B. Values to hand over

**Frontend values — safe to commit/share (Firebase web keys are public):**
```
apiKey, authDomain, projectId, storageBucket, messagingSenderId, appId
# optional: measurementId
```

**Backend secret — do NOT commit:**
- **Service account private key JSON** (Project settings → Service accounts →
  *Generate new private key*). I need either the JSON file or its base64,
  supplied as an env var.
  - Deployed backend (Render etc.): paste as env var.
  - Local dev: point at a local file via env var (git-ignored).

### C. Decisions — LOCKED
1. **Email sign-in** = Firebase **Email/Password** provider. New signups skip the
   Django OTP round-trip entirely.
2. **Scope** = **customer-web only**. Admin accounts are Django superusers and
   keep the existing password login; admin-web is untouched.
3. **Existing Django users** = **auto-link by email**. A Google or Firebase
   sign-in whose email matches an existing Django account attaches the Firebase
   identity to that account rather than creating a duplicate.
4. **Password migration** = **none**. Existing Django passwords (PBKDF2) stay on
   the current `/auth/login/` endpoint; new accounts use Firebase.

#### Consequence of 1 + 4: the login form must serve both populations
Existing password users cannot sign in through Firebase (their hashes were not
imported), so both paths must remain reachable from one screen. Recommended:
**one email/password form that tries Firebase first and falls back to
`POST /api/v1/auth/login/`** on any non-throttle credential error. A legacy user
types their password once and lands on the Django path transparently; a new user
lands on the Firebase path. The Django OTP screens stay in place for legacy
register/verify during the transition.

---

## 2. Implementation plan

### Phase 0 — Prep (you + me)
- You complete §1.A/§1.B and drop values into root `.env` and
  `customer-web/.env.local`. Decisions (§1.C) are **already locked**.
- I confirm `firebase-admin` installs cleanly on Python 3.x in this venv.

> Everything in Phases 1–3 is env-driven and can be built **before** the
> credentials exist; only the live end-to-end sign-in needs §1.B.

### Phase 1 — Frontend Firebase bootstrap (`customer-web`)
- Add `firebase` to `customer-web/package.json`.
- New `customer-web/src/services/firebase.ts`:
  - read `import.meta.env.VITE_FIREBASE_*`, `initializeApp`, `getAuth`.
  - export `signInWithGoogle()` (popup, **redirect fallback** for
    popup-blocked browsers), `signInWithEmail()`, `signUpWithEmail()`,
    `sendPasswordReset()`, `firebaseSignOut()`, and `currentIdToken()`.
- Add `VITE_FIREBASE_*` to `customer-web/.env.example`; document in
  `GETTING_STARTED.md`.

### Phase 2 — Backend token verification (`backend/users`)
- Add `firebase-admin` to `requirements.txt`.
- New `backend/users/firebase_auth.py`: lazy singleton `firebase_admin`
  initialisation from env (either `FIREBASE_CREDENTIALS_JSON` base64/raw, or
  `GOOGLE_APPLICATION_CREDENTIALS` path); helper `verify_id_token(token)` →
  claims, with a clear error when credentials are missing.
- New serializers/view: `POST /api/v1/auth/firebase/`
  - body `{ "id_token": "<...>" }`, throttled (`throttle_scope = "login"`).
  - `auth.verify_id_token(token, check_revoked=True)`.
  - Upsert user: look up by `firebase_uid` → fall back to `email__iexact`
    (auto-link per your §1.C answer) → else create. Copy `name`/`picture`
    into `first_name`/`last_name` when the account is new.
  - Set `is_email_verified=True` when the `email_verified` claim is true
    (this bypasses `CustomTokenObtainPairSerializer`'s OTP gate, so it must be
    set explicitly here).
  - Return the **existing** `{access, refresh, user}` shape (via
    `RefreshToken.for_user`) so `AuthContext.signIn()` and every authed
    endpoint work untouched.
- New migration: nullable unique `firebase_uid` on `users.User`
  (needed to survive email changes and to key cleanly).

### Phase 3 — UI wiring
- `customer-web/src/pages/AuthPage.tsx`:
  - add a **"Continue with Google"** button above the form;
  - one email/password form that tries Firebase then falls back to the Django
    `/auth/login/` endpoint (per §1.C);
  - keep the register + OTP screens for legacy accounts during the transition.
- `customer-web/src/context/AuthContext.tsx`: add
  `signInWithFirebase(idToken)`; keep `signOut()` also calling
  `firebaseSignOut()` so Firebase state and JWTs stay in sync.
- Reuse the existing `signIn(tokens, user)` unchanged — no context rewrite.
- Admin-web is **out of scope** — no changes.

### Phase 4 — Config, deploy, hardening
- Root `.env` / `.env.example`: backend Firebase vars.
- Netlify (customer-web) env vars; Render backend env vars.
- Add the deployed origins to `DJANGO_CORS_ALLOWED_ORIGINS` and to Firebase
  **Authorized domains**.
- Consider `auth.revoke_refresh_tokens(uid)` on logout; confirm Firebase
  Google-sign-up org/workspace restrictions if any.

### Phase 5 — Tests & verification
- Backend unit tests with `firebase_admin` mocked: new user created, existing
  email linked, bad/expired token rejected, throttle works.
- `cd backend && DATABASE_URL="sqlite:///test_tmp.sqlite3" ../.venv/Scripts/python.exe manage.py test`
  (expect the current 268 → slightly higher, all green).
- `cd customer-web && npx tsc --noEmit` clean.
- Live browser E2E: Google popup + email sign-up → land on home page, cart and
  orders still work with the issued JWT.

---

## 3. Decisions worth spelling out

**Firebase Email/Password vs keeping Django OTP** — *decided:* Firebase owns
sign-up for new users; the OTP screens remain only as a legacy path. The known
cost is two password validators (mitigated by setting Firebase's minimum to 10
in the console) and a transitional double flow for existing accounts.

**Why Option A and not replacing SimpleJWT with Firebase tokens:** swapping the
token on every request means rewriting DRF authentication, per-view
permissions, the admin-panel gate, cart/order ownership checks and the
`is_email_verified` gate. Option A touches one new endpoint + one migration.

**Security notes**
- The Firebase `apiKey` is *designed* to be public — it identifies the project,
  it does not authorise anything. Real protection is the ID-token
  verification server-side.
- The service-account JSON is a real secret (it can mint tokens for any user);
  it must never be committed and must be env-injected in every environment.
- The new endpoint must be throttled, or it becomes a free user-provisioning
  oracle.

---

## 4. Open items / risks
- **Ambiguous callback:** Firebase reports `auth/invalid-credential` both for
  "wrong password" and for "account has no password provider" (a legacy user
  who once used Google). The fallback must therefore trigger on any non-throttle
  error, which costs one extra round-trip on a genuinely wrong password.
- Windows local dev needs the service-account JSON path handled with forward
  slashes / raw env; I'll validate on this machine.
- `firebase-admin` pulls `google-auth` and its dependencies — install time and
  cold-start cost on Render should be measured.
- If the consent screen stays in *Testing*, QA will fail Google sign-in for
  non-tester accounts.
