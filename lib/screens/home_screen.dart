import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../algorithms/persona_animal.dart';
import '../algorithms/recommendation_engine.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/animal_illustration.dart';
import 'goal_gap_screen.dart';
import 'quiz_result_screen.dart';
import 'stock_detail_screen.dart';

/// ═══════════════════════════════════════════════════════════
///  HomeScreen v3 — 미니멀하게 정리
///   1) Greeting
///   2) Animal Banner (페르소나)
///   3) Monthly Hero (세전·세후 한 줄로 압축)
///   4) (조건부) Goal Gap 카드
///   5) 목표분석 단일 Quick Action
///   6) 포트폴리오
///
///  ⭐ 세금 카드 제거 — 프로필에서 진입 (또는 캘린더/목표분석에서)
/// ═══════════════════════════════════════════════════════════
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final persona = ref.watch(personaProfileProvider);
    final rec = ref.watch(portfolioRecommendationProvider);

    if (persona == null || rec == null) {
      return const Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(child: CircularProgressIndicator(color: AppColors.wine)),
      );
    }

    final animal = PersonaAnimal.fromProfile(persona);
    final goalGap = RecommendationEngine.analyzeGoalGap(
      persona: persona,
      rec: rec,
    );

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 100),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: const _Greeting(),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _AnimalBanner(animal: animal),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _MonthlyHero(persona: persona, rec: rec),
            ),

            // ── Goal Gap 카드 (50% 미만일 때만)
            if (goalGap.hasSignificantGap) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _GoalGapCard(analysis: goalGap)
                    .animate()
                    .fadeIn(delay: 350.ms, duration: 380.ms)
                    .slideY(begin: 0.05),
              ),
            ] else ...[
              // 목표 달성 가능한 경우 — 작은 단일 Quick Action
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _GoalQuickAction(
                  analysis: goalGap,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GoalGapScreen()),
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 380.ms),
              ),
            ],

            const SizedBox(height: 28),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _PortfolioSection(rec: rec),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: Text(
                  AppCopy.footerSlow,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Greeting
// ═══════════════════════════════════════════════════════════
class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 24, height: 1.5, color: AppColors.wine),
        const SizedBox(width: 10),
        Text(
          AppCopy.homeBrandLabel,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.wine,
            letterSpacing: 2.5,
          ),
        ),
        const Spacer(),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: const Icon(Icons.notifications_none_rounded,
              size: 16, color: AppColors.wine),
        ),
      ],
    ).animate().fadeIn(duration: 280.ms);
  }
}

// ═══════════════════════════════════════════════════════════
//  Animal Banner (작게)
// ═══════════════════════════════════════════════════════════
class _AnimalBanner extends StatelessWidget {
  final PersonaAnimal animal;
  const _AnimalBanner({required this.animal});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QuizResultScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        decoration: BoxDecoration(
          color: animal.signatureBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 1,
                        color: animal.signatureText.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        AppCopy.homeYourSpiritLabel,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: animal.signatureText.withValues(alpha: 0.7),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    animal.name,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: animal.signatureText,
                      letterSpacing: -0.6,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    animal.tagline,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: animal.signatureText.withValues(alpha: 0.85),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            // 흑백 미니 일러스트
            SizedBox(
              width: 90,
              height: 90,
              child: AnimalIllustration(
                illustrationId: animal.illustrationId,
                ink: animal.illustrationInk.withValues(alpha: 0.7),
                size: 90,
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: animal.signatureText.withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.05);
  }
}

// ═══════════════════════════════════════════════════════════
//  Monthly Hero (세금 정보 통합 — 작게)
// ═══════════════════════════════════════════════════════════
class _MonthlyHero extends StatelessWidget {
  final dynamic persona;
  final PortfolioRecommendation rec;

  const _MonthlyHero({required this.persona, required this.rec});

  @override
  Widget build(BuildContext context) {
    final monthly = rec.totalMonthlyDividend.round();
    final target = persona.monthlyTarget;
    final pct = target > 0
        ? ((rec.totalMonthlyDividend / target) * 100).round()
        : 0;
    final progress = target > 0
        ? (rec.totalMonthlyDividend / target).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('·',
                style: TextStyle(
                    color: AppColors.wine,
                    fontSize: 14,
                    fontWeight: FontWeight.w900)),
            const SizedBox(width: 6),
            Text(
              AppCopy.homeMonthlyLabel,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.wine,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 6),
            const Text('·',
                style: TextStyle(
                    color: AppColors.wine,
                    fontSize: 14,
                    fontWeight: FontWeight.w900)),
          ],
        ).animate().fadeIn(delay: 200.ms, duration: 280.ms),
        const SizedBox(height: 14),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: monthly.toDouble()),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '₩',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: AppColors.wine,
                    letterSpacing: -1,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _fmt(value.round()),
                  style: GoogleFonts.inter(
                    fontSize: 52,
                    fontWeight: FontWeight.w700,
                    color: AppColors.wineDeep,
                    letterSpacing: -2.5,
                    height: 1,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.borderSoft,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 1100),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return FractionallySizedBox(
                        widthFactor: value,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: AppColors.wine,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Text(
              '$pct%',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: pct >= 100 ? AppColors.gold : AppColors.wine,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 600.ms, duration: 320.ms),
        const SizedBox(height: 8),
        Text(
          '${AppCopy.homeTargetPrefix}₩${_fmt(target)}',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textTertiary,
            fontStyle: FontStyle.italic,
          ),
        ).animate().fadeIn(delay: 700.ms),
      ],
    );
  }

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ═══════════════════════════════════════════════════════════
//  Goal Gap Card
// ═══════════════════════════════════════════════════════════
class _GoalGapCard extends StatelessWidget {
  final GoalGapAnalysis analysis;
  const _GoalGapCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GoalGapScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceWarm,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                Icons.lightbulb_outline_rounded,
                size: 18,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 12, height: 1, color: AppColors.gold),
                      const SizedBox(width: 6),
                      Text(
                        AppCopy.gapLabel,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.gold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '목표까지 ${(100 - analysis.achievementRate * 100).clamp(0, 100).round()}% 부족',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppCopy.gapHomeBannerSub,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              size: 14,
              color: AppColors.gold,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Goal Quick Action (목표 달성된 경우)
// ═══════════════════════════════════════════════════════════
class _GoalQuickAction extends StatelessWidget {
  final GoalGapAnalysis analysis;
  final VoidCallback onTap;

  const _GoalQuickAction({required this.analysis, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.wine.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                Icons.gps_fixed_rounded,
                size: 14,
                color: AppColors.wine,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppCopy.homeQuickGoalTitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(analysis.achievementRate * 100).clamp(0, 999).round()}${AppCopy.homeQuickGoalSuffix}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded,
                size: 14, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Portfolio Section
// ═══════════════════════════════════════════════════════════
class _PortfolioSection extends StatelessWidget {
  final PortfolioRecommendation rec;
  const _PortfolioSection({required this.rec});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppCopy.homePortfolioLabel,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(height: 1, color: AppColors.borderSoft),
            ),
            const SizedBox(width: 8),
            Text(
              '${rec.picks.length}',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.wine,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppCopy.homePortfolioTitle,
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: -0.6,
              ),
            ),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sort_rounded,
                      size: 11, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    AppCopy.homePortfolioSort,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            children: rec.picks.asMap().entries.map((entry) {
              return _PickRow(
                pick: entry.value,
                index: entry.key + 1,
                isLast: entry.key == rec.picks.length - 1,
              )
                  .animate()
                  .fadeIn(
                delay: Duration(milliseconds: 500 + entry.key * 60),
                duration: 320.ms,
              )
                  .slideX(begin: 0.03);
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _PickRow extends StatelessWidget {
  final PortfolioPick pick;
  final int index;
  final bool isLast;

  const _PickRow({
    required this.pick,
    required this.index,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final stock = pick.stock;
    final monthly = pick.monthlyDividend.round();
    final pct = (pick.weightOfTotal * 100).round();
    final palette = AppColors.paletteFor(stock.sector.name);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StockDetailScreen(stock: stock)),
      ),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
            bottom: BorderSide(color: AppColors.borderSoft, width: 1),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text(
                index.toString().padLeft(2, '0'),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 6,
              height: 36,
              decoration: BoxDecoration(
                color: palette.bg,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stock.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${pick.shares}주 · ${stock.frequency.label}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₩${_fmt(monthly)}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.wineDeep,
                    letterSpacing: -0.2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$pct%',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.wine,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
