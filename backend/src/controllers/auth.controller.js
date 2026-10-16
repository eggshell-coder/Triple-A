// src/controllers/auth.controller.js
const supabase = require('../config/supabase');
const { createError } = require('../middleware/error.middleware');

// ── Admin login ───────────────────────────────────────────────────────────────
const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) return next(createError('Invalid credentials', 401));

    const { data: adminProfile, error: profileError } = await supabase
      .from('admins').select('id, full_name, email, role').eq('email', email).single();

    if (profileError || !adminProfile)
      return next(createError('Access denied – not an admin account', 403));

    res.json({
      success: true,
      data: {
        token:         data.session.access_token,
        refresh_token: data.session.refresh_token,
        user:          adminProfile,
      },
    });
  } catch (err) { next(err); }
};

const logout = async (req, res, next) => {
  try {
    await supabase.auth.signOut();
    res.json({ success: true, message: 'Logged out' });
  } catch (err) { next(err); }
};

// ── Admin token refresh ───────────────────────────────────────────────────────
const refreshAdminToken = async (req, res, next) => {
  try {
    const { refresh_token } = req.body;
    if (!refresh_token) return next(createError('refresh_token required', 400));

    const { data, error } = await supabase.auth.refreshSession({ refresh_token });
    if (error || !data.session)
      return next(createError('Session expired – please log in again', 401));

    const { data: adminProfile, error: profileError } = await supabase
      .from('admins').select('id, full_name, email, role').eq('email', data.user.email).single();

    if (profileError || !adminProfile)
      return next(createError('Access denied – not an admin account', 403));

    res.json({
      success: true,
      data: {
        token:         data.session.access_token,
        refresh_token: data.session.refresh_token,
        user:          adminProfile,
      },
    });
  } catch (err) { next(err); }
};

// Where the confirmation link should send the user back to.
//
// Supabase APPENDS its token to this URL. Because the Flutter web app uses
// hash routing, pointing this at a "/#/route" path would bury the appended
// `?code=` inside the fragment where it cannot be read. So we send the user
// to the bare frontend origin and let the app route itself.
const frontendOrigin = (req) =>
  process.env.FRONTEND_URL ||
  (req.headers.origin && /^https?:\/\//.test(req.headers.origin)
    ? req.headers.origin
    : 'http://localhost:5000');

// ── Email-confirmation helpers ────────────────────────────────────────────────
//
// Supabase decides whether a signup needs an email click. Two outcomes:
//   • "Confirm email" ON  → signUp returns a user but NO session, and
//                            email_confirmed_at is null until they click.
//   • "Confirm email" OFF → signUp returns a session immediately.
//
// We copy that state into public.users so the app can read it.

/** Writes the auth user's confirmation state onto the public profile row. */
const syncProfile = async (authUser, { full_name } = {}) => {
  if (!authUser?.id) return null;

  const row = {
    id: authUser.id,
    email: authUser.email,
    full_name: full_name ?? undefined,
    email_confirmed_at: authUser.email_confirmed_at || null,
  };
  // `undefined` leaves the existing column untouched on upsert.
  for (const k of Object.keys(row)) {
    if (row[k] === undefined) delete row[k];
  }

  const { data, error } = await supabase
    .from('users')
    .upsert([row])
    .select('id, email, full_name, phone, email_confirmed_at')
    .single();

  if (error) {
    // Loud, because a silent fallback here means accounts exist in Auth but
    // not in our profile table — hard to notice, easy to lose data.
    console.error('syncProfile upsert failed:', error.message, JSON.stringify(row));
    // A missing email_confirmed_at column means the migration has not been
    // run yet. Fall back to a non-upserting update so signups still work.
    const { data: fallback } = await supabase
      .from('users')
      .select('id, email, full_name, phone')
      .eq('id', authUser.id)
      .maybeSingle();
    return fallback || { id: authUser.id, email: authUser.email, full_name };
  }
  return data;
};

// ── Customer signup ───────────────────────────────────────────────────────────
//
// Two modes, chosen by the AUTO_CONFIRM_EMAIL env flag:
//
//   false (default) — Supabase emails a confirmation link and the user signs
//                     in after clicking it. Requires working SMTP; the free
//                     tier only sends a couple of emails per hour, which is
//                     easy to exhaust while testing.
//
//   true            — the service-role key marks the address confirmed
//                     immediately. No email is sent, so no rate limit, and
//                     signup finishes with the user already signed in. Works
//                     on the free tier.
const autoConfirmEmail = () =>
  String(process.env.AUTO_CONFIRM_EMAIL || '').toLowerCase() === 'true';

const customerSignup = async (req, res, next) => {
  try {
    const { email, password, full_name } = req.body;

    const redirectTo = `${frontendOrigin(req)}/?flow=signup`;
    let data;

    if (autoConfirmEmail()) {
      // admin.createUser needs the service-role key, which only the backend
      // has — that is what makes auto-confirm possible here at all.
      const created = await supabase.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: { full_name },
      });

      if (created.error) {
        // "already registered" is the common one; keep the message honest.
        return next(createError(created.error.message, 400));
      }

      // admin.createUser never returns a session, so mint one now. This is
      // what lets the app go straight to the homepage.
      const signedIn = await supabase.auth.signInWithPassword({ email, password });
      if (signedIn.error || !signedIn.data?.session) {
        // The account exists and is confirmed; the user can simply log in.
        return next(createError('Account created. Please sign in.', 401));
      }

      data = {
        user: created.data.user,
        session: signedIn.data.session,
      };
    } else {
      const signedUp = await supabase.auth.signUp({
        email,
        password,
        options: {
          // Bare origin + flow marker: Supabase appends ?code=… to it, and a
          // hash route here would swallow that into the fragment.
          emailRedirectTo: redirectTo,
        },
      });
      if (signedUp.error) return next(createError(signedUp.error.message, 400));
      data = signedUp.data;
    }

    const userId = data.user?.id;
    if (!userId) return next(createError('Signup failed', 500));

    // A session here means Supabase confirmed the email itself (confirmation
    // disabled), so the user is fully logged in.
    const signedInImmediately = Boolean(data.session);

    const user = await syncProfile(data.user, { full_name });

    res.status(201).json({
      success: true,
      message: signedInImmediately
        ? 'Account created successfully'
        : 'Account created — check your email to confirm it',
      data: {
        token:   data.session?.access_token || null,
        user,
        email_confirmation_required: !signedInImmediately,
        email_confirmed: Boolean(data.user.email_confirmed_at) || signedInImmediately,
      },
    });
  } catch (err) { next(err); }
};

// ── Resend the confirmation email ─────────────────────────────────────────────
const resendConfirmation = async (req, res, next) => {
  try {
    const { email } = req.body;

    // Always answer 200. Reporting "no such user" would let anyone probe
    // which addresses have accounts.
    const { error } = await supabase.auth.resend({ type: 'signup', email });
    if (error) console.warn('resend failed:', error.message);

    res.json({
      success: true,
      message: 'If that address needs confirming, a new link is on its way.',
    });
  } catch (err) { next(err); }
};

// ── Exchange a Supabase session for our customer profile ──────────────────────
//
// Used after the user clicks the confirmation link: the browser holds a
// valid Supabase session, and we swap it for our own profile + token.
const customerSession = async (req, res, next) => {
  try {
    const { token } = req.body;
    if (!token) return next(createError('token required', 400));

    const { data, error } = await supabase.auth.getUser(token);
    if (error || !data?.user) return next(createError('Invalid or expired session', 401));

    // Re-sync so clicking the link is what flips email_confirmed_at in the DB.
    const user = await syncProfile(data.user);
    if (!user) return next(createError('No customer account found', 403));

    res.json({
      success: true,
      data: { user, email_confirmed: Boolean(data.user.email_confirmed_at) },
    });
  } catch (err) { next(err); }
};

// ── Customer login ────────────────────────────────────────────────────────────
const customerLogin = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) return next(createError('Invalid email or password', 401));

    // Keep the mirror row in step on every login — this is what marks an
    // account confirmed the first time a verified user signs in.
    const userProfile = await syncProfile(data.user);

    if (!userProfile) return next(createError('No customer account found', 403));

    res.json({
      success: true,
      data: {
        token: data.session.access_token,
        refresh_token: data.session.refresh_token,
        user: userProfile,
        email_confirmed: Boolean(data.user.email_confirmed_at),
      },
    });
  } catch (err) { next(err); }
};

// ── My orders (customer — paginated) ─────────────────────────────────────────
const getMyOrders = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const page   = Math.max(1, Number(req.query.page)  || 1);
    const limit  = Math.min(100, Math.max(1, Number(req.query.limit) || 20));
    const from   = (page - 1) * limit;
    const to     = from + limit - 1;

    const { data: orders, error, count } = await supabase
      .from('orders')
      .select(`
        id, total_amount, delivery_charge, district, status, note, created_at,
        order_items ( id, quantity, unit_price, products ( id, name, image_url ) )
      `, { count: 'exact' })
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .range(from, to);

    if (error) return next(createError(error.message));

    const total      = count || 0;
    const totalPages = Math.ceil(total / limit);

    res.json({
      success: true,
      data:    orders || [],
      count:   total,
      pagination: { page, limit, total, totalPages },
    });
  } catch (err) { next(err); }
};

module.exports = {
  login,
  logout,
  refreshAdminToken,
  customerSignup,
  customerLogin,
  resendConfirmation,
  customerSession,
  getMyOrders,
};
