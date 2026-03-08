const Wallet = require('../models/Wallet');
const Expense = require('../models/Expense');
const Income = require('../models/Income');
const mongoose = require('mongoose');

// Get all wallets for current user
const getWallets = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    
    const wallets = await Wallet.find({ userId }).sort({ isDefault: -1, name: 1 });
    
    // Calculate actual balance for each wallet based on transactions
    const walletBalances = await Promise.all(wallets.map(async (wallet) => {
      const [expenses, incomes] = await Promise.all([
        Expense.aggregate([
          { $match: { userId, walletId: wallet._id } },
          { $group: { _id: null, total: { $sum: '$amount' } } }
        ]),
        Income.aggregate([
          { $match: { userId, walletId: wallet._id } },
          { $group: { _id: null, total: { $sum: '$amount' } } }
        ])
      ]);
      
      const totalExpenses = expenses[0]?.total || 0;
      const totalIncomes = incomes[0]?.total || 0;
      
      return {
        ...wallet.toObject(),
        actualBalance: wallet.balance + totalIncomes - totalExpenses,
        totalIncome: totalIncomes,
        totalExpense: totalExpenses
      };
    }));
    
    res.json({ data: walletBalances });
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
    
    const { name, balance, icon, color, type, isDefault } = req.body;
    
    const wallet = await Wallet.findOne({ _id: walletId, userId });
    if (!wallet) {
      return res.status(404).json({ message: 'Wallet not found or access denied' });
    }
    
    if (name) wallet.name = name;
    if (balance !== undefined) wallet.balance = balance;
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

// Get single wallet details
const getWalletById = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const walletId = new mongoose.Types.ObjectId(req.params.id);
    
    const wallet = await Wallet.findOne({ _id: walletId, userId });
    if (!wallet) {
      return res.status(404).json({ message: 'Wallet not found' });
    }
    
    const [recentExpenses, recentIncomes] = await Promise.all([
      Expense.find({ userId, walletId }).sort({ date: -1 }).limit(10),
      Income.find({ userId, walletId }).sort({ date: -1 }).limit(10)
    ]);
    
    res.json({
      ...wallet.toObject(),
      recentTransactions: [
        ...recentExpenses.map(e => ({ ...e.toObject(), type: 'expense' })),
        ...recentIncomes.map(i => ({ ...i.toObject(), type: 'income' }))
      ].sort((a, b) => new Date(b.date) - new Date(a.date)).slice(0, 10)
    });
  } catch (error) {
    console.error('Get wallet error:', error);
    res.status(500).json({ message: 'Error fetching wallet', error: error.message });
  }
};

module.exports = { getWallets, createWallet, updateWallet, deleteWallet, getWalletById };

