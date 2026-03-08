import 'package:dio/dio.dart';

class Goal {
  final String? id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final String icon;
  final String color;
  final bool isCompleted;
  final DateTime? completedAt;
  final double? progress;
  final double? remaining;

  Goal({
    this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0,
    this.deadline,
    this.icon = 'flag',
    this.color = '#10B981',
    this.isCompleted = false,
    this.completedAt,
    this.progress,
    this.remaining,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['_id'] ?? json['id'],
      title: json['title'] ?? '',
      targetAmount: (json['targetAmount'] ?? 0).toDouble(),
      currentAmount: (json['currentAmount'] ?? 0).toDouble(),
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      icon: json['icon'] ?? 'flag',
      color: json['color'] ?? '#10B981',
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      progress: json['progress']?.toDouble(),
      remaining: json['remaining']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      if (deadline != null) 'deadline': deadline!.toIso8601String(),
      'icon': icon,
      'color': color,
    };
  }
}

class GoalRepository {
  GoalRepository(this._dio);

  final Dio _dio;

  Future<List<Goal>> getGoals({bool? isCompleted}) async {
    final queryParams = <String, dynamic>{};
    if (isCompleted != null) queryParams['isCompleted'] = isCompleted.toString();
    
    final response = await _dio.get('/goals', queryParameters: queryParams.isNotEmpty ? queryParams : null);
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((json) => Goal.fromJson(json)).toList();
  }

  Future<Goal> createGoal({
    required String title,
    required double targetAmount,
    double? currentAmount,
    DateTime? deadline,
    String? icon,
    String? color,
  }) async {
    final response = await _dio.post('/goals', data: {
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount ?? 0,
      if (deadline != null) 'deadline': deadline.toIso8601String(),
      'icon': icon ?? 'flag',
      'color': color ?? '#10B981',
    });
    return Goal.fromJson(response.data);
  }

  Future<Goal> updateGoal(String id, {
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    String? icon,
    String? color,
    bool? isCompleted,
  }) async {
    final response = await _dio.put('/goals/$id', data: {
      // ignore: use_null_aware_elements
      if (title != null) 'title': title,
      // ignore: use_null_aware_elements
      if (targetAmount != null) 'targetAmount': targetAmount,
      // ignore: use_null_aware_elements
      if (currentAmount != null) 'currentAmount': currentAmount,
      if (deadline != null) 'deadline': deadline.toIso8601String(),
      // ignore: use_null_aware_elements
      if (icon != null) 'icon': icon,
      // ignore: use_null_aware_elements
      if (color != null) 'color': color,
      // ignore: use_null_aware_elements
      if (isCompleted != null) 'isCompleted': isCompleted,
    });
    return Goal.fromJson(response.data);
  }

  Future<Goal> addSavings(String id, double amount) async {
    final response = await _dio.post('/goals/$id/savings', data: {
      'amount': amount,
    });
    return Goal.fromJson(response.data);
  }

  Future<void> deleteGoal(String id) async {
    await _dio.delete('/goals/$id');
  }
}
