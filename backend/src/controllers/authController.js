const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Expense = require('../models/Expense');
const Income = require('../models/Income');
const mongoose = require('mongoose');

const register = async (req, res) => {
  try {
    const { name, email, password, dateOfBirth, gender } = req.body;

    // Validate required fields
    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Name, email, and password are required' });
    }

    const exists = await User.findOne({ email });
    if (exists) return res.status(400).json({ message: 'Email already exists' });

    const hashed = await bcrypt.hash(password, 10);
    const user = await User.create({ name, email, password: hashed, dateOfBirth, gender });
    
    // Auto-login after successful registration
    // NOTE: New user starts with EMPTY financial data (no expenses/incomes inherited)
    const token = jwt.sign({ id: user._id, role: user.role }, process.env.JWT_SECRET || 'secret_key', { expiresIn: '7d' });
    res.status(201).json({ 
      token, 
      user: {
        _id: user._id,
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        monthlyBudget: user.monthlyBudget || 0,
        avatar: user.avatar,
        dateOfBirth: user.dateOfBirth,
        gender: user.gender
      }
    });
  } catch (error) {
    res.status(500).json({ message: 'Error creating account', error: error.message });
  }
};

const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validate required fields
    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }

    const user = await User.findOne({ email });
    if (!user) return res.status(401).json({ message: 'Invalid credentials' });
    if (user.blocked) return res.status(403).json({ message: 'Account blocked' });

    const ok = await bcrypt.compare(password, user.password);
    if (!ok) return res.status(401).json({ message: 'Invalid credentials' });

    const token = jwt.sign({ id: user._id, role: user.role }, process.env.JWT_SECRET || 'secret_key', { expiresIn: '7d' });
    
    // Return user without password
    const { password: _, ...userWithoutPassword } = user.toObject();
    
    res.json({ 
      token, 
      user: {
        _id: userWithoutPassword._id,
        id: userWithoutPassword._id,
        name: userWithoutPassword.name,
        email: userWithoutPassword.email,
        role: userWithoutPassword.role,
        monthlyBudget: userWithoutPassword.monthlyBudget || 0,
        avatar: userWithoutPassword.avatar,
        dateOfBirth: userWithoutPassword.dateOfBirth,
        gender: userWithoutPassword.gender
      }
    });
  } catch (error) {
    res.status(500).json({ message: 'Error logging in', error: error.message });
  }
};

const forgotPassword = async (req, res) => {
  const { email } = req.body;
  res.json({ message: `Mock email sent to ${email}` });
};

const changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const userId = req.user.id;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({ message: 'Please provide current and new password' });
    }

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: 'User not found' });

    const isValid = await bcrypt.compare(currentPassword, user.password);
    if (!isValid) {
      return res.status(401).json({ message: 'Current password is incorrect' });
    }

    const hashed = await bcrypt.hash(newPassword, 10);
    user.password = hashed;
    await user.save();

    res.json({ message: 'Password changed successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Error changing password', error: error.message });
  }
};

const changeEmail = async (req, res) => {
  try {
    const { newEmail, password } = req.body;
    const userId = req.user.id;

    if (!newEmail || !password) {
      return res.status(400).json({ message: 'Please provide new email and password' });
    }

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: 'User not found' });

    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) {
      return res.status(401).json({ message: 'Password is incorrect' });
    }

    const emailExists = await User.findOne({ email: newEmail });
    if (emailExists) {
      return res.status(400).json({ message: 'Email already in use' });
    }

    user.email = newEmail;
    await user.save();

    res.json({ message: 'Email changed successfully', user: { email: user.email } });
  } catch (error) {
    res.status(500).json({ message: 'Error changing email', error: error.message });
  }
};

// Get current user profile (who is logged in)
const getProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const user = await User.findById(userId).select('-password');
    
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    
    res.json({
      _id: user._id,
      id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
      monthlyBudget: user.monthlyBudget || 0,
      avatar: user.avatar,
      dateOfBirth: user.dateOfBirth,
      gender: user.gender,
      createdAt: user.createdAt
    });
  } catch (error) {
    res.status(500).json({ message: 'Error fetching profile', error: error.message });
  }
};

// Update current user profile
const updateProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const { name, avatar, dateOfBirth, gender, monthlyBudget } = req.body;
    
    const updateData = {};
    if (name) updateData.name = name;
    if (avatar !== undefined) updateData.avatar = avatar;
    if (dateOfBirth) updateData.dateOfBirth = dateOfBirth;
    if (gender) updateData.gender = gender;
    if (monthlyBudget !== undefined) updateData.monthlyBudget = monthlyBudget;
    
    const user = await User.findByIdAndUpdate(userId, updateData, { new: true }).select('-password');
    
    res.json({
      _id: user._id,
      id: user._id,
      name: user.name,
      email: user.email,
      role: user.role,
      monthlyBudget: user.monthlyBudget || 0,
      avatar: user.avatar,
      dateOfBirth: user.dateOfBirth,
      gender: user.gender
    });
  } catch (error) {
    res.status(500).json({ message: 'Error updating profile', error: error.message });
  }
};

// Get current user's statistics (income, expenses, summary)
const getUserStats = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    
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
    
    const totalExpenses = expenseStats[0]?.total || 0;
    const totalIncomes = incomeStats[0]?.total || 0;
    const balance = totalIncomes - totalExpenses;
    
    res.json({
      expenses: {
        total: totalExpenses,
        count: expenseStats[0]?.count || 0,
        average: expenseStats[0]?.avg || 0
      },
      incomes: {
        total: totalIncomes,
        count: incomeStats[0]?.count || 0,
        average: incomeStats[0]?.avg || 0
      },
      summary: {
        totalIncomes,
        totalExpenses,
        balance,
        lastUpdated: new Date()
      }
    });
  } catch (error) {
    console.error('Get user stats error:', error);
    res.status(500).json({ message: 'Error fetching statistics', error: error.message });
  }
};

// Reset all financial data for current user (admin-like operation on own account)
const resetUserData = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    
    // Delete all expenses and incomes for this user
    const [expensesDeleted, incomesDeleted] = await Promise.all([
      Expense.deleteMany({ userId }),
      Income.deleteMany({ userId })
    ]);
    
    res.json({
      message: 'Financial data reset successfully',
      data: {
        expensesDeleted: expensesDeleted.deletedCount,
        incomesDeleted: incomesDeleted.deletedCount,
        timestamp: new Date()
      }
    });
  } catch (error) {
    console.error('Reset user data error:', error);
    res.status(500).json({ message: 'Error resetting financial data', error: error.message });
  }
};

module.exports = { register, login, forgotPassword, changePassword, changeEmail, getProfile, updateProfile, getUserStats, resetUserData };
