const express = require('express');
const {
  getTransactions,
  getWalletTransactions,
  createIncome,
  createExpense,
  createTransfer,
  updateTransaction,
  deleteTransaction,
  getTransactionStats
} = require('../controllers/transactionController');
const auth = require('../middleware/auth');

const router = express.Router();

// Get all transactions for user
router.get('/', auth(['user', 'admin']), getTransactions);

// Get statistics
router.get('/stats', auth(['user', 'admin']), getTransactionStats);

// Get transactions for a specific wallet
router.get('/wallet/:walletId', auth(['user', 'admin']), getWalletTransactions);

// Create transactions
router.post('/income', auth(['user', 'admin']), createIncome);
router.post('/expense', auth(['user', 'admin']), createExpense);
router.post('/transfer', auth(['user', 'admin']), createTransfer);

// Update transaction
router.put('/:id', auth(['user', 'admin']), updateTransaction);

// Delete transaction
router.delete('/:id', auth(['user', 'admin']), deleteTransaction);

module.exports = router;
