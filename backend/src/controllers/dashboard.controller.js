// src/controllers/dashboard.controller.js
const supabase = require('../config/supabase');
const { createError } = require('../middleware/error.middleware');

/**
 * GET /api/dashboard/stats  [Admin]
 *
 * Aggregated counts come from a single get_dashboard_stats() RPC so Postgres
 * does the work instead of Node fetching every row.
 * The two bounded list queries (recent orders, low-stock products) are kept
 * as direct table reads because they are not aggregations.
 */
const getStats = async (req, res, next) => {
  try {
    const [rpcRes, recentOrdersRes, lowStockRes] = await Promise.all([
      supabase.rpc('get_dashboard_stats'),
      supabase
        .from('orders')
        .select('id, total_amount, delivery_charge, district, status, created_at, customers ( full_name, phone )')
        .order('created_at', { ascending: false })
        .limit(10),
      supabase
        .from('products')
        .select('id, name, stock, image_url, categories ( name )')
        .eq('is_active', true)
        .lte('stock', 5)
        .order('stock', { ascending: true }),
    ]);

    if (rpcRes.error) return next(createError(rpcRes.error.message));

    // RPC may return an array with one row or an object directly — handle both
    const stats = Array.isArray(rpcRes.data) ? rpcRes.data[0] : rpcRes.data;

    res.json({
      success: true,
      data: {
        total_products:    stats?.total_products    ?? 0,
        total_orders:      stats?.total_orders      ?? 0,
        pending_orders:    stats?.pending_orders    ?? 0,
        processing_orders: stats?.processing_orders ?? 0,
        completed_orders:  stats?.completed_orders  ?? 0,
        cancelled_orders:  stats?.cancelled_orders  ?? 0,
        total_revenue:     stats?.total_revenue     ?? 0,
        recent_orders:     recentOrdersRes.data     || [],
        low_stock_products: lowStockRes.data        || [],
      },
    });
  } catch (err) {
    next(err);
  }
};

module.exports = { getStats };
