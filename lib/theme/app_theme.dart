import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bgPage = Color(0xFF121212);
  static const bgCard = Color(0xFF1C1C1E);

  static const primary = Color(0xFF10B981);
  static const accent = Color(0xFF34D399);
  static const accentWarm = Color(0xFFFFD54F);

  static const textPrimary = Color(0xFFF9F9F9);
  static const textSecondary = Color(0xFFA1A1AA);
  static const textHint = Color(0xFF52525B);

  static const border = Color(0xFF2C2C2E);
  static const positive = Color(0xFF10B981);
  static const negative = Color(0xFFEF4444);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bgPage,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.bgCard,
      ),
      textTheme: _textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgPage,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
    );
  }

  static TextTheme get _textTheme {
    return TextTheme(
      displayLarge: GoogleFonts.notoSansKr(
        fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -1.0,
      ),
      displayMedium: GoogleFonts.notoSansKr(
        fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.5,
      ),
      titleLarge: GoogleFonts.notoSansKr(
        fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.notoSansKr(
        fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.notoSansKr(
        fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary,
      ),
    );
  }
}