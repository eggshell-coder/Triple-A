// backend/src/controllers/order.controller.js
const supabase = require('../config/supabase');

// ── POST /api/orders ──────────────────────────────────────────────────────────
const placeOrder = async (req, res) => {
  const {
    customer,
    items,
    note,
    delivery_charge = 0,
    user_id,
  } = req.body;

  // Read idempotency key from header (generated once per checkout screen open)
  const idempotencyKey = req.headers['idempotency-key'] || null;

  const fullName   = customer?.full_name   ?? req.body.full_name;
  const phone      = customer?.phone       ?? req.body.phone;
  const district   = customer?.district    ?? req.body.district;
  const upazila    = customer?.upazila     ?? req.body.upazila;
  const addressLine = customer?.address_line ?? req.body.address_line;

  if (!items?.length) return res.status(400).json({ success: false, error: 'items are required' });
  if (!fullName || !phone || !district || !upazila || !addressLine) {
    return res.status(400).json({
      success: false,
      error: 'full_name, phone, district, upazila, address_line are required',
    });
  }

  // Delegate the entire transaction to a Postgres RPC so it runs atomically.
  // The function handles stock checks, customer insert, order insert, item inserts,
  // stock decrement, and idempotency deduplication — all in one transaction.
  const { data, error } = await supabase.rpc('place_order_atomic', {
    p_full_name:       fullName,
    p_phone:           phone,
    p_district:        district,
    p_upazila:         upazila,
    p_address_line:    addressLine,
    p_items:           items,
    p_delivery_charge: Number(delivery_charge),
    p_note:            note || null,
    p_user_id:         user_id || null,
    p_idempotency_key: idempotencyKey,
  });

  if (error) {
    // Map Postgres-raised application errors to clean HTTP responses
    const msg = error.message || '';
    if (msg.startsWith('OUT_OF_STOCK:'))    return res.status(409).json({ success: false, error: msg });
    if (msg.startsWith('INVALID_QUANTITY:')) return res.status(400).json({ success: false, error: msg });
    return res.status(500).json({ success: false, error: msg });
  }

  // Normalize: RPC may return an array with one row or an object directly
  const result = Array.isArray(data) ? data[0] : data;

  if (result?.duplicate) {
    // Idempotent replay — same order already exists, return it
    return res.status(200).json({
      success:   true,
      duplicate: true,
      data:      { order_id: result.order_id, total_amount: result.total_amount },
    });
  }

  return res.status(201).json({
    success: true,
    data:    { order_id: result.order_id, total_amount: result.total_amount },
  });
};

// ── GET /api/auth/customer/my-orders  (customer) ──────────────────────────────
// NOTE: this function is exported here but mounted on auth.routes.js
const getMyOrders = async (req, res) => {
  const user_id = req.user?.id;
  if (!user_id) return res.status(401).json({ error: 'Unauthorised' });

  const { data, error } = await supabase
    .from('orders')
    .select(`
      id, total_amount, delivery_charge, district, upazila, status, note, created_at,
      customers ( full_name, phone, address_line ),
      order_items ( id, quantity, unit_price, products ( id, name, image_url ) )
    `)
    .eq('user_id', user_id)
    .order('created_at', { ascending: false });

  if (error) return res.status(500).json({ error: error.message });
  return res.json({ success: true, data: data || [] });
};

// ── GET /api/orders  (admin) ──────────────────────────────────────────────────
const adminGetOrders = async (req, res) => {
  const { status, page = 1, limit = 20 } = req.query;
  const from = (Number(page) - 1) * Number(limit);
  const to   = from + Number(limit) - 1;

  let query = supabase
    .from('orders')
    .select(`
      id, total_amount, delivery_charge, district, upazila, status, note, created_at,
      customers ( full_name, phone, address_line ),
      order_items ( id, quantity, unit_price, products ( id, name, image_url ) )
    `, { count: 'exact' })
    .order('created_at', { ascending: false })
    .range(from, to);

  if (status && status !== 'all') query = query.eq('status', status);

  const { data, error, count } = await query;
  if (error) return res.status(500).json({ error: error.message });
  return res.json({ success: true, data: data || [], count: count || 0 });
};

// ── GET /api/orders/:id  (admin) ──────────────────────────────────────────────
const getOrderById = async (req, res) => {
  const { data, error } = await supabase
    .from('orders')
    .select(`
      id, total_amount, delivery_charge, district, upazila, status, note, created_at,
      customers ( full_name, phone, address_line, email ),
      order_items ( id, quantity, unit_price, products ( id, name, image_url ) )
    `)
    .eq('id', req.params.id)
    .single();

  if (error || !data) return res.status(404).json({ error: 'Order not found' });
  return res.json({ success: true, data });
};

// ── PATCH /api/orders/:id/status  (admin) ────────────────────────────────────
const updateOrderStatus = async (req, res) => {
  const { status } = req.body;
  const valid = ['pending','processing','confirmed','shipped','delivered','completed','cancelled'];
  if (!valid.includes(status))
    return res.status(400).json({ error: `status must be one of: ${valid.join(', ')}` });

  const { data, error } = await supabase
    .from('orders')
    .update({ status })
    .eq('id', req.params.id)
    .select()
    .single();

  if (error) return res.status(500).json({ error: error.message });
  return res.json({ success: true, data });
};

// ── GET /api/orders/revenue-summary  (admin) ──────────────────────────────────
// Reads from the v_revenue_summary database view — no Node-side aggregation.
const getRevenueSummary = async (req, res) => {
  const { data, error } = await supabase
    .from('v_revenue_summary')
    .select('total_revenue, pending_revenue, valid_order_count, total_order_count')
    .single();

  if (error) return res.status(500).json({ error: error.message });

  return res.json({
    success: true,
    data: {
      total:       data.total_revenue,
      pending:     data.pending_revenue,
      // keep legacy 'count' key for backwards compatibility
      count:       data.valid_order_count,
      completed:   data.valid_order_count,
      total_count: data.total_order_count,
    },
  });
};

// ── GET /api/orders/product-summary  (admin) ──────────────────────────────────
// Reads from the v_product_sales_summary database view.
const getProductOrdersSummary = async (req, res) => {
  const { data, error } = await supabase
    .from('v_product_sales_summary')
    .select('*')
    .order('total_qty', { ascending: false });

  if (error) return res.status(500).json({ error: error.message });
  return res.json({ success: true, data: data || [] });
};

// ── GET /api/orders/track/:orderId  (public) ──────────────────────────────────
const trackOrder = async (req, res) => {
  const { data, error } = await supabase
    .from('orders')
    .select(`
      id, status, created_at, district, upazila,
      customers ( full_name ),
      order_items ( quantity, unit_price, products ( name, image_url ) )
    `)
    .eq('id', req.params.orderId)
    .single();

  if (error || !data) return res.status(404).json({ error: 'Order not found' });
  return res.json({ success: true, data });
};

module.exports = {
  placeOrder,
  getMyOrders,
  adminGetOrders,
  getOrderById,
  updateOrderStatus,
  getRevenueSummary,
  trackOrder,
  getProductOrdersSummary,
};
