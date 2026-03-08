const express = require('express');
const { getBudgets, createBudget, updateBudget, deleteBudget } = require('../controllers/budgetController');
const auth = require('../middleware/auth');

const router = express.Router();

router.get('/', auth(['user', 'admin']), getBudgets);
router.post('/', auth(['user', 'admin']), createBudget);
router.put('/:id', auth(['user', 'admin']), updateBudget);
router.delete('/:id', auth(['user', 'admin']), deleteBudget);

module.exports = router;

