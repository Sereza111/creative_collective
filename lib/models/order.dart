class Order {
  final int id;
  final String title;
  final String? description;
  final double? budget;
  final DateTime? deadline;
  final String status; // draft, published, in_progress, review, completed, cancelled
  final int clientId;
  final String? clientName;
  final String? clientEmail;
  final int? freelancerId;
  final String? freelancerName;
  final String? freelancerEmail;
  final String? category;
  final int applicationsCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Order({
    required this.id,
    required this.title,
    this.description,
    this.budget,
    this.deadline,
    required this.status,
    required this.clientId,
    this.clientName,
    this.clientEmail,
    this.freelancerId,
    this.freelancerName,
    this.freelancerEmail,
    this.category,
    this.applicationsCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? 'Без названия',
      description: json['description'],
      budget: json['budget'] != null 
          ? (json['budget'] is String ? double.tryParse(json['budget']) : (json['budget'] as num).toDouble())
          : null,
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      status: json['status'] ?? 'draft',
      clientId: json['client_id'] is int ? json['client_id'] : int.tryParse(json['client_id'].toString()) ?? 0,
      clientName: json['client_name'],
      clientEmail: json['client_email'],
      freelancerId: json['freelancer_id'] is int 
          ? json['freelancer_id'] 
          : (json['freelancer_id'] != null ? int.tryParse(json['freelancer_id'].toString()) : null),
      freelancerName: json['freelancer_name'],
      freelancerEmail: json['freelancer_email'],
      category: json['category'],
      applicationsCount: json['applications_count'] is int 
          ? json['applications_count'] 
          : int.tryParse(json['applications_count']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'budget': budget,
      'deadline': deadline?.toIso8601String(),
      'status': status,
      'client_id': clientId,
      'freelancer_id': freelancerId,
      'category': category,
    };
  }

  String getStatusLabel() {
    switch (status) {
      case 'draft':
        return 'Черновик';
      case 'published':
        return 'Опубликован';
      case 'in_progress':
        return 'В работе';
      case 'review':
        return 'На проверке';
      case 'completed':
        return 'Завершен';
      case 'cancelled':
        return 'Отменен';
      default:
        return status;
    }
  }
}

