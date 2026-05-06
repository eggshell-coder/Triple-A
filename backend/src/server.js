// src/server.js
require('dotenv').config();
const express   = require('express');
const cors      = require('cors');
const helmet    = require('helmet');
const morgan    = require('morgan');
const rateLimit = require('express-rate-limit');
const supabase  = require('./config/supabase');

const authRoutes        = require('./routes/auth.routes');
const productRoutes     = require('./routes/product.routes');
const categoryRoutes    = require('./routes/category.routes');
const orderRoutes       = require('./routes/order.routes');
const dashboardRoutes   = require('./routes/dashboard.routes');
const uploadRoutes      = require('./routes/upload.routes');
const collectionsRoutes = require('./routes/collectionsRoutes');
const wishlistRoutes    = require('./routes/wishlist.routes');
const errorHandler      = require('./middleware/error.middleware');

const app  = express();
const PORT = process.env.PORT || 5000;

// ── Security ──────────────────────────────────────────────────────────────────
app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));

// ── CORS — env-driven allow-list ──────────────────────────────────────────────
const allowedOrigins = (process.env.CORS_ORIGIN || '')
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean);

const corsOptions = {
  origin(origin, callback) {
    // Allow requests with no origin (mobile apps, curl, same-origin SSR)
    if (!origin) return callback(null, true);
    if (allowedOrigins.includes(origin)) return callback(null, true);
    const err    = new Error(`CORS blocked: ${origin}`);
    err.status   = 403;
    err.code     = 'CORS_BLOCKED';
    err.origin   = origin;
    callback(err);
  },
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Idempotency-Key'],
  credentials: true,
};

app.use(cors(corsOptions));
app.options('*', cors(corsOptions));

// ── Rate limiters ─────────────────────────────────────────────────────────────
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, max: 5, skipSuccessfulRequests: true,
  standardHeaders: true, legacyHeaders: false,
  message: { success: false, message: 'Too many login attempts – try again in 15 minutes.' },
});

const signupLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, max: 3,
  standardHeaders: true, legacyHeaders: false,
  message: { success: false, message: 'Too many signup attempts – try again in an hour.' },
});

const uploadLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, max: 20,
  standardHeaders: true, legacyHeaders: false,
  message: { success: false, message: 'Upload limit reached – try again in an hour.' },
});

const orderLimiter = rateLimit({
  windowMs: 60 * 1000, max: 5,
  standardHeaders: true, legacyHeaders: false,
  message: { success: false, message: 'Too many order requests – slow down.' },
});

const browseLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, max: 1000,
  standardHeaders: true, legacyHeaders: false,
  message: { success: false, message: 'Too many requests – please try again later.' },
});

// Make limiters available to route files via app.locals
app.locals.loginLimiter  = loginLimiter;
app.locals.signupLimiter = signupLimiter;
app.locals.uploadLimiter = uploadLimiter;
app.locals.orderLimiter  = orderLimiter;

// ── Body Parsing ──────────────────────────────────────────────────────────────
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// ── Logging ───────────────────────────────────────────────────────────────────
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('dev'));
}

// ── Health Check — pings the database ────────────────────────────────────────
app.get('/health', async (req, res) => {
  try {
    const { error } = await supabase.from('products').select('id').limit(1);
    if (error) throw error;
    res.json({ success: true, db: 'ok', timestamp: new Date().toISOString() });
  } catch (err) {
    res.status(503).json({ success: false, db: 'down', error: err.message });
  }
});

// ── Routes ────────────────────────────────────────────────────────────────────
// login/signup/upload/order limiters are mounted inside their own route files
app.use('/api/auth',        authRoutes);
app.use('/api/products',    browseLimiter, productRoutes);
app.use('/api/categories',  browseLimiter, categoryRoutes);
app.use('/api/orders',      orderRoutes);
app.use('/api/dashboard',   dashboardRoutes);
app.use('/api/upload',      uploadRoutes);
app.use('/api/collections', browseLimiter, collectionsRoutes);
app.use('/api/wishlist',    browseLimiter, wishlistRoutes);

// ── 404 ───────────────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Route not found' });
});

// ── CORS-blocked → clean 403 (must come before generic error handler) ─────────
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
  if (err.code === 'CORS_BLOCKED') {
    return res.status(403).json({ success: false, error: 'CORS blocked', origin: err.origin });
  }
  next(err);
});

// ── Generic Error Handler ─────────────────────────────────────────────────────
app.use(errorHandler);

// ── Start + Graceful Shutdown ─────────────────────────────────────────────────
const server = app.listen(PORT, () => {
  console.log(`✅  Triple A API running on http://localhost:${PORT}`);
  console.log(`🌍  Environment: ${process.env.NODE_ENV || 'development'}`);
});

const shutdown = (signal) => {
  console.log(`\n${signal} received — draining connections…`);
  server.close(() => {
    console.log('Server closed cleanly.');
    process.exit(0);
  });
  // Hard-kill if connections don't drain within 10 s
  setTimeout(() => {
    console.error('Force-killing after 10 s timeout.');
    process.exit(1);
  }, 10_000).unref();
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT',  () => shutdown('SIGINT'));

module.exports = app;
