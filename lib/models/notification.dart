class NotificationModel {
  final int id;
  final int userId;
  final String type;
  final String title;
  final String message;
  final int? relatedId;
  final String? relatedType;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? relatedTitle;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedId,
    this.relatedType,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.relatedTitle,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userId: json['user_id'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      relatedId: json['related_id'],
      relatedType: json['related_type'],
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: DateTime.parse(json['created_at']),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      relatedTitle: json['related_title'],
    );
  }

  NotificationModel copyWith({
    int? id,
    int? userId,
    String? type,
    String? title,
    String? message,
    int? relatedId,
    String? relatedType,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    String? relatedTitle,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      relatedId: relatedId ?? this.relatedId,
      relatedType: relatedType ?? this.relatedType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      relatedTitle: relatedTitle ?? this.relatedTitle,
    );
  }
}
