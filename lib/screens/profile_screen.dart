import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stock_model.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rec = ref.watch(portfolioRecommendationProvider);
    final monthly = ref.watch(monthlyDividendCalendarProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: const Text('배당 캘린더',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: rec == null
          ? const Center(
        child: Text('퀴즈를 먼저 완료해주세요',
            style: TextStyle(color: AppColors.textSecondary)),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 연 합계 헤더
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('연 예상 배당',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      )),
                  const SizedBox(height: 4),
                  Text(
                    formatKRW(monthly.fold(0.0, (a, b) => a + b).round()),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '월 평균 ${formatKRW((monthly.fold(0.0, (a, b) => a + b) / 12).round())}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── 12개월 바 차트
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('월별 배당 패턴',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      )),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 160,
                    child: _MonthlyBarChart(monthly: monthly),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── 월별 상세 카드
            ...List.generate(12, (i) {
              final month = i + 1;
              final amount = monthly[i];
              final picks = rec.picks
                  .where((p) =>
              p.stock.paymentMonths.contains(month) &&
                  _stockMonthlyAmount(p.stock, p.shares) > 0)
                  .toList();
              return _MonthCard(
                month: month,
                amount: amount,
                picks: picks,
              );
            }),
          ],
        ),
      ),
    );
  }
}

double _stockMonthlyAmount(StockModel stock, int shares) {
  final annual = stock.dividendPerShare > 0
      ? stock.dividendPerShare
      : stock.latestDividend;
  if (annual == 0 || stock.paymentMonths.isEmpty) return 0;
  return (annual / stock.paymentMonths.length) * shares;
}

class _MonthlyBarChart extends StatelessWidget {
  final List<double> monthly;
  const _MonthlyBarChart({required this.monthly});

  @override
  Widget build(BuildContext context) {
    final maxV = monthly.reduce((a, b) => a > b ? a : b);
    if (maxV == 0) {
      return const Center(
        child: Text('배당 지급 데이터가 없습니다',
            style: TextStyle(color: AppColors.textHint, fontSize: 12)),
      );
    }

    return BarChart(
      BarChartData(
        maxY: maxV * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, _) => Text('${value.toInt() + 1}',
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 10,
                  )),
            ),
          ),
        ),
        barGroups: List.generate(12, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: monthly[i],
                color: monthly[i] > 0
                    ? AppColors.primary
                    : AppColors.border,
                width: 14,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  final int month;
  final double amount;
  final List<dynamic> picks; // PortfolioPick
  const _MonthCard(
      {required this.month, required this.amount, required this.picks});

  @override
  Widget build(BuildContext context) {
    final hasPayout = amount > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasPayout
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$month월',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )),
              if (hasPayout)
                Text(formatKRW(amount.round()),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: -0.5,
                    ))
              else
                const Text('지급 없음',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    )),
            ],
          ),
          if (picks.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),
            ...picks.map((pick) {
              final amt = _stockMonthlyAmount(pick.stock, pick.shares);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text(pick.stock.sector.emoji,
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${pick.stock.name} (${pick.shares}주)',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(formatKRW(amt.round()),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}