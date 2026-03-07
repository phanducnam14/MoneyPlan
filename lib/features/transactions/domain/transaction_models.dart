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
}
