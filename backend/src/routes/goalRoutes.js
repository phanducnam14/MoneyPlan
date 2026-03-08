const express = require('express');
const { getGoals, createGoal, updateGoal, addSavings, deleteGoal } = require('../controllers/goalController');
const auth = require('../middleware/auth');

const router = express.Router();

router.get('/', auth(['user', 'admin']), getGoals);
router.post('/', auth(['user', 'admin']), createGoal);
router.put('/:id', auth(['user', 'admin']), updateGoal);
router.post('/:id/savings', auth(['user', 'admin']), addSavings);
router.delete('/:id', auth(['user', 'admin']), deleteGoal);

module.exports = router;
