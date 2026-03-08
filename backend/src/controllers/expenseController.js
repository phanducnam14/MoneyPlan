const Expense = require('../models/Expense');
const mongoose = require('mongoose');

const getExpenses = async (req, res) => {
  try {
    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 10);
    
    // CRITICAL: Filter by userId to enforce data isolation
    const userId = new mongoose.Types.ObjectId(req.user.id);
    
    const expenses = await Expense.find({ userId })
      .sort({ date: -1 })
      .skip(Math.max(0, (page - 1) * limit))
      .limit(Math.min(limit, 100));
    
    const total = await Expense.countDocuments({ userId });
    
    res.json({
      data: expenses,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Get expenses error:', error);
    res.status(500).json({ message: 'Error fetching expenses', error: error.message });
  }
};

const createExpense = async (req, res) => {
  try {
    const { amount, category, date, note, walletId } = req.body;
    
    // Validate required fields
    if (!amount || !category || !date) {
      return res.status(400).json({ message: 'Amount, category, and date are required' });
    }
    
    // CRITICAL: Always attach userId to new expense
    const userId = new mongoose.Types.ObjectId(req.user.id);
    
    const expense = await Expense.create({
      userId,
      amount: Number(amount),
      category,
      date: new Date(date),
      note: note || '',
      walletId: walletId ? new mongoose.Types.ObjectId(walletId) : undefined
    });
    
    res.status(201).json(expense);
  } catch (error) {
    console.error('Create expense error:', error);
    res.status(500).json({ message: 'Error creating expense', error: error.message });
  }
};

const updateExpense = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const expenseId = new mongoose.Types.ObjectId(req.params.id);
    
    // CRITICAL: Verify ownership before updating
    const expense = await Expense.findOneAndUpdate(
      { _id: expenseId, userId },
      req.body,
      { new: true, runValidators: true }
    );
    
    if (!expense) {
      return res.status(404).json({ message: 'Expense not found or access denied' });
    }
    
    res.json(expense);
  } catch (error) {
    console.error('Update expense error:', error);
    res.status(500).json({ message: 'Error updating expense', error: error.message });
  }
};

const deleteExpense = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const expenseId = new mongoose.Types.ObjectId(req.params.id);
    
    // CRITICAL: Verify ownership before deleting
    const expense = await Expense.findOneAndDelete({ _id: expenseId, userId });
    
    if (!expense) {
      return res.status(404).json({ message: 'Expense not found or access denied' });
    }
    
    res.status(204).send();
  } catch (error) {
    console.error('Delete expense error:', error);
    res.status(500).json({ message: 'Error deleting expense', error: error.message });
  }
};

module.exports = { getExpenses, createExpense, updateExpense, deleteExpense };
