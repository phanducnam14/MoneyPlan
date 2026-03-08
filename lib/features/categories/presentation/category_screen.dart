import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_provider.dart';
import '../../../shared/widgets/premium_page.dart';
import '../../../shared/widgets/modern_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../data/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(dioProvider));
});

final categoriesProvider = FutureProvider.family<List<Category>, String?>((ref, type) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getCategories(type: type);
});

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenseCategories = ref.watch(categoriesProvider('expense'));
    final incomeCategories = ref.watch(categoriesProvider('income'));

    return PremiumPage(
      appBar: AppBar(
        title: const Text('Quản lý danh mục'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '💰 Chi tiêu'),
            Tab(text: '📈 Thu nhập'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm danh mục'),
      ),
      child: TabBarView(
        controller: _tabController,
        children: [
          _CategoryList(
            categories: expenseCategories,
            onRefresh: () async => await ref.refresh(categoriesProvider('expense').future),
            onDelete: (id) => _deleteCategory(id, 'expense'),
          ),
          _CategoryList(
            categories: incomeCategories,
            onRefresh: () async => await ref.refresh(categoriesProvider('income').future),
            onDelete: (id) => _deleteCategory(id, 'income'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddCategoryDialog(BuildContext context) async {
    final nameController = TextEditingController();
    var selectedType = _tabController.index == 0 ? 'expense' : 'income';
    String selectedIcon = 'category';
    String selectedColor = '#6366F1';

    final icons = ['restaurant', 'home', 'directions_car', 'movie', 'school', 
                  'medical_services', 'shopping_bag', 'work', 'laptop', 
                  'trending_up', 'card_giftcard', 'attach_money', 'category'];
    final colors = ['#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7', 
                   '#DDA0DD', '#98D8C8', '#2ECC71', '#3498DB', '#9B59B6', 
                   '#E74C3C', '#95A5A6', '#6366F1'];

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Thêm danh mục mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên danh mục',
                    prefixIcon: Icon(Icons.label),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Chọn icon:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: icons.map((icon) => 
                    GestureDetector(
                      onTap: () => setState(() => selectedIcon = icon),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: selectedIcon == icon 
                              ? AppTheme.primaryGradientStart.withValues(alpha: 0.2) 
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: selectedIcon == icon 
                              ? Border.all(color: AppTheme.primaryGradientStart, width: 2) 
                              : null,
                        ),
                        child: Icon(_getIconData(icon), size: 24),
                      ),
                    ),
                  ).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Chọn màu:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colors.map((color) => 
                    GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(int.parse(color.replaceFirst('#', '0xFF'))),
                          shape: BoxShape.circle,
                          border: selectedColor == color 
                              ? Border.all(color: Colors.black, width: 3) 
                              : null,
                        ),
                      ),
                    ),
                  ).toList(),
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
                if (nameController.text.trim().isEmpty) return;
                try {
                  final repo = ref.read(categoryRepositoryProvider);
                  await repo.createCategory(
                    name: nameController.text.trim(),
                    type: selectedType,
                    icon: selectedIcon,
                    color: selectedColor,
                  );
                  if (context.mounted) Navigator.pop(context);
                  unawaited(ref.refresh(categoriesProvider(null).future));
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
      ),
    );
  }

  Future<void> _deleteCategory(String id, String type) async {
    try {
      final repo = ref.read(categoryRepositoryProvider);
      await repo.deleteCategory(id);
      unawaited(ref.refresh(categoriesProvider(null).future));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  IconData _getIconData(String iconName) {
    final iconMap = {
      'restaurant': Icons.restaurant,
      'home': Icons.home,
      'directions_car': Icons.directions_car,
      'movie': Icons.movie,
      'school': Icons.school,
      'medical_services': Icons.medical_services,
      'shopping_bag': Icons.shopping_bag,
      'work': Icons.work,
      'laptop': Icons.laptop,
      'trending_up': Icons.trending_up,
      'card_giftcard': Icons.card_giftcard,
      'attach_money': Icons.attach_money,
      'category': Icons.category,
    };
    return iconMap[iconName] ?? Icons.category;
  }
}

class _CategoryList extends StatelessWidget {
  final AsyncValue<List<Category>> categories;
  final Future<void> Function() onRefresh;
  final Future<void> Function(String) onDelete;

  const _CategoryList({
    required this.categories,
    required this.onRefresh,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return categories.when(
      data: (list) => list.isEmpty
          ? const Center(child: Text('Chưa có danh mục'))
          : RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final cat = list[index];
                  return _CategoryCard(
                    category: cat,
                    onDelete: cat.isDefault ? null : () => onDelete(cat.id!),
                  );
                },
              ),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback? onDelete;

  const _CategoryCard({
    required this.category,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(category.color.replaceFirst('#', '0xFF')));
    final icon = _getIconData(category.icon);

    return GlassCard(
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(category.name),
        subtitle: category.isDefault 
            ? const Text('Danh mục mặc định', style: TextStyle(fontSize: 12))
            : const Text('Danh mục tùy chỉnh', style: TextStyle(fontSize: 12)),
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _showDeleteDialog(context),
              )
            : null,
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa danh mục'),
        content: Text('Bạn có chắc muốn xóa "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    final iconMap = {
      'restaurant': Icons.restaurant,
      'home': Icons.home,
      'directions_car': Icons.directions_car,
      'movie': Icons.movie,
      'school': Icons.school,
      'medical_services': Icons.medical_services,
      'shopping_bag': Icons.shopping_bag,
      'work': Icons.work,
      'laptop': Icons.laptop,
      'trending_up': Icons.trending_up,
      'card_giftcard': Icons.card_giftcard,
      'attach_money': Icons.attach_money,
      'category': Icons.category,
    };
    return iconMap[iconName] ?? Icons.category;
  }
}

