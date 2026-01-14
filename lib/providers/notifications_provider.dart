import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification.dart';
import '../models/task.dart';
import 'tasks_provider.dart';

class NotificationsState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final String? error;

  NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final Ref ref;
  
  NotificationsNotifier(this.ref) : super(NotificationsState()) {
    _checkTaskDeadlines();
  }

  void _checkTaskDeadlines() {
    final tasksState = ref.read(tasksProvider);
    final now = DateTime.now();
    final notifications = <AppNotification>[];
    int notificationId = 1;

    for (var task in tasksState.tasks) {
      final daysUntilDue = task.dueDate.difference(now).inDays;
      
      // Task overdue
      if (daysUntilDue < 0 && task.status != 'done') {
        notifications.add(AppNotification(
          id: notificationId++,
          title: 'Просроченная задача',
          message: 'Задача "${task.title}" просрочена на ${-daysUntilDue} дн.',
          type: 'error',
          createdAt: now,
          data: {'task_id': task.id, 'type': 'overdue'},
        ));
      }
      // Task due soon (within 3 days)
      else if (daysUntilDue >= 0 && daysUntilDue <= 3 && task.status != 'done') {
        notifications.add(AppNotification(
          id: notificationId++,
          title: 'Задача скоро истекает',
          message: 'Задача "${task.title}" должна быть выполнена через $daysUntilDue дн.',
          type: 'warning',
          createdAt: now,
          data: {'task_id': task.id, 'type': 'due_soon'},
        ));
      }
    }

    state = state.copyWith(notifications: notifications);
  }

  void markAsRead(int notificationId) {
    final updatedNotifications = state.notifications.map((notification) {
      if (notification.id == notificationId) {
        return notification.copyWith(isRead: true);
      }
      return notification;
    }).toList();

    state = state.copyWith(notifications: updatedNotifications);
  }

  void markAllAsRead() {
    final updatedNotifications = state.notifications.map((notification) {
      return notification.copyWith(isRead: true);
    }).toList();

    state = state.copyWith(notifications: updatedNotifications);
  }

  void dismiss(int notificationId) {
    final updatedNotifications = state.notifications
        .where((notification) => notification.id != notificationId)
        .toList();

    state = state.copyWith(notifications: updatedNotifications);
  }

  void refresh() {
    _checkTaskDeadlines();
  }

  void addNotification(AppNotification notification) {
    state = state.copyWith(
      notifications: [notification, ...state.notifications],
    );
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(ref);
});

