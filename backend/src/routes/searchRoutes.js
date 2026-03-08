const express = require('express');
const { searchTransactions, getCategoryStats, getMonthlyStats } = require('../controllers/searchController');
const auth = require('../middleware/auth');

const router = express.Router();

router.get('/transactions', auth(['user', 'admin']), searchTransactions);
router.get('/categories', auth(['user', 'admin']), getCategoryStats);
router.get('/monthly', auth(['user', 'admin']), getMonthlyStats);

module.exports = router;

