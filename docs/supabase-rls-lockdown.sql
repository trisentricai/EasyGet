-- ============================================================================
-- EASYGET — Supabase RLS lockdown (fixes the 76 Advisor issues)
-- Run once in the Supabase dashboard → SQL Editor → New query → Run.
-- Idempotent: safe to run repeatedly.
--
-- Why this works for this project:
--   Django is the ONLY writer/reader. It connects with the `postgres` role
--   (DATABASE_URL user `postgres.qxdxlwdprmubnisfofgg`), which OWNS the
--   tables — table owners BYPASS RLS entirely, so Django is unaffected.
--
--   The Supabase REST/Realtime gateways (PostgREST at /rest/v1) use the
--   `anon` (public key) and `authenticated` (client login) roles. With RLS
--   enabled and NO policies, those roles can see nothing and change nothing:
--   every query returns 0 rows / permission-denied. That is exactly what the
--   Advisor wants — the anon key stops being a data leak even if it appears
--   in a browser bundle.
-- ============================================================================

-- 1) Enable RLS on every public-schema table that does not have it yet -----
DO $$
DECLARE
  t text;
BEGIN
  FOR t IN
    SELECT tablename
    FROM pg_tables
    WHERE schemaname = 'public'
      AND rowsecurity = false
  LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
    RAISE NOTICE 'RLS enabled on public.%', t;
  END LOOP;
END $$;

-- 2) Belt-and-braces: strip direct table grants from the gateway roles -----
-- (PostgREST would refuse anyway once RLS is on with no policies, but revoking
-- keeps the Advisor happy and blocks any future role misconfiguration.)
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon, authenticated;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM anon, authenticated;

-- 3) Same rule for tables created in the future (Django migrations) --------
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE ALL ON TABLES FROM anon, authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE ALL ON SEQUENCES FROM anon, authenticated;

-- 4) Verify ----------------------------------------------------------------
-- Every row should say rowsecurity = true:
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Sanity check (run as the dashboard's default role, NOT service_role):
--   SELECT * FROM public.users_user;   -- should now error/return nothing
-- Django keeps working because it connects as the table owner.

-- ============================================================================
-- Operational reminders (do these in the dashboard, not SQL):
--   * service_role key bypasses RLS — keep it server-side only; rotate it in
--     Settings → API if it ever shipped to a client bundle.
--   * If a future feature must read Postgres straight from the browser
--     (e.g. Supabase Realtime subscriptions), add an explicit, narrow
--     `CREATE POLICY ... FOR SELECT USING (...)` for that one table — never
--     a blanket "true" policy.
-- ============================================================================
