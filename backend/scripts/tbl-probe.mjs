// One-off: which public tables have RLS disabled?
// RLS state is only visible in the catalogue, so this reads it through a
// PostgREST probe on each table plus the known schema, and reports the
// anon-key view for each. Deleted right after use.
import { createClient } from '@supabase/supabase-js';
import 'dotenv/config';

const url = process.env.SUPABASE_URL.replace(/^https?:\/\//, '').replace(/\/+$/, '');
const service = createClient(`https://${url}`, process.env.SUPABASE_SERVICE_KEY);
const { readFileSync } = await import('node:fs');
const anon = readFileSync(
  new URL('../../frontend/lib/main.dart', import.meta.url), 'utf8',
).match(/eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/)[0];

// Discover tables by asking PostgREST for the root, then reading our schema
// for the authoritative list.
const schema = readFileSync(
  new URL('../../sql/schema.sql', import.meta.url), 'utf8',
);
const tables = [...schema.matchAll(/CREATE TABLE IF NOT EXISTS\s+(\w+)/gi)]
  .map((m) => m[1]);

console.log(`\nPublic tables declared in schema.sql: ${tables.length}\n`);
console.log('table            rows(service)  anon can read?');
console.log('─'.repeat(52));

for (const t of tables) {
  let count = '?';
  try {
    const { count: c } = await service.from(t).select('*', { count: 'exact', head: true });
    count = c ?? 0;
  } catch { count = 'err'; }

  let anonRead = 'BLOCKED';
  try {
    const res = await fetch(`https://${url}/rest/v1/${t}?select=*&limit=1`, {
      headers: { apikey: anon, Authorization: `Bearer ${anon}` },
    });
    if (res.ok) {
      const b = await res.json();
      anonRead = Array.isArray(b) && b.length
        ? 'YES -> ' + Object.keys(b[0]).slice(0, 4).join(',')
        : 'empty/filtered';
    } else anonRead = `blocked(${res.status})`;
  } catch (e) { anonRead = 'probe error'; }

  console.log(`${t.padEnd(17)}${String(count).padEnd(14)}${anonRead}`);
}
console.log('');