import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import './domain/transaction_models.dart';
import '../../storage/per_user_storage.dart';
import '../auth/presentation/auth_controller.dart';
import '../wallets/presentation/wallet_screen.dart';
import '../../core/network/dio_provider.dart';

enum DateFilter { all, today, last7Days, last30Days, thisMonth }

extension DateFilterExtension on DateFilter {
  String get label {
    switch (this) {
      case DateFilter.all:
        return 'Tất cả';
      case DateFilter.today:
        return 'Hôm nay';
      case DateFilter.last7Days:
        return '7 ngày qua';
      case DateFilter.last30Days:
        return '30 ngày qua';
      case DateFilter.thisMonth:
        return 'Tháng này';
    }
  }

  DateTime? get startDate {
    final now = DateTime.now();
    switch (this) {
      case DateFilter.all:
        return null;
      case DateFilter.today:
        return DateTime(now.year, now.month, now.day);
      case DateFilter.last7Days:
        return DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
      case DateFilter.last30Days:
        return DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 29));
      case DateFilter.thisMonth:
        return DateTime(now.year, now.month, 1);
    }
  }

  DateTime? get endDate {
    if (this == DateFilter.all) return null;
    return DateTime.now();
  }
}

class TransactionsState {
  const TransactionsState({
    this.expenses = const [],
    this.incomes = const [],
    this.isLoading = false,
    this.page = 1,
    this.dateFilter = DateFilter.all,
  });

  final List<Expense> expenses;
  final List<Income> incomes;
  final bool isLoading;
  final int page;
  final DateFilter dateFilter;

  List<Expense> get filteredExpenses {
    final filter = dateFilter;
    if (filter == DateFilter.all) return expenses;
    final start = filter.startDate;
    final end = filter.endDate ?? DateTime.now();
    return expenses.where((e) {
      if (start != null && e.date.isBefore(start)) return false;
      if (e.date.isAfter(end)) return false;
      return true;
    }).toList();
  }

  List<Income> get filteredIncomes {
    final filter = dateFilter;
    if (filter == DateFilter.all) return incomes;
    final start = filter.startDate;
    final end = filter.endDate ?? DateTime.now();
    return incomes.where((i) {
      if (start != null && i.date.isBefore(start)) return false;
      if (i.date.isAfter(end)) return false;
      return true;
    }).toList();
  }

  double get totalExpense =>
      filteredExpenses.fold(0, (sum, e) => sum + e.amount);
  double get totalIncome =>
      filteredIncomes.fold(0, (sum, i) => sum + i.amount);
  double get balance => totalIncome - totalExpense;

  TransactionsState copyWith({
    List<Expense>? expenses,
    List<Income>? incomes,
    bool? isLoading,
    int? page,
    DateFilter? dateFilter,
  }) {
    return TransactionsState(
      expenses: expenses ?? this.expenses,
      incomes: incomes ?? this.incomes,
      isLoading: isLoading ?? this.isLoading,
      page: page ?? this.page,
      dateFilter: dateFilter ?? this.dateFilter,
    );
  }
}

final _currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authControllerProvider).user?.id;
});

final transactionsProvider =
    StateNotifierProvider<TransactionsController, TransactionsState>((ref) {
  final controller = TransactionsController(ref);

  ref.listen<String?>(_currentUserIdProvider, (previousId, newId) {
    debugPrint('🔔 userId changed: $previousId → $newId');
    if (newId != null && newId.isNotEmpty && newId != previousId) {
      controller.loadForUser(newId);
    } else if (newId == null && previousId != null) {
      controller.clearStateOnLogout();
    }
  });

  final userId = ref.read(_currentUserIdProvider);
  debugPrint('🚀 transactionsProvider init, userId=$userId');
  if (userId != null && userId.isNotEmpty) {
    controller.loadForUser(userId);
  }

  return controller;
});

class TransactionsController extends StateNotifier<TransactionsState> {
  TransactionsController(this._ref) : super(const TransactionsState());
  final Ref _ref;
  final PerUserStorage _storage = PerUserStorage();

  Future<void> loadForUser(String userId) async {
    debugPrint('🔵 loadForUser: $userId');
    state = state.copyWith(isLoading: true);
    final expenses = await _storage.loadExpenses(userId);
    final incomes = await _storage.loadIncomes(userId);
    debugPrint('🟢 loaded ${expenses.length} expenses, ${incomes.length} incomes for $userId');
    state = state.copyWith(
      expenses: expenses,
      incomes: incomes,
      isLoading: false,
    );
  }

  Future<void> loadForCurrentUser() async {
    final userId = _ref.read(authControllerProvider).user?.id;
    debugPrint('🔵 loadForCurrentUser: userId=$userId');
    if (userId == null || userId.isEmpty) return;
    await loadForUser(userId);
  }

  Future<void> refreshData() async {
    await loadForCurrentUser();
  }

  Future<void> _saveAll(String userId) async {
    debugPrint('💾 _saveAll: userId=$userId, expenses=${state.expenses.length}, incomes=${state.incomes.length}');
    await _storage.saveExpenses(userId, state.expenses);
    await _storage.saveIncomes(userId, state.incomes);
    debugPrint('✅ _saveAll done for $userId');
  }

  Future<void> addExpense(Expense expense) async {
    debugPrint('➕ addExpense: ${expense.category} ${expense.amount}');
    state = state.copyWith(expenses: [expense, ...state.expenses]);
    await _persistCurrentUser();

    if (expense.sourceType == 'wallet' && expense.sourceWalletId != null) {
      try {
        final repo = _ref.read(transactionRepositoryProvider);
        await repo.createExpense(
          walletId: expense.sourceWalletId!,
          amount: expense.amount,
          category: expense.category,
          date: expense.date,
          note: expense.sourceWalletName,
        );
        // ignore: unused_result
        _ref.refresh(walletsProvider);
      } catch (_) {}
    }
  }

  Future<void> addIncome(Income income) async {
    debugPrint('➕ addIncome: ${income.source} ${income.amount}');
    state = state.copyWith(incomes: [income, ...state.incomes]);
    await _persistCurrentUser();
  }

  Future<void> deleteExpense(String id) async {
    state = state.copyWith(
      expenses: state.expenses.where((e) => e.id != id).toList(),
    );
    await _persistCurrentUser();
  }

  Future<void> deleteIncome(String id) async {
    state = state.copyWith(
      incomes: state.incomes.where((i) => i.id != id).toList(),
    );
    await _persistCurrentUser();
  }

  void setDateFilter(DateFilter filter) {
    state = state.copyWith(dateFilter: filter);
  }

  Future<void> clearAllData() async {
    final userId = _ref.read(authControllerProvider).user?.id ?? '';
    state = state.copyWith(
      expenses: [],
      incomes: [],
      isLoading: false,
      page: 1,
      dateFilter: DateFilter.all,
    );
    if (userId.isNotEmpty) await _saveAll(userId);
  }

  void clearStateOnLogout() {
    debugPrint('🚪 clearStateOnLogout');
    state = const TransactionsState();
  }

  Future<void> _persistCurrentUser() async {
    final userId = _ref.read(authControllerProvider).user?.id;
    debugPrint('💾 _persistCurrentUser: userId=$userId');
    if (userId == null || userId.isEmpty) {
      debugPrint('⚠️ _persistCurrentUser: userId null, skip save!');
      return;
    }
    await _saveAll(userId);
  }
}