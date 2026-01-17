import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/notifications_provider.dart';
import '../models/notification.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(notificationsProvider.notifier).loadNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final notificationsState = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('УВЕДОМЛЕНИЯ'),
        actions: [
          // Фильтр непрочитанных
          IconButton(
            icon: Icon(
              _showUnreadOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _showUnreadOnly ? AppTheme.electricBlue : AppTheme.tombstoneWhite,
            ),
            onPressed: () {
              setState(() {
                _showUnreadOnly = !_showUnreadOnly;
              });
              ref.read(notificationsProvider.notifier).loadNotifications(unreadOnly: _showUnreadOnly);
            },
            tooltip: 'Только непрочитанные',
          ),
          // Отметить все как прочитанные
          if (notificationsState.unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: () async {
                await ref.read(notificationsProvider.notifier).markAllAsRead();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Все уведомления отмечены как прочитанные')),
                  );
                }
              },
              tooltip: 'Отметить все как прочитанные',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(notificationsProvider.notifier).loadNotifications(unreadOnly: _showUnreadOnly),
        backgroundColor: AppTheme.shadowGray,
        color: AppTheme.tombstoneWhite,
        child: notificationsState.isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppTheme.tombstoneWhite),
              )
            : notificationsState.error != null
                ? _buildError(notificationsState.error!)
                : notificationsState.notifications.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: notificationsState.notifications.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final notification = notificationsState.notifications[index];
                          return _buildNotificationCard(notification);
                        },
                      ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final icon = _getNotificationIcon(notification.type);
    final color = _getNotificationColor(notification.type);

    return Dismissible(
      key: Key('notification_${notification.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.bloodRed,
          border: Border.all(color: AppTheme.bloodRed),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (direction) {
        ref.read(notificationsProvider.notifier).deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Уведомление удалено')),
        );
      },
      child: AppTheme.animatedGothicCard(
        child: InkWell(
          onTap: () async {
            if (!notification.isRead) {
              await ref.read(notificationsProvider.notifier).markAsRead(notification.id);
            }
            // TODO: Навигация к связанной сущности
            if (notification.relatedType == 'order' && notification.relatedId != null) {
              // Navigator.pushNamed(context, '/order_detail', arguments: notification.relatedId);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: notification.isRead ? Colors.transparent : AppTheme.dimGray.withOpacity(0.1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Иконка
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.2),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                // Контент
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: notification.isRead ? FontWeight.w400 : FontWeight.bold,
                                color: notification.isRead ? AppTheme.ashGray : AppTheme.tombstoneWhite,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.electricBlue,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: notification.isRead ? AppTheme.mistGray : AppTheme.ashGray,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(notification.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.dimGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: AppTheme.dimGray,
          ),
          const SizedBox(height: 24),
          Text(
            'НЕТ УВЕДОМЛЕНИЙ',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.mistGray,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Все уведомления отобразятся здесь',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.dimGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: AppTheme.bloodRed),
          const SizedBox(height: 16),
          Text(
            'ОШИБКА',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.bloodRed,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.mistGray,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.read(notificationsProvider.notifier).loadNotifications(),
            style: AppTheme.gothicButtonStyle,
            child: const Text('ПОВТОРИТЬ'),
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'order_created':
        return Icons.add_shopping_cart;
      case 'order_updated':
        return Icons.update;
      case 'application_received':
        return Icons.mail_outline;
      case 'application_accepted':
        return Icons.check_circle_outline;
      case 'application_rejected':
        return Icons.cancel_outlined;
      case 'message_received':
        return Icons.chat_bubble_outline;
      case 'review_received':
        return Icons.star_outline;
      case 'order_completed':
        return Icons.done_all;
      case 'dispute_opened':
        return Icons.gavel;
      case 'dispute_resolved':
        return Icons.verified;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'order_created':
      case 'application_received':
        return AppTheme.electricBlue;
      case 'application_accepted':
      case 'order_completed':
      case 'dispute_resolved':
        return AppTheme.gothicGreen;
      case 'application_rejected':
      case 'dispute_opened':
        return AppTheme.bloodRed;
      case 'review_received':
        return AppTheme.goldenrod;
      case 'message_received':
        return AppTheme.gothicBlue;
      default:
        return AppTheme.ashGray;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Только что';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч назад';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн назад';
    } else {
      return DateFormat('dd.MM.yyyy', 'ru_RU').format(date);
    }
  }
}
