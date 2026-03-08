import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/premium_page.dart';
import '../data/goal_repository.dart';
import '../../../core/network/dio_provider.dart';

final goalsProvider = FutureProvider<List<Goal>>((ref) async {
  final repo = ref.watch(goalRepositoryProvider);
  return repo.getGoals();
});

class GoalScreen extends ConsumerWidget {
  const GoalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);

    return PremiumPage(
      appBar: AppBar(
        title: const Text('Muc tieu tiet kiem'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showAddGoalDialog(context, ref)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Them muc tieu'),
      ),
      child: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Loi: $err')),
        data: (goals) {
          if (goals.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.flag_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('Chua co muc tieu', style: Theme.of(context).textTheme.titleMedium),
            ]));
          }
          final currencyFormat = NumberFormat('#,###');
          return ListView(padding: const EdgeInsets.all(16), children: [
            ...goals.map((goal) {
              final color = Color(int.parse(goal.color.replaceFirst('#', '0xFF')));
              final progress = goal.targetAmount > 0 ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0) : 0.0;
              return Card(margin: const EdgeInsets.only(bottom: 12), child: InkWell(
                onTap: () => _showAddSavingsDialog(context, ref, goal),
                borderRadius: BorderRadius.circular(16),
                child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                      child: Icon(goal.isCompleted ? Icons.check_circle : Icons.flag, color: color)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(goal.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (goal.deadline != null) Text('Han: ${DateFormat('dd/MM/yyyy').format(goal.deadline!)}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ])),
                  ]),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('${currencyFormat.format(goal.currentAmount)}d', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                    Text('${currencyFormat.format(goal.targetAmount)}d', style: TextStyle(color: Colors.grey[600])),
                  ]),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: progress, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation(color), minHeight: 8, borderRadius: BorderRadius.circular(4)),
                ])),
              ));
            }),
            const SizedBox(height: 80),
          ]);
        },
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Them muc tieu moi'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Ten muc tieu', prefixIcon: Icon(Icons.flag))),
        const SizedBox(height: 16),
        TextField(controller: targetController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'So tien muc tieu', prefixIcon: Icon(Icons.attach_money))),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huy')),
        FilledButton(onPressed: () async {
          if (titleController.text.isEmpty || targetController.text.isEmpty) return;
          final repo = ref.read(goalRepositoryProvider);
          await repo.createGoal(title: titleController.text, targetAmount: double.tryParse(targetController.text) ?? 0);
          ref.invalidate(goalsProvider);
          if (context.mounted) Navigator.pop(context);
        }, child: const Text('Them')),
      ],
    ));
  }

  void _showAddSavingsDialog(BuildContext context, WidgetRef ref, Goal goal) {
    final amountController = TextEditingController();
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Text('Them tiet kiem cho "${goal.title}"'),
      content: TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'So tien', prefixIcon: Icon(Icons.savings))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huy')),
        FilledButton(onPressed: () async {
          final amount = double.tryParse(amountController.text) ?? 0;
          if (amount <= 0) return;
          final repo = ref.read(goalRepositoryProvider);
          await repo.addSavings(goal.id!, amount);
          ref.invalidate(goalsProvider);
          if (context.mounted) Navigator.pop(context);
        }, child: const Text('Them')),
      ],
    ));
  }
}

