// test/api.test.js
// Node's built-in test runner (node --test) — no extra runner dependency.
// These are HTTP-level tests against the real Express app with Supabase
// stubbed, so they run in CI without touching a live database.

process.env.NODE_ENV = 'test';

// Stub the Supabase client before server.js loads it.
const Module = require('module');
const originalLoad = Module._load;

const fakeSupabase = {
  from: () => ({
    select: () => ({
      limit: () => Promise.resolve({ data: [], error: null }),
      single: () => Promise.resolve({ data: null, error: null }),
      eq: () => ({
        single: () => Promise.resolve({ data: null, error: null }),
        maybeSingle: () => Promise.resolve({ data: null, error: null }),
      }),
    }),
    insert: () => Promise.resolve({ data: null, error: null }),
    update: () => Promise.resolve({ data: null, error: null }),
    upsert: () => Promise.resolve({ data: null, error: null }),
  }),
  auth: {
    signInWithPassword: () =>
      Promise.resolve({ data: { session: null }, error: { message: 'stub' } }),
    refreshSession: () =>
      Promise.resolve({ data: { session: null }, error: { message: 'stub' } }),
    signOut: () => Promise.resolve({ error: null }),
  },
  storage: { from: () => ({ upload: () => Promise.resolve({ error: null }) }) },
};

// Stub the Supabase client before server.js loads it.
//
// Two request strings must be intercepted. Modules inside src/controllers use
// '../config/supabase', while src/server.js itself uses './config/supabase'.
// Missing the second one meant the real client was constructed in CI, where
// .env is absent (it is gitignored), and the suite died on startup.
Module._load = function (request, parent, isMain) {
  if (request === '../config/supabase' || request === './config/supabase') {
    return fakeSupabase;
  }
  return originalLoad.apply(this, arguments);
};

const request = require('supertest');
const { test, describe, before } = require('node:test');
const assert = require('node:assert/strict');

const app = require('../src/server');

let agent;
before(() => {
  agent = request(app);
});

describe('health', () => {
  test('GET /health reports db ok', async () => {
    const res = await agent.get('/health').expect(200);
    assert.equal(res.body.success, true);
    assert.equal(res.body.db, 'ok');
    assert.ok(res.body.timestamp);
  });
});

describe('routing', () => {
  test('unknown route returns 404 JSON', async () => {
    const res = await agent.get('/definitely-not-a-route').expect(404);
    assert.equal(res.body.success, false);
    assert.match(res.body.message, /not found/i);
  });

  test('auth login rejects a missing email with 422', async () => {
    const res = await agent
      .post('/api/auth/login')
      .send({ password: 'whatever' })
      .expect(422);
    assert.equal(res.body.success, false);
  });

  test('auth login rejects a malformed email with 422', async () => {
    const res = await agent
      .post('/api/auth/login')
      .send({ email: 'not-an-email', password: 'whatever' })
      .expect(422);
    assert.equal(res.body.success, false);
  });
});

describe('security headers', () => {
  test('helmet sets standard headers', async () => {
    const res = await agent.get('/health').expect(200);
    // helmet always sets X-Content-Type-Options and X-Frame-Options
    assert.equal(res.headers['x-content-type-options'], 'nosniff');
    assert.ok(res.headers['x-frame-options']);
  });
});

describe('cors', () => {
  test('allows requests with no Origin (curl / server-to-server)', async () => {
    // No Origin header — must not be blocked.
    await agent.get('/health').expect(200);
  });

  test('blocks a disallowed origin with 403', async () => {
    const res = await agent
      .get('/health')
      .set('Origin', 'https://evil.example.com')
      .expect(403);
    assert.equal(res.body.error, 'CORS blocked');
  });
});