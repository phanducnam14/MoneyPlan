const User = require('../models/User');
const Expense = require('../models/Expense');
const Income = require('../models/Income');
const mongoose = require('mongoose');

const getUsers = async (_req, res) => {
  try {
    const users = await User.find().select('-password');
    res.json(users);
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ message: 'Error fetching users', error: error.message });
  }
};

const blockUser = async (req, res) => {
  try {
    const { blocked } = req.body;
    const userId = new mongoose.Types.ObjectId(req.params.id);
    
    const user = await User.findByIdAndUpdate(userId, { blocked }, { new: true }).select('-password');
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    res.json(user);
  } catch (error) {
    console.error('Block user error:', error);
    res.status(500).json({ message: 'Error blocking user', error: error.message });
  }
};

const systemStats = async (_req, res) => {
  try {
    const [userCount, expenseStats, incomeStats] = await Promise.all([
      User.countDocuments(),
      Expense.aggregate([
        { $group: { _id: null, total: { $sum: '$amount' }, count: { $sum: 1 } } }
      ]),
      Income.aggregate([
        { $group: { _id: null, total: { $sum: '$amount' }, count: { $sum: 1 } } }
      ])
    ]);
    
    res.json({
      userCount,
      totalExpenses: expenseStats[0]?.total || 0,
      totalExpenseCount: expenseStats[0]?.count || 0,
      totalIncomes: incomeStats[0]?.total || 0,
      totalIncomeCount: incomeStats[0]?.count || 0,
      timestamp: new Date()
    });
  } catch (error) {
    console.error('System stats error:', error);
    res.status(500).json({ message: 'Error fetching system stats', error: error.message });
  }
};

// Get per-user statistics (admin can view any user's stats)
const getUserStats = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.params.id);
    
    const user = await User.findById(userId).select('-password');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    const [expenseStats, incomeStats] = await Promise.all([
      Expense.aggregate([
        { $match: { userId } },
        { $group: { _id: null, total: { $sum: '$amount' }, count: { $sum: 1 }, avg: { $avg: '$amount' } } }
      ]),
      Income.aggregate([
        { $match: { userId } },
        { $group: { _id: null, total: { $sum: '$amount' }, count: { $sum: 1 }, avg: { $avg: '$amount' } } }
      ])
    ]);
    
    res.json({
      user: {
        _id: user._id,
        name: user.name,
        email: user.email,
        role: user.role
      },
      expenses: {
        total: expenseStats[0]?.total || 0,
        count: expenseStats[0]?.count || 0,
        average: expenseStats[0]?.avg || 0
      },
      incomes: {
        total: incomeStats[0]?.total || 0,
        count: incomeStats[0]?.count || 0,
        average: incomeStats[0]?.avg || 0
      }
    });
  } catch (error) {
    console.error('Get user stats error:', error);
    res.status(500).json({ message: 'Error fetching user stats', error: error.message });
  }
};

module.exports = { getUsers, blockUser, systemStats, getUserStats };
