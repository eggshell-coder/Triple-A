// src/controllers/category.controller.js
const supabase = require('../config/supabase');
const { createError } = require('../middleware/error.middleware');

const getCategories = async (req, res, next) => {
  try {
    const { data, error } = await supabase
      .from('categories')
      .select('*')
      .order('name');

    if (error) return next(createError(error.message));

    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
};

const getAllCategoriesAdmin = async (req, res, next) => {
  try {
    const { data, error } = await supabase
      .from('categories')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) return next(createError(error.message));

    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
};

const createCategory = async (req, res, next) => {
  try {
    const { name } = req.body;

    const { data, error } = await supabase
      .from('categories')
      .insert([{ name }])
      .select()
      .single();

    if (error) return next(createError(error.message));

    res.status(201).json({ success: true, data });
  } catch (err) {
    next(err);
  }
};

const updateCategory = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name } = req.body;

    const { data, error } = await supabase
      .from('categories')
      .update({ name })
      .eq('id', id)
      .select()
      .single();

    if (error) return next(createError(error.message));

    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
};

const deleteCategory = async (req, res, next) => {
  try {
    const { id } = req.params;

    const { error } = await supabase
      .from('categories')
      .delete()
      .eq('id', id);

    if (error) return next(createError(error.message));

    res.json({ success: true, message: 'Category deleted successfully' });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  getCategories,
  getAllCategoriesAdmin,
  createCategory,
  updateCategory,
  deleteCategory,
};