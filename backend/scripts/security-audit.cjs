#!/usr/bin/env node
// scripts/security-audit.cjs
//
// Repeatable self-audit for the Triple A backend.
//
//   node scripts/security-audit.cjs
//
// Scope is deliberately this project only: it reads its own repository and
// its own Supabase project using the credentials already in .env. It is a
// defensive review tool — it reports what is exposed so it can be fixed.
//
// Checks, grouped by severity:
//   CRITICAL  secrets committed to git; anon-key reachable tables
//   HIGH      admin routes missing authorisation; weak auth headers
//   MEDIUM    unauthenticated data endpoints; debug logging; audit level
//
// Exit code is 1 when a CRITICAL or HIGH finding is open, so it can gate CI.

require('dotenv').config();
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// This file lives at backend/scripts/, so the repository root is two levels
// up. Getting this wrong silently points every check at backend/backend/…
const ROOT = path.resolve(__dirname, '..', '..');
const BACKEND = path.join(ROOT, 'backend');
const results = [];

const record = (severity, name, ok, detail) => {
  results.push({ severity, name, ok, detail });
};

const banner = (t) => console.log(`\n${'─'.repeat(64)}\n${t}\n${'─'.repeat(64)}`);

// ─────────────────────────────────────────────────────────────────────────────
// 1. Secrets must not be in version control
// ─────────────────────────────────────────────────────────────────────────────
function checkSecrets() {
  banner('1. Committed secrets');

  let tracked = [];
  try {
    tracked = execSync('git ls-files', { cwd: ROOT, encoding: 'utf8' })
      .split('\n')
      .filter(Boolean);
  } catch {
    console.log('  (not a git repository — skipping)');
    return;
  }

  const PATTERNS = [
    { re: /eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/g, label: 'JWT' },
    { re: /-----BEGIN [A-Z ]*PRIVATE KEY-----/g, label: 'private key' },
    { re: /AIza[0-9A-Za-z_-]{30,}/g, label: 'Google API key' },
    { re: /xox[baprs]-[0-9A-Za-z-]{10,}/g, label: 'Slack token' },
  ];

  // A service_role JWT is the one that must never be committed. The anon
  // key is designed to ship in the client, so it is reported separately.
  let serviceRole = 0;
  let anonKey = 0;

  for (const f of tracked) {
    const abs = path.join(ROOT, f);
    if (!fs.existsSync(abs) || /\.(png|jpe?g|gif|ico|lock|woff2?|ttf)$/i.test(f)) continue;
    let text;
    try {
      text = fs.readFileSync(abs, 'utf8');
    } catch {
      continue;
    }
    for (const { re, label } of PATTERNS) {
      for (const m of text.match(re) || []) {
        if (label === 'JWT') {
          try {
            const seg = m.split('.')[1];
            const json = JSON.parse(
              Buffer.from(seg, 'base64url').toString('utf8'),
            );
            if (json.role === 'service_role') {
              serviceRole++;
              console.log(`  FAIL  service_role key committed in ${f}`);
            } else {
              anonKey++;
              console.log(`  note  anon key in ${f} (expected in a web client)`);
            }
          } catch {
            /* undecodable JWT, ignore */
          }
        } else {
          console.log(`  FAIL  ${label} committed in ${f}`);
          serviceRole++;
        }
      }
    }
  }

  record(
    'CRITICAL',
    'No service_role key committed',
    serviceRole === 0,
    serviceRole === 0
      ? 'clean — only the anon key is present, which is correct for web'
      : `${serviceRole} service_role key(s) in git history`,
  );

  // .env must be ignored, and .env.example must hold placeholders.
  let envIgnored = false;
  try {
    execSync('git check-ignore backend/.env', { cwd: ROOT, stdio: 'pipe' });
    envIgnored = true;
  } catch {
    envIgnored = false;
  }
  record(
    'CRITICAL',
    'backend/.env is gitignored',
    envIgnored,
    envIgnored ? '.env cannot be committed by accident' : '.env is NOT ignored',
  );

  const example = path.join(ROOT, 'backend/.env.example');
  if (fs.existsSync(example)) {
    const t = fs.readFileSync(example, 'utf8');
    const placeholder = /your-service-role-key|your-project/.test(t);
    record(
      'CRITICAL',
      '.env.example holds placeholders only',
      placeholder,
      placeholder ? 'no live credentials in the template' : 'contains a real-looking value',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Supabase exposure via the public anon key
// ─────────────────────────────────────────────────────────────────────────────
async function checkSupabaseExposure() {
  banner('2. Supabase data exposure (anon key)');

  const url = process.env.SUPABASE_URL;

  // The anon key lives in the Flutter client by design, so it is committed.
  // Prefer an explicit env var, otherwise read it from main.dart so the
  // audit runs with no setup at all.
  let anon = process.env.SUPABASE_ANON_KEY;
  if (!anon) {
    const mainDart = path.join(ROOT, 'frontend', 'lib', 'main.dart');
    if (fs.existsSync(mainDart)) {
      const m = fs
        .readFileSync(mainDart, 'utf8')
        .match(/eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/);
      if (m) {
        anon = m[0];
        console.log('  (anon key read from frontend/lib/main.dart)');
      }
    }
  }
  const admin = process.env.SUPABASE_SERVICE_KEY;

  if (!url || !anon) {
    console.log('  (SUPABASE_URL or anon key unavailable — skipping)');
    return;
  }

  // SUPABASE_URL already includes https://, so prefixing it again produces
  // "https://https://…" and every fetch fails. Normalise, and make fetch
  // failures loud — a silent catch here reported "no exposure" while the
  // exposure was real, which is the worst possible bug in a security tool.
  const host = url.replace(/^https?:\/\//, '').replace(/\/+$/, '');
  const rest = (table) => `https://${host}/rest/v1/${table}`;

  // Tables that must never be world-readable with the client key.
  const SENSITIVE = ['users', 'admins', 'orders', 'customers', 'order_items'];

  let exposed = [];
  let probeErrors = 0;
  for (const t of SENSITIVE) {
    try {
      const res = await fetch(`${rest(t)}?select=*&limit=1`, {
        headers: { apikey: anon, Authorization: `Bearer ${anon}` },
      });
      if (!res.ok) continue;
      const body = await res.json();
      if (Array.isArray(body) && body.length) {
        exposed.push(`${t} -> ${Object.keys(body[0]).join(', ')}`);
      }
    } catch (err) {
      probeErrors++;
      console.log(`  ! could not probe ${t}: ${err.message}`);
    }
  }

  // A probe that never completed must not be reported as "clean".
  if (probeErrors === SENSITIVE.length) {
    record('CRITICAL', 'No sensitive table readable by anon key', false,
      'every probe failed, so exposure status is UNKNOWN — fix connectivity first');
    return;
  }

  if (exposed.length === 0) {
    record('CRITICAL', 'No sensitive table readable by anon key', true,
      'all sensitive tables are empty or filtered by RLS');
  } else {
    record('CRITICAL', 'No sensitive table readable by anon key', false,
      `READABLE: ${exposed.join('; ')}`);
  }

  // If we have the service key we can prove whether RLS is disabled by
  // attempting a write that a constraint will reject. A 403 means RLS
  // blocked it; a 409 means it got past RLS and only the FK stopped it.
  if (admin) {
    const probeId = '00000000-0000-0000-0000-000000000001';
    try {
      const res = await fetch(rest('users'), {
        method: 'POST',
        headers: {
          apikey: anon,
          Authorization: `Bearer ${anon}`,
          'Content-Type': 'application/json',
          Prefer: 'return=minimal',
        },
        body: JSON.stringify([
          { id: probeId, email: 'audit-probe@example.invalid', full_name: 'AUDIT' },
        ]),
      });
      const blocked = res.status === 401 || res.status === 403;
      record(
        'CRITICAL',
        'users rejects writes from the anon key',
        blocked,
        blocked
          ? 'RLS denies anon writes'
          : `HTTP ${res.status} — the request reached the write path, meaning RLS is not protecting this table`,
      );
      if (!blocked && res.status === 409) {
        console.log('  → 409 = stopped by the foreign key, not by permissions.');
        console.log('     With a real auth.users id this write would succeed.');
      }
    } catch {
      console.log('  (write probe failed to run)');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Route authorisation
// ─────────────────────────────────────────────────────────────────────────────
function checkRoutes() {
  banner('3. Route authorisation');

  const routesDir = path.join(BACKEND, 'src', 'routes');
  if (!fs.existsSync(routesDir)) return;

  const PUBLIC_OK = new Set([
    '/', '/login', '/featured', '/admin/all', '/categories',
  ]);

  let unprotectedAdmin = [];
  let publicData = [];

  for (const f of fs.readdirSync(routesDir).filter((x) => x.endsWith('.js'))) {
    const text = fs.readFileSync(path.join(routesDir, f), 'utf8');
    const lines = text.split('\n');
    lines.forEach((line, i) => {
      const m = line.match(/router\.(get|post|put|patch|delete)\s*\(\s*'([^']*)'/);
      if (!m) return;
      const [, method, p] = m;
      const guarded = /requireAdmin|authenticate/.test(line);
      const ctx = lines.slice(Math.max(0, i - 6), i + 6).join(' ');
      const guardedMulti = /requireAdmin|authenticate/.test(ctx);

      if (!guarded && !guardedMulti) {
        if (/\/(admin|dashboard)/.test(p) || /revenue-summary|product-summary/.test(p)) {
          unprotectedAdmin.push(`${f} ${method.toUpperCase()} ${p}`);
        } else if (/track/.test(p)) {
          publicData.push(`${f} ${method.toUpperCase()} ${p}`);
        }
      }
    });
  }

  record('HIGH', 'All admin routes require authorisation', unprotectedAdmin.length === 0,
    unprotectedAdmin.length ? unprotectedAdmin.join('; ') : 'every /admin, /dashboard and summary route is guarded');

  record('MEDIUM', 'Unauthenticated data endpoints reviewed',
    true,
    publicData.length
      ? `${publicData.join('; ')} — public by design, confirm the returned fields are acceptable`
      : 'none found');
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Configuration and dependencies
// ─────────────────────────────────────────────────────────────────────────────
function checkConfig() {
  banner('4. Configuration & dependencies');

  const envPath = path.join(BACKEND, '.env');
  if (fs.existsSync(envPath)) {
    const t = fs.readFileSync(envPath, 'utf8');
    const cors = (t.match(/^CORS_ORIGIN=(.*)$/m) || [])[1] || '';
    const wildcard = cors.trim() === '*';
    record('HIGH', 'CORS is not a wildcard in development', !wildcard,
      wildcard ? 'CORS_ORIGIN=* allows any origin' : `CORS_ORIGIN=${cors.trim()}`);

    const autoConfirm = (t.match(/^AUTO_CONFIRM_EMAIL=(.*)$/m) || [])[1];
    record('MEDIUM', 'Email confirmation mode', true,
      `AUTO_CONFIRM_EMAIL=${autoConfirm ?? 'unset'}` +
      (String(autoConfirm).toLowerCase() === 'true'
        ? ' — addresses are confirmed server-side, so users cannot prove inbox ownership'
        : ''));
  }

  // Server must not listen when merely required by a test.
  const server = fs.readFileSync(
    path.join(BACKEND, 'src', 'server.js'), 'utf8',
  );
  const guardedListen = /require\.main === module/.test(server);
  record('HIGH', 'server.js only binds a port as an entrypoint', guardedListen,
    guardedListen ? 'test runner can import the app without holding the port' : 'app.listen runs on import');

  // Debug logging left in a request path can leak identifiers into logs.
  const order = fs.readFileSync(
    path.join(BACKEND, 'src', 'controllers', 'order.controller.js'), 'utf8',
  );
  const debugLog = /console\.log\((?!\s*`?\s*(?:✅|🌍))/.test(order);
  record('MEDIUM', 'No debug logging in the order controller', !debugLog,
    debugLog ? 'console.log present in order.controller.js' : 'clean');

  // npm audit exits non-zero when it finds anything, which makes execSync
// throw and discard stdout. Read the output off the error instead, or the
// check silently reports "unavailable" exactly when it matters most.
  const runAudit = () => {
    try {
      return execSync('npm audit --json', {
        cwd: BACKEND,
        encoding: 'utf8',
        stdio: ['pipe', 'pipe', 'ignore'],
      });
    } catch (err) {
      const out = err.stdout && err.stdout.toString();
      if (out) return out;
      throw err;
    }
  };

  try {
    const v = JSON.parse(runAudit()).metadata.vulnerabilities;
    record('HIGH', 'No high/critical dependency advisories',
      v.high === 0 && v.critical === 0,
      `high=${v.high} critical=${v.critical} moderate=${v.moderate}`);
  } catch {
    console.log('  (npm audit could not be parsed)');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
(async () => {
  console.log('Triple A — security self-audit');
  console.log(`target: ${ROOT}`);

  checkSecrets();
  await checkSupabaseExposure();
  checkRoutes();
  checkConfig();

  banner('Summary');
  const ORDER = { CRITICAL: 0, HIGH: 1, MEDIUM: 2 };
  results.sort((a, b) => ORDER[a.severity] - ORDER[b.severity]);
  for (const r of results) {
    const mark = r.ok ? 'PASS ' : 'FAIL ';
    console.log(`${mark}[${r.severity.padEnd(8)}] ${r.name}`);
    if (r.detail) console.log(`             ${r.detail}`);
  }

  const blocking = results.filter((r) => !r.ok && ['CRITICAL', 'HIGH'].includes(r.severity));
  console.log(
    `\n${results.length - blocking.length}/${results.length} checks passing.` +
    (blocking.length ? `  ${blocking.length} need attention.` : '  Nothing blocking.'),
  );
  process.exit(blocking.length ? 1 : 0);
})();