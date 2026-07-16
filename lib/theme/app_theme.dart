import 'package:flutter/material.dart';

/// Design system. Dark-first, 8px spacing grid, one radius scale, quiet
/// glass surfaces over near-black, and a disciplined type ramp.
class AppTheme {
  AppTheme._();

  // --- Color tokens ----------------------------------------------------------

  static const Color bg = Color(0xFF050507);
  static const Color surface = Color(0xFF0E0E12);
  static const Color surfaceRaised = Color(0xFF16161C);

  /// Quiet glass: a whisper of white over black, held by a hairline border.
  static const Color glassFill = Color(0x0AFFFFFF); // white 4%
  static const Color glassBorder = Color(0x14FFFFFF); // white 8%

  static const Color accent = Color(0xFF2EC5FF);
  static const Color accentAlt = Color(0xFF7A5CFF);
  static const Color accentDim = Color(0xFF1B7FA8);
  static const Color pink = Color(0xFFFF5CA8);
  static const Color danger = Color(0xFFFF453A);

  static const Color textPrimary = Color(0xFFF5F6F8);
  static const Color textSecondary = Color(0x99FFFFFF); // 60%
  static const Color textTertiary = Color(0x59FFFFFF); // 35%

  // Activity-ring palette.
  static const Color ringMove = Color(0xFFFF375F);
  static const Color ringExercise = Color(0xFFA5FF00);
  static const Color ringStand = Color(0xFF2EC5FF);
  static const Color ringOver = Color(0xFFFF453A);

  /// Signature gradient for the one loud element per screen.
  static const LinearGradient heroGradient = LinearGradient(
    colors: [accent, accentAlt],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- Spacing (8px system) ---------------------------------------------------

  static const double s1 = 8;
  static const double s2 = 16;
  static const double s3 = 24;
  static const double s4 = 32;

  // --- Radius scale ------------------------------------------------------------

  static const double rSm = 12;
  static const double rMd = 20;
  static const double rLg = 28;

  // --- Motion -------------------------------------------------------------------

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 320);
  static const Curve ease = Curves.easeOutCubic;

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
    ).copyWith(
      surface: surface,
      primary: accent,
      secondary: accentAlt,
      error: danger,
      onPrimary: const Color(0xFF03121C),
    );

    const textTheme = TextTheme(
      // Screen titles ("Summary").
      displaySmall: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.0,
          height: 1.1),
      titleLarge: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.4),
      titleMedium: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2),
      bodyMedium: TextStyle(fontSize: 15, height: 1.45),
      bodySmall:
          TextStyle(fontSize: 12.5, height: 1.4, color: textSecondary),
      labelLarge: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.1),
      // Uppercase micro-labels for section headers.
      labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.6,
          color: textTertiary),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      textTheme: textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(rSm + 2),
          ),
          textStyle:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle:
              const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x0DFFFFFF),
        hintStyle: const TextStyle(color: textTertiary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: s2, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rSm + 2),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rSm + 2),
          borderSide: const BorderSide(color: accentDim, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        showDragHandle: true,
        dragHandleColor: Color(0x33FFFFFF),
        dragHandleSize: Size(36, 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(rLg)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceRaised,
        contentTextStyle:
            const TextStyle(color: textPrimary, fontSize: 13.5),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(rSm)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x0FFFFFFF),
        thickness: 1,
        space: 1,
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: accent,
        thumbColor: Colors.white,
        inactiveTrackColor: Color(0x1AFFFFFF),
        trackHeight: 3,
      ),
    );
  }
}
