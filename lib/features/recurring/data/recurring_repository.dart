import 'package:dio/dio.dart';

class RecurringTransaction {
  final String? id;
  final double amount;
  final String category;
  final String type;
  final String frequency;
  final DateTime nextExecutionDate;
  final DateTime? lastExecutionDate;
  final String description;
  final bool isActive;
  final String? walletId;
  final String? walletName;

  RecurringTransaction({
    this.id,
    required this.amount,
    required this.category,
    required this.type,
    required this.frequency,
    required this.nextExecutionDate,
    this.lastExecutionDate,
    this.description = '',
    this.isActive = true,
    this.walletId,
    this.walletName,
  });

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      id: json['_id'] ?? json['id'],
      amount: (json['amount'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      type: json['type'] ?? 'expense',
      frequency: json['frequency'] ?? 'monthly',
      nextExecutionDate: DateTime.parse(json['nextExecutionDate']),
      lastExecutionDate: json['lastExecutionDate'] != null ? DateTime.parse(json['lastExecutionDate']) : null,
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? true,
      walletId: json['walletId']?['_id'] ?? json['walletId'],
      walletName: json['walletId']?['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'amount': amount,
      'category': category,
      'type': type,
      'frequency': frequency,
      'nextExecutionDate': nextExecutionDate.toIso8601String(),
      'description': description,
      'isActive': isActive,
      if (walletId != null) 'walletId': walletId,
    };
  }

  String get frequencyLabel {
    switch (frequency) {
      case 'daily':
        return 'Hàng ngày';
      case 'weekly':
        return 'Hàng tuần';
      case 'monthly':
        return 'Hàng tháng';
      case 'yearly':
        return 'Hàng năm';
      default:
        return frequency;
    }
  }
}

class RecurringRepository {
  RecurringRepository(this._dio);

  final Dio _dio;

  Future<List<RecurringTransaction>> getRecurringTransactions({bool? isActive}) async {
    final queryParams = <String, dynamic>{};
    if (isActive != null) queryParams['isActive'] = isActive.toString();
    
    final response = await _dio.get('/recurring', queryParameters: queryParams.isNotEmpty ? queryParams : null);
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((json) => RecurringTransaction.fromJson(json)).toList();
  }

  Future<RecurringTransaction> createRecurringTransaction({
    required double amount,
    required String category,
    required String type,
    required String frequency,
    required DateTime nextExecutionDate,
    String? description,
    String? walletId,
  }) async {
    final response = await _dio.post('/recurring', data: {
      'amount': amount,
      'category': category,
      'type': type,
      'frequency': frequency,
      'nextExecutionDate': nextExecutionDate.toIso8601String(),
      'description': description ?? '',
      // ignore: use_null_aware_elements
      if (walletId != null) 'walletId': walletId,
    });
    return RecurringTransaction.fromJson(response.data);
  }

  Future<RecurringTransaction> updateRecurringTransaction(String id, {
    double? amount,
    String? category,
    String? type,
    String? frequency,
    DateTime? nextExecutionDate,
    String? description,
    bool? isActive,
    String? walletId,
  }) async {
    final response = await _dio.put('/recurring/$id', data: {
      // ignore: use_null_aware_elements
      if (amount != null) 'amount': amount,
      // ignore: use_null_aware_elements
      if (category != null) 'category': category,
      // ignore: use_null_aware_elements
      if (type != null) 'type': type,
      // ignore: use_null_aware_elements
      if (frequency != null) 'frequency': frequency,
      if (nextExecutionDate != null) 'nextExecutionDate': nextExecutionDate.toIso8601String(),
      // ignore: use_null_aware_elements
      if (description != null) 'description': description,
      // ignore: use_null_aware_elements
      if (isActive != null) 'isActive': isActive,
      // ignore: use_null_aware_elements
      if (walletId != null) 'walletId': walletId,
    });
    return RecurringTransaction.fromJson(response.data);
  }

  Future<void> deleteRecurringTransaction(String id) async {
    await _dio.delete('/recurring/$id');
  }

  Future<void> executePending() async {
    await _dio.post('/recurring/execute');
  }
}
