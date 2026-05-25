import '../utils/ids.dart';

class TransactionModel {
  final String id;
  final String userId;
  final String? orderId;
  final String type; // income, expense, commission, withdrawal, refund
  final double amount;
  final String? description;
  final String status; // pending, completed, cancelled, refunded
  final String? paymentMethod;
  final String? relatedUserId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final String? orderTitle;
  final String? relatedUserName;

  TransactionModel({
    required this.id,
    required this.userId,
    this.orderId,
    required this.type,
    required this.amount,
    this.description,
    required this.status,
    this.paymentMethod,
    this.relatedUserId,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.orderTitle,
    this.relatedUserName,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: idFromJson(json['id']),
      userId: idFromJson(json['user_id']),
      orderId: json['order_id'] != null ? idFromJson(json['order_id']) : null,
      type: json['type']?.toString() ?? 'expense',
      amount: _parseDouble(json['amount']),
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'completed',
      paymentMethod: json['payment_method']?.toString(),
      relatedUserId: json['related_user_id'] != null ? idFromJson(json['related_user_id']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'].toString()) : null,
      orderTitle: json['order_title']?.toString(),
      relatedUserName: json['related_user_name']?.toString(),
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
