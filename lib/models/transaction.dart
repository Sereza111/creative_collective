class Transaction {
  final String id;
  final String financeId;
  final String type; // 'earned', 'spent', 'bonus', 'penalty'
  final double amount;
  final String? description;
  final String? category;
  final DateTime date;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.financeId,
    required this.type,
    required this.amount,
    this.description,
    this.category,
    required this.date,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      financeId: json['finance_id'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      description: json['description'],
      category: json['category'],
      date: DateTime.parse(json['date'] ?? json['transaction_date']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'finance_id': financeId,
      'type': type,
      'amount': amount,
      'description': description,
      'category': category,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isPositive => type == 'earned' || type == 'bonus';
}

