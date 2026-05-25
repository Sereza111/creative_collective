import '../utils/ids.dart';

class Chat {
  final String id;
  final String? orderId;
  final String clientId;
  final String freelancerId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String? orderTitle;
  final String? otherUserId;
  final String? otherUserName;
  final String? otherUserEmail;
  final String? otherUserAvatar;
  final int unreadCount;

  Chat({
    required this.id,
    this.orderId,
    required this.clientId,
    required this.freelancerId,
    this.lastMessage,
    this.lastMessageAt,
    this.createdAt,
    this.updatedAt,
    this.orderTitle,
    this.otherUserId,
    this.otherUserName,
    this.otherUserEmail,
    this.otherUserAvatar,
    this.unreadCount = 0,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: idFromJson(json['id']),
      orderId: json['order_id'] != null ? idFromJson(json['order_id']) : null,
      clientId: idFromJson(json['client_id']),
      freelancerId: idFromJson(json['freelancer_id']),
      lastMessage: json['last_message']?.toString(),
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      orderTitle: json['order_title']?.toString(),
      otherUserId: json['other_user_id'] != null ? idFromJson(json['other_user_id']) : null,
      otherUserName: json['other_user_name']?.toString(),
      otherUserEmail: json['other_user_email']?.toString(),
      otherUserAvatar: json['other_user_avatar']?.toString(),
      unreadCount: json['unread_count'] is int
          ? json['unread_count']
          : int.tryParse(json['unread_count']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'client_id': clientId,
      'freelancer_id': freelancerId,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
