class UserBalance {
  final int id;
  final int userId;
  final double balance;
  final double totalEarned;
  final double totalSpent;
  final double totalWithdrawn;
  final double pendingAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserBalance({
    required this.id,
    required this.userId,
    required this.balance,
    required this.totalEarned,
    required this.totalSpent,
    required this.totalWithdrawn,
    required this.pendingAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserBalance.fromJson(Map<String, dynamic> json) {
    return UserBalance(
      id: json['id'],
      userId: json['user_id'],
      balance: _parseDouble(json['balance']),
      totalEarned: _parseDouble(json['total_earned']),
      totalSpent: _parseDouble(json['total_spent']),
      totalWithdrawn: _parseDouble(json['total_withdrawn']),
      pendingAmount: _parseDouble(json['pending_amount']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

