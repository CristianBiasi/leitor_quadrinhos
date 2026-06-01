import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF1A1A2E);
  static const Color secondary = Color(0xFF16213E);
  static const Color accent = Color(0xFFE94560);
  static const Color gold = Color(0xFFFFD700);
  static const Color surface = Color(0xFF0F3460);
  static const Color cardBg = Color(0xFF1E2A45);
  static const Color textLight = Color(0xFFECECEC);
  static const Color textMuted = Color(0xFF9E9E9E);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: gold,
        surface: secondary,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: textLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: secondary,
        foregroundColor: textLight,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textLight,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: secondary,
        selectedItemColor: accent,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        hintStyle: const TextStyle(color: textMuted),
        labelStyle: const TextStyle(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: textLight, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: textLight, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: textLight, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: textLight),
        bodyLarge: TextStyle(color: textLight),
        bodyMedium: TextStyle(color: textMuted),
        labelLarge: TextStyle(color: textLight, fontWeight: FontWeight.w600),
      ),
    );
  }
}
