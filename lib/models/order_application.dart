class OrderApplication {
  final int id;
  final int orderId;
  final int freelancerId;
  final String? freelancerName;
  final String? freelancerEmail;
  final String? freelancerAvatar;
  final String? message;
  final double? proposedBudget;
  final DateTime? proposedDeadline;
  final String status; // pending, accepted, rejected
  final DateTime createdAt;
  final DateTime? updatedAt;

  OrderApplication({
    required this.id,
    required this.orderId,
    required this.freelancerId,
    this.freelancerName,
    this.freelancerEmail,
    this.freelancerAvatar,
    this.message,
    this.proposedBudget,
    this.proposedDeadline,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory OrderApplication.fromJson(Map<String, dynamic> json) {
    return OrderApplication(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      orderId: json['order_id'] is int ? json['order_id'] : int.tryParse(json['order_id'].toString()) ?? 0,
      freelancerId: json['freelancer_id'] is int ? json['freelancer_id'] : int.tryParse(json['freelancer_id'].toString()) ?? 0,
      freelancerName: json['freelancer_name'],
      freelancerEmail: json['freelancer_email'],
      freelancerAvatar: json['freelancer_avatar'],
      message: json['message'],
      proposedBudget: json['proposed_budget'] != null 
          ? (json['proposed_budget'] is String ? double.tryParse(json['proposed_budget']) : (json['proposed_budget'] as num).toDouble())
          : null,
      proposedDeadline: json['proposed_deadline'] != null ? DateTime.parse(json['proposed_deadline']) : null,
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'freelancer_id': freelancerId,
      'message': message,
      'proposed_budget': proposedBudget,
      'proposed_deadline': proposedDeadline?.toIso8601String(),
      'status': status,
    };
  }

  String getStatusLabel() {
    switch (status) {
      case 'pending':
        return 'Ожидает';
      case 'accepted':
        return 'Принят';
      case 'rejected':
        return 'Отклонен';
      default:
        return status;
    }
  }
}

