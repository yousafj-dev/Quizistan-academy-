import 'package:flutter/material.dart';

/// Brand theme for Quizistan Academy — "Board ki Tayyari".
/// Colors sampled from the official logo gradient.
class AppTheme {
  static const Color deepBlue = Color(0xFF1B3FAB);
  static const Color royalPurple = Color(0xFF7B2FF7);
  static const Color vividOrange = Color(0xFFFF7A1A);
  static const Color inkNavy = Color(0xFF101B3C);
  static const Color paperWhite = Color(0xFFF7F8FC);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [deepBlue, royalPurple, vividOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: royalPurple,
      primary: deepBlue,
      secondary: vividOrange,
      surface: paperWhite,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: paperWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: deepBlue,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
