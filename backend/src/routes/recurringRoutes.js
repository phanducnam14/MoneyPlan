const express = require('express');
const { getRecurringTransactions, createRecurringTransaction, updateRecurringTransaction, deleteRecurringTransaction, executePendingRecurring } = require('../controllers/recurringController');
const auth = require('../middleware/auth');

const router = express.Router();

router.get('/', auth(['user', 'admin']), getRecurringTransactions);
router.post('/', auth(['user', 'admin']), createRecurringTransaction);
router.put('/:id', auth(['user', 'admin']), updateRecurringTransaction);
router.delete('/:id', auth(['user', 'admin']), deleteRecurringTransaction);
router.post('/execute', auth(['user', 'admin']), executePendingRecurring);

module.exports = router;
