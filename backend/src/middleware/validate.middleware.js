// src/middleware/validate.middleware.js
const { validationResult } = require('express-validator');

/**
 * Runs after express-validator checks.
 * Returns 422 with field-level errors if validation fails.
 */
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(422).json({
      success: false,
      message: 'Validation failed',
      errors: errors.array().map(e => ({ field: e.path, message: e.msg })),
    });
  }
  next();
};

module.exports = { validate };
