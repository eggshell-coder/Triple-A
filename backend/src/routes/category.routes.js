// src/routes/category.routes.js
const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const { validate } = require('../middleware/validate.middleware');
const { authenticate } = require('../middleware/auth.middleware');
const {
  getCategories, getAllCategoriesAdmin,
  createCategory, updateCategory, deleteCategory
} = require('../controllers/category.controller');

// Public
router.get('/', getCategories);

// Admin
router.get('/admin/all', authenticate, getAllCategoriesAdmin);
router.post('/', authenticate,
  [body('name').trim().notEmpty().withMessage('Category name required'), validate],
  createCategory
);
router.patch('/:id', authenticate, updateCategory);
router.delete('/:id', authenticate, deleteCategory);

module.exports = router;