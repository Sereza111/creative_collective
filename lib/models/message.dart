import '../utils/ids.dart';

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  final String? senderName;
  final String? senderEmail;
  final String? senderAvatar;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.message,
    this.isRead = false,
    this.createdAt,
    this.senderName,
    this.senderEmail,
    this.senderAvatar,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: idFromJson(json['id']),
      chatId: idFromJson(json['chat_id']),
      senderId: idFromJson(json['sender_id']),
      message: json['message']?.toString() ?? '',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      senderName: json['sender_name']?.toString(),
      senderEmail: json['sender_email']?.toString(),
      senderAvatar: json['sender_avatar']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  DateTime get displayCreatedAt => createdAt ?? DateTime.now();

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
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
