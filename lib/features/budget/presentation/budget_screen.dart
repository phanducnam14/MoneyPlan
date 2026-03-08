import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/dio_provider.dart';
import '../../../shared/widgets/premium_page.dart';
import '../../../shared/widgets/modern_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../data/budget_repository.dart';
import '../../categories/data/category_repository.dart';

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(dioProvider));
});

final budgetCategoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(dioProvider));
});

final budgetsProvider = FutureProvider((ref) async {
  final repo = ref.watch(budgetRepositoryProvider);
  final now = DateTime.now();
  return repo.getBudgets(month: now.month + 1, year: now.year);
});

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final budgets = ref.watch(budgetsProvider);
    final currencyFormat = NumberFormat('#,###');

    return PremiumPage(
      appBar: AppBar(
        title: const Text('Ngân sách'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _selectMonth(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBudgetDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm ngân sách'),
      ),
      child: budgets.when(
        data: (data) {
          final (budgetsList, summary) = data;
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(budgetsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Month selector
                _MonthSelector(
                  month: _selectedMonth,
                  onTap: () => _selectMonth(context),
                ),
                const SizedBox(height: 16),
                
                // Summary card
                _BudgetSummaryCard(summary: summary, currencyFormat: currencyFormat),
                const SizedBox(height: 24),
                
                // Budget list
                if (budgetsList.isEmpty)
                  const _EmptyBudgetState()
                else
                  ...budgetsList.map((budget) => _BudgetCard(
                    budget: budget,
                    currencyFormat: currencyFormat,
                    onEdit: () => _showEditBudgetDialog(context, budget),
                    onDelete: () => _deleteBudget(budget.id!),
                  )),
                  
                const SizedBox(height: 80),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }

  Future<void> _selectMonth(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _selectedMonth = picked;
      });
      // Reload budgets for selected month
      ref.invalidate(budgetsProvider);
    }
  }

  Future<void> _showAddBudgetDialog(BuildContext context) async {
    final amountController = TextEditingController();
    String? selectedCategoryId;
    
    // Get categories before showing dialog to avoid BuildContext issue
    final categories = await ref.read(budgetCategoryRepositoryProvider).getCategories(type: 'expense');

    if (!context.mounted) return;
    
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm ngân sách'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số tiền (đ)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Danh mục (tùy chọn)',
                  prefixIcon: Icon(Icons.category),
                ),
                initialValue: selectedCategoryId,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Tổng ngân sách'),
                  ),
                  ...categories.map((cat) => DropdownMenuItem(
                    value: cat.id,
                    child: Text(cat.name),
                  )),
                ],
                onChanged: (value) => selectedCategoryId = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) return;
              
              try {
                final repo = ref.read(budgetRepositoryProvider);
                await repo.createBudget(
                  amount: amount,
                  month: _selectedMonth.month,
                  year: _selectedMonth.year,
                  categoryId: selectedCategoryId,
                );
                if (context.mounted) Navigator.pop(context);
                ref.invalidate(budgetsProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditBudgetDialog(BuildContext context, Budget budget) async {
    final amountController = TextEditingController(text: budget.amount.toString());
    
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa ngân sách'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Số tiền (đ)',
            prefixIcon: Icon(Icons.attach_money),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) return;
              
              try {
                final repo = ref.read(budgetRepositoryProvider);
                await repo.updateBudget(budget.id!, amount: amount);
                if (context.mounted) Navigator.pop(context);
                ref.invalidate(budgetsProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBudget(String id) async {
    try {
      final repo = ref.read(budgetRepositoryProvider);
      await repo.deleteBudget(id);
      ref.invalidate(budgetsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }
}

class _MonthSelector extends StatelessWidget {
  final DateTime month;
  final VoidCallback onTap;

  const _MonthSelector({required this.month, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final monthNames = ['Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
                        'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'];
    
    return GlassCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.calendar_month, color: AppTheme.primaryGradientStart),
              const SizedBox(width: 12),
              Text(
                '${monthNames[month.month - 1]} ${month.year}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetSummaryCard extends StatelessWidget {
  final BudgetSummary summary;
  final NumberFormat currencyFormat;

  const _BudgetSummaryCard({required this.summary, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    final isOverBudget = summary.isOverBudget;
    final progressColor = isOverBudget ? Colors.red : (summary.percentUsed > 80 ? Colors.orange : Colors.green);

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng ngân sách',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: progressColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${summary.percentUsed}%',
                    style: TextStyle(color: progressColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${currencyFormat.format(summary.totalSpent)} / ${currencyFormat.format(summary.totalBudget)}đ',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (summary.percentUsed / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation(progressColor),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Còn lại: ${currencyFormat.format(summary.remaining)}đ',
                  style: TextStyle(
                    color: summary.remaining >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isOverBudget)
                  const Text(
                    '⚠️ Vượt ngân sách!',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBudgetState extends StatelessWidget {
  const _EmptyBudgetState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Chưa có ngân sách',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Thiết lập ngân sách để theo dõi chi tiêu',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final Budget budget;
  final NumberFormat currencyFormat;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BudgetCard({
    required this.budget,
    required this.currencyFormat,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor = budget.isOverBudget ? Colors.red : (budget.percentUsed > 80 ? Colors.orange : Colors.green);
    final categoryColor = budget.category != null 
        ? Color(int.parse(budget.category!.color.replaceFirst('#', '0xFF')))
        : AppTheme.primaryGradientStart;

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (budget.category != null) ...[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.category, color: categoryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        budget.category?.name ?? 'Tổng ngân sách',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${currencyFormat.format(budget.spent)} / ${currencyFormat.format(budget.amount)}đ',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Sửa')),
                    const PopupMenuItem(value: 'delete', child: Text('Xóa', style: TextStyle(color: Colors.red))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (budget.percentUsed / 100).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation(progressColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${budget.percentUsed}% đã sử dụng',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  'Còn ${currencyFormat.format(budget.remaining)}đ',
                  style: TextStyle(
                    fontSize: 12,
                    color: budget.remaining >= 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

