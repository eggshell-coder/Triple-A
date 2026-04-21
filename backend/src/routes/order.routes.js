// src/routes/order.routes.js — FIXED
const express  = require('express');
const router   = express.Router();
const { body } = require('express-validator');
const { validate }     = require('../middleware/validate.middleware');
const { authenticate } = require('../middleware/auth.middleware');
const {
  placeOrder,
  trackOrder,
  adminGetOrders,
  getOrderById,
  updateOrderStatus,
  getRevenueSummary,
  getProductOrdersSummary,
} = require('../controllers/order.controller');

// ── Public ─────────────────────────────────────────────────────────────────
router.post('/',
  [
    body('customer.full_name').trim().notEmpty().withMessage('Full name required'),
    body('customer.phone').trim().notEmpty().withMessage('Phone number required'),
    body('items').isArray({ min: 1 }).withMessage('At least one item required'),
    body('items.*.product_id').notEmpty().withMessage('Product ID required'),
    body('items.*.quantity').isInt({ min: 1 }).withMessage('Quantity must be at least 1'),
    validate,
  ],
  placeOrder
);

router.get('/track/:orderId', trackOrder);

// ── Admin ───────────────────────────────────────────────────────────────────
router.get('/product-summary', authenticate, getProductOrdersSummary);
router.get('/',                authenticate, adminGetOrders);
router.get('/:id',             authenticate, getOrderById);
router.patch('/:id/status',    authenticate,
  [body('status').notEmpty().withMessage('Status required'), validate],
  updateOrderStatus
);

module.exports = router;
