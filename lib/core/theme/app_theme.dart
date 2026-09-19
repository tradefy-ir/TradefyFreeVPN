import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFF07111F);
  static const Color surface = Color(0xFF0E1C31);
  static const Color card = Color(0xFF13243D);
  static const Color accent = Color(0xFF2EE6A8);
  static const Color accentDim = Color(0xFF1A8F6E);
  static const Color warning = Color(0xFFFFC14D);
  static const Color danger = Color(0xFFFF6B6B);
  static const Color textPrimary = Color(0xFFF4F7FB);
  static const Color textSecondary = Color(0xFF9AA8BD);

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: surface,
        error: danger,
      ),
    );

    final textTheme = GoogleFonts.vazirmatnTextTheme(base.textTheme).apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: card,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
