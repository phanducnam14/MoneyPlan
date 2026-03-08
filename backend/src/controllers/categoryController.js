const Category = require('../models/Category');
const mongoose = require('mongoose');

// Get all categories for current user
const getCategories = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const type = req.query.type; // 'expense' or 'income' or undefined for all
    
    const filter = { userId };
    if (type && ['expense', 'income'].includes(type)) {
      filter.type = type;
    }
    
    const categories = await Category.find(filter).sort({ isDefault: -1, name: 1 });
    res.json({ data: categories });
  } catch (error) {
    console.error('Get categories error:', error);
    res.status(500).json({ message: 'Error fetching categories', error: error.message });
  }
};

// Create a new category
const createCategory = async (req, res) => {
  try {
    const { name, type, icon, color } = req.body;
    
    // Validate required fields
    if (!name || !type) {
      return res.status(400).json({ message: 'Name and type are required' });
    }
    
    if (!['expense', 'income'].includes(type)) {
      return res.status(400).json({ message: 'Type must be expense or income' });
    }
    
    const userId = new mongoose.Types.ObjectId(req.user.id);
    
    // Check if category already exists for this user
    const exists = await Category.findOne({ userId, name, type });
    if (exists) {
      return res.status(400).json({ message: 'Category already exists' });
    }
    
    const category = await Category.create({
      userId,
      name,
      type,
      icon: icon || 'category',
      color: color || '#6366F1',
      isDefault: false,
    });
    
    res.status(201).json(category);
  } catch (error) {
    console.error('Create category error:', error);
    res.status(500).json({ message: 'Error creating category', error: error.message });
  }
};

// Update a category
const updateCategory = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const categoryId = new mongoose.Types.ObjectId(req.params.id);
    
    const { name, icon, color } = req.body;
    
    // Find category and verify ownership
    const category = await Category.findOne({ _id: categoryId, userId });
    if (!category) {
      return res.status(404).json({ message: 'Category not found or access denied' });
    }
    
    // Cannot modify default categories' name or type
    if (category.isDefault) {
      // Only allow icon and color changes for default categories
      if (name && name !== category.name) {
        return res.status(400).json({ message: 'Cannot change name of default category' });
      }
    }
    
    // Update fields
    if (name) category.name = name;
    if (icon) category.icon = icon;
    if (color) category.color = color;
    
    await category.save();
    res.json(category);
  } catch (error) {
    console.error('Update category error:', error);
    res.status(500).json({ message: 'Error updating category', error: error.message });
  }
};

// Delete a category
const deleteCategory = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const categoryId = new mongoose.Types.ObjectId(req.params.id);
    
    // Find category and verify ownership
    const category = await Category.findOne({ _id: categoryId, userId });
    if (!category) {
      return res.status(404).json({ message: 'Category not found or access denied' });
    }
    
    // Cannot delete default categories
    if (category.isDefault) {
      return res.status(400).json({ message: 'Cannot delete default category' });
    }
    
    await Category.deleteOne({ _id: categoryId });
    res.status(204).send();
  } catch (error) {
    console.error('Delete category error:', error);
    res.status(500).json({ message: 'Error deleting category', error: error.message });
  }
};

// Initialize default categories for a user (called on first login)
const initializeDefaults = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    
    // Check if user already has categories
    const existing = await Category.countDocuments({ userId });
    if (existing > 0) {
      return res.status(400).json({ message: 'User already has categories' });
    }
    
    // Create default categories
    const categories = await Category.createDefaultsForUser(userId);
    res.status(201).json({ message: 'Default categories created', data: categories });
  } catch (error) {
    console.error('Initialize defaults error:', error);
    res.status(500).json({ message: 'Error initializing default categories', error: error.message });
  }
};

module.exports = { 
  getCategories, 
  createCategory, 
  updateCategory, 
  deleteCategory,
  initializeDefaults 
};

