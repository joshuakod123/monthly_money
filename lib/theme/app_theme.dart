import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // 메인 팔레트 (딥 포레스트 그린 + 민트 액센트)
  static const primary = Color(0xFF1A3A2A);
  static const primaryLight = Color(0xFF2A5A40);
  static const accent = Color(0xFF3DD68C);
  static const accentWarm = Color(0xFFF5A623);

  // 배경
  static const bgPage = Color(0xFFF8FAF9);
  static const bgCard = Color(0xFFFFFFFF);
  static const bgDark = Color(0xFF0F2019);

  // 텍스트
  static const textPrimary = Color(0xFF1C2B22);
  static const textSecondary = Color(0xFF6B8070);
  static const textHint = Color(0xFFADC0B4);

  // 보조
  static const border = Color(0xFFE0EBE4);
  static const positive = Color(0xFF1A6B40);
  static const positiveBg = Color(0xFFEAF7F0);
  static const negative = Color(0xFFE85D4A);
  static const negativeBg = Color(0xFFFFF0EE);

  // 섹터별 색상
  static const sectorFinance = Color(0xFFEAF0FF);
  static const sectorTelecom = Color(0xFFFFF0E6);
  static const sectorEnergy = Color(0xFFFFF8E0);
  static const sectorREIT = Color(0xFFE8F8EF);
  static const sectorConsumer = Color(0xFFFFF0F5);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bgPage,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.bgCard,
        background: AppColors.bgPage,
      ),
      textTheme: _textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
    );
  }

  static TextTheme get _textTheme {
    return TextTheme(
      displayLarge: GoogleFonts.notoSansKr(
        fontSize: 32, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, letterSpacing: -1.0,
      ),
      displayMedium: GoogleFonts.notoSansKr(
        fontSize: 26, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary, letterSpacing: -0.5,
      ),
      titleLarge: GoogleFonts.notoSansKr(
        fontSize: 18, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.notoSansKr(
        fontSize: 15, fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleSmall: GoogleFonts.notoSansKr(
        fontSize: 13, fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.notoSansKr(
        fontSize: 15, fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.notoSansKr(
        fontSize: 13, fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      bodySmall: GoogleFonts.notoSansKr(
        fontSize: 11, fontWeight: FontWeight.w400,
        color: AppColors.textHint,
      ),
    );
  }
}
