import 'package:dio/dio.dart';

class Category {
  final String? id;
  final String name;
  final String type; // 'expense' or 'income'
  final String icon;
  final String color;
  final bool isDefault;

  Category({
    this.id,
    required this.name,
    required this.type,
    this.icon = 'category',
    this.color = '#6366F1',
    this.isDefault = false,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      type: json['type'] ?? 'expense',
      icon: json['icon'] ?? 'category',
      color: json['color'] ?? '#6366F1',
      isDefault: json['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
    };
  }
}

class CategoryRepository {
  CategoryRepository(this._dio);

  final Dio _dio;

  Future<List<Category>> getCategories({String? type}) async {
    final queryParams = <String, dynamic>{};
    if (type != null) queryParams['type'] = type;
    
    final response = await _dio.get(
      '/categories',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((json) => Category.fromJson(json)).toList();
  }

  Future<Category> createCategory({
    required String name,
    required String type,
    String? icon,
    String? color,
  }) async {
    final response = await _dio.post(
      '/categories',
      data: {
        'name': name,
        'type': type,
        'icon': icon ?? 'category',
        'color': color ?? '#6366F1',
      },
    );
    return Category.fromJson(response.data);
  }

  Future<Category> updateCategory(String id, {
    String? name,
    String? icon,
    String? color,
  }) async {
    final response = await _dio.put(
      '/categories/$id',
      data: {
        // ignore: use_null_aware_elements
        if (name != null) 'name': name,
        // ignore: use_null_aware_elements
        if (icon != null) 'icon': icon,
        // ignore: use_null_aware_elements
        if (color != null) 'color': color,
      },
    );
    return Category.fromJson(response.data);
  }

  Future<void> deleteCategory(String id) async {
    await _dio.delete('/categories/$id');
  }

  Future<void> initializeDefaults() async {
    await _dio.post('/categories/initialize');
  }
}

