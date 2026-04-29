import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../models/stock_model.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'stock_detail_screen.dart';
import 'goal_setup_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(userGoalProvider);
    final selectedSector = ref.watch(selectedSectorProvider);
    final stocksAsync = ref.watch(filteredStocksProvider);
    final forecastAsync = ref.watch(portfolioForecastProvider);
    final myPortfolio = ref.watch(portfolioProvider);
    final myMonthly =
        ref.read(portfolioProvider.notifier).totalMonthlyDividend.round();

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(allStocksProvider);
            ref.invalidate(recommendedPortfolioProvider);
            ref.invalidate(portfolioForecastProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 상단 헤더
                Container(
                  color: AppColors.primary,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '배당나무',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.notifications_none_rounded,
                                color: Colors.white70, size: 22),
                            onPressed: () {},
                          ),
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '김',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      forecastAsync.when(
                        data: (forecast) => GoalProgressCard(
                          targetAmount: goal.monthlyTarget,
                          currentAmount: myMonthly,
                          futureExpected: forecast.expectedMonthly,
                          targetYear: forecast.targetYear,
                        ),
                        loading: () => _GoalCardSkeleton(),
                        error: (e, _) => _GoalCardSkeleton(),
                      ),
                    ],
                  ),
                ),

                // ── AI 예측 카드
                Transform.translate(
                  offset: const Offset(0, -16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: forecastAsync.when(
                      data: (forecast) => InvestmentCalcCard(
                        totalInvestment: forecast.totalInvestment,
                        avgYield: forecast.currentMonthly > 0
                            ? (forecast.currentMonthly *
                                    12 /
                                    forecast.totalInvestment) *
                                100
                            : 0,
                        confidence: forecast.avgConfidence,
                      )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.1, end: 0),
                      loading: () => _ShimmerBox(height: 120, radius: 20),
                      error: (e, _) => _ErrorCard(
                        message: '데이터를 불러오지 못했어요',
                        onRetry: () => ref.invalidate(allStocksProvider),
                      ),
                    ),
                  ),
                ),

                // ── 미래 예측 박스
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: forecastAsync.when(
                    data: (forecast) => _ForecastSummaryCard(forecast: forecast),
                    loading: () => _ShimmerBox(height: 100, radius: 16),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                ),

                // ── 목표 설정 진입
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: _GoalSetupTile(goal: goal),
                ),

                // ── 섹션 헤더
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Row(
                    children: [
                      const Text('내 성향 맞춤 추천',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentWarm.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          goal.profile.label,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9A5E00),
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Text('전체보기 →',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w500,
                          )),
                    ],
                  ),
                ),

                // 섹터 가로 스크롤
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: StockSector.values
                        .map((s) => SectorChip(
                              sector: s,
                              isActive: selectedSector == s,
                              onTap: () => ref
                                  .read(selectedSectorProvider.notifier)
                                  .state = s,
                            ))
                        .toList(),
                  ),
                ),

                const SizedBox(height: 14),

                // 주식 리스트
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  child: stocksAsync.when(
                    data: (stocks) {
                      if (stocks.isEmpty) {
                        return const _EmptyState();
                      }
                      return Column(
                        children: stocks
                            .asMap()
                            .entries
                            .map((entry) => StockCard(
                                  stock: entry.value,
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StockDetailScreen(
                                          stock: entry.value),
                                    ),
                                  ),
                                )
                                    .animate()
                                    .fadeIn(
                                        delay: Duration(
                                            milliseconds: entry.key * 60),
                                        duration: 400.ms)
                                    .slideY(begin: 0.1, end: 0))
                            .toList(),
                      );
                    },
                    loading: () => Column(
                      children: List.generate(
                          5, (_) => _ShimmerBox(height: 110, radius: 16)),
                    ),
                    error: (e, _) => _ErrorCard(
                      message: '종목 정보를 불러오지 못했어요\n$e',
                      onRetry: () => ref.invalidate(allStocksProvider),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 에러/로딩/빈 상태 위젯들
// ─────────────────────────────────────────

class _ShimmerBox extends StatelessWidget {
  final double height;
  final double radius;
  const _ShimmerBox({required this.height, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Shimmer.fromColors(
        baseColor: AppColors.border.withOpacity(0.4),
        highlightColor: AppColors.border.withOpacity(0.15),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }
}

class _GoalCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: SizedBox(
          width: 22, height: 22,
          child: CircularProgressIndicator(
            color: AppColors.accent,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.negativeBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.negative.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.negative, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                )),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('재시도',
                style: TextStyle(
                  color: AppColors.negative,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: AppColors.border),
          const SizedBox(height: 12),
          Text('해당 조건의 종목이 없어요',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              )),
        ],
      ),
    );
  }
}

class _GoalSetupTile extends StatelessWidget {
  final UserGoal goal;
  const _GoalSetupTile({required this.goal});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const GoalSetupScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('목표 & 성향 설정',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 2),
                  Text(
                    '${goal.profile.label} · ${formatKRW(goal.monthlyTarget)} / 월',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _ForecastSummaryCard extends StatelessWidget {
  final dynamic forecast;
  const _ForecastSummaryCard({required this.forecast});

  @override
  Widget build(BuildContext context) {
    final growth = forecast.growthRate;
    final isPositive = growth >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              const Text('3년 후 예상 월 배당',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  )),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isPositive
                      ? AppColors.positiveBg
                      : AppColors.negativeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${isPositive ? '+' : ''}${growth.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isPositive
                        ? AppColors.positive
                        : AppColors.negative,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatKRW(forecast.expectedMonthly),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  )),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Text('/ 월',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '범위: ${formatKRW(forecast.lowerBoundMonthly)} ~ ${formatKRW(forecast.upperBoundMonthly)} (95% 신뢰구간)',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
