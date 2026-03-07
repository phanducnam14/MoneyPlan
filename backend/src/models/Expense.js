const mongoose = require('mongoose');

const expenseSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    amount: { type: Number, required: true },
    category: { type: String, required: true },
    note: String,
    date: { type: Date, required: true }
  },
  { timestamps: true }
);

// Ensure userId filter is always enforced
expenseSchema.index({ userId: 1, date: -1 });

module.exports = mongoose.model('Expense', expenseSchema);
