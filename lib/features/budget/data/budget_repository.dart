import 'package:dio/dio.dart';

class BudgetCategory {
  final String? id;
  final String name;
  final String icon;
  final String color;
  final String type;

  BudgetCategory({
    this.id,
    required this.name,
    this.icon = 'category',
    this.color = '#6366F1',
    this.type = 'expense',
  });

  factory BudgetCategory.fromJson(Map<String, dynamic> json) {
    final cat = json['name'] != null ? json : (json['category'] ?? {});
    return BudgetCategory(
      id: cat['_id'] ?? cat['id'],
      name: cat['name'] ?? '',
      icon: cat['icon'] ?? 'category',
      color: cat['color'] ?? '#6366F1',
      type: cat['type'] ?? 'expense',
    );
  }
}

class Budget {
  final String? id;
  final double amount;
  final String period;
  final int month;
  final int year;
  final BudgetCategory? category;
  final double spent;
  final double remaining;
  final int percentUsed;
  final bool isOverBudget;

  Budget({
    this.id,
    required this.amount,
    this.period = 'monthly',
    required this.month,
    required this.year,
    this.category,
    this.spent = 0,
    this.remaining = 0,
    this.percentUsed = 0,
    this.isOverBudget = false,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['_id'] ?? json['id'],
      amount: (json['amount'] ?? 0).toDouble(),
      period: json['period'] ?? 'monthly',
      month: json['month'] ?? 1,
      year: json['year'] ?? 2024,
      category: json['category'] != null 
          ? BudgetCategory.fromJson(json['category'])
          : null,
      spent: (json['spent'] ?? 0).toDouble(),
      remaining: (json['remaining'] ?? 0).toDouble(),
      percentUsed: json['percentUsed'] ?? 0,
      isOverBudget: json['isOverBudget'] ?? false,
    );
  }
}

class BudgetSummary {
  final double totalBudget;
  final double totalSpent;
  final double remaining;
  final int percentUsed;
  final bool isOverBudget;

  BudgetSummary({
    required this.totalBudget,
    required this.totalSpent,
    required this.remaining,
    required this.percentUsed,
    required this.isOverBudget,
  });

  factory BudgetSummary.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] ?? json;
    return BudgetSummary(
      totalBudget: (summary['totalBudget'] ?? 0).toDouble(),
      totalSpent: (summary['totalSpent'] ?? 0).toDouble(),
      remaining: (summary['remaining'] ?? 0).toDouble(),
      percentUsed: summary['percentUsed'] ?? 0,
      isOverBudget: summary['isOverBudget'] ?? false,
    );
  }
}

class BudgetRepository {
  BudgetRepository(this._dio);

  final Dio _dio;

  Future<(List<Budget>, BudgetSummary)> getBudgets({int? month, int? year}) async {
    final queryParams = <String, dynamic>{};
    if (month != null) queryParams['month'] = month;
    if (year != null) queryParams['year'] = year;
    
    final response = await _dio.get(
      '/budgets',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    
    final List<dynamic> data = response.data['data'] ?? [];
    final budgets = data.map((json) => Budget.fromJson(json)).toList();
    final summary = BudgetSummary.fromJson(response.data);
    
    return (budgets, summary);
  }

  Future<Budget> createBudget({
    required double amount,
    required int month,
    required int year,
    String? categoryId,
    String period = 'monthly',
  }) async {
    final response = await _dio.post(
      '/budgets',
      data: {
        'amount': amount,
        'month': month,
        'year': year,
        // ignore: use_null_aware_elements
        if (categoryId != null) 'categoryId': categoryId,
        'period': period,
      },
    );
    return Budget.fromJson(response.data);
  }

  Future<Budget> updateBudget(String id, {
    double? amount,
    String? period,
  }) async {
    final response = await _dio.put(
      '/budgets/$id',
      data: {
        // ignore: use_null_aware_elements
        if (amount != null) 'amount': amount,
        // ignore: use_null_aware_elements
        if (period != null) 'period': period,
      },
    );
    return Budget.fromJson(response.data);
  }

  Future<void> deleteBudget(String id) async {
    await _dio.delete('/budgets/$id');
  }
}

