class Chat {
  final int id;
  final int? orderId;
  final int clientId;
  final int freelancerId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Дополнительные поля из JOIN
  final String? orderTitle;
  final int? otherUserId;
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
    required this.createdAt,
    required this.updatedAt,
    this.orderTitle,
    this.otherUserId,
    this.otherUserName,
    this.otherUserEmail,
    this.otherUserAvatar,
    this.unreadCount = 0,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      orderId: json['order_id'] != null 
          ? (json['order_id'] is int ? json['order_id'] : int.parse(json['order_id'].toString()))
          : null,
      clientId: json['client_id'] is int 
          ? json['client_id'] 
          : int.parse(json['client_id'].toString()),
      freelancerId: json['freelancer_id'] is int 
          ? json['freelancer_id'] 
          : int.parse(json['freelancer_id'].toString()),
      lastMessage: json['last_message'],
      lastMessageAt: json['last_message_at'] != null 
          ? DateTime.parse(json['last_message_at']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      orderTitle: json['order_title'],
      otherUserId: json['other_user_id'] != null
          ? (json['other_user_id'] is int ? json['other_user_id'] : int.parse(json['other_user_id'].toString()))
          : null,
      otherUserName: json['other_user_name'],
      otherUserEmail: json['other_user_email'],
      otherUserAvatar: json['other_user_avatar'],
      unreadCount: json['unread_count'] is int ? json['unread_count'] : int.parse(json['unread_count'].toString()),
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
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

