const Income = require('../models/Income');
const mongoose = require('mongoose');

const getIncomes = async (req, res) => {
  try {
    const page = Number(req.query.page || 1);
    const limit = Number(req.query.limit || 10);
    
    // CRITICAL: Filter by userId to enforce data isolation
    const userId = new mongoose.Types.ObjectId(req.user.id);
    
    const incomes = await Income.find({ userId })
      .sort({ date: -1 })
      .skip(Math.max(0, (page - 1) * limit))
      .limit(Math.min(limit, 100));
    
    const total = await Income.countDocuments({ userId });
    
    res.json({
      data: incomes,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit)
      }
    });
  } catch (error) {
    console.error('Get incomes error:', error);
    res.status(500).json({ message: 'Error fetching incomes', error: error.message });
  }
};

const createIncome = async (req, res) => {
  try {
    const { amount, source, date, note } = req.body;
    
    // Validate required fields
    if (!amount || !source || !date) {
      return res.status(400).json({ message: 'Amount, source, and date are required' });
    }
    
    // CRITICAL: Always attach userId to new income
    const userId = new mongoose.Types.ObjectId(req.user.id);
    
    const income = await Income.create({
      userId,
      amount: Number(amount),
      source,
      date: new Date(date),
      note: note || ''
    });
    
    res.status(201).json(income);
  } catch (error) {
    console.error('Create income error:', error);
    res.status(500).json({ message: 'Error creating income', error: error.message });
  }
};

const updateIncome = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const incomeId = new mongoose.Types.ObjectId(req.params.id);
    
    // CRITICAL: Verify ownership before updating
    const income = await Income.findOneAndUpdate(
      { _id: incomeId, userId },
      req.body,
      { new: true, runValidators: true }
    );
    
    if (!income) {
      return res.status(404).json({ message: 'Income not found or access denied' });
    }
    
    res.json(income);
  } catch (error) {
    console.error('Update income error:', error);
    res.status(500).json({ message: 'Error updating income', error: error.message });
  }
};

const deleteIncome = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const incomeId = new mongoose.Types.ObjectId(req.params.id);
    
    // CRITICAL: Verify ownership before deleting
    const income = await Income.findOneAndDelete({ _id: incomeId, userId });
    
    if (!income) {
      return res.status(404).json({ message: 'Income not found or access denied' });
    }
    
    res.status(204).send();
  } catch (error) {
    console.error('Delete income error:', error);
    res.status(500).json({ message: 'Error deleting income', error: error.message });
  }
};

module.exports = { getIncomes, createIncome, updateIncome, deleteIncome };
