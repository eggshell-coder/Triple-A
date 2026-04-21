// collection.controller.js  (updated — now primary content feature)
const supabase = require('../config/supabase');

// ── GET /api/collections  (public — active only, ordered) ────────────────
const getCollections = async (req, res) => {
  const { data, error } = await supabase
    .from('collections')
    .select('id, name, slug, description, image')
    .eq('is_active', true)
    .order('display_order', { ascending: true });

  if (error) return res.status(500).json({ error: error.message });
  return res.json({ success: true, data: data || [] });
};

// ── GET /api/collections/:slug/products  (public) ────────────────────────
const getCollectionBySlug = async (req, res) => {
  const { data: collection, error: colErr } = await supabase
    .from('collections')
    .select('id, name, slug, description, image')
    .eq('slug', req.params.slug)
    .eq('is_active', true)
    .single();

  if (colErr || !collection) return res.status(404).json({ error: 'Collection not found' });

  const { data: products, error: prodErr } = await supabase
    .from('products')
    .select('id, name, gender, type, price, stock, image, image_url, description')
    .eq('collection_id', collection.id)
    .eq('is_active', true)
    .order('created_at', { ascending: false });

  if (prodErr) return res.status(500).json({ error: prodErr.message });
  return res.json({ success: true, data: { collection, products: products || [] } });
};

// ── GET /api/admin/collections  (admin — all including inactive) ──────────
const adminGetCollections = async (req, res) => {
  const { data, error } = await supabase
    .from('collections')
    .select('*')
    .order('display_order', { ascending: true });

  if (error) return res.status(500).json({ error: error.message });
  return res.json({ success: true, data: data || [] });
};

// ── POST /api/admin/collections ───────────────────────────────────────────
const createCollection = async (req, res) => {
  const { name, slug, description, image, display_order } = req.body;
  if (!name || !slug) return res.status(400).json({ error: 'name and slug are required' });

  const { data, error } = await supabase
    .from('collections')
    .insert({ name, slug, description, image, display_order: display_order || 0 })
    .select()
    .single();

  if (error) return res.status(500).json({ error: error.message });
  return res.status(201).json({ success: true, data });
};

// ── PUT /api/admin/collections/:id ────────────────────────────────────────
const updateCollection = async (req, res) => {
  const allowed = ['name','slug','description','image','is_active','display_order'];
  const updates = {};
  for (const key of allowed) {
    if (req.body[key] !== undefined) updates[key] = req.body[key];
  }

  const { data, error } = await supabase
    .from('collections')
    .update(updates)
    .eq('id', req.params.id)
    .select()
    .single();

  if (error) return res.status(500).json({ error: error.message });
  return res.json({ success: true, data });
};

// ── DELETE /api/admin/collections/:id ────────────────────────────────────
const deleteCollection = async (req, res) => {
  // Products with this collection_id will be set to NULL via ON DELETE SET NULL
  const { error } = await supabase.from('collections').delete().eq('id', req.params.id);
  if (error) return res.status(500).json({ error: error.message });
  return res.json({ success: true, message: 'Collection deleted' });
};

// ── PUT /api/admin/collections/:id/toggle ────────────────────────────────
const toggleCollection = async (req, res) => {
  const { data: current } = await supabase
    .from('collections')
    .select('is_active')
    .eq('id', req.params.id)
    .single();

  const { data, error } = await supabase
    .from('collections')
    .update({ is_active: !current?.is_active })
    .eq('id', req.params.id)
    .select()
    .single();

  if (error) return res.status(500).json({ error: error.message });
  return res.json({ success: true, data });
};

module.exports = {
  getCollections,
  getCollectionBySlug,
  adminGetCollections,
  createCollection,
  updateCollection,
  deleteCollection,
  toggleCollection,
};