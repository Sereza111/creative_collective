class Message {
  final int id;
  final int chatId;
  final int senderId;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  
  // Дополнительные поля из JOIN
  final String? senderName;
  final String? senderEmail;
  final String? senderAvatar;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.message,
    this.isRead = false,
    required this.createdAt,
    this.senderName,
    this.senderEmail,
    this.senderAvatar,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      chatId: json['chat_id'] is int ? json['chat_id'] : int.parse(json['chat_id'].toString()),
      senderId: json['sender_id'] is int ? json['sender_id'] : int.parse(json['sender_id'].toString()),
      message: json['message'],
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: DateTime.parse(json['created_at']),
      senderName: json['sender_name'],
      senderEmail: json['sender_email'],
      senderAvatar: json['sender_avatar'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Message copyWith({
    int? id,
    int? chatId,
    int? senderId,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    String? senderName,
    String? senderEmail,
    String? senderAvatar,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      senderAvatar: senderAvatar ?? this.senderAvatar,
    );
  }
}

