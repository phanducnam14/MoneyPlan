const mongoose = require('mongoose');

const budgetSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    categoryId: { type: mongoose.Schema.Types.ObjectId, ref: 'Category' },
    amount: { type: Number, required: true },
    period: { type: String, enum: ['monthly', 'weekly', 'yearly'], default: 'monthly' },
    month: { type: Number, required: true }, // 1-12
    year: { type: Number, required: true },
    spent: { type: Number, default: 0 },
  },
  { timestamps: true }
);

// Compound index for user + month + year + category
budgetSchema.index({ userId: 1, month: 1, year: 1, categoryId: 1 }, { unique: true });

// Calculate remaining budget
budgetSchema.virtual('remaining').get(function() {
  return this.amount - this.spent;
});

// Check if over budget
budgetSchema.virtual('isOverBudget').get(function() {
  return this.spent > this.amount;
});

// Get percentage used
budgetSchema.virtual('percentUsed').get(function() {
  if (this.amount === 0) return 0;
  return Math.round((this.spent / this.amount) * 100);
});

module.exports = mongoose.model('Budget', budgetSchema);

