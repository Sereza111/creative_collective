import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../providers/chat_provider.dart';
import '../models/chat.dart';
import 'chat_screen.dart';

class ChatsListWithSearchScreen extends ConsumerStatefulWidget {
  const ChatsListWithSearchScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ChatsListWithSearchScreen> createState() => _ChatsListWithSearchScreenState();
}

class _ChatsListWithSearchScreenState extends ConsumerState<ChatsListWithSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Chat> _filterChats(List<Chat> chats) {
    if (_searchQuery.isEmpty) {
      return chats;
    }

    final query = _searchQuery.toLowerCase();
    return chats.where((chat) {
      final otherUserName = chat.otherUserName?.toLowerCase() ?? '';
      final orderTitle = chat.orderTitle?.toLowerCase() ?? '';
      final lastMessage = chat.lastMessage?.toLowerCase() ?? '';
      
      return otherUserName.contains(query) ||
             orderTitle.contains(query) ||
             lastMessage.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final chatsState = ref.watch(chatsProvider);
    final filteredChats = _filterChats(chatsState.chats);

    return Scaffold(
      appBar: AppBar(
        title: const Text('СООБЩЕНИЯ'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.charcoalGray,
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: AppTheme.tombstoneWhite),
              decoration: InputDecoration(
                hintText: 'Поиск по чатам...',
                hintStyle: TextStyle(color: AppTheme.mistGray),
                prefixIcon: Icon(Icons.search, color: AppTheme.mistGray),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppTheme.mistGray),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.midnightBlack,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppTheme.ashGray),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppTheme.ashGray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppTheme.tombstoneWhite),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
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
              : filteredChats.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isEmpty ? Icons.chat_bubble_outline : Icons.search_off,
                            size: 64,
                            color: AppTheme.mistGray,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _searchQuery.isEmpty ? 'Нет активных чатов' : 'Ничего не найдено',
                            style: TextStyle(color: AppTheme.tombstoneWhite, fontSize: 18),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _searchQuery.isEmpty
                                ? 'Чаты появятся после начала работы над заказом'
                                : 'Попробуйте изменить запрос',
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
                        itemCount: filteredChats.length,
                        itemBuilder: (context, index) {
                          final chat = filteredChats[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: AppTheme.slideUpAnimation(
                              offset: 15,
                              duration: Duration(milliseconds: 800 + (index * 100)),
                              child: _buildChatCard(chat),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildChatCard(Chat chat) {
    final hasUnread = chat.unreadCount > 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chat: chat),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasUnread ? AppTheme.shadowGray.withOpacity(0.5) : AppTheme.charcoalGray,
          border: Border.all(
            color: hasUnread ? AppTheme.tombstoneWhite.withOpacity(0.3) : AppTheme.ashGray,
            width: hasUnread ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Аватар
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.ashGray,
              backgroundImage: chat.otherUserAvatar != null
                  ? NetworkImage(chat.otherUserAvatar!)
                  : null,
              child: chat.otherUserAvatar == null
                  ? Text(
                      chat.otherUserName?[0].toUpperCase() ?? 'U',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.tombstoneWhite,
                      ),
                    )
                  : null,
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
                          chat.otherUserName ?? 'Пользователь',
                          style: TextStyle(
                            color: AppTheme.tombstoneWhite,
                            fontSize: 16,
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                            letterSpacing: 1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.lastMessageAt != null)
                        Text(
                          DateFormat('HH:mm').format(chat.lastMessageAt!),
                          style: TextStyle(
                            color: AppTheme.mistGray,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  if (chat.orderTitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Заказ: ${chat.orderTitle}',
                      style: TextStyle(
                        color: AppTheme.ashGray,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (chat.lastMessage != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      chat.lastMessage!,
                      style: TextStyle(
                        color: hasUnread ? AppTheme.tombstoneWhite : AppTheme.mistGray,
                        fontSize: 14,
                        fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w300,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            
            // Бейдж непрочитанных
            if (hasUnread) ...[
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.bloodRed,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
                child: Center(
                  child: Text(
                    chat.unreadCount > 99 ? '99+' : chat.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

