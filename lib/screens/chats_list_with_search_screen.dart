import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/chat.dart';
import '../providers/chat_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/workspace_components.dart';
import 'chat_screen.dart';

class ChatsListWithSearchScreen extends ConsumerStatefulWidget {
  const ChatsListWithSearchScreen({super.key});

  @override
  ConsumerState<ChatsListWithSearchScreen> createState() =>
      _ChatsListWithSearchScreenState();
}

class _ChatsListWithSearchScreenState
    extends ConsumerState<ChatsListWithSearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatsProvider);
    final query = _searchQuery.trim().toLowerCase();
    final chats = state.chats.where((chat) {
      if (query.isEmpty) return true;
      return (chat.otherUserName?.toLowerCase().contains(query) ?? false) ||
          (chat.orderTitle?.toLowerCase().contains(query) ?? false) ||
          (chat.lastMessage?.toLowerCase().contains(query) ?? false);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Чаты'),
        actions: [
          IconButton(
            tooltip: 'Обновить чаты',
            onPressed: () => ref.read(chatsProvider.notifier).loadChats(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: WorkspaceContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WorkspacePageIntro(
              eyebrow: 'Переписка по работе',
              title: 'Диалоги в контексте заказа',
              description:
                  'Обсуждения привязаны к работе, поэтому договоренности не теряются.',
              actions: [
                if (state.unreadCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppTheme.subtleAccent.withOpacity(0.12),
                      border: Border.all(color: AppTheme.subtleAccent),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      'Непрочитанных: ${state.unreadCount}',
                      style: const TextStyle(
                        color: AppTheme.tombstoneWhite,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            WorkspaceSearchField(
              controller: _searchController,
              hintText: 'Найти человека, заказ или сообщение',
              onChanged: (value) => setState(() => _searchQuery = value),
              onClear: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
            const SizedBox(height: 18),
            Expanded(child: _buildContent(state, chats)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ChatsState state, List<Chat> chats) {
    if (state.isLoading && state.chats.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.chats.isEmpty) {
      return WorkspaceErrorState(
        message: state.error!,
        onRetry: () => ref.read(chatsProvider.notifier).loadChats(),
      );
    }
    if (chats.isEmpty) {
      final isSearching = _searchQuery.trim().isNotEmpty;
      return WorkspaceEmptyState(
        icon: isSearching ? Icons.search_off : Icons.forum_outlined,
        title: isSearching ? 'Диалог не найден' : 'Активных чатов пока нет',
        message: isSearching
            ? 'Попробуйте другой запрос.'
            : 'Чат появится после начала работы над заказом.',
      );
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(chatsProvider.notifier).loadChats(),
      color: AppTheme.goldenrod,
      backgroundColor: AppTheme.shadowGray,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: chats.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) => _ChatCard(
          chat: chats[index],
          onOpen: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatScreen(chat: chats[index])),
            );
            if (mounted) {
              await ref.read(chatsProvider.notifier).loadChats();
            }
          },
        ),
      ),
    );
  }
}

class _ChatCard extends StatelessWidget {
  const _ChatCard({required this.chat, required this.onOpen});

  final Chat chat;
  final VoidCallback onOpen;

  String _formatTime(DateTime value) {
    final now = DateTime.now();
    final sameDay = value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;
    return DateFormat(sameDay ? 'HH:mm' : 'dd.MM').format(value);
  }

  @override
  Widget build(BuildContext context) {
    final unread = chat.unreadCount > 0;
    final name = chat.otherUserName?.trim().isNotEmpty == true
        ? chat.otherUserName!
        : 'Пользователь';
    final initial = name.characters.first.toUpperCase();

    return WorkspacePanel(
      accent: unread ? AppTheme.subtleAccent : AppTheme.dimGray,
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 17),
      onTap: onOpen,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 54,
            decoration: BoxDecoration(
              color: AppTheme.deepBlack,
              border: Border.all(
                color: unread ? AppTheme.goldenrod : AppTheme.dimGray,
              ),
              borderRadius: BorderRadius.circular(2),
              image: chat.otherUserAvatar == null
                  ? null
                  : DecorationImage(
                      image: NetworkImage(chat.otherUserAvatar!),
                      fit: BoxFit.cover,
                    ),
            ),
            alignment: Alignment.center,
            child: chat.otherUserAvatar == null
                ? Text(
                    initial,
                    style: const TextStyle(
                      color: AppTheme.tombstoneWhite,
                      fontFamily: 'Georgia',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.tombstoneWhite,
                          fontFamily: 'Georgia',
                          fontSize: 16,
                          fontWeight:
                              unread ? FontWeight.w700 : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (chat.lastMessageAt != null)
                      Text(
                        _formatTime(chat.lastMessageAt!),
                        style: const TextStyle(
                          color: AppTheme.mistGray,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
                if (chat.orderTitle?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    chat.orderTitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.goldenrod,
                      fontSize: 10,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  chat.lastMessage?.trim().isNotEmpty == true
                      ? chat.lastMessage!
                      : 'Сообщений пока нет',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: unread ? AppTheme.ashGray : AppTheme.mistGray,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (unread) ...[
            const SizedBox(width: 12),
            Container(
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppTheme.subtleAccent,
                shape: BoxShape.circle,
              ),
              child: Text(
                chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                style: const TextStyle(
                  color: AppTheme.ghostWhite,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right, color: AppTheme.mistGray),
          ],
        ],
      ),
    );
  }
}
