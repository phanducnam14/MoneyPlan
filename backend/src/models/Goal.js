const mongoose = require('mongoose');

const goalSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    title: { type: String, required: true },
    targetAmount: { type: Number, required: true },
    currentAmount: { type: Number, default: 0 },
    deadline: { type: Date },
    icon: { type: String, default: 'flag' },
    color: { type: String, default: '#10B981' },
    isCompleted: { type: Boolean, default: false },
    completedAt: { type: Date }
  },
  { timestamps: true }
);

goalSchema.index({ userId: 1, isCompleted: 1 });

module.exports = mongoose.model('Goal', goalSchema);
