import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../shared/widgets/premium_page.dart';
import '../../../shared/widgets/modern_widgets.dart';
import '../data/wallet_repository.dart';
import '../../../core/network/dio_provider.dart';

final walletsProvider = FutureProvider<List<Wallet>>((ref) async {
  final repo = ref.watch(walletRepositoryProvider);
  return repo.getWallets();
});

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsProvider);

    return PremiumPage(
      appBar: AppBar(
        title: const Text('Ví của tôi'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddWalletDialog(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWalletDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Thêm ví'),
      ),
      child: walletsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
        data: (wallets) {
          if (wallets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Chưa có ví', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Thêm ví để quản lý tài chính', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          final totalBalance = wallets.fold(0.0, (sum, w) => sum + (w.actualBalance ?? w.balance));
          final currencyFormat = NumberFormat('#,###');

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('Tổng số dư', style: TextStyle(fontSize: 14, color: Colors.white70)),
                      const SizedBox(height: 8),
                      Text('${currencyFormat.format(totalBalance)}đ', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 8),
                      Text('${wallets.length} ví', style: const TextStyle(fontSize: 12, color: Colors.white60)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Danh sách ví', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...wallets.map((wallet) => _WalletCard(wallet: wallet, onTap: () => _showEditWalletDialog(context, ref, wallet), onDelete: () => _deleteWallet(context, ref, wallet))),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  void _showAddWalletDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String selectedType = 'cash';
    String selectedColor = '#6366F1';
    final colors = ['#6366F1', '#10B981', '#F59E0B', '#EF4444', '#8B5CF6', '#EC4899'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm ví mới'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên ví', prefixIcon: Icon(Icons.account_balance_wallet))),
              const SizedBox(height: 16),
              TextField(controller: balanceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số dư ban đầu', prefixIcon: Icon(Icons.attach_money))),
              const SizedBox(height: 16),
              const Text('Loại ví', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                ChoiceChip(label: const Text('💵 Tiền mặt'), selected: selectedType == 'cash', onSelected: (s) { if (s) selectedType = 'cash'; }),
                ChoiceChip(label: const Text('🏦 Ngân hàng'), selected: selectedType == 'bank', onSelected: (s) { if (s) selectedType = 'bank'; }),
                ChoiceChip(label: const Text('💳 Thẻ'), selected: selectedType == 'credit', onSelected: (s) { if (s) selectedType = 'credit'; }),
              ]),
              const SizedBox(height: 16),
              const Text('Màu sắc', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: colors.map((c) => GestureDetector(
                onTap: () => selectedColor = c,
                child: Container(width: 36, height: 36, decoration: BoxDecoration(
                  color: Color(int.parse(c.replaceFirst('#', '0xFF'))),
                  shape: BoxShape.circle,
                  border: selectedColor == c ? Border.all(color: Colors.white, width: 3) : null,
                )),
              )).toList()),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          FilledButton(onPressed: () async {
            if (nameController.text.isEmpty) return;
            final repo = ref.read(walletRepositoryProvider);
            await repo.createWallet(name: nameController.text, balance: double.tryParse(balanceController.text) ?? 0, type: selectedType, color: selectedColor);
            ref.invalidate(walletsProvider);
            if (context.mounted) Navigator.pop(context);
          }, child: const Text('Thêm')),
        ],
      ),
    );
  }

  void _showEditWalletDialog(BuildContext context, WidgetRef ref, Wallet wallet) {
    final nameController = TextEditingController(text: wallet.name);
    final balanceController = TextEditingController(text: wallet.balance.toString());
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Sửa ví'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên ví', prefixIcon: Icon(Icons.account_balance_wallet))),
        const SizedBox(height: 16),
        TextField(controller: balanceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Số dư', prefixIcon: Icon(Icons.attach_money))),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(onPressed: () async {
          if (nameController.text.isEmpty) return;
          final repo = ref.read(walletRepositoryProvider);
          await repo.updateWallet(wallet.id!, name: nameController.text, balance: double.tryParse(balanceController.text));
          ref.invalidate(walletsProvider);
          if (context.mounted) Navigator.pop(context);
        }, child: const Text('Lưu')),
      ],
    ));
  }

  void _deleteWallet(BuildContext context, WidgetRef ref, Wallet wallet) async {
    final confirm = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Xóa ví?'),
      content: Text('Bạn có chắc muốn xóa ví "${wallet.name}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
      ],
    ));
    if (confirm == true) {
      final repo = ref.read(walletRepositoryProvider);
      await repo.deleteWallet(wallet.id!);
      ref.invalidate(walletsProvider);
    }
  }
}

class _WalletCard extends StatelessWidget {
  final Wallet wallet;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _WalletCard({required this.wallet, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat('#,###');
    final color = Color(int.parse(wallet.color.replaceFirst('#', '0xFF')));
    final typeIcons = {'cash': Icons.account_balance_wallet, 'bank': Icons.account_balance, 'credit': Icons.credit_card, 'digital': Icons.phone_android};

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(typeIcons[wallet.type] ?? Icons.account_balance_wallet, color: color)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(wallet.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(wallet.isDefault ? 'Ví mặc định' : wallet.type, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${currencyFormat.format(wallet.actualBalance ?? wallet.balance)}đ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: (wallet.actualBalance ?? wallet.balance) >= 0 ? Colors.green : Colors.red)),
          ]),
          PopupMenuButton(itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Sửa')),
            if (!wallet.isDefault) const PopupMenuItem(value: 'delete', child: Text('Xóa', style: TextStyle(color: Colors.red))),
          ], onSelected: (value) { if (value == 'edit') onTap(); if (value == 'delete') onDelete(); }),
        ])),
      ),
    );
  }
}

