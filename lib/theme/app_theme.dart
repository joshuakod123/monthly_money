import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ═══════════════════════════════════════════════════════════
///  "Slow Wealth" 디자인 시스템 v5
///  - GICS 11개 섹터 팔레트
///  - 카피는 AppCopy 한 곳에 집중 (편집 쉬움)
/// ═══════════════════════════════════════════════════════════

class AppColors {
  static const canvas = Color(0xFFF5E9CD);
  static const surface = Color(0xFFEFDFBB);
  static const surfaceDeep = Color(0xFFE5D2A8);
  static const surfaceWarm = Color(0xFFFAF2DC);

  static const wine = Color(0xFF722F37);
  static const wineDeep = Color(0xFF4A1E24);
  static const wineMid = Color(0xFF8B3F47);
  static const wineLight = Color(0xFFA85962);
  static const wineSoft = Color(0xFFD4A5AA);

  static const textPrimary = Color(0xFF2D1518);
  static const textSecondary = Color(0xFF5C4248);
  static const textTertiary = Color(0xFF847A75);
  static const textDisabled = Color(0xFFB8A89A);

  static const gold = Color(0xFFB8860B);
  static const goldSoft = Color(0xFFE8C77B);

  static const borderSoft = Color(0xFFE0CDA8);
  static const border = Color(0xFFD4BC8E);
  static const borderStrong = Color(0xFFAA8D5C);

  static const positive = Color(0xFF6B7A3F);
  static const negative = Color(0xFF8B3F47);
  static const warning = Color(0xFFB8860B);

  // ═══════════════════════════════════════════════════════════
  //  GICS 11개 섹터 팔레트
  // ═══════════════════════════════════════════════════════════
  static const Map<String, SectorPalette> sectorPalettes = {
    'energy': SectorPalette(
      bg: Color(0xFF1F2E47),
      onBg: Color(0xFFF5E9CD),
      accent: Color(0xFF6B7A98),
      label: 'ENERGY',
      koLabel: '에너지',
    ),
    'materials': SectorPalette(
      bg: Color(0xFF7A5C3D),
      onBg: Color(0xFFF5E9CD),
      accent: Color(0xFFB89878),
      label: 'MATERIALS',
      koLabel: '소재',
    ),
    'industrial': SectorPalette(
      bg: Color(0xFF555A5C),
      onBg: Color(0xFFF5E9CD),
      accent: Color(0xFFB0B5B7),
      label: 'INDUSTRIALS',
      koLabel: '산업재',
    ),
    'consumerDisc': SectorPalette(
      bg: Color(0xFFB8542F),
      onBg: Color(0xFFF5E9CD),
      accent: Color(0xFFE8B89A),
      label: 'CONSUMER DISC.',
      koLabel: '경기소비재',
    ),
    'consumerStpl': SectorPalette(
      bg: Color(0xFFC9A227),
      onBg: Color(0xFF2D1518),
      accent: Color(0xFFFFE08A),
      label: 'STAPLES',
      koLabel: '필수소비재',
    ),
    'healthcare': SectorPalette(
      bg: Color(0xFFE8B5BE),
      onBg: Color(0xFF2D1518),
      accent: Color(0xFFFFE0E5),
      label: 'HEALTH CARE',
      koLabel: '헬스케어',
    ),
    'finance': SectorPalette(
      bg: Color(0xFF722F37),
      onBg: Color(0xFFF5E9CD),
      accent: Color(0xFFD4A5AA),
      label: 'FINANCIALS',
      koLabel: '금융',
    ),
    'tech': SectorPalette(
      bg: Color(0xFF3D5A7A),
      onBg: Color(0xFFF5E9CD),
      accent: Color(0xFF8FA5BD),
      label: 'INFO TECH',
      koLabel: 'IT',
    ),
    'telecom': SectorPalette(
      bg: Color(0xFF6B5B95),
      onBg: Color(0xFFF5E9CD),
      accent: Color(0xFFB5A8D4),
      label: 'COMM. SVC.',
      koLabel: '커뮤니케이션',
    ),
    'utilities': SectorPalette(
      bg: Color(0xFF6B7A5F),
      onBg: Color(0xFFF5E9CD),
      accent: Color(0xFFA8B89A),
      label: 'UTILITIES',
      koLabel: '유틸리티',
    ),
    'reit': SectorPalette(
      bg: Color(0xFFA85962),
      onBg: Color(0xFFF5E9CD),
      accent: Color(0xFFE8A8AE),
      label: 'REAL ESTATE',
      koLabel: '리츠·부동산',
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

/// ═══════════════════════════════════════════════════════════
///  📝 AppCopy — 모든 텍스트 카피를 한 곳에 모음
///
///  ⭐ 멘트가 마음에 안 들면 여기서 한 줄만 바꾸면 앱 전체에 반영됨
///  ─ 화면별 그룹핑 / 한국어 위주 / 번역어투 제거
/// ═══════════════════════════════════════════════════════════
class AppCopy {
  // ─────────── 브랜드
  static const brandKo       = '배당나무';
  static const brandEn       = 'Baedang Namu';
  static const brandSymbol   = '※';

  // ─────────── 온보딩 / 시작화면
  static const onboardingEst       = 'EST. 2026';
  static const onboardingHeadline  = '8가지 질문으로\n나에게 맞는\n배당 포트폴리오';
  static const onboardingSub       = '소요 시간 약 2분';
  static const onboardingCta       = '시작하기';

  // ─────────── 홈
  static const homeBrandLabel       = 'BAEDANG NAMU';
  static const homeMonthlyLabel     = 'MONTHLY DIVIDEND';
  static const homeAfterTaxPrefix   = '세후 ';
  static const homeTargetPrefix     = '목표 ';
  static const homeQuickGoalTitle   = '목표 분석';
  static const homeQuickGoalSuffix  = '% 달성';
  static const homePortfolioLabel   = 'PORTFOLIO';
  static const homePortfolioTitle   = '추천 종목';
  static const homePortfolioSort    = '비중순';
  static const homeYourSpiritLabel  = 'YOUR SPIRIT';

  // ─────────── 캘린더
  static const calLabel       = 'CALENDAR';
  static const calTitle       = '배당 캘린더';
  static const calSub         = '매달 들어올 배당금';
  static const calAnnual      = 'ANNUAL';
  static const calCoverage    = 'COVERAGE';
  static const calCashflow    = 'CASH FLOW';
  static const calTapHint     = '월별 탭 →';
  static const calMonthFull   = '매달 들어옴';
  static const calMonthEmpty  = '개월 비어있음';
  static const calNoDividend  = '이 달엔 배당이 없어요';
  static const calNoDivHint   = '월배당 ETF를 추가하면 채울 수 있어요';
  static const calYearReport  = 'YEARLY REPORT';

  // ─────────── 탐색 (섹터 도감)
  static const exploreLabel    = 'EXPLORE';
  static const exploreTitle    = '섹터 도감';
  static const exploreSub      = '11개 섹터로 분류';

  // ─────────── 프로필
  static const profileLabel    = 'YOUR PROFILE';
  static const profileTraits   = 'INVESTMENT TRAITS';
  static const profileGoals    = 'GOALS';
  static const profileActions  = 'ACTIONS';
  static const profileRetake   = '퀴즈 다시 풀기';
  static const profileRetakeSub= '투자 성향 다시 진단';
  static const profileReceipt  = '내 영수증 다시 보기';
  static const profileAppInfo  = '배당나무 정보';

  // ─────────── 퀴즈
  static const quizLabel      = 'QUESTION';
  static const quizGoalLabel  = 'FINAL STEP';
  static const quizGoalTitle  = '목표와 예산을\n알려주세요';
  static const quizGoalSub    = '직접 입력하세요. 단위는 원';
  static const quizMonthlyLbl = '월 배당 목표';
  static const quizBudgetLbl  = '투자 예산';
  static const quizSectorLbl  = '선호 섹터';
  static const quizSectorSub  = '선택사항. 비워두면 자동 분산';
  static const quizCta        = '내 포트폴리오 보기';

  // ─────────── 결과 (영수증)
  static const resultPersona      = 'PERSONA';
  static const resultRecommended  = 'RECOMMENDED PORTFOLIO';
  static const resultSummary      = 'SUMMARY';
  static const resultMonthly      = 'MONTHLY';
  static const resultGoalSuffix   = '% 목표 달성';
  static const resultReceiptHint  = '영수증은 언제든 다시 확인할 수 있어요';
  static const resultCtaToReceipt = '내 영수증 보기';
  static const resultCtaToHome    = '포트폴리오로 이동';

  // ─────────── 목표 갭 분석
  static const gapLabel          = 'GOAL ANALYSIS';
  static const gapTitle          = '목표 분석';
  static const gapSub            = '내 목표까지 가는 길';
  static const gapAchievement    = 'ACHIEVEMENT';
  static const gapOptionsLabel   = 'YOUR OPTIONS';
  static const gapOptionsSub     = '세 가지 길 중 하나를 선택해보세요';
  static const gapBuildLabel     = 'BUILD PLANS';
  static const gapBuildHint      = '월 적립 시 목표 도달까지';
  static const gapBuildFootnote  = '단순 적립 기준 (이자 미반영)';
  static const gapAchievable     = '목표 달성 가능';
  static const gapAchievableSub  = '현재 예산과 추천 종목으로 목표를 거의 채울 수 있어요';
  static const gapHomeBannerSub  = '세 가지 해결 방법을 제안해드릴게요';

  // ─────────── 세금
  static const taxLabel             = 'TAX BREAKDOWN';
  static const taxTitle             = '세후 실수령';
  static const taxSub               = '한국 세제 기준 추정';
  static const taxNetMonthly        = 'NET MONTHLY';
  static const taxBreakdown         = 'BREAKDOWN';
  static const taxReceiptLabel      = 'TAX RECEIPT';
  static const taxAnnualGross       = '연 배당 (세전)';
  static const taxWithholding       = '원천징수 (15.4%)';
  static const taxComprehensive     = '종합과세 추가분';
  static const taxNetAnnual         = '실수령 (연)';
  static const taxCompTitle         = '종합과세 대상';
  static const taxSeparateTitle     = '분리과세 신청 가능';
  static const taxSeparateSub       = '2026년부터 고배당 상장사 배당은 종합과세 대신 14~30%로 분리과세 선택 가능';
  static const taxTipsLabel         = 'TAX SAVING';
  static const taxDisclaimer        = '세무사 상담을 권장해요. 부양가족·의료비·기부금 등 개인 상황에 따라 실제 세액은 달라져요';

  // ─────────── 동물 페르소나
  static const personaSpiritLabel   = 'YOUR INVESTMENT SPIRIT';
  static const personaDiscoverLabel = 'Discover';

  // ─────────── 종목 상세
  static const stockLabel        = 'STOCK';
  static const stockPrice        = 'PRICE';
  static const stockYield        = 'YIELD';
  static const stockHistory      = 'DIVIDEND HISTORY';
  static const stockHistoryReal  = '실제';
  static const stockHistoryEst   = '예측';
  static const stockYearly       = 'YEARLY RECORD';

  // ─────────── 푸터
  static const footerSlow      = '· 천천히 익어가는 자산 ·';

  // ─────────── 단위 / 포맷 (편집 안 권장)
  static const unitWon         = '원';
  static const unitMan         = '만';
  static const unitOk          = '억';
  static const unitMonth       = '월';
  static const unitYear        = '년';
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
