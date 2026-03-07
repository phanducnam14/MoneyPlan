class Expense {
  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.note = '',
  });

  final String id;
  final double amount;
  final String category;
  final DateTime date;
  final String note;

  // JSON helpers for persistence
  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'] as String,
    amount: (json['amount'] as num).toDouble(),
    category: json['category'] as String,
    date: DateTime.parse(json['date'] as String),
    note: json['note'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'category': category,
    'date': date.toIso8601String(),
    'note': note,
  };
}

class Income {
  Income({
    required this.id,
    required this.amount,
    required this.source,
    required this.date,
    this.note = '',
  });

  final String id;
  final double amount;
  final String source;
  final DateTime date;
  final String note;

  factory Income.fromJson(Map<String, dynamic> json) => Income(
    id: json['id'] as String,
    amount: (json['amount'] as num).toDouble(),
    source: json['source'] as String,
    date: DateTime.parse(json['date'] as String),
    note: json['note'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'amount': amount,
    'source': source,
    'date': date.toIso8601String(),
    'note': note,
  };
}
