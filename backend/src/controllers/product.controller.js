// backend/src/controllers/product.controller.js
const supabase = require('../config/supabase');

const PRODUCT_SELECT = `id, name, gender, type, price, stock, is_active, image_url, description, created_at,
      collection_id, collections ( id, name, slug )`;

// ── GET /api/products ────────────────────────────────────────────────
const getProducts = async (req, res) => {
  const {
    gender,
    type,
    collection_id,
    collection_slug,
    search,
    include_inactive = 'false',
    page = 1,
    limit = 20,
  } = req.query;

  const from = (Number(page) - 1) * Number(limit);
  const to = from + Number(limit) - 1;

  let query = supabase
    .from('products')
    .select(PRODUCT_SELECT, { count: 'exact' })
    .range(from, to)
    .order('created_at', { ascending: false });

  if (include_inactive !== 'true') query = query.eq('is_active', true);
  if (gender) query = query.eq('gender', gender);
  if (type) query = query.eq('type', type);
  if (collection_id) query = query.eq('collection_id', collection_id);

  if (collection_slug && !collection_id) {
    const { data: col } = await supabase
      .from('collections')
      .select('id')
      .eq('slug', collection_slug)
      .single();

    if (!col) return res.json({ success: true, data: [], count: 0 });
    query = query.eq('collection_id', col.id);
  }

  if (search) query = query.ilike('name', `%${search}%`);

  const { data, error, count } = await query;
  if (error) return res.status(500).json({ error: error.message });
  return res.json({ success: true, data: data || [], count: count || 0 });
};

// ── GET /api/products/featured ───────────────────────────────────────
const getFeaturedProducts = async (req, res) => {
  const { data, error } = await supabase
    .from('products')
    .select(PRODUCT_SELECT)
    .eq('is_active', true)
    .order('created_at', { ascending: false })
    .limit(12);

  if (error) return res.status(500).json({ error: error.message });
  return res.json({ success: true, data: data || [] });
};

// ── GET /api/products/:id ────────────────────────────────────────────
const getProductById = async (req, res) => {
  const { data, error } = await supabase
    .from('products')
    .select(PRODUCT_SELECT)
    .eq('id', req.params.id)
    .single();

  if (error || !data) return res.status(404).json({ error: 'Product not found' });
  return res.json({ success: true, data });
};

// ── GET /api/products/admin/all  (admin) ───────────────────────────────
const getAllProductsAdmin = async (req, res) => {
  const { data, error } = await supabase
    .from('products')
    .select(PRODUCT_SELECT)
    .order('created_at', { ascending: false });

  if (error) return res.status(500).json({ error: error.message });
  return res.json({ success: true, data: data || [] });
};

// ── POST /api/products  (admin) ──────────────────────────────────────
const createProduct = async (req, res) => {
  const {
    name,
    gender,
    type,
    collection_id,
    price,
    stock = 0,
    is_active = true,
    image,
    image_url,
    description,
  } = req.body;
  const finalImage = image_url || image || null;

  if (!name || !gender || !type || !price)
    return res.status(400).json({ error: 'name, gender, type, price are required' });

  if (!['men','women'].includes(gender))
    return res.status(400).json({ error: 'gender must be men or women' });

  const validTypes = ['oversized','polo','full-sleeve','half-sleeve','drop-shoulder','basic'];
  if (!validTypes.includes(type))
    return res.status(400).json({ error: `type must be one of: ${validTypes.join(', ')}` });

  const { data, error } = await supabase
    .from('products')
    .insert({
      name,
      gender,
      type,
      collection_id: collection_id || null,
      price,
      stock: Number(stock) || 0,
      is_active: !!is_active,
      image_url: finalImage,
      description,
    })
    .select(PRODUCT_SELECT)
    .single();
  if (error) return res.status(500).json({ error: error.message });
  return res.status(201).json({ success: true, data });
};

// ── PUT /api/products/:id  (admin) ───────────────────────────────────
const updateProduct = async (req, res) => {
  const allowed = ['name','gender','type','collection_id','price','description','stock','is_active'];
  const updates = {};
  for (const key of allowed) {
    if (req.body[key] !== undefined) updates[key] = req.body[key];
  }
  // Accept image_url from frontend
  if (req.body.image_url !== undefined) updates.image_url = req.body.image_url;

  if (updates.stock !== undefined) updates.stock = Number(updates.stock) || 0;

  const { data, error } = await supabase
    .from('products')
    .update(updates)
    .eq('id', req.params.id)
    .select(PRODUCT_SELECT)
    .single();
  if (error) return res.status(500).json({ error: error.message });
  return res.json({ success: true, data });
};

// ── DELETE /api/products/:id  (admin) ────────────────────────────────
const deleteProduct = async (req, res) => {
  const { error } = await supabase.from('products').delete().eq('id', req.params.id);
  if (error) return res.status(500).json({ error: error.message });
  return res.json({ success: true, message: 'Product deleted' });
};

module.exports = { getProducts, getFeaturedProducts, getProductById, getAllProductsAdmin, createProduct, updateProduct, deleteProduct };