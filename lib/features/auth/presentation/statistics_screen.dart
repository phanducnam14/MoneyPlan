import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../transactions/transaction_controller.dart';
import '../../wallets/presentation/wallet_screen.dart';
import '../../../shared/widgets/premium_page.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transactionsProvider);
    final walletsAsync = ref.watch(walletsProvider);

    final ratio = state.totalIncome == 0 ? 0.0 : state.totalExpense / state.totalIncome;
    final savingRate = state.totalIncome == 0 ? 0.0 : state.balance / state.totalIncome;

    // Wallet totals
    double totalWalletBalance = 0.0;
    final walletAsyncData = walletsAsync.value;
    if (walletAsyncData != null) {
      totalWalletBalance = walletAsyncData.fold(0.0, (sum, w) => sum + (w.actualBalance ?? w.balance));
    }

    // Current month wallet spending
    final currentMonthWalletExpenses = state.filteredExpenses.where((e) =>
      e.date.year == DateTime.now().year && e.date.month == DateTime.now().month &&
      e.sourceType == 'wallet' && e.sourceWalletName != null
    ).toList();
    final walletSpendingTotal = currentMonthWalletExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final walletRemaining = totalWalletBalance - walletSpendingTotal;

    // Compute current month spending split for lists
    final currentMonthExpenses = state.filteredExpenses.where((e) =>
      e.date.year == DateTime.now().year && e.date.month == DateTime.now().month
    ).toList();

    final walletSpendingMap = <String, double>{};
    final accountSpending = <String, double>{};

    for (final expense in currentMonthExpenses) {
      if (expense.sourceType == 'wallet' && expense.sourceWalletName != null) {
        walletSpendingMap[expense.sourceWalletName!] = (walletSpendingMap[expense.sourceWalletName!] ?? 0) + expense.amount;
      } else {
        accountSpending[expense.category] = (accountSpending[expense.category] ?? 0) + expense.amount;
      }
    }

    // Fix: tách sort và take thành 2 bước riêng — ..take() trên cascade không có tác dụng
    final topWallets = (walletSpendingMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)))
      .take(5).toList();

    final topAccountCategories = (accountSpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)))
      .take(5).toList();

    final currencyFormat = NumberFormat('#,###', 'vi_VN');

    final suggestions = <({String title, String description, IconData icon, Color color})>[
      (
        title: 'Chi tiêu vượt mức mục tiêu',
        description: ratio > 0.8
            ? 'Chi tiêu của bạn vượt quá 80% ngân sách tháng. Cần cập nhật ngân sách hoặc giảm chi tiêu.'
            : 'Chi tiêu của bạn ở mức hợp lý.',
        icon: ratio > 0.8 ? Icons.warning : Icons.check_circle,
        color: ratio > 0.8 ? Colors.orange : Colors.green,
      ),
      (
        title: 'Tỉ lệ tiết kiệm',
        description: savingRate < 0.1
            ? 'Tỉ lệ tiết kiệm dưới 10% thu nhập. Hãy cố gắng tiết kiệm từ 10-20% thu nhập.'
            : 'Bạn đang tiết kiệm tốt! Tiếp tục duy trì thói quen này.',
        icon: savingRate < 0.1 ? Icons.trending_down : Icons.trending_up,
        color: savingRate < 0.1 ? Colors.red : Colors.green,
      ),
      (
        title: 'Phân bổ ngân sách (Quy tắc 50/30/20)',
        description: 'Dành 50% cho nhu cầu, 30% cho mong muốn, và 20% để tiết kiệm.',
        icon: Icons.pie_chart,
        color: Colors.blue,
      ),
    ];

    return PremiumPage(
      appBar: AppBar(
        title: const Text('Thống kê'),
        elevation: 0,
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary Cards
          const Text('Tóm tắt tài chính', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Tổng quan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        _HealthMetric(label: 'Thu nhập', value: '${state.totalIncome.toStringAsFixed(0)}đ', icon: Icons.trending_up, color: Colors.green),
                        _HealthMetric(label: 'Chi tiêu', value: '${state.totalExpense.toStringAsFixed(0)}đ', icon: Icons.trending_down, color: Colors.red),
                        _HealthMetric(label: 'Số dư', value: '${state.balance.toStringAsFixed(0)}đ', icon: Icons.account_balance_wallet, color: Colors.blue),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Trong ví', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        _HealthMetric(label: 'Tổng tiền', value: '${totalWalletBalance.toStringAsFixed(0)}đ', icon: Icons.wallet, color: Colors.indigo),
                        _HealthMetric(label: 'Chi tiêu', value: '${walletSpendingTotal.toStringAsFixed(0)}đ', icon: Icons.shopping_cart, color: Colors.orange),
                        _HealthMetric(label: 'Còn lại', value: '${walletRemaining.toStringAsFixed(0)}đ', icon: Icons.account_balance, color: Colors.green),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Wallet Spending list
          Text('Tiêu từ các ví (Tháng này)', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: topWallets.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Chưa có chi tiêu từ ví'),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: topWallets.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = topWallets[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withValues(alpha: 0.2),
                        child: Text('${index + 1}'),
                      ),
                      title: Text(entry.key),
                      trailing: Text(
                        '${currencyFormat.format(entry.value)}đ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
          ),
          const SizedBox(height: 16),

          // Account Spending list
          Text('Tiêu từ thu nhập ròng (Tháng này)', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: topAccountCategories.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Chưa có chi tiêu từ thu nhập'),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: topAccountCategories.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final entry = topAccountCategories[index];
                    return ListTile(
                      leading: const Icon(Icons.category),
                      title: Text(entry.key),
                      trailing: Text(
                        '${currencyFormat.format(entry.value)}đ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
          ),
          const SizedBox(height: 24),

          // Financial indicators
          Text('Chỉ số tài chính', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...suggestions.map((suggestion) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: suggestion.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        suggestion.icon,
                        color: suggestion.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suggestion.title,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            suggestion.description,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class _HealthMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _HealthMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}