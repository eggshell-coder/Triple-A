// src/routes/upload.routes.js
const express = require('express');
const router = express.Router();
const multer = require('multer');
const { authenticate } = require('../middleware/auth.middleware');
const { uploadImage } = require('../controllers/upload.controller');

// Store in memory buffer (sent directly to Supabase)
const storage = multer.memoryStorage();
const upload = multer({
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  fileFilter: (req, file, cb) => {
    if (['image/jpeg', 'image/png', 'image/webp', 'image/gif'].includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Only JPEG, PNG, WebP, or GIF images are allowed'));
    }
  },
});

router.post('/', authenticate, upload.single('image'), uploadImage);

module.exports = router;
