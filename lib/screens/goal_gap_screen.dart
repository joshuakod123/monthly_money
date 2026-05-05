import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../algorithms/recommendation_engine.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'quiz_screen.dart';

class GoalGapScreen extends ConsumerWidget {
  const GoalGapScreen({super.key});

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

    final analysis = RecommendationEngine.analyzeGoalGap(
      persona: persona,
      rec: rec,
    );

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        size: 16, color: AppColors.textPrimary),
                  ),
                ),
                const Spacer(),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Container(width: 24, height: 1.5, color: AppColors.wine),
                const SizedBox(width: 10),
                Text(
                  'GOAL ANALYSIS',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.wine,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 280.ms),

            const SizedBox(height: 12),
            Text(
              '목표 분석',
              style: GoogleFonts.playfairDisplay(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -1,
                height: 1.1,
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 4),
            Text(
              'Path to Your Goal',
              style: GoogleFonts.playfairDisplay(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppColors.textTertiary,
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 24),

            // ── 갭 시각화 카드
            _GapCard(analysis: analysis)
                .animate()
                .fadeIn(delay: 300.ms)
                .slideY(begin: 0.05),

            const SizedBox(height: 24),

            if (analysis.hasSignificantGap) ...[
              _SectionLabel(label: 'YOUR OPTIONS'),
              const SizedBox(height: 6),
              Text(
                '3가지 길 중 하나를 선택하세요',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 14),

              ...analysis.recommendations.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RecommendationCard(
                    rec: entry.value,
                    index: entry.key + 1,
                    onAction: () => _handleAction(context, entry.value.type),
                  )
                      .animate()
                      .fadeIn(
                    delay: Duration(milliseconds: 400 + entry.key * 100),
                  )
                      .slideX(begin: 0.05),
                );
              }),

              if (analysis.buildPlans.isNotEmpty) ...[
                const SizedBox(height: 24),
                _SectionLabel(label: 'BUILD PLANS'),
                const SizedBox(height: 12),
                _BuildPlansCard(plans: analysis.buildPlans, analysis: analysis)
                    .animate()
                    .fadeIn(delay: 700.ms),
              ],
            ] else ...[
              _AchievableCard(analysis: analysis)
                  .animate()
                  .fadeIn(delay: 400.ms),
            ],

            const SizedBox(height: 32),

            Center(
              child: Text(
                '· 시간이 자산을 익혀줍니다 ·',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, RecommendationType type) {
    switch (type) {
      case RecommendationType.lowerTarget:
      case RecommendationType.increaseBudget:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QuizScreen()),
        );
        break;
      case RecommendationType.monthlyBuild:
      case RecommendationType.highYield:
      // TODO: 추후 적립식 시뮬레이션 화면 / 고배당 필터 화면 연결
        break;
    }
  }
}

class _GapCard extends StatelessWidget {
  final GoalGapAnalysis analysis;
  const _GapCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final pct = (analysis.achievementRate * 100).clamp(0, 999).round();
    final isAchievable = analysis.achievementRate >= 0.95;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isAchievable
              ? [AppColors.gold, AppColors.wine]
              : const [AppColors.wine, AppColors.wineDeep],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 1,
                color: AppColors.surface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                'ACHIEVEMENT',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.surface.withValues(alpha: 0.8),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$pct',
                style: GoogleFonts.inter(
                  fontSize: 64,
                  fontWeight: FontWeight.w800,
                  color: AppColors.surface,
                  letterSpacing: -3,
                  height: 0.9,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '%',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.surface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor:
              (analysis.achievementRate).clamp(0.0, 1.0).toDouble(),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: AppColors.surface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: '현재',
                  value: '₩${_fmt(analysis.actualMonthly)}',
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: AppColors.surface.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _MiniMetric(
                  label: '목표',
                  value: '₩${_fmt(analysis.targetMonthly)}',
                  alignCenter: true,
                ),
              ),
              if (analysis.budgetGap > 0) ...[
                Container(
                  width: 1,
                  height: 32,
                  color: AppColors.surface.withValues(alpha: 0.2),
                ),
                Expanded(
                  child: _MiniMetric(
                    label: '필요 예산',
                    value: '+₩${_fmt(analysis.budgetGap)}',
                    alignEnd: true,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(int v) {
    if (v >= 100000000) return '${(v / 100000000).toStringAsFixed(1)}억';
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(0)}만';
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool alignCenter;
  final bool alignEnd;

  const _MiniMetric({
    required this.label,
    required this.value,
    this.alignCenter = false,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final align = alignEnd
        ? CrossAxisAlignment.end
        : alignCenter
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            color: AppColors.surface.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.surface,
            letterSpacing: -0.3,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: AppColors.borderSoft)),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final GoalRecommendation rec;
  final int index;
  final VoidCallback onAction;

  const _RecommendationCard({
    required this.rec,
    required this.index,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;
    switch (rec.type) {
      case RecommendationType.lowerTarget:
        icon = Icons.tune_rounded;
        iconColor = AppColors.wine;
        break;
      case RecommendationType.monthlyBuild:
        icon = Icons.timeline_rounded;
        iconColor = AppColors.gold;
        break;
      case RecommendationType.increaseBudget:
        icon = Icons.add_rounded;
        iconColor = AppColors.wineDeep;
        break;
      case RecommendationType.highYield:
        icon = Icons.trending_up_rounded;
        iconColor = AppColors.wine;
        break;
    }

    return GestureDetector(
      onTap: onAction,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        index.toString().padLeft(2, '0'),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textTertiary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 1,
                        color: AppColors.borderSoft,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rec.title,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.4,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rec.description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        rec.actionLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.wine,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 12,
                        color: AppColors.wine,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuildPlansCard extends StatelessWidget {
  final List<MonthlyBuildPlan> plans;
  final GoalGapAnalysis analysis;
  const _BuildPlansCard({required this.plans, required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.wine,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              'MONTHLY BUILD',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.surface,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '월 적립 시 목표 도달까지',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 14),
          ...plans.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _PlanRow(plan: entry.value),
            );
          }),
          const SizedBox(height: 6),
          Text(
            '* 단순 적립 기준 (이자 미반영)',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.textTertiary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  final MonthlyBuildPlan plan;
  const _PlanRow({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '월 ₩${_fmt(plan.monthlyContribution)}',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.borderSoft,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${plan.yearsToGoal.toStringAsFixed(1)}년',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.wine,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '소요',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.textTertiary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  String _fmt(int v) {
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(0)}만';
    return v.toString();
  }
}

class _AchievableCard extends StatelessWidget {
  final GoalGapAnalysis analysis;
  const _AchievableCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.gold, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColors.gold,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '목표 달성 가능',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '현재 예산과 추천 종목으로 목표를 거의 달성할 수 있어요',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}