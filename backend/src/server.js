// src/server.js
require('dotenv').config();
const express = require('express');
const cors    = require('cors');
const helmet  = require('helmet');
const morgan  = require('morgan');
const rateLimit = require('express-rate-limit');

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

// ── Security ────────────────────────────────────────────────────────────────
app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));

// ── CORS — handle OPTIONS preflight explicitly ──────────────────────────────
const corsOptions = {
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: false,
};
app.use(cors(corsOptions));
app.options('*', cors(corsOptions)); // handle preflight for ALL routes

// ── Rate Limiting ────────────────────────────────────────────────────────────
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
  message: { success: false, message: 'Too many requests, please try again later.' },
});
app.use(limiter);

// ── Body Parsing ─────────────────────────────────────────────────────────────
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// ── Logging ──────────────────────────────────────────────────────────────────
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('dev'));
}

// ── Health Check ─────────────────────────────────────────────────────────────
app.get('/health', (req, res) => {
  res.json({ success: true, message: 'Triple A API is running', timestamp: new Date().toISOString() });
});

// ── Routes ───────────────────────────────────────────────────────────────────
app.use('/api/auth',        authRoutes);
app.use('/api/products',    productRoutes);
app.use('/api/categories',  categoryRoutes);
app.use('/api/orders',      orderRoutes);
app.use('/api/dashboard',   dashboardRoutes);
app.use('/api/upload',      uploadRoutes);
app.use('/api/collections', collectionsRoutes);
app.use('/api/wishlist',    wishlistRoutes);

// ── 404 ──────────────────────────────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Route not found' });
});

// ── Error Handler ────────────────────────────────────────────────────────────
app.use(errorHandler);

// ── Start ────────────────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`✅  Triple A API running on http://localhost:${PORT}`);
  console.log(`🌍  Environment: ${process.env.NODE_ENV || 'development'}`);
});

module.exports = app;