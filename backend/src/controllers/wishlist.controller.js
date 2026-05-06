// backend/src/controllers/wishlist.controller.js
const supabase = require('../config/supabase');

// Shared pagination helper
const paginate = (query, page, limit) => {
  const from = (page - 1) * limit;
  const to   = from + limit - 1;
  return query.range(from, to);
};

// ── USER: Toggle wishlist ─────────────────────────────────────────────────────
const toggleWishlist = async (req, res) => {
  const { product_id } = req.body;
  const user_id = req.user?.id;

  if (!user_id)    return res.status(401).json({ error: 'Unauthorised' });
  if (!product_id) return res.status(400).json({ error: 'product_id required' });

  const { data: existing } = await supabase
    .from('wishlists')
    .select('id')
    .eq('user_id', user_id)
    .eq('product_id', product_id)
    .single();

  if (existing) {
    await supabase.from('wishlists').delete().eq('id', existing.id);
    return res.json({ wishlisted: false });
  } else {
    const { error } = await supabase.from('wishlists').insert({ user_id, product_id });
    if (error) return res.status(500).json({ error: error.message });
    return res.json({ wishlisted: true });
  }
};

// ── USER: Get my wishlist (paginated) ─────────────────────────────────────────
const getMyWishlist = async (req, res) => {
  const user_id = req.user?.id;
  if (!user_id) return res.status(401).json({ error: 'Unauthorised' });

  const page  = Math.max(1, Number(req.query.page)  || 1);
  const limit = Math.min(100, Math.max(1, Number(req.query.limit) || 20));

  const baseQuery = supabase
    .from('wishlists')
    .select(`
      id, created_at,
      products ( id, name, gender, type, price, image_url, collection_id )
    `, { count: 'exact' })
    .eq('user_id', user_id)
    .order('created_at', { ascending: false });

  const { data, error, count } = await paginate(baseQuery, page, limit);

  if (error) return res.status(500).json({ error: error.message });

  const total      = count || 0;
  const totalPages = Math.ceil(total / limit);

  return res.json({
    success: true,
    data:    data || [],
    count:   total,
    pagination: { page, limit, total, totalPages },
  });
};

// ── USER: Check single product ────────────────────────────────────────────────
const checkWishlist = async (req, res) => {
  const { product_id } = req.params;
  const user_id = req.user?.id;
  if (!user_id) return res.json({ wishlisted: false });

  const { data } = await supabase
    .from('wishlists')
    .select('id')
    .eq('user_id', user_id)
    .eq('product_id', product_id)
    .single();

  return res.json({ wishlisted: !!data });
};

// ── ADMIN: Users who wishlisted a product (paginated) ────────────────────────
const getWishlistersForProduct = async (req, res) => {
  const { product_id } = req.params;
  const page  = Math.max(1, Number(req.query.page)  || 1);
  const limit = Math.min(100, Math.max(1, Number(req.query.limit) || 50));

  const baseQuery = supabase
    .from('wishlists')
    .select(`
      id, created_at, user_id,
      users:user_id ( email, full_name )
    `, { count: 'exact' })
    .eq('product_id', product_id)
    .order('created_at', { ascending: false });

  const { data, error, count } = await paginate(baseQuery, page, limit);

  if (error) return res.status(500).json({ error: error.message });

  const total      = count || 0;
  const totalPages = Math.ceil(total / limit);

  return res.json({
    product_id,
    count: total,
    users: data || [],
    pagination: { page, limit, total, totalPages },
  });
};

// ── ADMIN: Wishlist summary (paginated) ───────────────────────────────────────
// Aggregation happens server-side first, then we slice for the page.
const getWishlistSummary = async (req, res) => {
  const page  = Math.max(1, Number(req.query.page)  || 1);
  const limit = Math.min(100, Math.max(1, Number(req.query.limit) || 20));

  // Fetch all rows for aggregation — counts must be accurate across the full set
  const { data, error } = await supabase
    .from('wishlists')
    .select('product_id, products(name, image_url)')
    .order('product_id');

  if (error) return res.status(500).json({ error: error.message });

  // Aggregate in Node
  const map = {};
  for (const row of data) {
    const pid = row.product_id;
    if (!map[pid]) map[pid] = { product_id: pid, product: row.products, count: 0 };
    map[pid].count++;
  }

  const sorted = Object.values(map).sort((a, b) => b.count - a.count);
  const total  = sorted.length;
  const from   = (page - 1) * limit;
  const paged  = sorted.slice(from, from + limit);

  return res.json({
    success: true,
    data:    paged,
    count:   total,
    pagination: { page, limit, total, totalPages: Math.ceil(total / limit) },
  });
};

module.exports = {
  toggleWishlist,
  getMyWishlist,
  checkWishlist,
  getWishlistersForProduct,
  getWishlistSummary,
};
