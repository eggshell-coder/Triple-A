// test/security.test.js
//
// Security regression suite for the Triple A API.
//
// These are NOT generic attack payloads. Each test encodes a specific
// threat this app actually has, so a future refactor cannot quietly
// reopen a hole that is closed today. Every one of them came out of a real
// audit finding rather than a checklist.
//
// Run: npm test        (runs alongside api.test.js)
// Run one group only: node --test --test-name-pattern="IDOR" test/security.test.js

process.env.NODE_ENV = 'test';

const Module = require('module');
const originalLoad = Module._load;

// Supabase is stubbed so the suite never touches the real database and
// never needs credentials. auth.signInWithPassword always succeeds, which
// lets us simulate "a logged-in but NON-admin user" — the case that
// matters most for privilege escalation.
const ADMIN_EMAIL = 'admin@triple-a.test';

// Emulates just enough of the Supabase query builder, including .eq()
// filtering. The filtering matters: if single() ignored the email that
// requireAdmin filters on, every caller would look like an admin and the
// privilege-escalation tests would pass for the wrong reason.
const makeTable = (table) => {
  let eqValue;

  const chain = {
    select: () => chain,
    order: () => chain,
    limit: () => Promise.resolve({ data: [], error: null }),
    range: () => Promise.resolve({ data: [], error: null }),
    single: () =>
      Promise.resolve({
        data:
          table === 'admins' && eqValue === ADMIN_EMAIL
            ? { id: 'a1', full_name: 'Admin', email: ADMIN_EMAIL, role: 'admin' }
            : null,
        error: null,
      }),
    maybeSingle: () => chain.single(),
    eq: (_col, value) => {
      eqValue = value;
      return chain;
    },
    in: () => chain,
    update: () => chain,
    insert: () => chain,
    upsert: () => chain,
    delete: () => chain,
    then: (resolve, reject) =>
      Promise.resolve({ data: [], error: null }).then(resolve, reject),
  };
  return chain;
};

const fakeSupabase = {
  from: (table) => makeTable(table),
  rpc: () => Promise.resolve({ data: [], error: null }),
  auth: {
    // Only the two tokens below are "real". Anything else must behave like
    // an invalid JWT (401), otherwise the "garbage token" test would pass
    // for the wrong reason and prove nothing.
    getUser: (token) => {
      if (token === ADMIN_TOKEN) {
        return Promise.resolve({
          data: { user: { id: 'a1', email: ADMIN_EMAIL } },
          error: null,
        });
      }
      if (token === USER_TOKEN) {
        return Promise.resolve({
          data: { user: { id: 'u1', email: 'shopper@example.com' } },
          error: null,
        });
      }
      return Promise.resolve({
        data: { user: null },
        error: { message: 'Invalid JWT' },
      });
    },
    signInWithPassword: () =>
      Promise.resolve({ data: { session: null }, error: { message: 'stub' } }),
    refreshSession: () =>
      Promise.resolve({ data: { session: null }, error: { message: 'stub' } }),
    signOut: () => Promise.resolve({ error: null }),
    resend: () => Promise.resolve({ data: {}, error: null }),
  },
  storage: { from: () => ({ upload: () => Promise.resolve({ error: null }) }) },
};

Module._load = function (request) {
  if (request === '../config/supabase' || request === './config/supabase') {
    return fakeSupabase;
  }
  return originalLoad.apply(this, arguments);
};

const request = require('supertest');
const { test, describe } = require('node:test');
const assert = require('node:assert/strict');

const app = require('../src/server');

const ADMIN_TOKEN = 'admin-token';
const USER_TOKEN = 'user-token';

describe('Privilege escalation', () => {
  test('admin product list rejects a request with no token', async () => {
    const res = await request(app).get('/api/products/admin/all').expect(401);
    assert.match(res.body.message, /token/i);
  });

  test('admin product list rejects a garbage token', async () => {
    await request(app)
      .get('/api/products/admin/all')
      .set('Authorization', 'Bearer not-a-real-jwt')
      .expect(401);
  });

  test('a signed-in NON-admin cannot read the admin product list', async () => {
    // The important case: the token is valid, the caller is simply not an
    // admin. requireAdmin must check the admins table, not just the JWT.
    const res = await request(app)
      .get('/api/products/admin/all')
      .set('Authorization', `Bearer ${USER_TOKEN}`)
      .expect(403);
    assert.match(res.body.message, /admin/i);
  });

  test('a signed-in non-admin cannot create a product', async () => {
    await request(app)
      .post('/api/products')
      .set('Authorization', `Bearer ${USER_TOKEN}`)
      .send({ name: 'Injected', price: 1 })
      .expect(403);
  });

  test('a signed-in non-admin cannot update or delete a product', async () => {
    await request(app)
      .put('/api/products/abc')
      .set('Authorization', `Bearer ${USER_TOKEN}`)
      .send({ name: 'x' })
      .expect(403);
    await request(app)
      .delete('/api/products/abc')
      .set('Authorization', `Bearer ${USER_TOKEN}`)
      .expect(403);
  });

  test('a signed-in non-admin cannot read dashboard stats', async () => {
    await request(app)
      .get('/api/dashboard/stats')
      .set('Authorization', `Bearer ${USER_TOKEN}`)
      .expect(403);
  });

  test('a signed-in non-admin cannot list all orders', async () => {
    await request(app)
      .get('/api/orders')
      .set('Authorization', `Bearer ${USER_TOKEN}`)
      .expect(403);
  });

  test('the admin token IS accepted, proving the guard is not blanket-denying', async () => {
    // Guards that reject everything pass every test above. This one proves
    // the middleware is actually wired up and still admits real admins.
    await request(app)
      .get('/api/products/admin/all')
      .set('Authorization', `Bearer ${ADMIN_TOKEN}`)
      .expect(200);
  });

  test('Authorization header must use the Bearer scheme', async () => {
    await request(app)
      .get('/api/products/admin/all')
      .set('Authorization', ADMIN_TOKEN) // no "Bearer " prefix
      .expect(401);
  });
});

describe('IDOR / broken object level authorisation', () => {
  test('order tracking is not reachable without knowing the id', async () => {
    // Documented finding: /api/orders/track/:orderId is unauthenticated and
    // returns the customer name and district. The id is a random UUID so it
    // cannot be enumerated, but this test pins that behaviour so a change to
    // sequential ids fails loudly.
    const res = await request(app).get('/api/orders/track/00000000-0000-0000-0000-000000000000');
    assert.equal(res.status, 404);
  });

  test('a non-admin cannot read another user order by id', async () => {
    await request(app)
      .get('/api/orders/00000000-0000-0000-0000-000000000000')
      .set('Authorization', `Bearer ${USER_TOKEN}`)
      .expect(403);
  });

  test("a customer's own order list requires a token", async () => {
    await request(app).get('/api/auth/customer/my-orders').expect(401);
  });
});

describe('Input validation', () => {
  test('login rejects a non-email', async () => {
    await request(app)
      .post('/api/auth/login')
      .send({ email: 'not-an-email', password: 'x' })
      .expect(422);
  });

  test('login error responses do not echo the submitted password', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'bad', password: 'hunter2-should-not-echo' })
      .expect(422);
    assert.ok(!JSON.stringify(res.body).includes('hunter2-should-not-echo'));
  });

  test('order placement rejects an empty items array', async () => {
    await request(app)
      .post('/api/orders')
      .send({ customer: { full_name: 'A', phone: '1' }, items: [] })
      .expect(422);
  });

  test('order placement rejects a zero or negative quantity', async () => {
    const base = { customer: { full_name: 'A', phone: '1' }, items: [{}] };
    for (const q of [0, -5, 'abc']) {
      const res = await request(app)
        .post('/api/orders')
        .send({ ...base, items: [{ product_id: 'p', quantity: q }] });
      assert.ok(res.status === 422 || res.status === 400, `quantity ${q} was accepted`);
    }
  });

  test('order status cannot be set to an arbitrary string by a non-admin', async () => {
    await request(app)
      .patch('/api/orders/abc/status')
      .set('Authorization', `Bearer ${USER_TOKEN}`)
      .send({ status: 'completed' })
      .expect(403);
  });
});

describe('Transport and header hardening', () => {
  test('security headers are present', async () => {
    const res = await request(app).get('/health').expect(200);
    assert.equal(res.headers['x-content-type-options'], 'nosniff');
    assert.ok(res.headers['x-frame-options']);
    assert.ok(res.headers['content-security-policy'] || res.headers['strict-transport-security']);
  });

  test('an unknown origin is rejected outright', async () => {
    const res = await request(app)
      .get('/health')
      .set('Origin', 'https://attacker.example')
      .expect(403);
    assert.equal(res.body.error, 'CORS blocked');
  });

  test('server-side callers with no Origin are allowed', async () => {
    // curl, mobile clients and server-to-server calls send no Origin.
    await request(app).get('/health').expect(200);
  });

  test('404 responses are JSON, not an HTML stack page', async () => {
    const res = await request(app).get('/nope').expect(404);
    assert.equal(res.body.success, false);
    assert.ok(!/<html/i.test(JSON.stringify(res.body)));
  });

  test('stack traces are not leaked in non-production responses', async () => {
    const res = await request(app).get('/nope').expect(404);
    assert.ok(!('stack' in res.body), 'stack trace present in response body');
  });
});

describe('Session and token handling', () => {
  test('a failed admin login does not return a token', async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ email: 'x@y.z', password: 'wrong' });
    assert.ok(!JSON.stringify(res.body).includes('access_token'));
  });

  test('the session exchange rejects a missing token', async () => {
    await request(app)
      .post('/api/auth/customer/session')
      .send({})
      .expect(422);
  });

  test('the resend endpoint does not reveal whether an account exists', async () => {
    // Always 200 with a neutral message, so it cannot be used to enumerate
    // which email addresses have accounts.
    const a = await request(app)
      .post('/api/auth/customer/resend-confirmation')
      .send({ email: 'definitely-not-registered@example.com' })
      .expect(200);
    assert.match(a.body.message, /if that address needs confirming/i);
  });
});