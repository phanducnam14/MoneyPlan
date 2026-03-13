const Wallet = require('../models/Wallet');
const Transaction = require('../models/Transaction');
const mongoose = require('mongoose');

class WalletService {
  /**
   * Create a default wallet for a new user
   */
  static async createDefaultWallet(userId) {
    try {
      const exists = await Wallet.findOne({ userId, isDefault: true });
      if (exists) return exists;

      const wallet = await Wallet.create({
        userId,
        name: 'My Wallet',
        balance: 0,
        type: 'cash',
        isDefault: true,
        icon: 'account_balance_wallet',
        color: '#6366F1'
      });

      console.log(`Default wallet created for user ${userId}`);
      return wallet;
    } catch (error) {
      console.error('Error creating default wallet:', error);
      throw error;
    }
  }

  /**
   * Get wallet with verified user ownership
   */
  static async getWalletWithVerification(walletId, userId) {
    const wallet = await Wallet.findOne({
      _id: walletId,
      userId
    });

    if (!wallet) {
      throw new Error('Wallet not found or access denied');
    }

    return wallet;
  }

  /**
   * Get all wallets for a user with calculated balances
   */
  static async getUserWallets(userId) {
    try {
      const userIdObj = new mongoose.Types.ObjectId(userId);

      const wallets = await Wallet.find({ userId: userIdObj }).sort({
        isDefault: -1,
        name: 1
      });

      // Calculate actual balance for each wallet based on transactions
      const walletBalances = await Promise.all(
        wallets.map(async (wallet) => {
          const balance = await this.calculateWalletBalance(wallet._id, userIdObj);

          return {
            ...wallet.toObject(),
            actualBalance: balance,
            displayBalance: balance
          };
        })
      );

      return walletBalances;
    } catch (error) {
      console.error('Error fetching wallets:', error);
      throw error;
    }
  }

  /**
   * Calculate actual wallet balance from transactions
   * Income increases balance, Expense decreases balance
   */
  static async calculateWalletBalance(walletId, userId) {
    try {
      const walletIdObj = new mongoose.Types.ObjectId(walletId);
      const userIdObj = new mongoose.Types.ObjectId(userId);

      const [incomTotal, expenseTotal] = await Promise.all([
        Transaction.aggregate([
          {
            $match: {
              userId: userIdObj,
              walletId: walletIdObj,
              type: 'income',
              status: 'completed'
            }
          },
          { $group: { _id: null, total: { $sum: '$amount' } } }
        ]),
        Transaction.aggregate([
          {
            $match: {
              userId: userIdObj,
              walletId: walletIdObj,
              type: 'expense',
              status: 'completed'
            }
          },
          { $group: { _id: null, total: { $sum: '$amount' } } }
        ])
      ]);

      const incomeAmount = incomTotal[0]?.total || 0;
      const expenseAmount = expenseTotal[0]?.total || 0;

      // Get initial wallet balance
      const wallet = await Wallet.findById(walletIdObj);
      const initialBalance = wallet?.balance || 0;

      // Actual balance = initial + income - expense
      const actualBalance = initialBalance + incomeAmount - expenseAmount;

      return Math.max(0, actualBalance); // Prevent negative balance display
    } catch (error) {
      console.error('Error calculating wallet balance:', error);
      throw error;
    }
  }

  /**
   * Add income to wallet
   * This is called when a transaction of type 'income' is created
   */
  static async addIncome(walletId, userId, amount, category, source, note, date) {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
      const userIdObj = new mongoose.Types.ObjectId(userId);
      const walletIdObj = new mongoose.Types.ObjectId(walletId);

      // Verify wallet ownership
      const wallet = await Wallet.findOne({
        _id: walletIdObj,
        userId: userIdObj
      }).session(session);

      if (!wallet) {
        throw new Error('Wallet not found or access denied');
      }

      // Create transaction record
      const transaction = await Transaction.create(
        [
          {
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
          }
        ],
        { session }
      );

      await session.commitTransaction();
      return transaction[0];
    } catch (error) {
      await session.abortTransaction();
      throw error;
    } finally {
      await session.endSession();
    }
  }

  /**
   * Deduct expense from wallet
   * This is called when a transaction of type 'expense' is created
   */
  static async deductExpense(walletId, userId, amount, category, note, date) {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
      const userIdObj = new mongoose.Types.ObjectId(userId);
      const walletIdObj = new mongoose.Types.ObjectId(walletId);

      // Verify wallet ownership
      const wallet = await Wallet.findOne({
        _id: walletIdObj,
        userId: userIdObj
      }).session(session);

      if (!wallet) {
        throw new Error('Wallet not found or access denied');
      }

      // Create transaction record
      const transaction = await Transaction.create(
        [
          {
            userId: userIdObj,
            walletId: walletIdObj,
            type: 'expense',
            amount: Number(amount),
            category,
            note: note || '',
            date: new Date(date),
            sourceType: 'wallet',
            status: 'completed'
          }
        ],
        { session }
      );

      await session.commitTransaction();
      return transaction[0];
    } catch (error) {
      await session.abortTransaction();
      throw error;
    } finally {
      await session.endSession();
    }
  }

  /**
   * Transfer money between wallets
   */
  static async transferBetweenWallets(
    fromWalletId,
    toWalletId,
    userId,
    amount,
    note,
    date
  ) {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
      const userIdObj = new mongoose.Types.ObjectId(userId);
      const fromWalletIdObj = new mongoose.Types.ObjectId(fromWalletId);
      const toWalletIdObj = new mongoose.Types.ObjectId(toWalletId);

      // Verify both wallets belong to user
      const [fromWallet, toWallet] = await Promise.all([
        Wallet.findOne({
          _id: fromWalletIdObj,
          userId: userIdObj
        }).session(session),
        Wallet.findOne({
          _id: toWalletIdObj,
          userId: userIdObj
        }).session(session)
      ]);

      if (!fromWallet || !toWallet) {
        throw new Error('One or both wallets not found or access denied');
      }

      // Create two linked transactions: expense from source, income to destination
      const transactions = await Transaction.create(
        [
          {
            userId: userIdObj,
            walletId: fromWalletIdObj,
            type: 'expense',
            amount: Number(amount),
            category: 'Transfer',
            note: `Transfer to ${toWallet.name}` + (note ? `: ${note}` : ''),
            date: new Date(date),
            sourceType: 'wallet',
            fromWalletId: fromWalletIdObj,
            toWalletId: toWalletIdObj,
            status: 'completed'
          },
          {
            userId: userIdObj,
            walletId: toWalletIdObj,
            type: 'income',
            amount: Number(amount),
            category: 'Transfer',
            note: `Transfer from ${fromWallet.name}` + (note ? `: ${note}` : ''),
            date: new Date(date),
            sourceType: 'wallet',
            fromWalletId: fromWalletIdObj,
            toWalletId: toWalletIdObj,
            status: 'completed'
          }
        ],
        { session }
      );

      // Link transactions together
      const linkedId = transactions[0]._id;
      await Transaction.updateMany(
        { _id: { $in: [transactions[0]._id, transactions[1]._id] } },
        { linkedTransactionId: linkedId },
        { session }
      );

      await session.commitTransaction();
      return transactions;
    } catch (error) {
      await session.abortTransaction();
      throw error;
    } finally {
      await session.endSession();
    }
  }

  /**
   * Delete transaction and adjust wallet balance
   */
  static async deleteTransaction(transactionId, userId) {
    const session = await mongoose.startSession();
    session.startTransaction();

    try {
      const userIdObj = new mongoose.Types.ObjectId(userId);
      const transactionIdObj = new mongoose.Types.ObjectId(transactionId);

      // Find and verify transaction ownership
      const transaction = await Transaction.findOne({
        _id: transactionIdObj,
        userId: userIdObj
      }).session(session);

      if (!transaction) {
        throw new Error('Transaction not found or access denied');
      }

      // If it's a transfer, delete both linked transactions
      if (transaction.type === 'transfer') {
        await Transaction.deleteOne(
          { _id: transactionIdObj },
          { session }
        );
        if (transaction.linkedTransactionId) {
          await Transaction.deleteOne(
            { _id: transaction.linkedTransactionId },
            { session }
          );
        }
      } else {
        // For regular transactions, just delete
        await Transaction.deleteOne(
          { _id: transactionIdObj },
          { session }
        );
      }

      await session.commitTransaction();
      return { success: true, deletedId: transactionId };
    } catch (error) {
      await session.abortTransaction();
      throw error;
    } finally {
      await session.endSession();
    }
  }

  /**
   * Get wallet transactions (unified view of income and expense)
   */
  static async getWalletTransactions(walletId, userId, page = 1, limit = 10) {
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
   * Get all user transactions across all wallets
   */
  static async getUserTransactions(userId, page = 1, limit = 10) {
    try {
      const userIdObj = new mongoose.Types.ObjectId(userId);

      const skip = Math.max(0, (page - 1) * limit);

      const transactions = await Transaction.find({ userId: userIdObj })
        .sort({ date: -1 })
        .skip(skip)
        .limit(Math.min(limit, 100))
        .populate('walletId', 'name');

      const total = await Transaction.countDocuments({ userId: userIdObj });

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
}

module.exports = WalletService;
