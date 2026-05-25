import '../utils/ids.dart';

class UserBalance {
  final String id;
  final String userId;
  final double balance;
  final double totalEarned;
  final double totalSpent;
  final double totalWithdrawn;
  final double pendingAmount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserBalance({
    required this.id,
    required this.userId,
    required this.balance,
    required this.totalEarned,
    required this.totalSpent,
    required this.totalWithdrawn,
    required this.pendingAmount,
    this.createdAt,
    this.updatedAt,
  });

  factory UserBalance.fromJson(Map<String, dynamic> json) {
    return UserBalance(
      id: idFromJson(json['id']),
      userId: idFromJson(json['user_id']),
      balance: _parseDouble(json['balance']),
      totalEarned: _parseDouble(json['total_earned']),
      totalSpent: _parseDouble(json['total_spent']),
      totalWithdrawn: _parseDouble(json['total_withdrawn']),
      pendingAmount: _parseDouble(json['pending_amount']),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
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
