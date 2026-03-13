const Transaction = require('../models/Transaction');
const TransactionService = require('../services/transactionService');
const WalletService = require('../services/walletService');
const mongoose = require('mongoose');

// Get all transactions for current user (across all wallets)
const getTransactions = async (req, res) => {
  try {
    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 10);
    const type = req.query.type; // 'income', 'expense', 'transfer'
    const walletId = req.query.walletId;
    const category = req.query.category;

    const userId = req.user.id;

    // Build filters
    const filters = {};
    if (type) filters.type = type;
    if (category) filters.category = category;
    if (walletId) filters.walletId = walletId;

    const result = await TransactionService.getAllUserTransactions(
      userId,
      page,
      limit,
      filters
    );

    res.json(result);
  } catch (error) {
    console.error('Get transactions error:', error);
    res.status(500).json({ message: 'Error fetching transactions', error: error.message });
  }
};

// Get transactions for a specific wallet
const getWalletTransactions = async (req, res) => {
  try {
    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 10);
    const walletId = req.params.walletId;
    const userId = req.user.id;

    const result = await TransactionService.getTransactionsByWallet(
      walletId,
      userId,
      page,
      limit
    );

    res.json(result);
  } catch (error) {
    console.error('Get wallet transactions error:', error);
    res.status(500).json({ message: 'Error fetching transactions', error: error.message });
  }
};

// Create income
const createIncome = async (req, res) => {
  try {
    const { amount, category, source, note, date, walletId } = req.body;
    const userId = req.user.id;

    // Validate required fields
    if (!amount || !category || !date) {
      return res
        .status(400)
        .json({ message: 'Amount, category, and date are required' });
    }

    if (!walletId) {
      return res
        .status(400)
        .json({ message: 'Wallet ID is required' });
    }

    // Create income using service
    const transaction = await TransactionService.createIncome(
      userId,
      walletId,
      amount,
      category,
      source,
      note,
      date
    );

    res.status(201).json(transaction);
  } catch (error) {
    console.error('Create income error:', error);
    res.status(500).json({ message: 'Error creating income', error: error.message });
  }
};

// Create expense
const createExpense = async (req, res) => {
  try {
    const { amount, category, note, date, walletId } = req.body;
    const userId = req.user.id;

    // Validate required fields
    if (!amount || !category || !date) {
      return res
        .status(400)
        .json({ message: 'Amount, category, and date are required' });
    }

    if (!walletId) {
      return res
        .status(400)
        .json({ message: 'Wallet ID is required' });
    }

    // Create expense using service
    const transaction = await TransactionService.createExpense(
      userId,
      walletId,
      amount,
      category,
      note,
      date
    );

    res.status(201).json(transaction);
  } catch (error) {
    console.error('Create expense error:', error);
    res.status(500).json({ message: 'Error creating expense', error: error.message });
  }
};

// Create transfer between wallets
const createTransfer = async (req, res) => {
  try {
    const { fromWalletId, toWalletId, amount, note, date } = req.body;
    const userId = req.user.id;

    // Validate required fields
    if (!fromWalletId || !toWalletId || !amount || !date) {
      return res
        .status(400)
        .json({ message: 'From wallet, to wallet, amount, and date are required' });
    }

    if (fromWalletId === toWalletId) {
      return res
        .status(400)
        .json({ message: 'Cannot transfer to the same wallet' });
    }

    // Create transfer using service
    const transactions = await WalletService.transferBetweenWallets(
      fromWalletId,
      toWalletId,
      userId,
      amount,
      note,
      date
    );

    res.status(201).json({ transactions, message: 'Transfer created successfully' });
  } catch (error) {
    console.error('Create transfer error:', error);
    res.status(500).json({ message: 'Error creating transfer', error: error.message });
  }
};

// Update transaction
const updateTransaction = async (req, res) => {
  try {
    const transactionId = req.params.id;
    const userId = req.user.id;

    const transaction = await TransactionService.updateTransaction(
      transactionId,
      userId,
      req.body
    );

    res.json(transaction);
  } catch (error) {
    console.error('Update transaction error:', error);
    res.status(500).json({ message: 'Error updating transaction', error: error.message });
  }
};

// Delete transaction
const deleteTransaction = async (req, res) => {
  try {
    const transactionId = req.params.id;
    const userId = req.user.id;

    await TransactionService.deleteTransaction(transactionId, userId);

    res.status(204).send();
  } catch (error) {
    console.error('Delete transaction error:', error);
    res.status(500).json({ message: 'Error deleting transaction', error: error.message });
  }
};

// Get transaction statistics
const getTransactionStats = async (req, res) => {
  try {
    const userId = req.user.id;

    const stats = await TransactionService.getUserTransactionStats(userId);

    res.json(stats);
  } catch (error) {
    console.error('Get transaction stats error:', error);
    res.status(500).json({ message: 'Error fetching statistics', error: error.message });
  }
};

module.exports = {
  getTransactions,
  getWalletTransactions,
  createIncome,
  createExpense,
  createTransfer,
  updateTransaction,
  deleteTransaction,
  getTransactionStats
};
