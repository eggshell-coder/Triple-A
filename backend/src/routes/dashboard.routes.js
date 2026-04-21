// src/routes/dashboard.routes.js
const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth.middleware');
const { getStats } = require('../controllers/dashboard.controller');

router.get('/stats', authenticate, getStats);

module.exports = router;
