import 'package:dio/dio.dart';

class Transaction {
  final String? id;
  final String userId;
  final String walletId;
  final String type; // 'income' or 'expense'
  final double amount;
  final String category;
  final String? note;
  final DateTime date;
  final String sourceType; // 'externalIncome', 'wallet', 'external'
  final String status; // 'completed', 'pending', 'cancelled'

  Transaction({
    this.id,
    required this.userId,
    required this.walletId,
    required this.type,
    required this.amount,
    required this.category,
    this.note,
    required this.date,
    this.sourceType = 'wallet',
    this.status = 'completed',
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['_id'] ?? json['id'],
      userId: json['userId'] ?? '',
      walletId: json['walletId'] ?? '',
      type: json['type'] ?? 'expense',
      amount: (json['amount'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      note: json['note'],
      date: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      sourceType: json['sourceType'] ?? 'wallet',
      status: json['status'] ?? 'completed',
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'userId': userId,
      'walletId': walletId,
      'type': type,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'sourceType': sourceType,
      'status': status,
    };
    if (id != null) map['_id'] = id;
    if (note != null) map['note'] = note;
    return map;
  }
}

class TransactionRepository {
  TransactionRepository(this._dio);

  final Dio _dio;

  Future<Transaction> createExpense({
    required String walletId,
    required double amount,
    required String category,
    required DateTime date,
    String? note,
  }) async {
    final response = await _dio.post(
      '/transactions/expense',
      data: {
        'walletId': walletId,
        'amount': amount,
        'category': category,
        'date': date.toIso8601String(),
        'note': note ?? '',
      },
    );
    return Transaction.fromJson(response.data);
  }

  Future<Transaction> createIncome({
    required String walletId,
    required double amount,
    required String category,
    required DateTime date,
    String? source,
    String? note,
  }) async {
    final response = await _dio.post(
      '/transactions/income',
      data: {
        'walletId': walletId,
        'amount': amount,
        'category': category,
        'source': source ?? 'External Income',
        'date': date.toIso8601String(),
        'note': note ?? '',
      },
    );
    return Transaction.fromJson(response.data);
  }

  Future<void> deleteTransaction(String transactionId) async {
    await _dio.delete('/transactions/$transactionId');
  }

  Future<Transaction> updateTransaction(
    String transactionId, {
    double? amount,
    String? category,
    DateTime? date,
    String? note,
  }) async {
    final updateData = <String, dynamic>{};
    if (amount != null) updateData['amount'] = amount;
    if (category != null) updateData['category'] = category;
    if (date != null) updateData['date'] = date.toIso8601String();
    if (note != null) updateData['note'] = note;

    final response = await _dio.put(
      '/transactions/$transactionId',
      data: updateData,
    );
    return Transaction.fromJson(response.data);
  }
}
