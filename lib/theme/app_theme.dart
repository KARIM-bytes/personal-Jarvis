import 'package:flutter/material.dart';

/// Jarvis wears a dark, arc-reactor-blue palette.
class AppTheme {
  AppTheme._();

  static const Color accent = Color(0xFF2EC5FF);
  static const Color accentDim = Color(0xFF1B7FA8);
  static const Color surface = Color(0xFF0A0A0C);
  static const Color surfaceRaised = Color(0xFF161618);
  static const Color background = Color(0xFF000000);
  static const Color danger = Color(0xFFFF453A);

  // Apple-Fitness-style ring palette (used for the usage rings).
  static const Color ringMove = Color(0xFFFF375F);
  static const Color ringExercise = Color(0xFFA5FF00);
  static const Color ringStand = Color(0xFF2EC5FF);
  static const Color ringOver = Color(0xFFFF453A);

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    ).copyWith(
      surface: surface,
      primary: accent,
      secondary: accent,
      error: danger,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      cardTheme: const CardThemeData(
        color: surfaceRaised,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }
}
