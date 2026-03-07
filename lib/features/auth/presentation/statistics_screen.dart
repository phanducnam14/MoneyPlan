import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../transactions/transaction_controller.dart';
import '../../../shared/widgets/premium_page.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transactionsProvider);
    final ratio = state.totalIncome == 0 ? 0.0 : state.totalExpense / state.totalIncome;
    final savingRate = state.totalIncome == 0 ? 0.0 : state.balance / state.totalIncome;

    final suggestions = <({String title, String description, IconData icon, Color color})>[
      (
        title: 'Chi tiêu vượt mức mục tiêu',
        description: ratio > 0.8 ? 'Chi tiêu của bạn vượt quá 80% ngân sách tháng. Cần cập nhật ngân sách hoặc giảm chi tiêu.' : 'Chi tiêu của bạn ở mức hợp lý.',
        icon: ratio > 0.8 ? Icons.warning : Icons.check_circle,
        color: ratio > 0.8 ? Colors.orange : Colors.green,
      ),
      (
        title: 'Tỉ lệ tiết kiệm',
        description: savingRate < 0.1 ? 'Tỉ lệ tiết kiệm dưới 10% thu nhập. Hãy cố gắng tiết kiệm từ 10-20% thu nhập.' : 'Bạn đang tiết kiệm tốt! Tiếp tục duy trì thói quen này.',
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
        title: const Text('Thống kê nâng cao'),
        elevation: 0,
      ),
      child: ListView(
        children: [
          // Key Metrics Header
          Text(
            'Chỉ số tài chính chính',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          
          // Ratio Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.compare_arrows, color: Colors.purple, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tỉ lệ chi tiêu/thu nhập'),
                        const SizedBox(height: 4),
                        Text(
                          '${(ratio * 100).toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: ratio > 0.8 ? Colors.orange : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ratio > 0.8 ? 'Vượt quá mục tiêu' : 'Ở mức hợp lý',
                          style: TextStyle(
                            fontSize: 12,
                            color: ratio > 0.8 ? Colors.orange : Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Saving Rate Card
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.savings, color: Colors.teal, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tỉ lệ tiết kiệm'),
                        const SizedBox(height: 4),
                        Text(
                          '${(savingRate * 100).toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: savingRate < 0.1 ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          savingRate < 0.1 ? 'Cần tăng' : 'Tốt',
                          style: TextStyle(
                            fontSize: 12,
                            color: savingRate < 0.1 ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Insights Section
          const SizedBox(height: 24),
          Text(
            'Gợi ý tài chính',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
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

          const SizedBox(height: 24),
          // Financial Health Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tóm tắt sức khỏe tài chính',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _HealthMetric(
                          label: 'Thu nhập',
                          value: '${state.totalIncome.toStringAsFixed(0)}đ',
                          icon: Icons.trending_up,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HealthMetric(
                          label: 'Chi tiêu',
                          value: '${state.totalExpense.toStringAsFixed(0)}đ',
                          icon: Icons.trending_down,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HealthMetric(
                          label: 'Số dư',
                          value: '${state.balance.toStringAsFixed(0)}đ',
                          icon: Icons.wallet,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 11,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
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
    );
  }
}

