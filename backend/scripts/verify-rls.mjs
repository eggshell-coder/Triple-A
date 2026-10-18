#!/usr/bin/env node
// scripts/verify-rls.mjs
//
// Proves two things at once, because they pull in opposite directions:
//
//   1. The BACKEND can still write a profile row  (signup must keep working)
//   2. The PUBLIC anon key CANNOT read or write it (it must not)
//
// Checking only one is how this bug survived: signup was fixed by disabling
// RLS, which silently broke confidentiality.
//
//   npm run verify:rls
//
// Exit 0 = correct. Exit 1 = do not deploy.

import { createClient } from '@supabase/supabase-js';
import 'dotenv/config';

const url = process.env.SUPABASE_URL?.replace(/^https?:\/\//, '').replace(/\/+$/, '');
const serviceKey = process.env.SUPABASE_SERVICE_KEY;

// The anon key is committed in the Flutter client by design; read it from
// there so this needs no extra setup.
async function anonKey() {
  if (process.env.SUPABASE_ANON_KEY) return process.env.SUPABASE_ANON_KEY;
  const { readFileSync } = await import('node:fs');
  const dart = readFileSync(
    new URL('../../frontend/lib/main.dart', import.meta.url), 'utf8',
  );
  return dart.match(/eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/)?.[0] ?? null;
}

const ok = (m) => console.log(`PASS  ${m}`);
const bad = (m) => { console.log(`FAIL  ${m}`); failures++; };
let failures = 0;

const testEmail = `rlsverify.${Date.now()}@gmail.com`;

(async () => {
  if (!url || !serviceKey) {
    console.log('SUPABASE_URL / SUPABASE_SERVICE_KEY missing from .env');
    process.exit(1);
  }
  const anon = await anonKey();
  if (!anon) {
    console.log('Could not find the anon key in frontend/lib/main.dart');
    process.exit(1);
  }

  const admin = createClient(`https://${url}`, serviceKey);

  console.log('\n1. Backend write path (must keep working)\n');

  // Create a real auth user so the foreign key to auth.users is satisfied.
  // This is the exact call customerSignup makes when AUTO_CONFIRM_EMAIL=true.
  const { data: created, error: createErr } = await admin.auth.admin.createUser({
    email: testEmail,
    password: 'Verify1234',
    email_confirm: true,
  });

  if (createErr) {
    bad(`could not create the auth user: ${createErr.message}`);
    return finish();
  }
  ok('auth user created');

  // Now the insert that used to fail with the RLS error.
  const { data: row, error: insErr } = await admin
    .from('users')
    .upsert([
      {
        id: created.user.id,
        email: testEmail,
        full_name: 'RLS Verify',
        email_confirmed_at: new Date().toISOString(),
      },
    ])
    .select('id, email')
    .single();

  if (insErr) {
    bad(`backend could not write users: ${insErr.message}`);
    console.log(
      '\n      If this says "row-level security policy", the FK lookup on\n' +
      '      auth.users is still the blocker. See the fallback note at the\n' +
      '      bottom of sql/fix_users_rls.sql.',
    );
  } else {
    ok(`backend wrote the profile row (${row.email})`);
  }

  console.log('\n2. Public anon key (must NOT have access)\n');

  const readRes = await fetch(
    `https://${url}/rest/v1/users?select=*&limit=1`,
    { headers: { apikey: anon, Authorization: `Bearer ${anon}` } },
  );

  if (readRes.ok) {
    const body = await readRes.json();
    if (Array.isArray(body) && body.length) {
      bad(`anon key READ the users table: ${Object.keys(body[0]).join(', ')}`);
    } else {
      ok('anon key read returned no rows (filtered or empty)');
    }
  } else {
    ok(`anon key read blocked (HTTP ${readRes.status})`);
  }

  // Write probe: an id that cannot satisfy the FK, so a 409 means the
  // request got PAST permissions and only the constraint stopped it.
  const writeRes = await fetch(`https://${url}/rest/v1/users`, {
    method: 'POST',
    headers: {
      apikey: anon,
      Authorization: `Bearer ${anon}`,
      'Content-Type': 'application/json',
      Prefer: 'return=minimal',
    },
    body: JSON.stringify([
      { id: '00000000-0000-0000-0000-000000000001', email: 'rls@probe.invalid', full_name: 'PROBE' },
    ]),
  });

  if (writeRes.status === 401 || writeRes.status === 403) {
    ok(`anon key write blocked (HTTP ${writeRes.status})`);
  } else {
    bad(
      `anon key write reached the table (HTTP ${writeRes.status}). ` +
      '409 = stopped by the foreign key, not by permissions — with a real ' +
      'auth.users id this write would succeed.',
    );
  }

  // Clean up so repeated runs do not pile up accounts.
  await admin.auth.admin.deleteUser(created.user.id);
  await admin.from('users').delete().eq('id', created.user.id);

  finish();

  function finish() {
    console.log(
      failures === 0
        ? '\nAll checks passed. The table is protected and signup still works.\n'
        : `\n${failures} check(s) failed. Do not deploy yet.\n`,
    );
    process.exit(failures === 0 ? 0 : 1);
  }
})();