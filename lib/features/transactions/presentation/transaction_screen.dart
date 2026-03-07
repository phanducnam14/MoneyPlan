import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../transaction_controller.dart';
import '../../../shared/widgets/premium_page.dart';
import '../domain/transaction_models.dart';
import '../../../shared/widgets/modern_widgets.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transactionsProvider);
    final controller = ref.read(transactionsProvider.notifier);

    return DefaultTabController(
      length: 2,
      child: PremiumPage(
        appBar: AppBar(
          title: const Text('Giao dịch'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: '💰 Chi tiêu'),
              Tab(text: '📈 Thu nhập'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddDialog(context, controller),
          icon: const Icon(Icons.add),
          label: const Text('Thêm giao dịch'),
        ),
        child: Column(
          children: [
            _FinancialSummary(
              totalIncome: state.totalIncome,
              totalExpense: state.totalExpense,
              balance: state.balance,
            ),
            _DateFilterChips(
              selectedFilter: state.dateFilter,
              onFilterChanged: controller.setDateFilter,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ExpenseList(
                    expenses: state.filteredExpenses,
                    isLoading: state.isLoading,
                    onRefresh: controller.refreshData,
                    onDelete: controller.deleteExpense,
                    onLoadMore: controller.loadMoreExpenses,
                  ),
                  _IncomeList(
                    incomes: state.filteredIncomes,
                    onDelete: controller.deleteIncome,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddDialog(
    BuildContext context,
    TransactionsController controller,
  ) async {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    var isExpense = true;
    var selectedDate = DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thêm giao dịch'),
          content: StatefulBuilder(
            builder: (context, setState) {
              final categories = [
                'Ăn uống',
                'Nhà ở',
                'Di chuyển',
                'Giải trí',
                'Học tập',
                'Khác',
              ];
              final sources = ['Lương', 'Freelance', 'Đầu tư', 'Khác'];
              final options = isExpense ? categories : sources;

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(
                          value: true,
                          label: const Text('Chi tiêu'),
                          icon: const Icon(Icons.remove),
                        ),
                        ButtonSegment(
                          value: false,
                          label: const Text('Thu nhập'),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                      selected: {isExpense},
                      onSelectionChanged: (Set<bool> newSelection) {
                        setState(() => isExpense = newSelection.first);
                        descController.clear();
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Số tiền (đ)',
                        prefixIcon: const Icon(Icons.attach_money),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Category/Source dropdown
                    DropdownButtonFormField<String>(
                      items: options
                          .map(
                            (opt) =>
                                DropdownMenuItem(value: opt, child: Text(opt)),
                          )
                          .toList(),
                      onChanged: (value) => descController.text = value ?? '',
                      decoration: InputDecoration(
                        labelText: isExpense ? 'Danh mục' : 'Nguồn thu',
                        prefixIcon: Icon(
                          isExpense ? Icons.category : Icons.attach_money,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Date picker
                    ListTile(
                      title: const Text('Ngày giao dịch'),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy').format(selectedDate),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0;
                final desc = descController.text.trim();
                if (amount <= 0 || desc.isEmpty) return;

                if (isExpense) {
                  controller.addExpense(
                    Expense(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      amount: amount,
                      category: desc,
                      date: selectedDate,
                    ),
                  );
                } else {
                  controller.addIncome(
                    Income(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      amount: amount,
                      source: desc,
                      date: selectedDate,
                    ),
                  );
                }
                Navigator.pop(context);
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.title,
    required this.amount,
    required this.date,
    required this.note,
    required this.icon,
    required this.color,
    required this.onDelete,
    required this.isExpense,
  });

  final String title;
  final double amount;
  final DateTime date;
  final String note;
  final IconData icon;
  final Color color;
  final bool isExpense;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###');
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Dismissible(
      key: Key(title + date.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red[400],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      child: GlassCard(
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(date),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isExpense ? '-' : '+'}${currencyFormat.format(amount.abs())}đ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Icon(Icons.more_vert, color: Colors.grey[400], size: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FinancialSummary extends StatelessWidget {
  const _FinancialSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
  });

  final double totalIncome;
  final double totalExpense;
  final double balance;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###đ');
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(
            label: 'Thu nhập',
            value: currencyFormat.format(totalIncome),
            color: Colors.green,
            icon: Icons.arrow_upward,
          ),
          _SummaryItem(
            label: 'Chi tiêu',
            value: currencyFormat.format(totalExpense),
            color: Colors.red,
            icon: Icons.arrow_downward,
          ),
          _SummaryItem(
            label: 'Số dư',
            value: currencyFormat.format(balance),
            color: balance >= 0 ? Colors.blue : Colors.orange,
            icon: Icons.account_balance_wallet,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _DateFilterChips extends StatelessWidget {
  const _DateFilterChips({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final DateFilter selectedFilter;
  final ValueChanged<DateFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: DateFilter.values.map((filter) {
          final isSelected = filter == selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (_) => onFilterChanged(filter),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ExpenseList extends StatelessWidget {
  const _ExpenseList({
    required this.expenses,
    required this.isLoading,
    required this.onRefresh,
    required this.onDelete,
    required this.onLoadMore,
  });

  final List<Expense> expenses;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final void Function(String) onDelete;
  final Future<void> Function() onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có chi tiêu',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: expenses.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == expenses.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final expense = expenses[index];
          final categoryMap = {
            'Ăn uống': Icons.restaurant,
            'Nhà ở': Icons.home,
            'Di chuyển': Icons.directions_car,
            'Giải trí': Icons.movie,
            'Học tập': Icons.school,
            'Khác': Icons.category,
          };
          return _TransactionCard(
            title: expense.category,
            amount: expense.amount,
            date: expense.date,
            note: expense.note,
            icon: categoryMap[expense.category] ?? Icons.category,
            color: Colors.red,
            onDelete: () => onDelete(expense.id),
            isExpense: true,
          );
        },
      ),
    );
  }
}

class _IncomeList extends StatelessWidget {
  const _IncomeList({required this.incomes, required this.onDelete});

  final List<Income> incomes;
  final void Function(String) onDelete;

  @override
  Widget build(BuildContext context) {
    if (incomes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Chưa có thu nhập',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: incomes.length,
      itemBuilder: (context, index) {
        final income = incomes[index];
        final sourceMap = {
          'Lương': Icons.work,
          'Freelance': Icons.laptop,
          'Đầu tư': Icons.trending_up,
          'Khác': Icons.attach_money,
        };
        return _TransactionCard(
          title: income.source,
          amount: income.amount,
          date: income.date,
          note: income.note,
          icon: sourceMap[income.source] ?? Icons.attach_money,
          color: Colors.green,
          onDelete: () => onDelete(income.id),
          isExpense: false,
        );
      },
    );
  }
}
