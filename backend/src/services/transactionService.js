const Transaction = require('../models/Transaction');
const Wallet = require('../models/Wallet');
const mongoose = require('mongoose');

class TransactionService {
  /**
   * Create an income transaction
   */
  static async createIncome(userId, walletId, amount, category, source, note, date) {
    try {
      const userIdObj = new mongoose.Types.ObjectId(userId);
      const walletIdObj = new mongoose.Types.ObjectId(walletId);

      // Verify wallet ownership
      const wallet = await Wallet.findOne({
        _id: walletIdObj,
        userId: userIdObj
      });

      if (!wallet) {
        throw new Error('Wallet not found or access denied');
      }

      // Validate amount
      if (!amount || amount <= 0) {
        throw new Error('Amount must be greater than 0');
      }

      const transaction = await Transaction.create({
        userId: userIdObj,
        walletId: walletIdObj,
        type: 'income',
        amount: Number(amount),
        category,
        source: source || 'External Income',
        note: note || '',
        date: new Date(date),
        sourceType: 'externalIncome',
        status: 'completed'
      });

      return transaction;
    } catch (error) {
      console.error('Error creating income transaction:', error);
      throw error;
    }
  }

  /**
   * Create an expense transaction
   */
  static async createExpense(userId, walletId, amount, category, note, date) {
    try {
      const userIdObj = new mongoose.Types.ObjectId(userId);
      const walletIdObj = new mongoose.Types.ObjectId(walletId);

      // Verify wallet ownership
      const wallet = await Wallet.findOne({
        _id: walletIdObj,
        userId: userIdObj
      });

      if (!wallet) {
        throw new Error('Wallet not found or access denied');
      }

      // Validate amount
      if (!amount || amount <= 0) {
        throw new Error('Amount must be greater than 0');
      }

      const transaction = await Transaction.create({
        userId: userIdObj,
        walletId: walletIdObj,
        type: 'expense',
        amount: Number(amount),
        category,
        note: note || '',
        date: new Date(date),
        sourceType: 'wallet',
        status: 'completed'
      });

      return transaction;
    } catch (error) {
      console.error('Error creating expense transaction:', error);
      throw error;
    }
  }

  /**
   * Update transaction
   */
  static async updateTransaction(transactionId, userId, updateData) {
    try {
      const userIdObj = new mongoose.Types.ObjectId(userId);
      const transactionIdObj = new mongoose.Types.ObjectId(transactionId);

      // Only allow updating certain fields
      const allowedFields = ['amount', 'category', 'note', 'date'];
      const cleanUpdateData = {};

      allowedFields.forEach(field => {
        if (field in updateData) {
          cleanUpdateData[field] = updateData[field];
        }
      });

      // Make sure date is a proper Date object
      if (cleanUpdateData.date) {
        cleanUpdateData.date = new Date(cleanUpdateData.date);
      }

      const transaction = await Transaction.findOneAndUpdate(
        { _id: transactionIdObj, userId: userIdObj },
        cleanUpdateData,
        { new: true, runValidators: true }
      );

      if (!transaction) {
        throw new Error('Transaction not found or access denied');
      }

      return transaction;
    } catch (error) {
      console.error('Error updating transaction:', error);
      throw error;
    }
  }

  /**
   * Delete transaction
   */
  static async deleteTransaction(transactionId, userId) {
    try {
      const userIdObj = new mongoose.Types.ObjectId(userId);
      const transactionIdObj = new mongoose.Types.ObjectId(transactionId);

      const transaction = await Transaction.findOneAndDelete(
        { _id: transactionIdObj, userId: userIdObj }
      );

      if (!transaction) {
        throw new Error('Transaction not found or access denied');
      }

      // If it's a transfer, delete the linked transaction too
      if (transaction.type === 'transfer' && transaction.linkedTransactionId) {
        await Transaction.deleteOne({
          _id: transaction.linkedTransactionId,
          userId: userIdObj
        });
      }

      return { success: true, deletedId: transactionId };
    } catch (error) {
      console.error('Error deleting transaction:', error);
      throw error;
    }
  }

  /**
   * Get transaction by ID with verification
   */
  static async getTransactionById(transactionId, userId) {
    try {
      const userIdObj = new mongoose.Types.ObjectId(userId);
      const transactionIdObj = new mongoose.Types.ObjectId(transactionId);

      const transaction = await Transaction.findOne({
        _id: transactionIdObj,
        userId: userIdObj
      }).populate('walletId', 'name');

      if (!transaction) {
        throw new Error('Transaction not found or access denied');
      }

      return transaction;
    } catch (error) {
      console.error('Error fetching transaction:', error);
      throw error;
    }
  }

  /**
   * Get transactions by wallet
   */
  static async getTransactionsByWallet(walletId, userId, page = 1, limit = 10) {
    try {
      const userIdObj = new mongoose.Types.ObjectId(userId);
      const walletIdObj = new mongoose.Types.ObjectId(walletId);

      // Verify wallet ownership
      const wallet = await Wallet.findOne({
        _id: walletIdObj,
        userId: userIdObj
      });

      if (!wallet) {
        throw new Error('Wallet not found or access denied');
      }

      const skip = Math.max(0, (page - 1) * limit);

      const transactions = await Transaction.find({
        userId: userIdObj,
        walletId: walletIdObj
      })
        .sort({ date: -1 })
        .skip(skip)
        .limit(Math.min(limit, 100));

      const total = await Transaction.countDocuments({
        userId: userIdObj,
        walletId: walletIdObj
      });

      return {
        data: transactions,
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit)
        }
      };
    } catch (error) {
      console.error('Error fetching wallet transactions:', error);
      throw error;
    }
  }

  /**
   * Get all user transactions
   */
  static async getAllUserTransactions(userId, page = 1, limit = 10, filters = {}) {
    try {
      const userIdObj = new mongoose.Types.ObjectId(userId);

      // Build filter query
      const query = { userId: userIdObj };

      if (filters.type) {
        query.type = filters.type;
      }

      if (filters.category) {
        query.category = filters.category;
      }

      if (filters.walletId) {
        query.walletId = new mongoose.Types.ObjectId(filters.walletId);
      }

      // Date range filter
      if (filters.startDate || filters.endDate) {
        query.date = {};
        if (filters.startDate) {
          query.date.$gte = new Date(filters.startDate);
        }
        if (filters.endDate) {
          query.date.$lte = new Date(filters.endDate);
        }
      }

      const skip = Math.max(0, (page - 1) * limit);

      const transactions = await Transaction.find(query)
        .populate('walletId', 'name type')
        .sort({ date: -1 })
        .skip(skip)
        .limit(Math.min(limit, 100));

      const total = await Transaction.countDocuments(query);

      return {
        data: transactions,
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit)
        }
      };
    } catch (error) {
      console.error('Error fetching user transactions:', error);
      throw error;
    }
  }

  /**
   * Get transaction statistics for user
   */
  static async getUserTransactionStats(userId) {
    try {
      const userIdObj = new mongoose.Types.ObjectId(userId);

      const stats = await Transaction.aggregate([
        { $match: { userId: userIdObj, status: 'completed' } },
        {
          $group: {
            _id: '$type',
            total: { $sum: '$amount' },
            count: { $sum: 1 },
            avg: { $avg: '$amount' }
          }
        }
      ]);

      const byCategory = await Transaction.aggregate([
        { $match: { userId: userIdObj, status: 'completed' } },
        {
          $group: {
            _id: '$category',
            total: { $sum: '$amount' },
            count: { $sum: 1 },
            type: { $first: '$type' }
          }
        },
        { $sort: { total: -1 } }
      ]);

      return {
        byType: stats,
        byCategory,
        summary: {
          income: stats.find(s => s._id === 'income')?.total || 0,
          expense: stats.find(s => s._id === 'expense')?.total || 0,
          transfer: stats.find(s => s._id === 'transfer')?.total || 0
        }
      };
    } catch (error) {
      console.error('Error calculating transaction stats:', error);
      throw error;
    }
  }
}

module.exports = TransactionService;
