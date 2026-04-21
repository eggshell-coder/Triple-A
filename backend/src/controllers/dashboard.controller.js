// src/controllers/dashboard.controller.js
const supabase = require('../config/supabase');
const { createError } = require('../middleware/error.middleware');

/**
 * GET /api/dashboard/stats  [Admin]
 */
const getStats = async (req, res, next) => {
  try {
    const [
      totalProductsRes,
      totalOrdersRes,
      pendingOrdersRes,
      processingOrdersRes,
      completedOrdersRes,
      cancelledOrdersRes,
      recentOrdersRes,
      revenueRes,
      lowStockRes,
    ] = await Promise.all([
      supabase.from('products').select('id', { count: 'exact', head: true }).eq('is_active', true),
      supabase.from('orders').select('id', { count: 'exact', head: true }),
      supabase.from('orders').select('id', { count: 'exact', head: true }).eq('status', 'pending'),
      supabase.from('orders').select('id', { count: 'exact', head: true }).eq('status', 'processing'),
      supabase.from('orders').select('id', { count: 'exact', head: true }).eq('status', 'completed'),
      supabase.from('orders').select('id', { count: 'exact', head: true }).eq('status', 'cancelled'),
      supabase
        .from('orders')
        .select(`id, total_amount, delivery_charge, district, status, created_at, customers ( full_name, phone )`)
        .order('created_at', { ascending: false })
        .limit(10),
      supabase.from('orders').select('total_amount').eq('status', 'completed'),
      // Low stock: active products with stock <= 5
      supabase
        .from('products')
        .select('id, name, stock, image_url, categories ( name )')
        .eq('is_active', true)
        .lte('stock', 5)
        .order('stock', { ascending: true }),
    ]);

    const totalRevenue = (revenueRes.data || []).reduce(
      (sum, o) => sum + parseFloat(o.total_amount || 0), 0
    );

    res.json({
      success: true,
      data: {
        total_products: totalProductsRes.count || 0,
        total_orders: totalOrdersRes.count || 0,
        pending_orders: pendingOrdersRes.count || 0,
        processing_orders: processingOrdersRes.count || 0,
        completed_orders: completedOrdersRes.count || 0,
        cancelled_orders: cancelledOrdersRes.count || 0,
        total_revenue: totalRevenue,
        recent_orders: recentOrdersRes.data || [],
        low_stock_products: lowStockRes.data || [],
      },
    });
  } catch (err) {
    next(err);
  }
};

module.exports = { getStats };