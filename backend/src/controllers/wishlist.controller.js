// backend/src/controllers/wishlist.controller.js
const supabase = require('../config/supabase'); // ← your actual file

// ── USER: Toggle wishlist ─────────────────────────────────────────────────
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

// ── USER: Get my wishlist ─────────────────────────────────────────────────
const getMyWishlist = async (req, res) => {
  const user_id = req.user?.id;
  if (!user_id) return res.status(401).json({ error: 'Unauthorised' });

  const { data, error } = await supabase
    .from('wishlists')
    .select(`
      id,
      created_at,
      products (
        id, name, gender, type, price, image_url, collection_id
      )
    `)
    .eq('user_id', user_id)
    .order('created_at', { ascending: false });

  if (error) return res.status(500).json({ error: error.message });
  return res.json(data);
};

// ── USER: Check single product ────────────────────────────────────────────
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

// ── ADMIN: Users who wishlisted a product ─────────────────────────────────
const getWishlistersForProduct = async (req, res) => {
  const { product_id } = req.params;

  const { data, error } = await supabase
    .from('wishlists')
    .select(`
      id,
      created_at,
      user_id,
      users:user_id (
        email,
        full_name
      )
    `)
    .eq('product_id', product_id)
    .order('created_at', { ascending: false });

  if (error) return res.status(500).json({ error: error.message });
  return res.json({ product_id, count: data.length, users: data });
};

// ── ADMIN: Wishlist summary ────────────────────────────────────────────────
const getWishlistSummary = async (req, res) => {
  const { data, error } = await supabase
    .from('wishlists')
    .select('product_id, products(name, image_url)')
    .order('product_id');

  if (error) return res.status(500).json({ error: error.message });

  const map = {};
  for (const row of data) {
    const pid = row.product_id;
    if (!map[pid]) map[pid] = { product_id: pid, product: row.products, count: 0 };
    map[pid].count++;
  }
  return res.json(Object.values(map).sort((a, b) => b.count - a.count));
};

module.exports = {
  toggleWishlist,
  getMyWishlist,
  checkWishlist,
  getWishlistersForProduct,
  getWishlistSummary,
};