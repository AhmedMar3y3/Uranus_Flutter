import 'package:flutter/material.dart';

class AppTheme {
  static const space = Color(0xFF050816);
  static const deepNavy = Color(0xFF08142F);
  static const surface = Color(0xFF111B36);
  static const surfaceSoft = Color(0xFF192445);
  static const cyan = Color(0xFF5DE7FF);
  static const blue = Color(0xFF3D8BFF);
  static const violet = Color(0xFF9A8CFF);
  static const teal = Color(0xFF6CE5C7);
  static const danger = Color(0xFFFF637D);
  static const textMuted = Color(0xFFAAB7D8);

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: cyan,
      brightness: Brightness.dark,
      primary: cyan,
      secondary: violet,
      surface: surface,
      error: danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: space,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: deepNavy.withValues(alpha: .92),
        indicatorColor: cyan.withValues(alpha: .16),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? cyan : textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? cyan : textMuted,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: deepNavy,
        selectedItemColor: cyan,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceSoft.withValues(alpha: .9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: cyan, width: 1.4),
        ),
        hintStyle: const TextStyle(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cyan,
          foregroundColor: space,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cyan,
          side: BorderSide(color: cyan.withValues(alpha: .44)),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
