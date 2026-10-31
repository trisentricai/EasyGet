"""Row-Level Security hardening for the Supabase database.

EasyGet talks to Postgres as the table owner (`postgres` via DATABASE_URL)
and owners bypass RLS (we never FORCE it), so enabling RLS has zero effect
on the Django API. What it does stop is direct access through Supabase's
PostgREST roles — `anon`/`authenticated` get no table privileges — and it
clears the "RLS disabled in public" warnings from Supabase Advisor.

Applied from the post_migrate signal, so it re-runs after every deploy
migration that may create new tables. No-op on sqlite (local tests/dev).
"""

import logging

logger = logging.getLogger(__name__)

_applied = False

ENABLE_RLS_SQL = """
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT c.relname
      FROM pg_class c
      JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'public'
       AND c.relkind = 'r'
       AND NOT c.relrowsecurity
       AND c.relowner = (SELECT oid FROM pg_roles WHERE rolname = current_user)
  LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', r.relname);
  END LOOP;
END $$;
"""

REVOKE_DIRECT_ACCESS_SQL = """
DO $$
DECLARE r RECORD;
BEGIN
  FOR r IN
    SELECT rolname FROM pg_roles
     WHERE rolname IN ('anon', 'authenticated')
  LOOP
    EXECUTE format(
      'REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM %I', r.rolname);
    EXECUTE format(
      'REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM %I', r.rolname);
    EXECUTE format(
      'ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM %I',
      r.rolname);
  END LOOP;
END $$;
"""


def enable_supabase_rls(sender, using="default", **kwargs):
    """post_migrate receiver: enable RLS on every public table we own.

    post_migrate is sent once per app config, so guard to a single run per
    process; the SQL itself is idempotent.
    """
    global _applied
    if _applied or using != "default":
        return
    from django.db import connection

    if connection.vendor != "postgresql":
        return
    with connection.cursor() as cursor:
        cursor.execute(ENABLE_RLS_SQL)
        cursor.execute(REVOKE_DIRECT_ACCESS_SQL)
    _applied = True
    logger.info("Supabase RLS: public tables secured (RLS on, anon/auth revoked)")
