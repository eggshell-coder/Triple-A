// backend/src/controllers/order.controller.js
const supabase = require('../config/supabase');

// ── POST /api/orders ──────────────────────────────────────────────────────
const placeOrder = async (req, res) => {
  const {
    user_id,
    customer,
    items,
    note,
    delivery_charge = 0,
  } = req.body;

  const fullName = customer?.full_name ?? req.body.full_name;
  const phone = customer?.phone ?? req.body.phone;
  const district = customer?.district ?? req.body.district;
  const upazila = customer?.upazila ?? req.body.upazila;
  const addressLine = customer?.address_line ?? req.body.address_line;

  if (!items?.length) return res.status(400).json({ error: 'items are required' });
  if (!fullName || !phone || !district || !upazila || !addressLine) {
    return res.status(400).json({
      error: 'full_name, phone, district, upazila, address_line are required',
    });
  }

  const productIds = items.map((i) => i.product_id);
  const { data: products, error: prodErr } = await supabase
    .from('products')
    .select('id, name, price, stock, is_active')
    .in('id', productIds);

  if (prodErr) return res.status(500).json({ error: prodErr.message });

  const productMap = new Map((products || []).map((p) => [p.id, p]));
  for (const item of items) {
    const product = productMap.get(item.product_id);
    if (!product) {
      return res.status(400).json({ error: `Product not found: ${item.product_id}` });
    }
    if (product.is_active !== true) {
      return res.status(400).json({ error: `${product.name} is not available for ordering` });
    }
    if (Number(product.stock) < Number(item.quantity)) {
      return res.status(400).json({
        error: `Only ${product.stock} unit(s) left for ${product.name}`,
      });
    }
  }

  const { data: customerRow, error: custErr } = await supabase
    .from('customers')
    .insert({
      full_name: fullName,
      phone,
      district,
      upazila,
      address_line: addressLine,
    })
    .select()
    .single();

  if (custErr) return res.status(500).json({ error: custErr.message });

  const normalizedItems = items.map((item) => {
    const product = productMap.get(item.product_id);
    return {
      product_id: item.product_id,
      quantity: Number(item.quantity),
      unit_price: Number(product?.price ?? item.unit_price),
    };
  });

  const subtotal = normalizedItems.reduce(
    (s, i) => s + (Number(i.unit_price) * Number(i.quantity)),
    0,
  );
  const total_amount = subtotal + Number(delivery_charge);

  const { data: order, error: orderErr } = await supabase
    .from('orders')
    .insert({
      customer_id: customerRow.id,
      user_id: user_id || null,
      total_amount,
      delivery_charge: Number(delivery_charge),
      district,
      upazila,
      status: 'pending',
      note: note || null,
    })
    .select()
    .single();

  if (orderErr) return res.status(500).json({ error: orderErr.message });

  const orderItems = normalizedItems.map((i) => ({
    order_id: order.id,
    product_id: i.product_id,
    quantity: i.quantity,
    unit_price: i.unit_price,
  }));

  const { error: itemsErr } = await supabase.from('order_items').insert(orderItems);
  if (itemsErr) return res.status(500).json({ error: itemsErr.message });

  for (const item of normalizedItems) {
    const product = productMap.get(item.product_id);
    const newStock = Math.max(0, Number(product.stock) - Number(item.quantity));
    const { error: stockErr } = await supabase
      .from('products')
      .update({ stock: newStock })
      .eq('id', item.product_id);

    if (stockErr) return res.status(500).json({ error: stockErr.message });
  }

  return res.status(201).json({ success: true, data: { order_id: order.id, total_amount } });
};

// ── GET /api/auth/customer/my-orders  (customer) ──────────────────────────
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

// ── GET /api/orders  (admin) ──────────────────────────────────────────────
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

// ── GET /api/orders/:id  (admin) ──────────────────────────────────────────
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

// ── PATCH /api/orders/:id/status  (admin) ────────────────────────────────
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

// ── GET /api/orders/product-summary  (admin — revenue) ────────────────────
const getRevenueSummary = async (req, res) => {
  const { data, error } = await supabase
    .from('orders')
    .select('total_amount, status, created_at')
    .neq('status', 'cancelled');

  if (error) return res.status(500).json({ error: error.message });

  const totalRevenue   = data.reduce((s, o) => s + parseFloat(o.total_amount || 0), 0);
  const pendingRevenue = data
    .filter(o => o.status === 'pending')
    .reduce((s, o) => s + parseFloat(o.total_amount || 0), 0);

  return res.json({ success: true, data: { total: totalRevenue, pending: pendingRevenue, count: data.length } });
};

// ── GET /api/orders/product-summary  (admin — per-product breakdown) ──────
const getProductOrdersSummary = async (req, res) => {
  const { data, error } = await supabase
    .from('order_items')
    .select(`
      id, quantity, unit_price,
      products ( id, name, image_url ),
      orders (
        id, status, created_at, total_amount,
        customers ( full_name, phone, address_line )
      )
    `)
    .order('id');

  if (error) return res.status(500).json({ error: error.message });

  const map = {};
  for (const item of data) {
    const product = item.products;
    if (!product) continue;
    const pid = product.id;
    if (!map[pid]) {
      map[pid] = { product, total_qty: 0, total_revenue: 0, orders: [] };
    }
    const subtotal = (item.unit_price || 0) * (item.quantity || 0);
    map[pid].total_qty     += item.quantity || 0;
    map[pid].total_revenue += subtotal;
    map[pid].orders.push({
      order_id:         item.orders?.id,
      order_date:       item.orders?.created_at,
      order_status:     item.orders?.status,
      customer_name:    item.orders?.customers?.full_name,
      customer_phone:   item.orders?.customers?.phone,
      customer_address: item.orders?.customers?.address_line,
      quantity:         item.quantity,
      subtotal,
    });
  }

  const result = Object.values(map).sort((a, b) => b.total_qty - a.total_qty);
  return res.json({ success: true, data: result });
};

// ── GET /api/orders/track/:orderId  (public) ──────────────────────────────
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