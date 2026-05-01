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
    final myMonthly = ref.read(portfolioProvider.notifier).totalMonthlyDividend.round();

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 세련된 상단 헤더
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '배당나무',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.bgCard,
                      child: const Icon(Icons.person_rounded, color: AppColors.textPrimary, size: 20),
                    ),
                  ],
                ),
              ),

              // ── 목표 달성률 카드
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: GoalProgressCard(
                  targetAmount: goal.monthlyTarget,
                  currentAmount: myMonthly,
                  futureExpected: forecast.expectedMonthly,
                  targetYear: forecast.targetYear,
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
              ),

              // ── AI 예측 카드
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: InvestmentCalcCard(
                  totalInvestment: forecast.totalInvestment,
                  avgYield: forecast.currentMonthly > 0
                      ? (forecast.currentMonthly * 12 / forecast.totalInvestment) * 100
                      : 0,
                  confidence: forecast.avgConfidence,
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.05),
              ),

              // ── 목표 설정 진입 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const GoalSetupScreen(),
                  )),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tune_rounded, color: AppColors.primary, size: 22),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('투자 목표 재설정',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                              const SizedBox(height: 4),
                              Text('${goal.profile.label} · ${formatKRW(goal.monthlyTarget)} / 월',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              ),

              // ── 섹션: 맞춤 추천
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Row(
                  children: [
                    const Text('내 성향 맞춤 추천',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(goal.profile.label,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ),
                  ],
                ),
              ),

              // ── 섹터 가로 스크롤 필터
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: StockSector.values.map((s) => SectorChip(
                    sector: s,
                    isActive: selectedSector == s,
                    onTap: () => ref.read(selectedSectorProvider.notifier).state = s,
                  )).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // ── 주식 리스트
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                child: Column(
                  children: stocks.asMap().entries.map((entry) => StockCard(
                    stock: entry.value,
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => StockDetailScreen(stock: entry.value),
                    )),
                  ).animate().fadeIn(delay: Duration(milliseconds: entry.key * 50), duration: 400.ms).slideY(begin: 0.05)).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}