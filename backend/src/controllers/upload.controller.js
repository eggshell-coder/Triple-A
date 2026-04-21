// src/controllers/upload.controller.js
const supabase = require('../config/supabase');
const { createError } = require('../middleware/error.middleware');

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

    const file = req.file;
    const fileExt = file.originalname.split('.').pop();
    const fileName = `${Date.now()}-${Math.random().toString(36).substr(2, 9)}.${fileExt}`;
    const filePath = `products/${fileName}`;

    // Upload to Supabase Storage bucket "product-images"
    const { data, error } = await supabase.storage
      .from('product-images')
      .upload(filePath, file.buffer, {
        contentType: file.mimetype,
        upsert: false,
      });

    if (error) return next(createError(`Storage error: ${error.message}`));

    // Get public URL
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
