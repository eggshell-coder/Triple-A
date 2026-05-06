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

// ── Customer signup ───────────────────────────────────────────────────────────
const customerSignup = async (req, res, next) => {
  try {
    const { email, password, full_name } = req.body;

    const { data, error } = await supabase.auth.signUp({ email, password });
    if (error) return next(createError(error.message, 400));

    const userId = data.user?.id;
    if (!userId) return next(createError('Signup failed', 500));

    await supabase.from('users').upsert([{ id: userId, email, full_name }]);

    res.status(201).json({
      success: true,
      message: 'Account created successfully',
      data: {
        token: data.session?.access_token || null,
        user:  { id: userId, email, full_name },
      },
    });
  } catch (err) { next(err); }
};

// ── Customer login ────────────────────────────────────────────────────────────
const customerLogin = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    const { data, error } = await supabase.auth.signInWithPassword({ email, password });
    if (error) return next(createError('Invalid email or password', 401));

    const { data: userProfile } = await supabase
      .from('users').select('id, email, full_name, phone').eq('id', data.user.id).single();

    if (!userProfile) return next(createError('No customer account found', 403));

    res.json({ success: true, data: { token: data.session.access_token, user: userProfile } });
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

module.exports = { login, logout, refreshAdminToken, customerSignup, customerLogin, getMyOrders };
