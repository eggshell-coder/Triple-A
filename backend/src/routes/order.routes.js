// src/routes/order.routes.js
const express  = require('express');
const router   = express.Router();
const { body } = require('express-validator');
const { validate }      = require('../middleware/validate.middleware');
const { requireAdmin }  = require('../middleware/adminAuth');
const {
  placeOrder,
  trackOrder,
  adminGetOrders,
  getOrderById,
  updateOrderStatus,
  getRevenueSummary,
  getProductOrdersSummary,
} = require('../controllers/order.controller');

// Pull order rate-limiter registered in server.js
const orderLimiter = (req, res, next) => req.app.locals.orderLimiter(req, res, next);

// ── Public ────────────────────────────────────────────────────────────────────
router.post('/',
  orderLimiter,
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

// ── Admin ─────────────────────────────────────────────────────────────────────
router.get('/revenue-summary',  requireAdmin, getRevenueSummary);
router.get('/product-summary',  requireAdmin, getProductOrdersSummary);
router.get('/',                 requireAdmin, adminGetOrders);
router.get('/:id',              requireAdmin, getOrderById);
router.patch('/:id/status',     requireAdmin,
  [body('status').notEmpty().withMessage('Status required'), validate],
  updateOrderStatus
);

module.exports = router;
