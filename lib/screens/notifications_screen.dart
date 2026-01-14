import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationsProvider);
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('УВЕДОМЛЕНИЯ'),
        actions: [
          if (notificationsState.unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: () {
                ref.read(notificationsProvider.notifier).markAllAsRead();
              },
              tooltip: 'Отметить все как прочитанные',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(notificationsProvider.notifier).refresh();
            },
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: notificationsState.notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: AppTheme.mistGray,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Нет уведомлений',
                    style: TextStyle(
                      color: AppTheme.tombstoneWhite,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Все задачи под контролем',
                    style: TextStyle(color: AppTheme.mistGray),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: notificationsState.notifications.length,
              itemBuilder: (context, index) {
                final notification = notificationsState.notifications[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AppTheme.slideUpAnimation(
                    offset: 15,
                    duration: Duration(milliseconds: 800 + (index * 100)),
                    child: Dismissible(
                      key: Key(notification.id.toString()),
                      onDismissed: (direction) {
                        ref.read(notificationsProvider.notifier).dismiss(notification.id);
                      },
                      background: Container(
                        color: AppTheme.bloodRed,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          if (!notification.isRead) {
                            ref.read(notificationsProvider.notifier).markAsRead(notification.id);
                          }
                        },
                        child: _buildNotificationCard(notification, dateFormat),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildNotificationCard(notification, DateFormat dateFormat) {
    final iconData = _getIconForType(notification.type);
    final color = _getColorForType(notification.type);

    return AppTheme.animatedGothicCard(
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: notification.isRead ? AppTheme.dimGray : color,
              width: 4,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  border: Border.all(color: color.withOpacity(0.5)),
                  borderRadius: BorderRadius.zero,
                ),
                child: Icon(iconData, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: notification.isRead ? FontWeight.w300 : FontWeight.w500,
                        color: notification.isRead ? AppTheme.ashGray : AppTheme.tombstoneWhite,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.mistGray,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      dateFormat.format(notification.createdAt),
                      style: TextStyle(
                        fontSize: 9,
                        color: AppTheme.dimGray,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'error':
        return Icons.error_outline;
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'success':
        return Icons.check_circle_outline;
      default:
        return Icons.info_outline;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'error':
        return AppTheme.bloodRed;
      case 'warning':
        return Colors.orange;
      case 'success':
        return Colors.green;
      default:
        return AppTheme.tombstoneWhite;
    }
  }
}

