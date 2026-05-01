import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/forecast_engine.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolio = ref.watch(portfolioProvider);
    final goal = ref.watch(userGoalProvider);
    final totalMonthly =
    ref.read(portfolioProvider.notifier).totalMonthlyDividend.round();
    final totalValue = ref.read(portfolioProvider.notifier).totalValue.round();

    // 보유 포트폴리오의 미래 예측
    final myPortfolioMap = {
      for (var item in portfolio) item.stock: item.shares
    };
    final forecast = portfolio.isNotEmpty
        ? ForecastEngine.forecastPortfolio(
        portfolio: myPortfolioMap, targetYears: 3)
        : null;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: const Text('내 포트폴리오'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 자산 요약
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('총 자산',
                      style: TextStyle(color: Colors.white60, fontSize: 12)),
                  Text(
                    formatKRW(totalValue),
                    style: const TextStyle(
                      color: Colors.white, fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          label: '월 배당',
                          value: formatKRW(totalMonthly),
                          highlight: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatBox(
                          label: '연 배당',
                          value: formatKRW(totalMonthly * 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _StatBox(
                          label: '목표 달성',
                          value: '${((totalMonthly / goal.monthlyTarget) * 100).round()}%',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 미래 예측
            if (forecast != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timeline_rounded,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 6),
                        const Text('보유 포트폴리오 미래 예측',
                            style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700,
                            )),
                        const Spacer(),
                        Text('${forecast.targetYear}년',
                            style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary,
                            )),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('현재 월 배당',
                                  style: TextStyle(
                                    fontSize: 11, color: AppColors.textSecondary,
                                  )),
                              const SizedBox(height: 2),
                              Text(formatKRW(forecast.currentMonthly),
                                  style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700,
                                  )),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded,
                            color: AppColors.accent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${forecast.targetYear}년 예상',
                                  style: const TextStyle(
                                    fontSize: 11, color: AppColors.textSecondary,
                                  )),
                              const SizedBox(height: 2),
                              Text(formatKRW(forecast.expectedMonthly),
                                  style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w700,
                                    color: AppColors.positive,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '예상 성장률 +${forecast.growthRate.toStringAsFixed(1)}% · 신뢰도 ${(forecast.avgConfidence * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // 섹터 분포 차트
            if (portfolio.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('섹터별 배당 분포',
                        style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700,
                        )),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: PieChart(
                        PieChartData(
                          sections: portfolio.map((item) {
                            return PieChartSectionData(
                              value: item.monthlyDividend,
                              title: item.stock.sector.label,
                              color: _sectorColor(item.stock.sector.label),
                              radius: 60,
                              titleStyle: const TextStyle(
                                fontSize: 11, color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }).toList(),
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // 보유 종목 리스트
            const Text('보유 종목',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...portfolio.map((item) => Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: item.stock.sectorColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(item.stock.sector.emoji,
                            style: const TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.stock.name,
                                style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700,
                                )),
                            Text('${item.shares}주 · 평단 ${formatKRW(item.avgPrice)}',
                                style: const TextStyle(
                                  fontSize: 11, color: AppColors.textSecondary,
                                )),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(formatKRW(item.totalValue),
                              style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700,
                              )),
                          Text(
                            '${item.gainLoss >= 0 ? '+' : ''}${item.gainLossPct.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 11,
                              color: item.gainLoss >= 0
                                  ? AppColors.positive
                                  : AppColors.negative,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 18),
                  Row(
                    children: [
                      const Icon(Icons.payments_rounded,
                          size: 14, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(
                        '월 배당 ${formatKRW(item.monthlyDividend)}',
                        style: const TextStyle(
                          fontSize: 12, color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '연 ${formatKRW(item.annualDividend)}',
                        style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Color _sectorColor(String label) {
    switch (label) {
      case '금융': return const Color(0xFF378ADD);
      case '통신': return const Color(0xFFEF9F27);
      case '에너지': return const Color(0xFFFFC107);
      case '리츠': return const Color(0xFF1D9E75);
      case '소비재': return const Color(0xFFD4537E);
      default: return AppColors.primary;
    }
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatBox({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 10)),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: highlight ? AppColors.accent : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}