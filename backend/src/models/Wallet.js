const mongoose = require('mongoose');

const walletSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    name: { type: String, required: true },
    balance: { type: Number, default: 0 },
    icon: { type: String, default: 'account_balance_wallet' },
    color: { type: String, default: '#6366F1' },
    isDefault: { type: Boolean, default: false },
    type: { type: String, enum: ['cash', 'bank', 'savings', 'investment', 'other'], default: 'cash' }
  },
  { timestamps: true }
);

// Ensure userId + name is unique
walletSchema.index({ userId: 1, name: 1 }, { unique: true });

module.exports = mongoose.model('Wallet', walletSchema);

