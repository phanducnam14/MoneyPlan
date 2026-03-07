const express = require('express');
const { createExpense, deleteExpense, getExpenses, updateExpense } = require('../controllers/expenseController');
const auth = require('../middleware/auth');

const router = express.Router();

router.get('/', auth(['user', 'admin']), getExpenses);
router.post('/', auth(['user', 'admin']), createExpense);
router.put('/:id', auth(['user', 'admin']), updateExpense);
router.delete('/:id', auth(['user', 'admin']), deleteExpense);

module.exports = router;
