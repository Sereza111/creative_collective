import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/unread_counter_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Chat chat;

  const ChatScreen({Key? key, required this.chat}) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    // Обновляем счетчик непрочитанных при открытии чата
    Future.delayed(Duration.zero, () {
      ref.read(unreadCounterProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final messages = await ApiService.getChatMessages(widget.chat.id);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final newMessage = await ApiService.sendMessage(widget.chat.id, text);
      if (mounted) {
        setState(() {
          _messages.add(newMessage);
          _messageController.clear();
          _isSending = false;
        });
        _scrollToBottom();
        
        // Обновляем список чатов
        ref.read(chatsProvider.notifier).updateChatLastMessage(
          widget.chat.id,
          text,
          DateTime.now(),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.bloodRed,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final otherUserName = widget.chat.otherUserName ?? widget.chat.otherUserEmail ?? 'Собеседник';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              otherUserName.toUpperCase(),
              style: const TextStyle(
                fontSize: 14,
                letterSpacing: 1.5,
              ),
            ),
            if (widget.chat.orderTitle != null) ...[
              const SizedBox(height: 2),
              Text(
                'Заказ: ${widget.chat.orderTitle}',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.mistGray,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ],
        ),
      ),
      body: Column(
        children: [
          // Список сообщений
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.tombstoneWhite),
                    ),
                  )
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: AppTheme.mistGray),
                            const SizedBox(height: 20),
                            Text(
                              'Нет сообщений',
                              style: TextStyle(color: AppTheme.tombstoneWhite, fontSize: 18),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Начните переписку',
                              style: TextStyle(color: AppTheme.mistGray),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMyMessage = message.senderId == user?.id;
                          final showDate = index == 0 ||
                              !_isSameDay(_messages[index - 1].createdAt, message.createdAt);

                          return Column(
                            children: [
                              if (showDate) _buildDateDivider(message.createdAt),
                              _buildMessageBubble(message, isMyMessage),
                            ],
                          );
                        },
                      ),
          ),
          // Поле ввода
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.shadowGray,
              border: Border(
                top: BorderSide(color: AppTheme.dimGray.withOpacity(0.3)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: AppTheme.tombstoneWhite, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Сообщение...',
                      hintStyle: TextStyle(color: AppTheme.mistGray, fontSize: 14),
                      filled: true,
                      fillColor: AppTheme.darkerCharcoal,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.dimGray),
                        borderRadius: BorderRadius.zero,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.dimGray),
                        borderRadius: BorderRadius.zero,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.tombstoneWhite),
                        borderRadius: BorderRadius.zero,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _isSending ? AppTheme.dimGray : AppTheme.tombstoneWhite,
                    border: Border.all(color: AppTheme.tombstoneWhite),
                  ),
                  child: IconButton(
                    icon: _isSending
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.charcoal),
                            ),
                          )
                        : Icon(Icons.send, color: AppTheme.charcoal),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    final dateFormat = DateFormat('dd MMMM yyyy', 'ru_RU');
    final now = DateTime.now();
    String dateText;

    if (_isSameDay(date, now)) {
      dateText = 'СЕГОДНЯ';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      dateText = 'ВЧЕРА';
    } else {
      dateText = dateFormat.format(date).toUpperCase();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: AppTheme.dimGray)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateText,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.mistGray,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Expanded(child: Divider(color: AppTheme.dimGray)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMyMessage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMyMessage) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.shadowGray,
              child: Icon(Icons.person, size: 16, color: AppTheme.mistGray),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMyMessage ? AppTheme.tombstoneWhite : AppTheme.shadowGray,
                border: Border.all(
                  color: isMyMessage ? AppTheme.tombstoneWhite : AppTheme.dimGray,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: isMyMessage ? AppTheme.charcoal : AppTheme.tombstoneWhite,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.createdAt),
                    style: TextStyle(
                      fontSize: 9,
                      color: isMyMessage 
                          ? AppTheme.charcoal.withOpacity(0.6) 
                          : AppTheme.mistGray,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMyMessage) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.tombstoneWhite,
              child: Icon(Icons.person, size: 16, color: AppTheme.charcoal),
            ),
          ],
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }
}

