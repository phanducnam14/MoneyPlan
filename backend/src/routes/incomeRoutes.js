const express = require('express');
const { createIncome, deleteIncome, getIncomes, updateIncome } = require('../controllers/incomeController');
const auth = require('../middleware/auth');

const router = express.Router();

router.get('/', auth(['user', 'admin']), getIncomes);
router.post('/', auth(['user', 'admin']), createIncome);
router.put('/:id', auth(['user', 'admin']), updateIncome);
router.delete('/:id', auth(['user', 'admin']), deleteIncome);

module.exports = router;
