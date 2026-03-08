const mongoose = require('mongoose');

const recurringTransactionSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    amount: { type: Number, required: true },
    category: { type: String, required: true },
    type: { type: String, enum: ['expense', 'income'], required: true },
    frequency: { type: String, enum: ['daily', 'weekly', 'monthly', 'yearly'], required: true },
    nextExecutionDate: { type: Date, required: true },
    lastExecutionDate: { type: Date },
    description: { type: String, default: '' },
    isActive: { type: Boolean, default: true },
    walletId: { type: mongoose.Schema.Types.ObjectId, ref: 'Wallet' }
  },
  { timestamps: true }
);

recurringTransactionSchema.index({ userId: 1, isActive: 1 });

module.exports = mongoose.model('RecurringTransaction', recurringTransactionSchema);

