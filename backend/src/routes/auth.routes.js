// src/routes/auth.routes.js
const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const { validate } = require('../middleware/validate.middleware');
const { authenticate } = require('../middleware/auth.middleware');
const {
  login, logout, refreshAdminToken,
  customerSignup, customerLogin,
  getMyOrders,
} = require('../controllers/auth.controller');

// ── Admin ─────────────────────────────────────────────────────────────────────
router.post('/login',
  [body('email').isEmail(), body('password').notEmpty(), validate],
  login
);
router.post('/logout', authenticate, logout);

// Refresh admin session – call this when a 401 is received on admin routes
router.post('/admin/refresh',
  [body('refresh_token').notEmpty().withMessage('refresh_token required'), validate],
  refreshAdminToken
);

// ── Customer ──────────────────────────────────────────────────────────────────
router.post('/customer/signup',
  [
    body('email').isEmail().withMessage('Valid email required'),
    body('password').isLength({ min: 6 }).withMessage('Password min 6 characters'),
    body('full_name').trim().notEmpty().withMessage('Name required'),
    validate,
  ],
  customerSignup
);

router.post('/customer/login',
  [body('email').isEmail(), body('password').notEmpty(), validate],
  customerLogin
);

// My orders (customer)
router.get('/customer/my-orders', authenticate, getMyOrders);

module.exports = router;