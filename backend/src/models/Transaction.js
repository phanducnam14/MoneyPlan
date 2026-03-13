const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    walletId: { type: mongoose.Schema.Types.ObjectId, ref: 'Wallet', required: true, index: true },
    type: { type: String, enum: ['income', 'expense', 'transfer'], required: true, index: true },
    amount: { type: Number, required: true, min: 0 },
    category: { type: String, required: true },
    note: String,
    date: { type: Date, required: true, index: true },
    sourceType: {
      type: String,
      enum: ['externalIncome', 'wallet', 'external'],
      default: 'external',
      description: 'externalIncome: salary/freelance/etc, wallet: from another wallet, external: general external'
    },
    // For transfer type: which wallet it came from
    fromWalletId: { type: mongoose.Schema.Types.ObjectId, ref: 'Wallet' },
    // For transfer type: which wallet it went to
    toWalletId: { type: mongoose.Schema.Types.ObjectId, ref: 'Wallet' },
    // Reference fields for income/expense metadata
    source: String, // e.g., "Salary", "Freelance" for income
    status: { type: String, enum: ['pending', 'completed', 'cancelled'], default: 'completed' },
    tags: [String],
    // For reconciliation and troubleshooting
    balanceAfter: Number,
    linkedTransactionId: mongoose.Schema.Types.ObjectId // for reversals/adjustments
  },
  { timestamps: true }
);

// Indexes for common queries
transactionSchema.index({ userId: 1, date: -1 });
transactionSchema.index({ userId: 1, walletId: 1, date: -1 });
transactionSchema.index({ userId: 1, type: 1, date: -1 });
transactionSchema.index({ userId: 1, category: 1, date: -1 });

module.exports = mongoose.model('Transaction', transactionSchema);
