// src/routes/upload.routes.js
const express = require('express');
const router  = express.Router();
const multer  = require('multer');
const { requireAdmin } = require('../middleware/adminAuth');
const { uploadImage }  = require('../controllers/upload.controller');

// Pull upload rate-limiter registered in server.js
const uploadLimiter = (req, res, next) => req.app.locals.uploadLimiter(req, res, next);

// Store in memory buffer (sent directly to Supabase)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB
  fileFilter: (req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
    if (allowed.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Only JPEG, PNG, WebP, or GIF images are allowed'));
    }
  },
});

router.post('/', uploadLimiter, requireAdmin, upload.single('image'), uploadImage);

module.exports = router;
