import 'package:flutter/services.dart';

class NotificationService {
  // Воспроизвести системный звук уведомления
  static Future<void> playNotificationSound() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      // Игнорируем ошибки воспроизведения звука
    }
  }

  // Вибрация (для мобильных устройств)
  static Future<void> vibrate() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      // Игнорируем ошибки вибрации
    }
  }

  // Комбо: звук + вибрация
  static Future<void> notifyNewMessage() async {
    await playNotificationSound();
    await vibrate();
  }
}

