import 'package:flutter/material.dart';

class AppTheme {
  static const Color deepBlack = Color(0xFF101317);
  static const Color voidBlack = Color(0xFF171B20);
  static const Color shadowGray = Color(0xFF20262D);
  static const Color charcoal = voidBlack;
  static const Color darkerCharcoal = deepBlack;

  static const Color tombstoneWhite = Color(0xFFF3F5F7);
  static const Color ashGray = Color(0xFFC4CAD1);
  static const Color mistGray = Color(0xFF8E98A3);
  static const Color dimGray = Color(0xFF343C45);

  static const Color subtleAccent = Color(0xFF58C2AA);
  static const Color ghostWhite = Color(0xFFF8FAFB);
  static const Color bloodRed = Color(0xFFE26767);
  static const Color electricBlue = Color(0xFF70A7F8);
  static const Color goldenrod = Color(0xFFE6B566);

  static const Color midnightBlack = deepBlack;
  static const Color charcoalGray = shadowGray;

  // Compatibility aliases used by the existing screens.
  static const Color cyberBlue = electricBlue;
  static const Color bgPrimary = deepBlack;
  static const Color bgSecondary = voidBlack;
  static const Color textPrimary = tombstoneWhite;
  static const Color textSecondary = ashGray;
  static const Color textMuted = mistGray;
  static const Color borderDark = dimGray;
  static const Color accentGold = goldenrod;
  static const Color offWhite = tombstoneWhite;
  static const Color darkBlack = deepBlack;
  static const Color richBlack = voidBlack;
  static const Color darkGray = shadowGray;
  static const Color silverGray = ashGray;
  static const Color crimsonRed = bloodRed;
  static const Color deepPurple = Color(0xFF8B7CC8);
  static const Color gothicGreen = subtleAccent;
  static const Color gothicOrange = goldenrod;
  static const Color gothicBlue = electricBlue;

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: deepBlack,
    colorScheme: const ColorScheme.dark(
      primary: subtleAccent,
      onPrimary: deepBlack,
      secondary: electricBlue,
      onSecondary: deepBlack,
      surface: voidBlack,
      onSurface: tombstoneWhite,
      error: bloodRed,
      onError: ghostWhite,
      outline: dimGray,
    ),
    dividerColor: dimGray,
    splashColor: subtleAccent.withOpacity(0.08),
    highlightColor: subtleAccent.withOpacity(0.05),
    appBarTheme: const AppBarTheme(
      backgroundColor: voidBlack,
      foregroundColor: tombstoneWhite,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      toolbarHeight: 64,
      titleSpacing: 24,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: tombstoneWhite,
      ),
      iconTheme: IconThemeData(color: ashGray, size: 21),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: ghostWhite,
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: tombstoneWhite,
        height: 1.25,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: tombstoneWhite,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: tombstoneWhite,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: tombstoneWhite,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: ashGray,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: ashGray,
        height: 1.45,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: mistGray,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: shadowGray,
      hintStyle: const TextStyle(color: mistGray, fontSize: 14),
      labelStyle: const TextStyle(color: mistGray, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: dimGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: dimGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: subtleAccent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: bloodRed),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: subtleAccent,
        foregroundColor: deepBlack,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ashGray,
        side: const BorderSide(color: dimGray),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: shadowGray,
      contentTextStyle: const TextStyle(color: tombstoneWhite),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: voidBlack,
      indicatorColor: subtleAccent.withOpacity(0.16),
      height: 68,
      labelTextStyle: const MaterialStatePropertyAll(
        TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: subtleAccent,
      linearTrackColor: dimGray,
    ),
  );

  static Widget fadeInAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Duration delay = Duration.zero,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + delay,
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(opacity: value, child: child),
      child: child,
    );
  }

  static Widget slideUpAnimation({
    required Widget child,
    Duration duration = const Duration(milliseconds: 280),
    double offset = 12,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: offset, end: 0),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, value),
        child: Opacity(
          opacity: offset == 0 ? 1 : (1 - value / offset).clamp(0, 1),
          child: child,
        ),
      ),
      child: child,
    );
  }

  static Widget animatedGothicCard({
    required Widget child,
    Color? borderColor,
    Duration delay = Duration.zero,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260) + delay,
      curve: Curves.easeOut,
      builder: (context, value, _) => Opacity(
        opacity: value,
        child: Container(
          decoration: BoxDecoration(
            color: voidBlack,
            border: Border.all(color: borderColor ?? dimGray),
            borderRadius: BorderRadius.circular(6),
          ),
          child: child,
        ),
      ),
    );
  }

  static Widget gothicTitle(String text, {Color? color}) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: color ?? ghostWhite,
        height: 1.25,
      ),
    );
  }

  static Widget gothicCard({
    required String title,
    required Widget child,
    Color? borderColor,
    EdgeInsets padding = const EdgeInsets.all(20),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: voidBlack,
        border: Border.all(color: borderColor ?? dimGray),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ashGray,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  static Widget gothicButton({
    required String text,
    required VoidCallback onPressed,
    bool isPrimary = true,
    Color? accentColor,
  }) {
    final color = accentColor ?? subtleAccent;
    return isPrimary
        ? ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: deepBlack,
            ),
            child: Text(text),
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(foregroundColor: color),
            child: Text(text),
          );
  }

  static Widget gothicBadge(String text, {Color? color}) {
    final badgeColor = color ?? subtleAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        border: Border.all(color: badgeColor.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }

  static Widget gothicDivider({Color? color}) {
    return Divider(height: 1, thickness: 1, color: color ?? dimGray);
  }

  static Widget gothicTextField({
    required TextEditingController controller,
    String? labelText,
    String? hintText,
    IconData? icon,
    Widget? prefixIcon,
    Widget? suffixIcon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      style: const TextStyle(color: tombstoneWhite, fontSize: 14),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: icon != null ? Icon(icon) : prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }

  static Widget gothicDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? labelText,
    IconData? icon,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      dropdownColor: shadowGray,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: icon != null ? Icon(icon) : null,
      ),
    );
  }
}
