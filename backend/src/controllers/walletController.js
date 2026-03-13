const Wallet = require('../models/Wallet');
const WalletService = require('../services/walletService');
const Expense = require('../models/Expense');
const Income = require('../models/Income');
const mongoose = require('mongoose');

// Get all wallets for current user
const getWallets = async (req, res) => {
  try {
    const userId = req.user.id;
    const wallets = await WalletService.getUserWallets(userId);
    res.json({ data: wallets });
  } catch (error) {
    console.error('Get wallets error:', error);
    res.status(500).json({ message: 'Error fetching wallets', error: error.message });
  }
};

// Create a new wallet
const createWallet = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const { name, balance, icon, color, type, isDefault } = req.body;

    if (!name) {
      return res.status(400).json({ message: 'Wallet name is required' });
    }

    const exists = await Wallet.findOne({ userId, name });
    if (exists) {
      return res.status(400).json({ message: 'Wallet with this name already exists' });
    }

    const wallet = await Wallet.create({
      userId,
      name,
      balance: balance || 0,
      icon: icon || 'account_balance_wallet',
      color: color || '#6366F1',
      type: type || 'cash',
      isDefault: isDefault || false
    });

    res.status(201).json(wallet);
  } catch (error) {
    console.error('Create wallet error:', error);
    res.status(500).json({ message: 'Error creating wallet', error: error.message });
  }
};

// Update a wallet
const updateWallet = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const walletId = new mongoose.Types.ObjectId(req.params.id);

    const { name, icon, color, type, isDefault } = req.body;

    const wallet = await Wallet.findOne({ _id: walletId, userId });
    if (!wallet) {
      return res.status(404).json({ message: 'Wallet not found or access denied' });
    }

    // Allow updating these fields only (NOT balance - balance is updated via transactions)
    if (name) wallet.name = name;
    if (icon) wallet.icon = icon;
    if (color) wallet.color = color;
    if (type) wallet.type = type;
    if (isDefault !== undefined) wallet.isDefault = isDefault;

    await wallet.save();
    res.json(wallet);
  } catch (error) {
    console.error('Update wallet error:', error);
    res.status(500).json({ message: 'Error updating wallet', error: error.message });
  }
};

// Delete a wallet
const deleteWallet = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const walletId = new mongoose.Types.ObjectId(req.params.id);

    const wallet = await Wallet.findOne({ _id: walletId, userId });
    if (!wallet) {
      return res.status(404).json({ message: 'Wallet not found or access denied' });
    }

    const [expenseCount, incomeCount] = await Promise.all([
      Expense.countDocuments({ userId, walletId }),
      Income.countDocuments({ userId, walletId })
    ]);

    if (expenseCount > 0 || incomeCount > 0) {
      return res.status(400).json({
        message: 'Cannot delete wallet with transactions'
      });
    }

    await Wallet.deleteOne({ _id: walletId });
    res.status(204).send();
  } catch (error) {
    console.error('Delete wallet error:', error);
    res.status(500).json({ message: 'Error deleting wallet', error: error.message });
  }
};

// Get single wallet details with recent transactions
const getWalletById = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const walletId = new mongoose.Types.ObjectId(req.params.id);

    const wallet = await Wallet.findOne({ _id: walletId, userId });
    if (!wallet) {
      return res.status(404).json({ message: 'Wallet not found' });
    }

    // Calculate balance
    const balance = await WalletService.calculateWalletBalance(walletId, userId);

    const [recentExpenses, recentIncomes] = await Promise.all([
      Expense.find({ userId, walletId }).sort({ date: -1 }).limit(10),
      Income.find({ userId, walletId }).sort({ date: -1 }).limit(10)
    ]);

    res.json({
      ...wallet.toObject(),
      actualBalance: balance,
      displayBalance: balance,
      recentTransactions: [
        ...recentExpenses.map(e => ({ ...e.toObject(), type: 'expense' })),
        ...recentIncomes.map(i => ({ ...i.toObject(), type: 'income' }))
      ]
        .sort((a, b) => new Date(b.date) - new Date(a.date))
        .slice(0, 10)
    });
  } catch (error) {
    console.error('Get wallet error:', error);
    res.status(500).json({ message: 'Error fetching wallet', error: error.message });
  }
};

module.exports = { getWallets, createWallet, updateWallet, deleteWallet, getWalletById };

