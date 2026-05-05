import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../algorithms/persona_animal.dart';
import '../algorithms/recommendation_engine.dart';
import '../algorithms/tax_calculator.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'goal_gap_screen.dart';
import 'quiz_result_screen.dart';
import 'stock_detail_screen.dart';
import 'tax_detail_screen.dart';

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
    final tax = TaxCalculator.calculate(
      monthlyDividend: rec.totalMonthlyDividend.round(),
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
              child: _Greeting(),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _AnimalBanner(animal: animal),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _MonthlyHero(persona: persona, rec: rec, tax: tax),
            ),

            // ── 목표 갭 카드 (50% 미만일 때만)
            if (goalGap.hasSignificantGap) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _GoalGapCard(analysis: goalGap)
                    .animate()
                    .fadeIn(delay: 350.ms, duration: 380.ms)
                    .slideY(begin: 0.05),
              ),
            ],

            const SizedBox(height: 24),

            // ── 세금 + 갭 분석 (Quick Actions 2x1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: _IconType.tax,
                      label: '세금 계산',
                      sublabel: '월 ₩${_fmt(tax.monthlyNet)} 실수령',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TaxDetailScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: _IconType.target,
                      label: '목표 분석',
                      sublabel:
                      '${(goalGap.achievementRate * 100).clamp(0, 999).round()}% 달성',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const GoalGapScreen()),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms, duration: 380.ms),
            ),

            const SizedBox(height: 28),

            // ── 포트폴리오 (깔끔한 새 디자인)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _PortfolioSection(rec: rec),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: Text(
                  '· 천천히 익어가는 자산 ·',
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

  static String _fmt(int v) {
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
//  Greeting (헤더)
// ═══════════════════════════════════════════════════════════
class _Greeting extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 24, height: 1.5, color: AppColors.wine),
        const SizedBox(width: 10),
        Text(
          'BAEDANG NAMU',
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
          child: const _Icon(_IconType.bell, size: 14),
        ),
      ],
    ).animate().fadeIn(duration: 280.ms);
  }
}

// ═══════════════════════════════════════════════════════════
//  Animal Banner
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: animal.signatureBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              top: -10,
              child: Opacity(
                opacity: 0.15,
                child: Text(
                  animal.emoji,
                  style: const TextStyle(fontSize: 100),
                ),
              ),
            ),
            Row(
              children: [
                Text(animal.emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 14,
                            height: 1,
                            color:
                            animal.signatureText.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'YOUR SPIRIT',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: animal.signatureText
                                  .withValues(alpha: 0.7),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        animal.name,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: animal.signatureText,
                          letterSpacing: -0.5,
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
                _Icon(
                  _IconType.arrowRight,
                  size: 16,
                  color: animal.signatureText.withValues(alpha: 0.7),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.05);
  }
}

// ═══════════════════════════════════════════════════════════
//  Monthly Hero
// ═══════════════════════════════════════════════════════════
class _MonthlyHero extends StatelessWidget {
  final dynamic persona;
  final PortfolioRecommendation rec;
  final TaxBreakdown tax;

  const _MonthlyHero({
    required this.persona,
    required this.rec,
    required this.tax,
  });

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
            Text('·',
                style: TextStyle(
                    color: AppColors.wine,
                    fontSize: 14,
                    fontWeight: FontWeight.w900)),
            const SizedBox(width: 6),
            Text(
              'MONTHLY DIVIDEND',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.wine,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 6),
            Text('·',
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
        const SizedBox(height: 6),
        // ⭐ NEW: 세후 실수령 표시
        Row(
          children: [
            Text(
              '세후 ',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
            Text(
              '₩${_fmt(tax.monthlyNet)}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
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
          '목표 ₩${_fmt(target)}',
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
//  ⭐ NEW: Goal Gap Card (목표 미달성 시 노출)
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
              child: const _Icon(
                _IconType.lightbulb,
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
                      Container(
                        width: 12,
                        height: 1,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'GOAL ANALYSIS',
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
                    '3가지 해결 방법을 제안해드릴게요',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const _Icon(
              _IconType.arrowRight,
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
//  Quick Action (세금/목표)
// ═══════════════════════════════════════════════════════════
class _QuickAction extends StatelessWidget {
  final _IconType icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.wine.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: _Icon(icon, size: 14, color: AppColors.wine),
                ),
                const Spacer(),
                _Icon(_IconType.arrowRight,
                    size: 12, color: AppColors.textTertiary),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              sublabel,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  ⭐ NEW: Portfolio Section (깔끔하게 재디자인)
//  - 헤더는 절제 (Portfolio · count · 정렬)
//  - 각 row는 더 호흡감 있는 spacing
//  - 우측 가격 정보를 column 정렬 (₩ 위, % 아래)
//  - 좌측 미니 막대로 비중 시각화
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
              'PORTFOLIO',
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
              '추천 종목',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: -0.6,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Icon(_IconType.sortDesc,
                      size: 11, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '비중순',
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
            // ── 인덱스 (영수증 라인 번호 스타일)
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
            // ── 섹터 컬러 도트
            Container(
              width: 6,
              height: 36,
              decoration: BoxDecoration(
                color: palette.bg,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 12),
            // ── 종목명 + 메타
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
            // ── 우측 가격 정보
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
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

// ═══════════════════════════════════════════════════════════
//  ⭐ NEW: Custom Icon System (Phosphor 풍 - thin & elegant)
//  Material Icons는 너무 두껍고 핀테크 톤과 안 맞음
// ═══════════════════════════════════════════════════════════
enum _IconType {
  bell,
  arrowRight,
  tax,
  target,
  lightbulb,
  sortDesc,
}

class _Icon extends StatelessWidget {
  final _IconType type;
  final double size;
  final Color? color;

  const _Icon(this.type, {this.size = 16, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _IconPainter(
          type: type,
          color: color ?? AppColors.wine,
        ),
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  final _IconType type;
  final Color color;

  _IconPainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final s = size.width;
    final c = Offset(s / 2, s / 2);

    switch (type) {
      case _IconType.bell:
      // 종 모양 (얇게)
        final p = Path()
          ..moveTo(s * 0.5, s * 0.15)
          ..arcToPoint(
            Offset(s * 0.5, s * 0.18),
            radius: const Radius.circular(0.5),
          )
          ..moveTo(s * 0.25, s * 0.7)
          ..lineTo(s * 0.75, s * 0.7)
          ..lineTo(s * 0.65, s * 0.5)
          ..lineTo(s * 0.65, s * 0.4)
          ..arcToPoint(
            Offset(s * 0.35, s * 0.4),
            radius: Radius.circular(s * 0.15),
            clockwise: false,
          )
          ..lineTo(s * 0.35, s * 0.5)
          ..lineTo(s * 0.25, s * 0.7)
          ..close();
        canvas.drawPath(p, paint);
        // 종 추
        canvas.drawLine(
          Offset(s * 0.42, s * 0.78),
          Offset(s * 0.58, s * 0.78),
          paint,
        );
        break;

      case _IconType.arrowRight:
        canvas.drawLine(Offset(s * 0.2, s / 2), Offset(s * 0.8, s / 2), paint);
        canvas.drawLine(
            Offset(s * 0.55, s * 0.3), Offset(s * 0.8, s / 2), paint);
        canvas.drawLine(
            Offset(s * 0.55, s * 0.7), Offset(s * 0.8, s / 2), paint);
        break;

      case _IconType.tax:
      // 영수증 + ₩ 모티브
        final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(s * 0.22, s * 0.15, s * 0.56, s * 0.7),
          Radius.circular(s * 0.05),
        );
        canvas.drawRRect(r, paint);
        // ₩ 심볼 (세로 두 줄)
        canvas.drawLine(
            Offset(s * 0.42, s * 0.35), Offset(s * 0.42, s * 0.7), paint);
        canvas.drawLine(
            Offset(s * 0.58, s * 0.35), Offset(s * 0.58, s * 0.7), paint);
        canvas.drawLine(
            Offset(s * 0.36, s * 0.5), Offset(s * 0.64, s * 0.5), paint);
        canvas.drawLine(
            Offset(s * 0.36, s * 0.6), Offset(s * 0.64, s * 0.6), paint);
        break;

      case _IconType.target:
      // 동심원 + 중심 점
        canvas.drawCircle(c, s * 0.35, paint);
        canvas.drawCircle(c, s * 0.2, paint);
        canvas.drawCircle(c, s * 0.06, fillPaint);
        break;

      case _IconType.lightbulb:
      // 전구
        final p = Path()
          ..moveTo(s * 0.35, s * 0.55)
          ..arcToPoint(
            Offset(s * 0.65, s * 0.55),
            radius: Radius.circular(s * 0.25),
            clockwise: true,
          );
        canvas.drawPath(p, paint);
        // 베이스
        canvas.drawLine(
            Offset(s * 0.42, s * 0.7), Offset(s * 0.58, s * 0.7), paint);
        canvas.drawLine(
            Offset(s * 0.42, s * 0.78), Offset(s * 0.58, s * 0.78), paint);
        canvas.drawLine(
            Offset(s * 0.45, s * 0.85), Offset(s * 0.55, s * 0.85), paint);
        // 빛살
        canvas.drawLine(
            Offset(s * 0.5, s * 0.1), Offset(s * 0.5, s * 0.18), paint);
        canvas.drawLine(
            Offset(s * 0.2, s * 0.25), Offset(s * 0.27, s * 0.32), paint);
        canvas.drawLine(
            Offset(s * 0.8, s * 0.25), Offset(s * 0.73, s * 0.32), paint);
        break;

      case _IconType.sortDesc:
      // 3줄 세로 (긴/중간/짧은)
        canvas.drawLine(
            Offset(s * 0.2, s * 0.3), Offset(s * 0.8, s * 0.3), paint);
        canvas.drawLine(
            Offset(s * 0.2, s * 0.5), Offset(s * 0.65, s * 0.5), paint);
        canvas.drawLine(
            Offset(s * 0.2, s * 0.7), Offset(s * 0.5, s * 0.7), paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _IconPainter old) =>
      old.type != type || old.color != color;
}