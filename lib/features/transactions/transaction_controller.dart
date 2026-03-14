import 'dart:math';

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
        return DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));
      case DateFilter.last30Days:
        return DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 29));
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
  double get totalIncome => filteredIncomes.fold(0, (sum, i) => sum + i.amount);
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

final transactionsProvider =
    StateNotifierProvider<TransactionsController, TransactionsState>(
      (ref) => TransactionsController(ref)..seed(),
    );

class TransactionsController extends StateNotifier<TransactionsState> {
  TransactionsController(this._ref) : super(const TransactionsState());
  final Ref _ref;
  final PerUserStorage _storage = PerUserStorage();

  Future<void> seed() async {
    // Load per-user data if a user is logged in
    final appUser = _ref.read(authControllerProvider).user;
    if (appUser == null || appUser.id.isEmpty) {
      // No user logged in yet; keep empty state for now
      state = state.copyWith(isLoading: false);
      return;
    }
    final userId = appUser.id;
    state = state.copyWith(isLoading: true);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final expenses = await _storage.loadExpenses(userId);
    final incomes = await _storage.loadIncomes(userId);
    state = state.copyWith(
      expenses: expenses,
      incomes: incomes,
      isLoading: false,
    );
  }

  Future<void> _saveAll(String userId) async {
    await _storage.saveExpenses(userId, state.expenses);
    await _storage.saveIncomes(userId, state.incomes);
  }

  Future<void> refreshData() async {
    await seed();
  }

  Future<void> loadForCurrentUser() async {
    final appUser = _ref.read(authControllerProvider).user;
    if (appUser == null) return;
    final userId = appUser.id;
    final expenses = await _storage.loadExpenses(userId);
    final incomes = await _storage.loadIncomes(userId);
    state = state.copyWith(
      expenses: expenses,
      incomes: incomes,
      isLoading: false,
    );
  }

  Future<void> loadMoreExpenses() async {
    final random = Random();
    state = state.copyWith(isLoading: true);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final more = List.generate(
      5,
      (index) => Expense(
        id: 'e${state.expenses.length + index}',
        amount: (80000 + random.nextInt(180000)).toDouble(),
        category: ['Ăn uống', 'Học tập', 'Khác'][index % 3],
        date: DateTime.now().subtract(
          Duration(days: state.expenses.length + index),
        ),
      ),
    );
    state = state.copyWith(
      expenses: [...state.expenses, ...more],
      page: state.page + 1,
      isLoading: false,
    );
  }

  Future<void> addExpense(Expense expense) async {
    // First, add to local state
    final newList = [expense, ...state.expenses];
    state = state.copyWith(expenses: newList);
    await _persistCurrentUser();

    // Then sync with backend if expense is from a wallet
    if (expense.sourceType == 'wallet' && expense.sourceWalletId != null) {
      try {
        final repo = _ref.read(transactionRepositoryProvider);
        // Send expense to backend via Transaction API
        await repo.createExpense(
          walletId: expense.sourceWalletId!,
          amount: expense.amount,
          category: expense.category,
          date: expense.date,
          note: expense.sourceWalletName,
        );
        // Refresh wallets to get updated balance from backend
        // ignore: unused_result
        _ref.refresh(walletsProvider);
      } catch (e) {
        // Silently handle error to not crash app
      }
    }
  }

  Future<void> addIncome(Income income) async {
    final newList = [income, ...state.incomes];
    state = state.copyWith(incomes: newList);
    await _persistCurrentUser();

    // Sync income with backend
    try {
      // Send income to backend via Transaction API
      // Note: We don't have walletId here, so this needs to be handled differently
      // For now, just refresh wallets
      // ignore: unused_result
      _ref.refresh(walletsProvider);
    } catch (e) {
      // Silently handle error
    }
  }

  Future<void> deleteExpense(String id) async {
    // Find the expense to get wallet info if needed
    final expense = state.expenses.firstWhere(
      (e) => e.id == id,
      orElse: () => Expense(
        id: '',
        amount: 0,
        category: '',
        date: DateTime.now(),
      ),
    );

    state = state.copyWith(
      expenses: state.expenses.where((e) => e.id != id).toList(),
    );
    await _persistCurrentUser();

    // Delete from backend if expense was from a wallet
    if (expense.sourceType == 'wallet' && expense.sourceWalletId != null) {
      try {
        // Note: In real app, you would need to store transaction IDs
        // For now, we'll just refresh wallets to sync        // ignore: unused_result        _ref.refresh(walletsProvider);
      } catch (e) {
        // Silently handle error to not crash app
      }
    }
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
    state = state.copyWith(
      expenses: [],
      incomes: [],
      isLoading: false,
      page: 1,
      dateFilter: DateFilter.all,
    );
    await _saveAll(_ref.read(authControllerProvider).user?.id ?? '');
  }

  Future<void> _persistCurrentUser() async {
    final user = _ref.read(authControllerProvider).user;
    if (user == null) return;
    await _saveAll(user.id);
  }
}
