const RecurringTransaction = require('../models/RecurringTransaction');
const Expense = require('../models/Expense');
const Income = require('../models/Income');
const mongoose = require('mongoose');

const getRecurringTransactions = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const { isActive } = req.query;
    
    const filter = { userId };
    if (isActive !== undefined) {
      filter.isActive = isActive === 'true';
    }
    
    const recurringTransactions = await RecurringTransaction.find(filter)
      .populate('walletId', 'name icon color')
      .sort({ nextExecutionDate: 1 });
    
    res.json({ data: recurringTransactions });
  } catch (error) {
    console.error('Get recurring transactions error:', error);
    res.status(500).json({ message: 'Error fetching recurring transactions', error: error.message });
  }
};

const createRecurringTransaction = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const { amount, category, type, frequency, nextExecutionDate, description, walletId } = req.body;
    
    if (!amount || !category || !type || !frequency || !nextExecutionDate) {
      return res.status(400).json({ message: 'Amount, category, type, frequency, and next execution date are required' });
    }
    
    if (!['expense', 'income'].includes(type)) {
      return res.status(400).json({ message: 'Type must be expense or income' });
    }
    
    const recurring = await RecurringTransaction.create({
      userId,
      amount: Number(amount),
      category,
      type,
      frequency,
      nextExecutionDate: new Date(nextExecutionDate),
      description: description || '',
      walletId: walletId || null,
      isActive: true
    });
    
    res.status(201).json(recurring);
  } catch (error) {
    console.error('Create recurring transaction error:', error);
    res.status(500).json({ message: 'Error creating recurring transaction', error: error.message });
  }
};

const updateRecurringTransaction = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const recurringId = new mongoose.Types.ObjectId(req.params.id);
    
    const { amount, category, type, frequency, nextExecutionDate, description, isActive, walletId } = req.body;
    
    const recurring = await RecurringTransaction.findOne({ _id: recurringId, userId });
    if (!recurring) {
      return res.status(404).json({ message: 'Recurring transaction not found or access denied' });
    }
    
    if (amount !== undefined) recurring.amount = Number(amount);
    if (category) recurring.category = category;
    if (type && ['expense', 'income'].includes(type)) recurring.type = type;
    if (frequency && ['daily', 'weekly', 'monthly', 'yearly'].includes(frequency)) recurring.frequency = frequency;
    if (nextExecutionDate) recurring.nextExecutionDate = new Date(nextExecutionDate);
    if (description !== undefined) recurring.description = description;
    if (isActive !== undefined) recurring.isActive = isActive;
    if (walletId !== undefined) recurring.walletId = walletId ? new mongoose.Types.ObjectId(walletId) : null;
    
    await recurring.save();
    res.json(recurring);
  } catch (error) {
    console.error('Update recurring transaction error:', error);
    res.status(500).json({ message: 'Error updating recurring transaction', error: error.message });
  }
};

const deleteRecurringTransaction = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const recurringId = new mongoose.Types.ObjectId(req.params.id);
    
    const recurring = await RecurringTransaction.findOne({ _id: recurringId, userId });
    if (!recurring) {
      return res.status(404).json({ message: 'Recurring transaction not found or access denied' });
    }
    
    await RecurringTransaction.deleteOne({ _id: recurringId });
    res.status(204).send();
  } catch (error) {
    console.error('Delete recurring transaction error:', error);
    res.status(500).json({ message: 'Error deleting recurring transaction', error: error.message });
  }
};

const executePendingRecurring = async (req, res) => {
  try {
    const now = new Date();
    
    const pendingRecurring = await RecurringTransaction.find({
      isActive: true,
      nextExecutionDate: { $lte: now }
    });
    
    const results = [];
    
    for (const recurring of pendingRecurring) {
      try {
        if (recurring.type === 'expense') {
          await Expense.create({
            userId: recurring.userId,
            amount: recurring.amount,
            category: recurring.category,
            note: recurring.description || 'Recurring expense',
            date: now,
            walletId: recurring.walletId
          });
        } else {
          await Income.create({
            userId: recurring.userId,
            amount: recurring.amount,
            source: recurring.category,
            note: recurring.description || 'Recurring income',
            date: now,
            walletId: recurring.walletId
          });
        }
        
        recurring.lastExecutionDate = now;
        
        let nextDate = new Date(recurring.nextExecutionDate);
        switch (recurring.frequency) {
          case 'daily':
            nextDate.setDate(nextDate.getDate() + 1);
            break;
          case 'weekly':
            nextDate.setDate(nextDate.getDate() + 7);
            break;
          case 'monthly':
            nextDate.setMonth(nextDate.getMonth() + 1);
            break;
          case 'yearly':
            nextDate.setFullYear(nextDate.getFullYear() + 1);
            break;
        }
        
        recurring.nextExecutionDate = nextDate;
        await recurring.save();
        
        results.push({ id: recurring._id, status: 'executed', nextDate });
      } catch (err) {
        console.error(`Error executing recurring ${recurring._id}:`, err);
        results.push({ id: recurring._id, status: 'error', message: err.message });
      }
    }
    
    res.json({ message: 'Recurring transactions processed', results });
  } catch (error) {
    console.error('Execute pending recurring error:', error);
    res.status(500).json({ message: 'Error executing recurring transactions', error: error.message });
  }
};

module.exports = {
  getRecurringTransactions,
  createRecurringTransaction,
  updateRecurringTransaction,
  deleteRecurringTransaction,
  executePendingRecurring
};
