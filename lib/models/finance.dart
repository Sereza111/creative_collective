class Finance {
  final String id;
  final String userId;
  final double balance;
  final double totalEarned;
  final List<Transaction> transactions;

  Finance({
    required this.id,
    required this.userId,
    required this.balance,
    required this.totalEarned,
    required this.transactions,
  });

  factory Finance.fromJson(Map<String, dynamic> json) {
    return Finance(
      id: json['id'],
      userId: json['user_id'],
      balance: (json['balance'] as num).toDouble(),
      totalEarned: (json['total_earned'] as num).toDouble(),
      transactions: (json['transactions'] as List)
          .map((t) => Transaction.fromJson(t))
          .toList(),
    );
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
      id: json['id'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      description: json['description'],
      date: DateTime.parse(json['date']),
    );
  }
}
