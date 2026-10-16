-- sql/email_verification.sql
-- Adds email-confirmation tracking to the public `users` table.
--
-- Run this once in the Supabase SQL Editor, then re-run schema.sql updates
-- if you rebuild from scratch. Safe to run repeatedly.
--
-- Why we mirror this instead of reading auth.users every time:
--   auth.users is owned by Supabase and not readable from the browser with
--   the anon key. The app needs to know "is this customer verified?" to gate
--   checkout, so the flag has to live in a table the app can query.

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS email_confirmed_at TIMESTAMPTZ;

-- Backfill: any account created before this migration was verified through
-- normal login, so treat existing rows as already confirmed.
UPDATE users
SET email_confirmed_at = created_at
WHERE email_confirmed_at IS NULL;

-- Partial index: the hot query is "unconfirmed accounts only", which is a
-- tiny slice of the table, so a partial index stays small.
CREATE INDEX IF NOT EXISTS idx_users_unconfirmed
    ON users (created_at)
    WHERE email_confirmed_at IS NULL;

-- ── Sanity check ─────────────────────────────────────────────────────────────
-- Expect one row per unconfirmed signup:
--
--   SELECT email, created_at
--   FROM users
--   WHERE email_confirmed_at IS NULL;