import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/chat_provider.dart';
import 'chat_screen.dart';

class ChatsListScreen extends ConsumerWidget {
  const ChatsListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsState = ref.watch(chatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('СООБЩЕНИЯ'),
      ),
      body: chatsState.isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.tombstoneWhite),
              ),
            )
          : chatsState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: AppTheme.bloodRed),
                      const SizedBox(height: 20),
                      Text(
                        'Ошибка: ${chatsState.error}',
                        style: TextStyle(color: AppTheme.tombstoneWhite),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => ref.read(chatsProvider.notifier).loadChats(),
                        child: const Text('Повторить'),
                      ),
                    ],
                  ),
                )
              : chatsState.chats.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 64, color: AppTheme.mistGray),
                          const SizedBox(height: 20),
                          Text(
                            'Нет активных чатов',
                            style: TextStyle(color: AppTheme.tombstoneWhite, fontSize: 18),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Чаты появятся после начала работы над заказом',
                            style: TextStyle(color: AppTheme.mistGray),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await ref.read(chatsProvider.notifier).loadChats();
                      },
                      backgroundColor: AppTheme.shadowGray,
                      color: AppTheme.tombstoneWhite,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: chatsState.chats.length,
                        itemBuilder: (context, index) {
                          final chat = chatsState.chats[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AppTheme.slideUpAnimation(
                              offset: 15,
                              duration: Duration(milliseconds: 800 + (index * 100)),
                              child: GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(chat: chat),
                                    ),
                                  );
                                  // Обновляем список после возврата из чата
                                  ref.read(chatsProvider.notifier).loadChats();
                                },
                                child: _buildChatCard(chat),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildChatCard(chat) {
    final otherUserName = chat.otherUserName ?? chat.otherUserEmail ?? 'Собеседник';
    final hasUnread = chat.unreadCount > 0;

    return AppTheme.animatedGothicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Аватар
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.shadowGray,
                border: Border.all(
                  color: hasUnread ? AppTheme.bloodRed : AppTheme.dimGray,
                  width: hasUnread ? 2 : 1,
                ),
              ),
              child: Icon(
                Icons.person,
                color: AppTheme.mistGray,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Информация о чате
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          otherUserName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w300,
                            color: AppTheme.tombstoneWhite,
                            letterSpacing: 1.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.lastMessageAt != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(chat.lastMessageAt!),
                          style: TextStyle(
                            fontSize: 10,
                            color: hasUnread ? AppTheme.tombstoneWhite : AppTheme.mistGray,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (chat.orderTitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Заказ: ${chat.orderTitle}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.ashGray,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (chat.lastMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      chat.lastMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: hasUnread ? AppTheme.tombstoneWhite : AppTheme.mistGray,
                        fontWeight: hasUnread ? FontWeight.w400 : FontWeight.w300,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Badge непрочитанных
            if (hasUnread) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.bloodRed,
                  border: Border.all(color: AppTheme.bloodRed),
                ),
                child: Text(
                  chat.unreadCount.toString(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.ghostWhite,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE', 'ru_RU').format(dateTime);
    } else {
      return DateFormat('dd.MM').format(dateTime);
    }
  }
}

