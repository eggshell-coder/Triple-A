// src/routes/dashboard.routes.js
const express = require('express');
const router  = express.Router();
const { requireAdmin } = require('../middleware/adminAuth');
const { getStats }     = require('../controllers/dashboard.controller');

router.get('/stats', requireAdmin, getStats);

module.exports = router;
