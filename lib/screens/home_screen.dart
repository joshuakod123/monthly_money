import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
    final stocks = ref.watch(filteredStocksProvider);
    final forecast = ref.watch(portfolioForecastProvider);
    final myPortfolio = ref.watch(portfolioProvider);
    final myMonthly = ref
        .read(portfolioProvider.notifier)
        .totalMonthlyDividend
        .round();

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: SingleChildScrollView(
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
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.notifications_none_rounded,
                              color: Colors.white70, size: 22),
                          onPressed: () {},
                        ),
                        Container(
                          width: 34, height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '김',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700, fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GoalProgressCard(
                      targetAmount: goal.monthlyTarget,
                      currentAmount: myMonthly,
                      futureExpected: forecast.expectedMonthly,
                      targetYear: forecast.targetYear,
                    ),
                  ],
                ),
              ),

              // ── AI 예측 카드 (홈으로 끌어올림)
              Transform.translate(
                offset: const Offset(0, -16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: InvestmentCalcCard(
                    totalInvestment: forecast.totalInvestment,
                    avgYield: forecast.currentMonthly > 0
                        ? (forecast.currentMonthly * 12 / forecast.totalInvestment) * 100
                        : 0,
                    confidence: forecast.avgConfidence,
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                ),
              ),

              // ── 미래 예측 박스
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: _ForecastSummaryCard(forecast: forecast),
              ),

              // ── 목표 설정 진입 버튼
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const GoalSetupScreen(),
                  )),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tune_rounded,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('목표 & 성향 설정',
                                  style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  )),
                              const SizedBox(height: 2),
                              Text(
                                '${goal.profile.label} · ${formatKRW(goal.monthlyTarget)} / 월',
                                style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary,
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
                ),
              ),

              // ── 섹션: 맞춤 추천
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Row(
                  children: [
                    const Text('내 성향 맞춤 추천',
                        style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        )),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentWarm.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        goal.profile.label,
                        style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w600,
                          color: Color(0xFF9A5E00),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text('전체보기 →',
                        style: TextStyle(
                          fontSize: 12, color: AppColors.accent,
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
                child: Column(
                  children: stocks
                      .asMap()
                      .entries
                      .map((entry) => StockCard(
                    stock: entry.value,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            StockDetailScreen(stock: entry.value),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(
                      delay: Duration(milliseconds: entry.key * 60),
                      duration: 400.ms)
                      .slideY(begin: 0.1, end: 0))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 미래 예측 요약 카드
// ─────────────────────────────────────────
class _ForecastSummaryCard extends StatelessWidget {
  final dynamic forecast; // PortfolioForecast
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
              const Text(
                '3년 후 예상 월 배당',
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isPositive
                      ? AppColors.positiveBg
                      : AppColors.negativeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${isPositive ? '+' : ''}${growth.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700,
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
              Text(
                formatKRW(forecast.expectedMonthly),
                style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary, letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Text(
                  '/ 월',
                  style: TextStyle(
                    fontSize: 13, color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '범위: ${formatKRW(forecast.lowerBoundMonthly)} ~ ${formatKRW(forecast.upperBoundMonthly)} (95% 신뢰구간)',
            style: const TextStyle(
              fontSize: 11, color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}