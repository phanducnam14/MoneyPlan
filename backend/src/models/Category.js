const mongoose = require('mongoose');

const categorySchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    name: { type: String, required: true },
    type: { type: String, enum: ['expense', 'income'], required: true },
    icon: { type: String, default: 'category' },
    color: { type: String, default: '#6366F1' },
    isDefault: { type: Boolean, default: false },
  },
  { timestamps: true }
);

// Ensure userId + name + type is unique for user
categorySchema.index({ userId: 1, name: 1, type: 1 }, { unique: true });

// Default categories for new users
const defaultExpenseCategories = [
  { name: 'Ăn uống', icon: 'restaurant', color: '#FF6B6B' },
  { name: 'Nhà ở', icon: 'home', color: '#4ECDC4' },
  { name: 'Di chuyển', icon: 'directions_car', color: '#45B7D1' },
  { name: 'Giải trí', icon: 'movie', color: '#96CEB4' },
  { name: 'Học tập', icon: 'school', color: '#FFEAA7' },
  { name: 'Sức khỏe', icon: 'medical_services', color: '#DDA0DD' },
  { name: 'Mua sắm', icon: 'shopping_bag', color: '#98D8C8' },
  { name: 'Khác', icon: 'category', color: '#95A5A6' },
];

const defaultIncomeCategories = [
  { name: 'Lương', icon: 'work', color: '#2ECC71' },
  { name: 'Freelance', icon: 'laptop', color: '#3498DB' },
  { name: 'Đầu tư', icon: 'trending_up', color: '#9B59B6' },
  { name: 'Quà tặng', icon: 'card_giftcard', color: '#E74C3C' },
  { name: 'Khác', icon: 'attach_money', color: '#95A5A6' },
];

// Static method to create default categories for a user
categorySchema.statics.createDefaultsForUser = async function(userId) {
  const categories = [];
  
  for (const cat of defaultExpenseCategories) {
    categories.push({
      userId,
      name: cat.name,
      type: 'expense',
      icon: cat.icon,
      color: cat.color,
      isDefault: true,
    });
  }
  
  for (const cat of defaultIncomeCategories) {
    categories.push({
      userId,
      name: cat.name,
      type: 'income',
      icon: cat.icon,
      color: cat.color,
      isDefault: true,
    });
  }
  
  await this.insertMany(categories);
  return categories;
};

module.exports = mongoose.model('Category', categorySchema);

