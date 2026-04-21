// wishlist.routes.js
const express = require('express');
const router  = express.Router();
const {
  toggleWishlist,
  getMyWishlist,
  checkWishlist,
  getWishlistersForProduct,
  getWishlistSummary,
} = require('../controllers/wishlist.controller');
const { authenticate }  = require('../middleware/auth.middleware'); // FIXED: was '../middleware/auth'
const { requireAdmin }  = require('../middleware/adminAuth');

// ── User routes ──────────────────────────────────────────────
router.post  ('/toggle',               authenticate, toggleWishlist);        // POST   /api/wishlist/toggle
router.get   ('/my',                   authenticate, getMyWishlist);          // GET    /api/wishlist/my
router.get   ('/check/:product_id',    authenticate, checkWishlist);          // GET    /api/wishlist/check/:product_id

// ── Admin routes ─────────────────────────────────────────────
router.get   ('/admin/summary',                requireAdmin, getWishlistSummary);          // GET /api/wishlist/admin/summary
router.get   ('/admin/product/:product_id',    requireAdmin, getWishlistersForProduct);    // GET /api/wishlist/admin/product/:id

module.exports = router;
