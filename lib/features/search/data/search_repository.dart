import 'package:dio/dio.dart';

class SearchTransaction {
  final String id;
  final double amount;
  final String category;
  final String? source;
  final String? note;
  final DateTime date;
  final String transactionType; // 'expense' or 'income'

  SearchTransaction({
    required this.id,
    required this.amount,
    required this.category,
    this.source,
    this.note,
    required this.date,
    required this.transactionType,
  });

  factory SearchTransaction.fromJson(Map<String, dynamic> json) {
    return SearchTransaction(
      id: json['_id'] ?? json['id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      category: json['category'] ?? json['source'] ?? '',
      source: json['source'],
      note: json['note'],
      date: DateTime.parse(json['date']),
      transactionType: json['transactionType'] ?? 'expense',
    );
  }
}

class SearchSummary {
  final double totalExpenses;
  final double totalIncomes;

  SearchSummary({
    required this.totalExpenses,
    required this.totalIncomes,
  });

  factory SearchSummary.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] ?? json;
    return SearchSummary(
      totalExpenses: (summary['totalExpenses'] ?? 0).toDouble(),
      totalIncomes: (summary['totalIncomes'] ?? 0).toDouble(),
    );
  }
}

class CategoryStat {
  final String category;
  final double total;
  final int count;
  final double average;
  final int percent;

  CategoryStat({
    required this.category,
    required this.total,
    required this.count,
    required this.average,
    required this.percent,
  });

  factory CategoryStat.fromJson(Map<String, dynamic> json) {
    return CategoryStat(
      category: json['category'] ?? json['source'] ?? '',
      total: (json['total'] ?? 0).toDouble(),
      count: json['count'] ?? 0,
      average: (json['average'] ?? 0).toDouble(),
      percent: json['percent'] ?? 0,
    );
  }
}

class MonthlyStat {
  final int month;
  final int year;
  final String label;
  final double expenses;
  final double incomes;
  final int expenseCount;
  final int incomeCount;
  final double balance;

  MonthlyStat({
    required this.month,
    required this.year,
    required this.label,
    required this.expenses,
    required this.incomes,
    required this.expenseCount,
    required this.incomeCount,
    required this.balance,
  });

  factory MonthlyStat.fromJson(Map<String, dynamic> json) {
    return MonthlyStat(
      month: json['month'] ?? 1,
      year: json['year'] ?? 2024,
      label: json['label'] ?? '',
      expenses: (json['expenses'] ?? 0).toDouble(),
      incomes: (json['incomes'] ?? 0).toDouble(),
      expenseCount: json['expenseCount'] ?? 0,
      incomeCount: json['incomeCount'] ?? 0,
      balance: (json['balance'] ?? 0).toDouble(),
    );
  }
}

class SearchRepository {
  SearchRepository(this._dio);

  final Dio _dio;

  Future<(List<SearchTransaction>, SearchSummary)> searchTransactions({
    String? query,
    String? type,
    double? minAmount,
    double? maxAmount,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    
    if (query != null && query.isNotEmpty) queryParams['query'] = query;
    if (type != null) queryParams['type'] = type;
    if (minAmount != null) queryParams['minAmount'] = minAmount;
    if (maxAmount != null) queryParams['maxAmount'] = maxAmount;
    if (category != null) queryParams['category'] = category;
    if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
    if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
    
    final response = await _dio.get(
      '/search/transactions',
      queryParameters: queryParams,
    );
    
    final List<dynamic> data = response.data['data'] ?? [];
    final transactions = data.map((json) => SearchTransaction.fromJson(json)).toList();
    final summary = SearchSummary.fromJson(response.data);
    
    return (transactions, summary);
  }

  Future<(List<CategoryStat>, List<CategoryStat>)> getCategoryStats({int? month, int? year}) async {
    final queryParams = <String, dynamic>{};
    if (month != null) queryParams['month'] = month;
    if (year != null) queryParams['year'] = year;
    
    final response = await _dio.get(
      '/search/categories',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    
    final expenseData = response.data['expenses']?['data'] as List<dynamic>? ?? [];
    final incomeData = response.data['incomes']?['data'] as List<dynamic>? ?? [];
    
    final expenseStats = expenseData.map((json) => CategoryStat.fromJson(json as Map<String, dynamic>)).toList();
    final incomeStats = incomeData.map((json) => CategoryStat.fromJson(json as Map<String, dynamic>)).toList();
    
    return (expenseStats, incomeStats);
  }

  Future<List<MonthlyStat>> getMonthlyStats({int months = 6}) async {
    final response = await _dio.get(
      '/search/monthly',
      queryParameters: {'months': months},
    );
    
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((json) => MonthlyStat.fromJson(json)).toList();
  }
}

