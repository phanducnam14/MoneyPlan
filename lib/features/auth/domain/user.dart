class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.monthlyBudget = 0,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final double monthlyBudget;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: (json['_id'] as String?) ?? (json['id'] as String?) ?? '',
    name: json['name'] as String? ?? '',
    email: json['email'] as String? ?? '',
    role: json['role'] as String? ?? 'user',
    monthlyBudget: (json['monthlyBudget'] as num?)?.toDouble() ?? 0,
  );

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    double? monthlyBudget,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
    );
  }
}
