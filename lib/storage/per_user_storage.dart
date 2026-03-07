import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/transactions/domain/transaction_models.dart';

class PerUserStorage {
  static final PerUserStorage _instance = PerUserStorage._internal();
  factory PerUserStorage() => _instance;
  PerUserStorage._internal();

  String _boxKey(String userId, String suffix) => '${suffix}_$userId';

  Future<List<Expense>> loadExpenses(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_boxKey(userId, 'expenses'));
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Income>> loadIncomes(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_boxKey(userId, 'incomes'));
    if (raw == null) return [];
    final List<dynamic> list = jsonDecode(raw);
    return list.map((e) => Income.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveExpenses(String userId, List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final list = expenses.map((e) => e.toJson()).toList();
    await prefs.setString(_boxKey(userId, 'expenses'), jsonEncode(list));
  }

  Future<void> saveIncomes(String userId, List<Income> incomes) async {
    final prefs = await SharedPreferences.getInstance();
    final list = incomes.map((i) => i.toJson()).toList();
    await prefs.setString(_boxKey(userId, 'incomes'), jsonEncode(list));
  }
}
