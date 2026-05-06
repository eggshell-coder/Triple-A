// src/routes/auth.routes.js
const express = require('express');
const router  = express.Router();
const { body } = require('express-validator');
const { validate }     = require('../middleware/validate.middleware');
const { authenticate } = require('../middleware/auth.middleware');
const {
  login, logout, refreshAdminToken,
  customerSignup, customerLogin,
  getMyOrders,
} = require('../controllers/auth.controller');

// Pull tuned limiters registered in server.js
const loginLimiter  = (req, res, next) => req.app.locals.loginLimiter(req, res, next);
const signupLimiter = (req, res, next) => req.app.locals.signupLimiter(req, res, next);

// ── Admin ─────────────────────────────────────────────────────────────────────
router.post('/login',
  loginLimiter,
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
  signupLimiter,
  [
    body('email').isEmail().withMessage('Valid email required'),
    body('password')
      .isLength({ min: 8 }).withMessage('Password must be at least 8 characters')
      .matches(/[A-Z]/).withMessage('Password must contain at least one uppercase letter')
      .matches(/[0-9]/).withMessage('Password must contain at least one digit'),
    body('full_name').trim().notEmpty().withMessage('Name required'),
    validate,
  ],
  customerSignup
);

router.post('/customer/login',
  loginLimiter,
  [body('email').isEmail(), body('password').notEmpty(), validate],
  customerLogin
);

// My orders (customer)
router.get('/customer/my-orders', authenticate, getMyOrders);

module.exports = router;
