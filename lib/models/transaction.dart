class TransactionModel {
  final int id;
  final int userId;
  final int? orderId;
  final String type; // income, expense, commission, withdrawal, refund
  final double amount;
  final String? description;
  final String status; // pending, completed, cancelled, refunded
  final String? paymentMethod;
  final int? relatedUserId;
  final DateTime createdAt;
  final DateTime updatedAt;
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
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
    this.orderTitle,
    this.relatedUserName,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'],
      userId: json['user_id'],
      orderId: json['order_id'],
      type: json['type'],
      amount: _parseDouble(json['amount']),
      description: json['description'],
      status: json['status'],
      paymentMethod: json['payment_method'],
      relatedUserId: json['related_user_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      orderTitle: json['order_title'],
      relatedUserName: json['related_user_name'],
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String get typeLabel {
    switch (type) {
      case 'income':
        return 'Доход';
      case 'expense':
        return 'Расход';
      case 'commission':
        return 'Комиссия';
      case 'withdrawal':
        return 'Вывод средств';
      case 'refund':
        return 'Возврат';
      default:
        return type;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'В ожидании';
      case 'completed':
        return 'Завершена';
      case 'cancelled':
        return 'Отменена';
      case 'refunded':
        return 'Возвращена';
      default:
        return status;
    }
  }
}
