import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'dart:async';

// Провайдер для отслеживания непрочитанных сообщений
class UnreadCounterNotifier extends StateNotifier<int> {
  Timer? _timer;
  int _previousCount = 0;
  
  UnreadCounterNotifier() : super(0) {
    _startPolling();
  }

  // Начать автоматическое обновление каждые 10 секунд
  void _startPolling() {
    _updateCount();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      _updateCount();
    });
  }

  // Обновить счетчик
  Future<void> _updateCount() async {
    try {
      final count = await ApiService.getUnreadMessagesCount();
      
      // Если количество увеличилось - новое сообщение!
      if (count > _previousCount && _previousCount > 0) {
        NotificationService.notifyNewMessage();
      }
      
      _previousCount = count;
      state = count;
    } catch (e) {
      // Игнорируем ошибки в фоновом режиме
    }
  }

  // Принудительное обновление
  Future<void> refresh() async {
    await _updateCount();
  }

  // Сбросить счетчик для конкретного чата
  void markChatAsRead(int chatId) {
    if (state > 0) {
      state = state - 1;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final unreadCounterProvider = StateNotifierProvider<UnreadCounterNotifier, int>((ref) {
  return UnreadCounterNotifier();
});

