import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ═══════════════════════════════════════════════════════════
///  "Slow Wealth" 디자인 시스템 v4
///  Dutch White (#EFDFBB) + Wine (#722F37)
///  + 섹터별 시그니처 컬러 (박물관 카드 시스템)
///
///  컨셉: 박물관 동물 도감 + 영수증 + 미니멀 핀테크
/// ═══════════════════════════════════════════════════════════

class AppColors {
  // ── Background scale (Dutch White)
  static const canvas = Color(0xFFF5E9CD);
  static const surface = Color(0xFFEFDFBB);
  static const surfaceDeep = Color(0xFFE5D2A8);
  static const surfaceWarm = Color(0xFFFAF2DC);

  // ── Wine scale
  static const wine = Color(0xFF722F37);
  static const wineDeep = Color(0xFF4A1E24);
  static const wineMid = Color(0xFF8B3F47);
  static const wineLight = Color(0xFFA85962);
  static const wineSoft = Color(0xFFD4A5AA);

  // ── Text
  static const textPrimary = Color(0xFF2D1518);
  static const textSecondary = Color(0xFF5C4248);
  static const textTertiary = Color(0xFF847A75);
  static const textDisabled = Color(0xFFB8A89A);

  // ── Accent
  static const gold = Color(0xFFB8860B);
  static const goldSoft = Color(0xFFE8C77B);

  // ── Border
  static const borderSoft = Color(0xFFE0CDA8);
  static const border = Color(0xFFD4BC8E);
  static const borderStrong = Color(0xFFAA8D5C);

  // ── Semantic
  static const positive = Color(0xFF6B7A3F);
  static const negative = Color(0xFF8B3F47);
  static const warning = Color(0xFFB8860B);

  // ═══════════════════════════════════════════════════════════
  //  섹터별 시그니처 컬러 (박물관 도감 컨셉)
  //  각 섹터 = 강한 시각 인장 (Image 2, 4 영감)
  // ═══════════════════════════════════════════════════════════
  static const Map<String, SectorPalette> sectorPalettes = {
    'finance': SectorPalette(
      bg: Color(0xFF722F37),       // Wine
      onBg: Color(0xFFF5E9CD),
      accent: Color(0xFFD4A5AA),
      label: 'FINANCE',
      koLabel: '금융',
    ),
    'telecom': SectorPalette(
      bg: Color(0xFF6B7A5F),       // Sage Green (Olive)
      onBg: Color(0xFFF5E9CD),
      accent: Color(0xFFA8B89A),
      label: 'TELECOM',
      koLabel: '통신',
    ),
    'reit': SectorPalette(
      bg: Color(0xFFB8542F),       // Terracotta
      onBg: Color(0xFFF5E9CD),
      accent: Color(0xFFE8B89A),
      label: 'REAL ESTATE',
      koLabel: '리츠',
    ),
    'consumer': SectorPalette(
      bg: Color(0xFFC9A227),       // Mustard
      onBg: Color(0xFF2D1518),
      accent: Color(0xFFFFE08A),
      label: 'CONSUMER',
      koLabel: '소비재',
    ),
    'energy': SectorPalette(
      bg: Color(0xFF1F2E47),       // Deep Navy
      onBg: Color(0xFFF5E9CD),
      accent: Color(0xFF6B7A98),
      label: 'ENERGY',
      koLabel: '에너지',
    ),
    'industrial': SectorPalette(
      bg: Color(0xFF555A5C),       // Steel Gray
      onBg: Color(0xFFF5E9CD),
      accent: Color(0xFFB0B5B7),
      label: 'INDUSTRIAL',
      koLabel: '산업재',
    ),
    'healthcare': SectorPalette(
      bg: Color(0xFFE8B5BE),       // Cream Pink
      onBg: Color(0xFF2D1518),
      accent: Color(0xFFFFE0E5),
      label: 'HEALTHCARE',
      koLabel: '헬스케어',
    ),
  };

  static SectorPalette paletteFor(String sectorId) {
    return sectorPalettes[sectorId] ??
        const SectorPalette(
          bg: wine,
          onBg: surface,
          accent: wineLight,
          label: 'OTHER',
          koLabel: '기타',
        );
  }

  // ── Legacy aliases
  static const bg = canvas;
  static const bgPage = canvas;
  static const bgElevated = surface;
  static const bgCard = surface;
  static const bgHover = surfaceDeep;
  static const bgInput = surfaceWarm;
  static const primary = wine;
  static const accent = wine;
  static const accentBright = wineMid;
  static const accentDim = wineDeep;
  static const accentGhost = Color(0x14722F37);
  static const accentWarm = gold;
  static const textOnDark = surface;
  static const textOnDarkSecondary = surfaceWarm;
  static const textOnDarkTertiary = textTertiary;
  static const textOnLight = textPrimary;
  static const textOnLightSecondary = textSecondary;
  static const textOnLightTertiary = textTertiary;
  static const textHint = textTertiary;
  static const sheetBg = surface;
  static const sheetCard = surfaceWarm;
  static const sheetHover = surfaceDeep;
  static const coral = wine;
  static const coralBright = wineMid;
  static const coralDeep = wineDeep;
  static const coralGhost = accentGhost;
  static const emerald = positive;
  static const emeraldBright = Color(0xFF8A9A4F);
  static const emeraldGhost = Color(0x146B7A3F);
}

class SectorPalette {
  final Color bg;
  final Color onBg;
  final Color accent;
  final String label;
  final String koLabel;

  const SectorPalette({
    required this.bg,
    required this.onBg,
    required this.accent,
    required this.label,
    required this.koLabel,
  });
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.canvas,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.wine,
        secondary: AppColors.gold,
        surface: AppColors.surface,
        onPrimary: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: _textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }

  static TextTheme get _textTheme {
    return TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 64,
        fontWeight: FontWeight.w700,
        color: AppColors.wineDeep,
        letterSpacing: -3.0,
        height: 0.95,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: AppColors.wineDeep,
        letterSpacing: -2.0,
        height: 1.0,
      ),
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.8,
        height: 1.2,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.4,
        height: 1.25,
      ),
      titleLarge: GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.55,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.wine,
        letterSpacing: 1.5,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.textTertiary,
        letterSpacing: 1.4,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 9,
        fontWeight: FontWeight.w600,
        color: AppColors.textTertiary,
        letterSpacing: 1.2,
      ),
    );
  }
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double xxxl = 40;
  static const double huge = 56;
}

class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double full = 999;
}