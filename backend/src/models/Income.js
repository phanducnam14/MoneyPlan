const mongoose = require('mongoose');

const incomeSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    amount: { type: Number, required: true },
    source: { type: String, required: true },
    note: String,
    date: { type: Date, required: true },
    walletId: { type: mongoose.Schema.Types.ObjectId, ref: 'Wallet' }
  },
  { timestamps: true }
);

// Ensure userId filter is always enforced
incomeSchema.index({ userId: 1, date: -1 });

module.exports = mongoose.model('Income', incomeSchema);
