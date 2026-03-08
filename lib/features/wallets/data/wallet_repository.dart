import 'package:dio/dio.dart';

class Wallet {
  final String? id;
  final String name;
  final double balance;
  final String icon;
  final String color;
  final bool isDefault;
  final String type;
  final double? actualBalance;
  final double? totalIncome;
  final double? totalExpense;

  Wallet({
    this.id,
    required this.name,
    this.balance = 0,
    this.icon = 'account_balance_wallet',
    this.color = '#6366F1',
    this.isDefault = false,
    this.type = 'cash',
    this.actualBalance,
    this.totalIncome,
    this.totalExpense,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      balance: (json['balance'] ?? 0).toDouble(),
      icon: json['icon'] ?? 'account_balance_wallet',
      color: json['color'] ?? '#6366F1',
      isDefault: json['isDefault'] ?? false,
      type: json['type'] ?? 'cash',
      actualBalance: json['actualBalance']?.toDouble(),
      totalIncome: json['totalIncome']?.toDouble(),
      totalExpense: json['totalExpense']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'name': name,
      'balance': balance,
      'icon': icon,
      'color': color,
      'isDefault': isDefault,
      'type': type,
    };
  }
}

class WalletRepository {
  WalletRepository(this._dio);

  final Dio _dio;

  Future<List<Wallet>> getWallets() async {
    final response = await _dio.get('/wallets');
    final List<dynamic> data = response.data['data'] ?? [];
    return data.map((json) => Wallet.fromJson(json)).toList();
  }

  Future<Wallet> getWalletById(String id) async {
    final response = await _dio.get('/wallets/$id');
    return Wallet.fromJson(response.data);
  }

  Future<Wallet> createWallet({
    required String name,
    double? balance,
    String? icon,
    String? color,
    String? type,
    bool? isDefault,
  }) async {
    final response = await _dio.post('/wallets', data: {
      'name': name,
      'balance': balance ?? 0,
      'icon': icon ?? 'account_balance_wallet',
      'color': color ?? '#6366F1',
      'type': type ?? 'cash',
      'isDefault': isDefault ?? false,
    });
    return Wallet.fromJson(response.data);
  }

  Future<Wallet> updateWallet(String id, {
    String? name,
    double? balance,
    String? icon,
    String? color,
    String? type,
    bool? isDefault,
  }) async {
    final response = await _dio.put('/wallets/$id', data: {
      // ignore: use_null_aware_elements
      if (name != null) 'name': name,
      // ignore: use_null_aware_elements
      if (balance != null) 'balance': balance,
      // ignore: use_null_aware_elements
      if (icon != null) 'icon': icon,
      // ignore: use_null_aware_elements
      if (color != null) 'color': color,
      // ignore: use_null_aware_elements
      if (type != null) 'type': type,
      // ignore: use_null_aware_elements
      if (isDefault != null) 'isDefault': isDefault,
    });
    return Wallet.fromJson(response.data);
  }

  Future<void> deleteWallet(String id) async {
    await _dio.delete('/wallets/$id');
  }
}
