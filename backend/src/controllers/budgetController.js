const Budget = require('../models/Budget');
const Expense = require('../models/Expense');
const mongoose = require('mongoose');

// Get all budgets for current user (optionally for a specific month/year)
const getBudgets = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const { month, year } = req.query;
    
    const currentDate = new Date();
    const queryMonth = month ? parseInt(month) : currentDate.getMonth() + 1;
    const queryYear = year ? parseInt(year) : currentDate.getFullYear();
    
    // Get all budgets for the period
    const budgets = await Budget.find({ 
      userId, 
      month: queryMonth, 
      year: queryYear 
    }).populate('categoryId', 'name icon color type');
    
    // Calculate spent amounts for each budget
    const startDate = new Date(queryYear, queryMonth - 1, 1);
    const endDate = new Date(queryYear, queryMonth, 0, 23, 59, 59);
    
    // Get total expenses for the month
    const expenses = await Expense.aggregate([
      {
        $match: {
          userId,
          date: { $gte: startDate, $lte: endDate }
        }
      },
      {
        $group: {
          _id: '$category',
          total: { $sum: '$amount' }
        }
      }
    ]);
    
    // Map expenses by category name
    const expenseByCategory = {};
    expenses.forEach(exp => {
      expenseByCategory[exp._id] = exp.total;
    });
    
    // Calculate total budget and total spent
    let totalBudget = 0;
    let totalSpent = 0;
    
    const budgetsWithSpent = budgets.map(budget => {
      const categoryName = budget.categoryId?.name;
      const spent = categoryName ? (expenseByCategory[categoryName] || 0) : 0;
      
      // Update spent in response (but don't save to DB yet)
      totalBudget += budget.amount;
      totalSpent += spent;
      
      return {
        _id: budget._id,
        amount: budget.amount,
        period: budget.period,
        month: budget.month,
        year: budget.year,
        category: budget.categoryId,
        spent: spent,
        remaining: budget.amount - spent,
        percentUsed: budget.amount > 0 ? Math.round((spent / budget.amount) * 100) : 0,
        isOverBudget: spent > budget.amount
      };
    });
    
    res.json({
      data: budgetsWithSpent,
      summary: {
        totalBudget,
        totalSpent,
        remaining: totalBudget - totalSpent,
        percentUsed: totalBudget > 0 ? Math.round((totalSpent / totalBudget) * 100) : 0,
        isOverBudget: totalSpent > totalBudget
      }
    });
  } catch (error) {
    console.error('Get budgets error:', error);
    res.status(500).json({ message: 'Error fetching budgets', error: error.message });
  }
};

// Create or update a budget
const createBudget = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const { amount, period, month, year, categoryId } = req.body;
    
    // Validate required fields
    if (!amount || !month || !year) {
      return res.status(400).json({ message: 'Amount, month, and year are required' });
    }
    
    const query = { 
      userId, 
      month: parseInt(month), 
      year: parseInt(year) 
    };
    
    if (categoryId) {
      query.categoryId = new mongoose.Types.ObjectId(categoryId);
    } else {
      query.categoryId = null; // Total budget
    }
    
    // Check if budget exists
    let budget = await Budget.findOne(query);
    
    if (budget) {
      // Update existing
      budget.amount = amount;
      if (period) budget.period = period;
      await budget.save();
    } else {
      // Create new
      budget = await Budget.create({
        userId,
        categoryId: categoryId ? new mongoose.Types.ObjectId(categoryId) : null,
        amount,
        period: period || 'monthly',
        month: parseInt(month),
        year: parseInt(year)
      });
    }
    
    await budget.populate('categoryId', 'name icon color type');
    res.json(budget);
  } catch (error) {
    console.error('Create budget error:', error);
    res.status(500).json({ message: 'Error creating budget', error: error.message });
  }
};

// Update a budget
const updateBudget = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const budgetId = new mongoose.Types.ObjectId(req.params.id);
    
    const { amount, period } = req.body;
    
    const budget = await Budget.findOne({ _id: budgetId, userId });
    if (!budget) {
      return res.status(404).json({ message: 'Budget not found or access denied' });
    }
    
    if (amount !== undefined) budget.amount = amount;
    if (period && ['monthly', 'weekly', 'yearly'].includes(period)) {
      budget.period = period;
    }
    
    await budget.save();
    await budget.populate('categoryId', 'name icon color type');
    res.json(budget);
  } catch (error) {
    console.error('Update budget error:', error);
    res.status(500).json({ message: 'Error updating budget', error: error.message });
  }
};

// Delete a budget
const deleteBudget = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const budgetId = new mongoose.Types.ObjectId(req.params.id);
    
    const budget = await Budget.findOneAndDelete({ _id: budgetId, userId });
    if (!budget) {
      return res.status(404).json({ message: 'Budget not found or access denied' });
    }
    
    res.status(204).send();
  } catch (error) {
    console.error('Delete budget error:', error);
    res.status(500).json({ message: 'Error deleting budget', error: error.message });
  }
};

module.exports = { getBudgets, createBudget, updateBudget, deleteBudget };

