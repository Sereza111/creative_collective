// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // ===== КЛАССИЧЕСКАЯ ГОТИЧЕСКАЯ ПАЛИТРА =====
  // Как камень на старом кладбище - элегантно и минималистично
  
  static const Color deepBlack = Color(0xFF0D0D0D);        // Глубокий чёрный
  static const Color voidBlack = Color(0xFF1A1A1A);        // Чёрная бездна
  static const Color shadowGray = Color(0xFF2A2A2A);       // Тень
  static const Color charcoal = Color(0xFF1A1A1A);         // Угольный (алиас для voidBlack)
  static const Color darkerCharcoal = Color(0xFF0D0D0D);   // Темнее угольного (алиас для deepBlack)
  
  static const Color tombstoneWhite = Color(0xFFD4D4D4);   // Белый как камень
  static const Color ashGray = Color(0xFFA8A8A8);          // Пепельно-серый
  static const Color mistGray = Color(0xFF7A7A7A);         // Туманно-серый
  static const Color dimGray = Color(0xFF4A4A4A);          // Тусклый серый
  
  // Очень приглушенные акценты (едва заметные)
  static const Color subtleAccent = Color(0xFF8A8A8A);     // Еле заметный акцент
  static const Color ghostWhite = Color(0xFFEEEEEE);       // Призрачно-белый
  static const Color bloodRed = Color(0xFF8B0000);         // Темно-красный для ошибок
  
  // ===== LEGACY COLORS (для совместимости) =====
  static const Color cyberBlue = subtleAccent;
  static const Color bgPrimary = deepBlack;
  static const Color bgSecondary = voidBlack;
  static const Color textPrimary = tombstoneWhite;
  static const Color textSecondary = ashGray;
  static const Color textMuted = mistGray;
  static const Color borderDark = dimGray;
  static const Color accentGold = subtleAccent;
  static const Color offWhite = tombstoneWhite;
  static const Color darkBlack = deepBlack;
  static const Color richBlack = voidBlack;
  static const Color darkGray = shadowGray;
  static const Color silverGray = ashGray;
  static const Color crimsonRed = Color(0xFF666666);
  static const Color deepPurple = Color(0xFF6A6A6A);
  static const Color gothicGreen = Color(0xFF707070);
  static const Color gothicOrange = Color(0xFF757575);
  static const Color gothicBlue = Color(0xFF656565);

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: tombstoneWhite,
    scaffoldBackgroundColor: deepBlack,
    appBarTheme: const AppBarTheme(
      backgroundColor: voidBlack,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w300,
        color: tombstoneWhite,
        letterSpacing: 4.0,
        fontFamily: 'serif',
      ),
      iconTheme: IconThemeData(color: ashGray),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w200,
        color: ghostWhite,
        letterSpacing: 3.0,
        fontFamily: 'serif',
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w300,
        color: tombstoneWhite,
        letterSpacing: 2.0,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w300,
        color: ashGray,
        height: 1.6,
        letterSpacing: 0.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w300,
        color: mistGray,
        letterSpacing: 0.3,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: voidBlack,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: const BorderSide(color: dimGray, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: const BorderSide(color: dimGray, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: const BorderSide(color: ashGray, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: tombstoneWhite,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        elevation: 0,
        side: const BorderSide(color: dimGray, width: 1),
      ),
    ),
  );

  // ===== МИНИМАЛИСТИЧНЫЕ АНИМАЦИИ =====
  
  /// Деликатная анимация появления
  static Widget fadeInAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 1200),
    Duration delay = Duration.zero,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: child,
    );
  }

  /// Тонкая анимация скольжения
  static Widget slideUpAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 800),
    double offset = 20.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: offset, end: 0.0),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: Opacity(
            opacity: 1.0 - (value / offset) * 0.5,
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  /// Элегантная готическая карточка
  static Widget animatedGothicCard({
    required Widget child,
    Color? borderColor,
    Duration delay = Duration.zero,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      builder: (context, value, _) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: Container(
              decoration: BoxDecoration(
                color: voidBlack,
                border: Border.all(
                  color: (borderColor ?? dimGray).withOpacity(0.3 + value * 0.2),
                  width: 1,
                ),
                borderRadius: BorderRadius.zero,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }

  // ===== ЭЛЕГАНТНЫЕ UI ЭЛЕМЕНТЫ =====
  
  /// Элегантный заголовок
  static Widget gothicTitle(String text, {Color? color}) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w200,
        color: color ?? ghostWhite,
        letterSpacing: 6.0,
        fontFamily: 'serif',
        height: 1.4,
      ),
    );
  }

  /// Минималистичная карточка
  static Widget gothicCard({
    required String title,
    required Widget child,
    Color? borderColor,
    EdgeInsets padding = const EdgeInsets.all(24),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: voidBlack,
        border: Border.all(
          color: borderColor ?? dimGray,
          width: 1,
        ),
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w300,
              color: ashGray,
              letterSpacing: 3.0,
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  /// Минималистичная кнопка
  static Widget gothicButton({
    required String text,
    required VoidCallback onPressed,
    bool isPrimary = true,
    Color? accentColor,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: isPrimary ? shadowGray.withOpacity(0.3) : Colors.transparent,
          border: Border.all(
            color: accentColor ?? dimGray,
            width: 1,
          ),
          borderRadius: BorderRadius.zero,
        ),
        child: Center(
          child: Text(
            text.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w300,
              letterSpacing: 3.0,
              fontSize: 12,
              color: accentColor ?? tombstoneWhite,
              fontFamily: 'serif',
            ),
          ),
        ),
      ),
    );
  }

  /// Тонкий статус бейдж
  static Widget gothicBadge(String text, {Color? color}) {
    final badgeColor = color ?? subtleAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: badgeColor.withOpacity(0.5),
          width: 1,
        ),
        borderRadius: BorderRadius.zero,
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w400,
          color: badgeColor,
          letterSpacing: 2.0,
          fontFamily: 'serif',
        ),
      ),
    );
  }

  /// Элегантный разделитель
  static Widget gothicDivider({Color? color}) {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            (color ?? dimGray).withOpacity(0.3),
            (color ?? dimGray).withOpacity(0.5),
            (color ?? dimGray).withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
