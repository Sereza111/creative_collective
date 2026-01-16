import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification.dart';
import '../models/task.dart';
import 'tasks_provider.dart';
import 'orders_provider.dart';
import 'auth_provider.dart';

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
    _checkAllNotifications();
  }

  void _checkAllNotifications() {
    final notifications = <AppNotification>[];
    int notificationId = 1;

    // Check task deadlines
    final tasksState = ref.read(tasksProvider);
    final now = DateTime.now();

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

    // Check marketplace orders
    final ordersState = ref.read(ordersProvider);
    final user = ref.read(authProvider).user;

    if (user != null) {
      for (var order in ordersState.orders) {
        // Notify freelancers about new orders in their category
        if (user.userRole == 'freelancer' && order.status == 'published') {
          final daysSinceCreated = now.difference(order.createdAt).inDays;
          if (daysSinceCreated <= 1) { // New orders within last 24 hours
            notifications.add(AppNotification(
              id: notificationId++,
              title: 'Новый заказ доступен',
              message: 'Заказ "${order.title}" - ${order.category ?? "без категории"}',
              type: 'info',
              createdAt: order.createdAt,
              data: {'order_id': order.id, 'type': 'new_order'},
            ));
          }
        }

        // Notify clients about new applications on their orders
        if (user.id == order.clientId && order.applicationsCount > 0) {
          notifications.add(AppNotification(
            id: notificationId++,
            title: 'Новые отклики на заказ',
            message: 'У заказа "${order.title}" ${order.applicationsCount} откликов',
            type: 'info',
            createdAt: now,
            data: {'order_id': order.id, 'type': 'new_applications'},
          ));
        }

        // Notify about order deadline
        if (order.deadline != null) {
          final daysUntilDeadline = order.deadline!.difference(now).inDays;
          if (daysUntilDeadline >= 0 && daysUntilDeadline <= 3 && 
              order.status == 'in_progress' && 
              (user.id == order.clientId || user.id == order.freelancerId)) {
            notifications.add(AppNotification(
              id: notificationId++,
              title: 'Дедлайн заказа приближается',
              message: 'Заказ "${order.title}" должен быть завершен через $daysUntilDeadline дн.',
              type: 'warning',
              createdAt: now,
              data: {'order_id': order.id, 'type': 'order_deadline'},
            ));
          }
        }
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
    _checkAllNotifications();
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

