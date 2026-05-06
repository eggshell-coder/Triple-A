// src/routes/category.routes.js
const express = require('express');
const router  = express.Router();
const { body } = require('express-validator');
const { validate }     = require('../middleware/validate.middleware');
const { requireAdmin } = require('../middleware/adminAuth');
const {
  getCategories, getAllCategoriesAdmin,
  createCategory, updateCategory, deleteCategory,
} = require('../controllers/category.controller');

// ── Public ────────────────────────────────────────────────────────────────────
router.get('/', getCategories);

// ── Admin ─────────────────────────────────────────────────────────────────────
router.get('/admin/all', requireAdmin, getAllCategoriesAdmin);
router.post('/', requireAdmin,
  [body('name').trim().notEmpty().withMessage('Category name required'), validate],
  createCategory
);
router.patch('/:id',  requireAdmin, updateCategory);
router.delete('/:id', requireAdmin, deleteCategory);

module.exports = router;
