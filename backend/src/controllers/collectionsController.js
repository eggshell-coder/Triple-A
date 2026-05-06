// src/controllers/collectionsController.js
const supabase = require('../config/supabase');
const { collectionsCache } = require('../utils/cache');

const CACHE_CONTROL_PUBLIC = 'public, max-age=300, stale-while-revalidate=600';

const invalidateCollectionsCache = () => collectionsCache.clear();

// ── GET /api/collections  (public — active only, ordered) ────────────────────
const getCollections = async (req, res) => {
  const cached = collectionsCache.get('all');
  if (cached) {
    res.set('Cache-Control', CACHE_CONTROL_PUBLIC);
    return res.json({ success: true, data: cached });
  }

  const { data, error } = await supabase
    .from('collections')
    .select('id, name, slug, description, image')
    .eq('is_active', true)
    .order('display_order', { ascending: true });

  if (error) return res.status(500).json({ error: error.message });

  collectionsCache.set('all', data || []);
  res.set('Cache-Control', CACHE_CONTROL_PUBLIC);
  return res.json({ success: true, data: data || [] });
};

// ── GET /api/collections/:slug/products  (public) ────────────────────────────
const getCollectionBySlug = async (req, res) => {
  const { slug } = req.params;

  const cached = collectionsCache.get(slug);
  if (cached) {
    res.set('Cache-Control', CACHE_CONTROL_PUBLIC);
    return res.json({ success: true, data: cached });
  }

  const { data: collection, error: colErr } = await supabase
    .from('collections')
    .select('id, name, slug, description, image')
    .eq('slug', slug)
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

  const payload = { collection, products: products || [] };
  collectionsCache.set(slug, payload);
  res.set('Cache-Control', CACHE_CONTROL_PUBLIC);
  return res.json({ success: true, data: payload });
};

// ── GET /api/collections/admin/all  (admin — all including inactive) ──────────
const adminGetCollections = async (req, res) => {
  const { data, error } = await supabase
    .from('collections')
    .select('*')
    .order('display_order', { ascending: true });

  if (error) return res.status(500).json({ error: error.message });
  return res.json({ success: true, data: data || [] });
};

// ── POST /api/collections  (admin) ───────────────────────────────────────────
const createCollection = async (req, res) => {
  const name          = req.body.name;
  const slug          = req.body.slug;
  const description   = req.body.description;
  const image         = req.body.image || req.body.image_url;
  const display_order = req.body.display_order || req.body.sort_order || 0;

  if (!name || !slug) return res.status(400).json({ error: 'name and slug are required' });

  const { data, error } = await supabase
    .from('collections')
    .insert({ name, slug, description, image, display_order })
    .select()
    .single();

  if (error) return res.status(500).json({ error: error.message });

  invalidateCollectionsCache();
  return res.status(201).json({ success: true, data });
};

// ── PATCH /api/collections/:id  (admin) ──────────────────────────────────────
const updateCollection = async (req, res) => {
  const allowed = ['name','slug','description','image','image_url','is_active','display_order','sort_order'];
  const updates = {};

  for (const key of allowed) {
    if (req.body[key] !== undefined) {
      if (key === 'image_url')  { updates['image']         = req.body[key]; }
      else if (key === 'sort_order') { updates['display_order'] = req.body[key]; }
      else { updates[key] = req.body[key]; }
    }
  }
  delete updates['image_url'];
  delete updates['sort_order'];

  const { data, error } = await supabase
    .from('collections')
    .update(updates)
    .eq('id', req.params.id)
    .select()
    .single();

  if (error) return res.status(500).json({ error: error.message });

  invalidateCollectionsCache();
  return res.json({ success: true, data });
};

// ── DELETE /api/collections/:id  (admin) ─────────────────────────────────────
const deleteCollection = async (req, res) => {
  const { error } = await supabase.from('collections').delete().eq('id', req.params.id);
  if (error) return res.status(500).json({ error: error.message });

  invalidateCollectionsCache();
  return res.json({ success: true, message: 'Collection deleted' });
};

// ── PUT /api/collections/:id/toggle  (admin) ─────────────────────────────────
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

  invalidateCollectionsCache();
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
