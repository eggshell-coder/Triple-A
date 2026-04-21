// product.routes.js  (updated)
const express = require('express');
const router  = express.Router();
const {
  getProducts,
  getFeaturedProducts,
  getProductById,
  getAllProductsAdmin,
  createProduct,
  updateProduct,
  deleteProduct,
} = require('../controllers/product.controller');
const { requireAdmin } = require('../middleware/adminAuth');

// ── Public ───────────────────────────────────────────────────
router.get('/',             getProducts);          // GET /api/products?gender=men&type=polo
router.get('/featured',     getFeaturedProducts);  // GET /api/products/featured  ← replaces /new-arrivals
router.get('/admin/all',    requireAdmin, getAllProductsAdmin);
router.get('/:id',          getProductById);       // GET /api/products/:id

// REMOVED: router.get('/new-arrivals', ...) ← intentionally deleted

// ── Admin ────────────────────────────────────────────────────
router.post  ('/',    requireAdmin, createProduct);   // POST   /api/admin/products
router.put   ('/:id', requireAdmin, updateProduct);   // PUT    /api/admin/products/:id
router.delete('/:id', requireAdmin, deleteProduct);   // DELETE /api/admin/products/:id

module.exports = router;