// src/routes/collectionsRoutes.js — FIXED
// Corrected function names to match collectionsController.js exports
const express = require('express');
const router  = express.Router();
const {
  getCollections,
  adminGetCollections,
  getCollectionBySlug,
  createCollection,
  updateCollection,
  deleteCollection,
} = require('../controllers/collectionsController');
const { requireAdmin } = require('../middleware/adminAuth');

// ── Public ────────────────────────────────────────────────────────────────
router.get('/', getCollections);

// IMPORTANT: /admin/all must come BEFORE /:slug to avoid slug param clash
router.get('/admin/all', requireAdmin, adminGetCollections);
router.get('/:slug/products', getCollectionBySlug);

// ── Admin (auth required) ─────────────────────────────────────────────────
router.post('/',    requireAdmin, createCollection);
router.patch('/:id', requireAdmin, updateCollection);
router.delete('/:id', requireAdmin, deleteCollection);

module.exports = router;
