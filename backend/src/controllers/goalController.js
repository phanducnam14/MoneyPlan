const Goal = require('../models/Goal');
const mongoose = require('mongoose');

// Get all goals for current user
const getGoals = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const { isCompleted } = req.query;
    
    const filter = { userId };
    if (isCompleted !== undefined) {
      filter.isCompleted = isCompleted === 'true';
    }
    
    const goals = await Goal.find(filter).sort({ isCompleted: 1, deadline: 1 });
    
    // Calculate progress percentage
    const goalsWithProgress = goals.map(goal => ({
      ...goal.toObject(),
      progress: goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount) * 100 : 0,
      remaining: Math.max(0, goal.targetAmount - goal.currentAmount)
    }));
    
    res.json({ data: goalsWithProgress });
  } catch (error) {
    console.error('Get goals error:', error);
    res.status(500).json({ message: 'Error fetching goals', error: error.message });
  }
};

// Create a new goal
const createGoal = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const { title, targetAmount, currentAmount, deadline, icon, color } = req.body;
    
    if (!title || !targetAmount) {
      return res.status(400).json({ message: 'Title and target amount are required' });
    }
    
    const goal = await Goal.create({
      userId,
      title,
      targetAmount: Number(targetAmount),
      currentAmount: Number(currentAmount) || 0,
      deadline: deadline ? new Date(deadline) : null,
      icon: icon || 'flag',
      color: color || '#10B981'
    });
    
    res.status(201).json(goal);
  } catch (error) {
    console.error('Create goal error:', error);
    res.status(500).json({ message: 'Error creating goal', error: error.message });
  }
};

// Update a goal
const updateGoal = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const goalId = new mongoose.Types.ObjectId(req.params.id);
    
    const { title, targetAmount, currentAmount, deadline, icon, color, isCompleted } = req.body;
    
    const goal = await Goal.findOne({ _id: goalId, userId });
    if (!goal) {
      return res.status(404).json({ message: 'Goal not found or access denied' });
    }
    
    if (title) goal.title = title;
    if (targetAmount !== undefined) goal.targetAmount = Number(targetAmount);
    if (currentAmount !== undefined) goal.currentAmount = Number(currentAmount);
    if (deadline) goal.deadline = new Date(deadline);
    if (icon) goal.icon = icon;
    if (color) goal.color = color;
    if (isCompleted !== undefined) {
      goal.isCompleted = isCompleted;
      if (isCompleted && !goal.completedAt) {
        goal.completedAt = new Date();
      }
    }
    
    await goal.save();
    res.json(goal);
  } catch (error) {
    console.error('Update goal error:', error);
    res.status(500).json({ message: 'Error updating goal', error: error.message });
  }
};

// Add savings to a goal
const addSavings = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const goalId = new mongoose.Types.ObjectId(req.params.id);
    const { amount } = req.body;
    
    if (!amount || amount <= 0) {
      return res.status(400).json({ message: 'Valid amount is required' });
    }
    
    const goal = await Goal.findOne({ _id: goalId, userId });
    if (!goal) {
      return res.status(404).json({ message: 'Goal not found or access denied' });
    }
    
    goal.currentAmount += Number(amount);
    
    // Auto-complete if target reached
    if (goal.currentAmount >= goal.targetAmount && !goal.isCompleted) {
      goal.isCompleted = true;
      goal.completedAt = new Date();
    }
    
    await goal.save();
    res.json({
      ...goal.toObject(),
      progress: (goal.currentAmount / goal.targetAmount) * 100,
      remaining: Math.max(0, goal.targetAmount - goal.currentAmount)
    });
  } catch (error) {
    console.error('Add savings error:', error);
    res.status(500).json({ message: 'Error adding savings', error: error.message });
  }
};

// Delete a goal
const deleteGoal = async (req, res) => {
  try {
    const userId = new mongoose.Types.ObjectId(req.user.id);
    const goalId = new mongoose.Types.ObjectId(req.params.id);
    
    const goal = await Goal.findOne({ _id: goalId, userId });
    if (!goal) {
      return res.status(404).json({ message: 'Goal not found or access denied' });
    }
    
    await Goal.deleteOne({ _id: goalId });
    res.status(204).send();
  } catch (error) {
    console.error('Delete goal error:', error);
    res.status(500).json({ message: 'Error deleting goal', error: error.message });
  }
};

module.exports = { getGoals, createGoal, updateGoal, addSavings, deleteGoal };
