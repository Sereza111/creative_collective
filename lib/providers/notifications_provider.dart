import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/notification.dart';

class NotificationsState {
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;
  final int unreadCount;

  NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
  });

  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
    int? unreadCount,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier() : super(NotificationsState()) {
    loadNotifications();
  }

  Future<void> loadNotifications({bool unreadOnly = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await ApiService.getNotifications(unreadOnly: unreadOnly);
      final notificationsList = (result['notifications'] as List)
          .map((json) => NotificationModel.fromJson(json))
          .toList();
      
      state = state.copyWith(
        notifications: notificationsList,
        unreadCount: result['unread_count'] ?? 0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refreshUnreadCount() async {
    try {
      final count = await ApiService.getUnreadNotificationsCount();
      state = state.copyWith(unreadCount: count);
    } catch (e) {
      print('Error refreshing unread count: $e');
    }
  }

  // Алиас для совместимости
  Future<void> refresh() async {
    await refreshUnreadCount();
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await ApiService.markNotificationAsRead(notificationId);
      
      // Обновляем локально
      final updatedNotifications = state.notifications.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(isRead: true, readAt: DateTime.now());
        }
        return n;
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
      );
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await ApiService.markAllNotificationsAsRead();
      
      // Обновляем локально
      final updatedNotifications = state.notifications.map((n) {
        return n.copyWith(isRead: true, readAt: DateTime.now());
      }).toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    try {
      await ApiService.deleteNotification(notificationId);
      
      // Удаляем локально
      final updatedNotifications = state.notifications.where((n) => n.id != notificationId).toList();
      final deletedNotification = state.notifications.firstWhere((n) => n.id == notificationId);
      
      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: deletedNotification.isRead ? state.unreadCount : (state.unreadCount > 0 ? state.unreadCount - 1 : 0),
      );
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier();
});

// Provider для количества непрочитанных уведомлений
final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).unreadCount;
});
