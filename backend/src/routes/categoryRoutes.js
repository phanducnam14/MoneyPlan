const express = require('express');
const { getCategories, createCategory, updateCategory, deleteCategory, initializeDefaults } = require('../controllers/categoryController');
const auth = require('../middleware/auth');

const router = express.Router();

router.get('/', auth(['user', 'admin']), getCategories);
router.post('/', auth(['user', 'admin']), createCategory);
router.put('/:id', auth(['user', 'admin']), updateCategory);
router.delete('/:id', auth(['user', 'admin']), deleteCategory);
router.post('/initialize', auth(['user', 'admin']), initializeDefaults);

module.exports = router;

