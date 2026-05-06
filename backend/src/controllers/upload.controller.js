// src/controllers/upload.controller.js
const crypto   = require('crypto');
const supabase = require('../config/supabase');
const { createError } = require('../middleware/error.middleware');

// Whitelist: mimetype → canonical extension
const MIME_TO_EXT = {
  'image/jpeg': 'jpg',
  'image/png':  'png',
  'image/webp': 'webp',
  'image/gif':  'gif',
};

/**
 * POST /api/upload
 * Uploads an image to Supabase Storage and returns the public URL.
 * Expects multipart/form-data with field "image".
 */
const uploadImage = async (req, res, next) => {
  try {
    if (!req.file) {
      return next(createError('No file uploaded', 400));
    }

    const file    = req.file;
    const ext     = MIME_TO_EXT[file.mimetype];

    if (!ext) {
      return next(createError('Unsupported image type', 415));
    }

    // Unguessable filename — UUID, not random-based
    const fileName = `${crypto.randomUUID()}.${ext}`;
    const filePath = `products/${fileName}`;

    const { error } = await supabase.storage
      .from('product-images')
      .upload(filePath, file.buffer, {
        contentType:  file.mimetype,
        upsert:       false,
        cacheControl: '31536000', // 1 year — immutable once written
      });

    if (error) return next(createError(`Storage error: ${error.message}`));

    const { data: urlData } = supabase.storage
      .from('product-images')
      .getPublicUrl(filePath);

    res.status(201).json({
      success: true,
      message: 'Image uploaded successfully',
      data: { url: urlData.publicUrl, path: filePath },
    });
  } catch (err) {
    next(err);
  }
};

module.exports = { uploadImage };
