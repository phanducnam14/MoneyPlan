const Expense = require('../models/Expense');
const Income = require('../models/Income');
const mongoose = require('mongoose');

// Search transactions (both expenses and incomes)
const searchTransactions = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const { 
      query,           // Search text in category/source/note
      type,            // 'expense' or 'income'
      minAmount,       // Minimum amount
      maxAmount,       // Maximum amount
      category,        // Specific category
      startDate,       // Start date filter
      endDate,         // End date filter
      page = 1,        // Page number
      limit = 20       // Items per page
    } = req.query;
    
    const pageNum = parseInt(page);
    const limitNum = Math.min(parseInt(limit), 100);
    const skip = Math.max(0, (pageNum - 1) * limitNum);
    
    // Build expense query
    const expenseQuery = { userId };
    const incomeQuery = { userId };
    
    // Amount filters
    if (minAmount) {
      expenseQuery.amount = { ...expenseQuery.amount, $gte: parseFloat(minAmount) };
      incomeQuery.amount = { ...incomeQuery.amount, $gte: parseFloat(minAmount) };
    }
    if (maxAmount) {
      expenseQuery.amount = { ...expenseQuery.amount, $lte: parseFloat(maxAmount) };
      incomeQuery.amount = { ...incomeQuery.amount, $lte: parseFloat(maxAmount) };
    }
    
    // Category filter
    if (category) {
      expenseQuery.category = category;
      incomeQuery.source = category; // For income, source is like category
    }
    
    // Date filters
    if (startDate) {
      const start = new Date(startDate);
      expenseQuery.date = { ...expenseQuery.date, $gte: start };
      incomeQuery.date = { ...incomeQuery.date, $gte: start };
    }
    if (endDate) {
      const end = new Date(endDate);
      expenseQuery.date = { ...expenseQuery.date, $lte: end };
      incomeQuery.date = { ...incomeQuery.date, $lte: end };
    }
    
    // Text search (category, note)
    if (query) {
      const regex = new RegExp(query, 'i');
      expenseQuery.$or = [
        { category: regex },
        { note: regex }
      ];
      incomeQuery.$or = [
        { source: regex },
        { note: regex }
      ];
    }
    
    let expenses = [];
    let incomes = [];
    let totalExpenses = 0;
    let totalIncomes = 0;
    
    // Get expenses
    if (!type || type === 'expense') {
      [expenses, totalExpenses] = await Promise.all([
        Expense.find(expenseQuery)
          .sort({ date: -1 })
          .skip(skip)
          .limit(limitNum),
        Expense.countDocuments(expenseQuery)
      ]);
    }
    
    // Get incomes
    if (!type || type === 'income') {
      [incomes, totalIncomes] = await Promise.all([
        Income.find(incomeQuery)
          .sort({ date: -1 })
          .skip(skip)
          .limit(limitNum),
        Income.countDocuments(incomeQuery)
      ]);
    }
    
    // Combine and sort by date
    const allTransactions = [
      ...expenses.map(e => ({ ...e.toObject(), transactionType: 'expense' })),
      ...incomes.map(i => ({ ...i.toObject(), transactionType: 'income' }))
    ].sort((a, b) => new Date(b.date) - new Date(a.date));
    
    // Apply pagination after sorting
    const paginatedTransactions = allTransactions.slice(0, limitNum);
    
    res.json({
      data: paginatedTransactions,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total: totalExpenses + totalIncomes,
        pages: Math.ceil((totalExpenses + totalIncomes) / limitNum)
      },
      summary: {
        totalExpenses: expenses.reduce((sum, e) => sum + e.amount, 0),
        totalIncomes: incomes.reduce((sum, i) => sum + i.amount, 0)
      }
    });
  } catch (error) {
    console.error('Search transactions error:', error);
    res.status(500).json({ message: 'Error searching transactions', error: error.message });
  }
};

// Get statistics by category
const getCategoryStats = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const { month, year } = req.query;
    
    const currentDate = new Date();
    const queryMonth = month ? parseInt(month) : currentDate.getMonth() + 1;
    const queryYear = year ? parseInt(year) : currentDate.getFullYear();
    
    const startDate = new Date(queryYear, queryMonth - 1, 1);
    const endDate = new Date(queryYear, queryMonth, 0, 23, 59, 59);
    
    // Get expense stats by category
    const expenseStats = await Expense.aggregate([
      {
        $match: {
          userId,
          date: { $gte: startDate, $lte: endDate }
        }
      },
      {
        $group: {
          _id: '$category',
          total: { $sum: '$amount' },
          count: { $sum: 1 },
          avg: { $avg: '$amount' }
        }
      },
      {
        $sort: { total: -1 }
      }
    ]);
    
    // Get income stats by source
    const incomeStats = await Income.aggregate([
      {
        $match: {
          userId,
          date: { $gte: startDate, $lte: endDate }
        }
      },
      {
        $group: {
          _id: '$source',
          total: { $sum: '$amount' },
          count: { $sum: 1 },
          avg: { $avg: '$amount' }
        }
      },
      {
        $sort: { total: -1 }
      }
    ]);
    
    const totalExpenses = expenseStats.reduce((sum, e) => sum + e.total, 0);
    const totalIncomes = incomeStats.reduce((sum, i) => sum + i.total, 0);
    
    res.json({
      expenses: {
        data: expenseStats.map(e => ({
          category: e._id,
          total: e.total,
          count: e.count,
          average: e.avg,
          percent: totalExpenses > 0 ? Math.round((e.total / totalExpenses) * 100) : 0
        })),
        total: totalExpenses
      },
      incomes: {
        data: incomeStats.map(i => ({
          source: i._id,
          total: i.total,
          count: i.count,
          average: i.avg,
          percent: totalIncomes > 0 ? Math.round((i.total / totalIncomes) * 100) : 0
        })),
        total: totalIncomes
      },
      month: queryMonth,
      year: queryYear
    });
  } catch (error) {
    console.error('Get category stats error:', error);
    res.status(500).json({ message: 'Error fetching category statistics', error: error.message });
  }
};

// Get monthly comparison statistics
const getMonthlyStats = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const { months = 6 } = req.query;
    
    const numMonths = parseInt(months);
    const currentDate = new Date();
    const stats = [];
    
    for (let i = 0; i < numMonths; i++) {
      const targetDate = new Date(currentDate.getFullYear(), currentDate.getMonth() - i, 1);
      const month = targetDate.getMonth() + 1;
      const year = targetDate.getFullYear();
      
      const startDate = new Date(year, month - 1, 1);
      const endDate = new Date(year, month, 0, 23, 59, 59);
      
      const [expenseResult, incomeResult] = await Promise.all([
        Expense.aggregate([
          { $match: { userId, date: { $gte: startDate, $lte: endDate } } },
          { $group: { _id: null, total: { $sum: '$amount' }, count: { $sum: 1 } } }
        ]),
        Income.aggregate([
          { $match: { userId, date: { $gte: startDate, $lte: endDate } } },
          { $group: { _id: null, total: { $sum: '$amount' }, count: { $sum: 1 } } }
        ])
      ]);
      
      stats.push({
        month,
        year,
        label: `${year}-${month.toString().padStart(2, '0')}`,
        expenses: expenseResult[0]?.total || 0,
        expenseCount: expenseResult[0]?.count || 0,
        incomes: incomeResult[0]?.total || 0,
        incomeCount: incomeResult[0]?.count || 0,
        balance: (incomeResult[0]?.total || 0) - (expenseResult[0]?.total || 0)
      });
    }
    
    // Reverse to show oldest first
    res.json({ data: stats.reverse() });
  } catch (error) {
    console.error('Get monthly stats error:', error);
    res.status(500).json({ message: 'Error fetching monthly statistics', error: error.message });
  }
};

module.exports = { searchTransactions, getCategoryStats, getMonthlyStats };

