import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/premium_page.dart';
import '../data/recurring_repository.dart';
import '../../../core/network/dio_provider.dart';

final recurringProvider = FutureProvider<List<RecurringTransaction>>((ref) async {
  final repo = ref.watch(recurringRepositoryProvider);
  return repo.getRecurringTransactions();
});

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(recurringProvider);
    return PremiumPage(
      appBar: AppBar(title: const Text('Giao dich dinh ky'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => _showAddDialog(context, ref), icon: const Icon(Icons.add), label: const Text('Them')),
      child: recurringAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Loi: $err')),
        data: (list) {
          if (list.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.repeat, size: 64, color: Colors.grey[400]), const SizedBox(height: 16), Text('Chua co giao dich dinh ky', style: Theme.of(context).textTheme.titleMedium)]));
          final fmt = NumberFormat('#,###');
          return ListView(padding: const EdgeInsets.all(16), children: [
            ...list.map((r) {
              final isExp = r.type == 'expense';
              final col = isExp ? Colors.red : Colors.green;
              return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: col.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(isExp ? Icons.remove_circle : Icons.add_circle, color: col)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r.category, style: const TextStyle(fontWeight: FontWeight.bold)), Text(r.frequencyLabel, style: TextStyle(color: Colors.grey[600], fontSize: 12))])),
                Text('${isExp ? "-" : "+"}${fmt.format(r.amount)}d', style: TextStyle(fontWeight: FontWeight.bold, color: col)),
              ])));
            }),
          ]);
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final amtCtrl = TextEditingController();
    String type = 'expense';
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Them dinh ky'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: amtCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'So tien')),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huy')), FilledButton(onPressed: () async {
        final amt = double.tryParse(amtCtrl.text) ?? 0;
        if (amt <= 0) return;
        final repo = ref.read(recurringRepositoryProvider);
        await repo.createRecurringTransaction(amount: amt, category: 'Khac', type: type, frequency: 'monthly', nextExecutionDate: DateTime.now().add(const Duration(days: 30)));
        ref.invalidate(recurringProvider);
        if (ctx.mounted) Navigator.pop(ctx);
      }, child: const Text('Them'))],
    ));
  }
}

