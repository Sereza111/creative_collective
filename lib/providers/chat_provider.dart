import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat.dart';
import '../services/api_service.dart';

class ChatsState {
  final List<Chat> chats;
  final bool isLoading;
  final String? error;
  final int unreadCount;

  ChatsState({
    this.chats = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
  });

  ChatsState copyWith({
    List<Chat>? chats,
    bool? isLoading,
    String? error,
    int? unreadCount,
  }) {
    return ChatsState(
      chats: chats ?? this.chats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class ChatsNotifier extends StateNotifier<ChatsState> {
  ChatsNotifier() : super(ChatsState()) {
    loadChats();
  }

  Future<void> loadChats() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final chats = await ApiService.getUserChats();
      final unreadCount = await ApiService.getUnreadMessagesCount();
      
      state = state.copyWith(
        chats: chats,
        unreadCount: unreadCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> refreshUnreadCount() async {
    try {
      final unreadCount = await ApiService.getUnreadMessagesCount();
      state = state.copyWith(unreadCount: unreadCount);
    } catch (e) {
      // Игнорируем ошибки при обновлении счетчика
    }
  }

  void updateChatLastMessage(int chatId, String message, DateTime timestamp) {
    final updatedChats = state.chats.map((chat) {
      if (chat.id == chatId) {
        return Chat(
          id: chat.id,
          orderId: chat.orderId,
          clientId: chat.clientId,
          freelancerId: chat.freelancerId,
          lastMessage: message,
          lastMessageAt: timestamp,
          createdAt: chat.createdAt,
          updatedAt: timestamp,
          orderTitle: chat.orderTitle,
          otherUserId: chat.otherUserId,
          otherUserName: chat.otherUserName,
          otherUserEmail: chat.otherUserEmail,
          otherUserAvatar: chat.otherUserAvatar,
          unreadCount: chat.unreadCount,
        );
      }
      return chat;
    }).toList();

    // Сортируем по последнему сообщению
    updatedChats.sort((a, b) {
      if (a.lastMessageAt == null) return 1;
      if (b.lastMessageAt == null) return -1;
      return b.lastMessageAt!.compareTo(a.lastMessageAt!);
    });

    state = state.copyWith(chats: updatedChats);
  }
}

final chatsProvider = StateNotifierProvider<ChatsNotifier, ChatsState>((ref) {
  return ChatsNotifier();
});

