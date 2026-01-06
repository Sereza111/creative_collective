class Finance {
  final String id;
  final String userId;
  final double balance;
  final double totalEarned;
  final double totalSpent;
  final List<Transaction> transactions;

  Finance({
    required this.id,
    required this.userId,
    required this.balance,
    required this.totalEarned,
    required this.totalSpent,
    required this.transactions,
  });

  factory Finance.fromJson(Map<String, dynamic> json) {
    return Finance(
      id: json['id'],
      userId: json['user_id'],
      balance: _parseDouble(json['balance']),
      totalEarned: _parseDouble(json['total_earned']),
      totalSpent: _parseDouble(json['total_spent']),
      transactions: (json['recent_transactions'] ?? json['transactions'] ?? [])
          is List
          ? ((json['recent_transactions'] ?? json['transactions']) as List)
              .map((t) => Transaction.fromJson(t))
              .toList()
          : [],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'balance': balance,
      'total_earned': totalEarned,
      'total_spent': totalSpent,
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
  }
}

class Transaction {
  final String id;
  final String type; // 'earned', 'spent', 'bonus'
  final double amount;
  final String description;
  final DateTime date;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      type: json['type'] ?? 'earned',
      amount: Finance._parseDouble(json['amount']),
      description: json['description'] ?? '',
      date: json['date'] != null 
          ? DateTime.tryParse(json['date']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
    };
  }
}
