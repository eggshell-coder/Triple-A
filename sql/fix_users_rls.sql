-- sql/fix_users_rls.sql
-- Re-enable Row Level Security on `users` after it was disabled to unblock
-- signup, without breaking the backend again.
--
-- BACKGROUND
-- ----------
-- `users` had RLS disabled so that inserts would succeed. With RLS off the
-- table became world-readable: the anon key ships inside the Flutter web
-- client, so anyone could read every customer's email, name and phone via
-- the REST API, and could pass a write through to the write path.
--
-- Why a policy alone was not enough earlier: `users.id` is a foreign key to
-- `auth.users(id)`. Postgres satisfies that FK with a SELECT on auth.users,
-- and auth.users has its own RLS. A failure there surfaces as
-- "new row violates row-level security policy for table users" — which
-- looks like the users policy failed when it is really the FK lookup.
--
-- Run this, then verify with:
--     cd backend && npm run verify:rls
--
-- Safe to run more than once.

-- ── 1. Lock the table back down ──────────────────────────────────────────────
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- ── 2. Clear the leftover permissive policy from the earlier attempt ─────────
DROP POLICY IF EXISTS service_role_full_access_users ON public.users;

-- ── 3. Only the backend (service_role) may touch this table ──────────────────
-- Permissive policies are OR-ed together, so this is the single gate:
-- anon and authenticated get no policy at all and are therefore denied.
CREATE POLICY service_role_only ON public.users
  FOR ALL TO service_role
  USING (true) WITH CHECK (true);

-- ── 4. Let the FK lookup on auth.users succeed ───────────────────────────────
-- Without this, inserting a profile can fail even though policy 3 allows it.
-- CREATE POLICY has no IF NOT EXISTS in PostgreSQL, so guard it in a DO
-- block to keep this script re-runnable.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'auth'
      AND tablename   = 'users'
      AND policyname  = 'service_role_read_auth_users'
  ) THEN
    EXECUTE 'CREATE POLICY service_role_read_auth_users
             ON auth.users FOR SELECT TO service_role USING (true)';
  END IF;
END
$$;

-- ── Verify: policy list should now contain service_role_only only ────────────
--   SELECT policyname, cmd, roles::text
--   FROM pg_policies WHERE schemaname = 'public' AND tablename = 'users';

-- ── If inserts still fail with "violates row-level security policy", the FK
-- ── check is still the blocker. Drop it and clean up orphans manually:
-- ──   ALTER TABLE public.users DROP CONSTRAINT users_id_fkey;

-- ── Diagnostic: which tables are still exposed to the public anon key? ───────
--   SELECT tablename, rowsecurity
--   FROM pg_tables
--   WHERE schemaname = 'public'
--   ORDER BY rowsecurity, tablename;
--   -- rowsecurity = false means the table is readable with the anon key.