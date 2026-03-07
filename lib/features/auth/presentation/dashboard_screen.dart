import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/modern_widgets.dart';
import '../../transactions/transaction_controller.dart';
import 'auth_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transactionsProvider);
    final currencyFormat = NumberFormat('#,###');
    final expenseByCategory = <String, double>{};
    for (final expense in state.expenses) {
      expenseByCategory.update(
        expense.category,
        (v) => v + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [const Color(0xFFF8FAFC), Colors.white],
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: ref.read(transactionsProvider.notifier).refreshData,
          color: AppTheme.primaryGradientStart,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Xin chao!',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tong quan tai chinh',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                          ),
                        ],
                      ),
                      PopupMenuButton<String>(
                        onSelected: (String result) {
                          if (result == 'reset') {
                            _showResetConfirmationDialog(context, ref);
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'reset',
                                child: Row(
                                  children: [
                                    Icon(Icons.restart_alt_outlined, size: 20),
                                    SizedBox(width: 12),
                                    Text('Reset du lieu'),
                                  ],
                                ),
                              ),
                            ],
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2D3748)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(Icons.more_vert, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildBalanceCard(
                    context,
                    state.balance,
                    state.totalIncome,
                    state.totalExpense,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Thu nhap',
                          currencyFormat.format(state.totalIncome),
                          Icons.trending_up,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Chi tieu',
                          currencyFormat.format(state.totalExpense),
                          Icons.trending_down,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (expenseByCategory.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildExpenseChart(
                      context,
                      expenseByCategory,
                      state.totalExpense,
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Giao dich gan day',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Tính năng xem tất cả đang được triển khai',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Text(
                          'Xem tat ca',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              state.expenses.isEmpty && state.incomes.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'Chua co giao dich',
                          subtitle: 'Them giao dich dau tien cua ban',
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index < state.expenses.length) {
                              final expense = state.expenses[index];
                              return _buildRecentTransaction(
                                context,
                                expense.category,
                                expense.amount,
                                expense.date,
                                true,
                              );
                            } else if (index <
                                state.expenses.length + state.incomes.length) {
                              final income =
                                  state.incomes[index - state.expenses.length];
                              return _buildRecentTransaction(
                                context,
                                income.source,
                                income.amount,
                                income.date,
                                false,
                              );
                            }
                            return null;
                          },
                          childCount:
                              (state.expenses.length + state.incomes.length)
                                  .clamp(0, 5),
                        ),
                      ),
                    ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
    BuildContext context,
    double balance,
    double income,
    double expense,
  ) {
    final currencyFormat = NumberFormat('#,###');
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'So du tai khoan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      balance >= 0 ? Icons.trending_up : Icons.trending_down,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      balance >= 0 ? 'Tich cuc' : 'Can cai thien',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${currencyFormat.format(balance)}d',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildMiniStat(
                Icons.arrow_upward,
                'Thu',
                currencyFormat.format(income),
                Colors.green[300]!,
              ),
              const SizedBox(width: 24),
              _buildMiniStat(
                Icons.arrow_downward,
                'Chi',
                currencyFormat.format(expense),
                Colors.red[300]!,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.white60),
            ),
            Text(
              '${value}d',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    // Premium look using GlassCard for consistency
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$value d',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseChart(
    BuildContext context,
    Map<String, double> expenseByCategory,
    double totalExpense,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phan bo chi tieu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: expenseByCategory.entries
                    .toList()
                    .asMap()
                    .entries
                    .map((entry) {
                      final index = entry.key;
                      final category = entry.value;
                      final percentage = (category.value / totalExpense * 100);
                      return PieChartSectionData(
                        value: category.value,
                        title: '${percentage.toStringAsFixed(0)}%',
                        color: colors[index % colors.length],
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    })
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: expenseByCategory.entries.toList().asMap().entries.map((
              entry,
            ) {
              final index = entry.key;
              final category = entry.value;
              return _buildLegendItem(
                category.key,
                colors[index % colors.length],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransaction(
    BuildContext context,
    String title,
    double amount,
    DateTime date,
    bool isExpense,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormat = NumberFormat('#,###');
    final dateFormat = DateFormat('dd MMM');
    final categoryIcons = {
      'An uong': Icons.restaurant,
      'Nha o': Icons.home,
      'Di chuyen': Icons.directions_car,
      'Giai tri': Icons.movie,
      'Hoc tap': Icons.school,
      'Luong': Icons.work,
      'Freelance': Icons.laptop,
      'Dau tu': Icons.trending_up,
      'Khac': Icons.category,
    };
    final color = isExpense ? Colors.red : Colors.green;
    final icon = categoryIcons[title] ?? Icons.category;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateFormat.format(date),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Text(
            '${isExpense ? '-' : '+'}${currencyFormat.format(amount.abs())}đ',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmationDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Reset du lieu tai chinh?',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'Hanh dong nay se xoa tat ca cac giao dich, thu nhap va chi tieu cua ban. Khong the hoan tac!',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Huy', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                // Show loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  // Call the reset API
                  await ref
                      .read(authControllerProvider.notifier)
                      .resetUserData();

                  // Clear frontend data
                  await ref.read(transactionsProvider.notifier).clearAllData();

                  // Close loading dialog
                  if (context.mounted) {
                    Navigator.pop(context);

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Da reset du lieu tai chinh!'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  // Close loading dialog
                  if (context.mounted) {
                    Navigator.pop(context);

                    // Show error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Loi reset du lieu: ${e.toString()}'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppTheme.dangerColor,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Xoa het',
                style: TextStyle(
                  color: AppTheme.dangerColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
