// src/routes/auth.routes.js
const express = require('express');
const router  = express.Router();
const { body } = require('express-validator');
const { validate }     = require('../middleware/validate.middleware');
const { authenticate } = require('../middleware/auth.middleware');
const {
  login, logout, refreshAdminToken,
  customerSignup, customerLogin,
  resendConfirmation, customerSession,
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
      // Must match kMinPasswordLength in
      // frontend/lib/services/password_reset_service.dart and the
      // "Minimum password length" setting in Supabase. If these disagree,
      // users pass our form and are rejected with no useful message.
      .isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
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

// ── Email verification ───────────────────────────────────────────────────────
// Re-send the "confirm your address" email after signup.
router.post('/customer/resend-confirmation',
  signupLimiter,
  [
    // Pasted addresses often carry stray whitespace or trailing newlines,
    // which would otherwise fail isEmail() for no good reason.
    body('email').trim().isEmail().withMessage('Valid email required'),
    validate,
  ],
  resendConfirmation
);

// Exchange a Supabase session (from the confirmation link) for our profile.
router.post('/customer/session',
  [body('token').notEmpty().withMessage('token required'), validate],
  customerSession
);

// My orders (customer)
router.get('/customer/my-orders', authenticate, getMyOrders);

module.exports = router;
