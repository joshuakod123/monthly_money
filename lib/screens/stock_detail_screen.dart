import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stock_model.dart';
import '../providers/app_providers.dart';
import '../services/forecast_engine.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class StockDetailScreen extends ConsumerWidget {
  final StockModel stock;
  const StockDetailScreen({super.key, required this.stock});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = ref.watch(userGoalProvider);
    final forecasts = ForecastEngine.forecast(stock, years: 3);
    final goalAnalysis = ForecastEngine.analyzeGoalAchievability(
      stock: stock,
      monthlyGoal: goal.monthlyTarget,
      targetYears: 3,
    );

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: Text(stock.name),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 종목 헤더
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: stock.sectorColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(stock.sector.emoji,
                            style: const TextStyle(fontSize: 26)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(stock.name,
                                style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w700,
                                )),
                            const SizedBox(height: 2),
                            Text('${stock.code} · ${stock.sector.label}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                )),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(formatKRW(stock.price),
                              style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700,
                              )),
                          Text(formatPct(stock.dividendYield),
                              style: const TextStyle(
                                fontSize: 13, color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      _MetricBox(label: 'PER', value: '${stock.per}'),
                      _MetricBox(label: 'PBR', value: '${stock.pbr}'),
                      _MetricBox(label: 'ROE', value: '${stock.roe}%'),
                      _MetricBox(label: '리스크', value: stock.riskLevel),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── 배당 히스토리 + 예측 차트
            _buildForecastChart(forecasts),

            const SizedBox(height: 16),

            // ── 목표 달성 분석
            _buildGoalAnalysis(goal, goalAnalysis, stock),

            const SizedBox(height: 16),

            // ── 예측 공식 설명
            _buildFormulaCard(stock, forecasts),

            const SizedBox(height: 16),

            // ── 연도별 배당 표
            _buildHistoryTable(stock, forecasts),

            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: const Text('관심 추가',
                    style: TextStyle(color: AppColors.textPrimary)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '포트폴리오 추가',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 예측 차트
  Widget _buildForecastChart(List<DividendForecast> forecasts) {
    final history = stock.history.toList()
      ..sort((a, b) => a.year.compareTo(b.year));
    final allYears = [
      ...history.map((h) => h.year.toDouble()),
      ...forecasts.map((f) => f.year.toDouble()),
    ];
    final allValues = [
      ...history.map((h) => h.amount.toDouble()),
      ...forecasts.map((f) => f.predictedAmount.toDouble()),
    ];

    if (allYears.isEmpty) return const SizedBox();

    final minY = (allValues.reduce((a, b) => a < b ? a : b) * 0.7).floorToDouble();
    final maxY = (allValues.reduce((a, b) => a > b ? a : b) * 1.2).ceilToDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
              const Icon(Icons.show_chart_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              const Text('배당금 추세 & 미래 예측',
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                  )),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text('AI 예측',
                    style: TextStyle(
                      color: AppColors.accent, fontSize: 10,
                      fontWeight: FontWeight.w700,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 4,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.border, strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, _) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          "'${value.toInt() % 100}",
                          style: const TextStyle(
                            fontSize: 10, color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      interval: (maxY - minY) / 4,
                      getTitlesWidget: (value, _) => Text(
                        '${(value / 1000).toStringAsFixed(0)}K',
                        style: const TextStyle(
                          fontSize: 9, color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: allYears.first,
                maxX: allYears.last,
                minY: minY < 0 ? 0 : minY,
                maxY: maxY,
                lineBarsData: [
                  // 과거 실제 배당
                  LineChartBarData(
                    spots: history
                        .map((h) =>
                            FlSpot(h.year.toDouble(), h.amount.toDouble()))
                        .toList(),
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.primary,
                        strokeColor: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.08),
                    ),
                  ),
                  // 예측 (점선)
                  if (forecasts.isNotEmpty &&
                      forecasts.first.predictedAmount > 0)
                    LineChartBarData(
                      spots: [
                        FlSpot(history.last.year.toDouble(),
                            history.last.amount.toDouble()),
                        ...forecasts.map((f) => FlSpot(
                            f.year.toDouble(),
                            f.predictedAmount.toDouble())),
                      ],
                      isCurved: true,
                      color: AppColors.accent,
                      barWidth: 3,
                      dashArray: [6, 4],
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.accent,
                          strokeColor: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ChartLegend(
                color: AppColors.primary,
                label: '과거 실제',
              ),
              const SizedBox(width: 16),
              _ChartLegend(
                color: AppColors.accent,
                label: '예측',
                isDashed: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 목표 달성 분석 카드
  Widget _buildGoalAnalysis(
      UserGoal goal, GoalProbability analysis, StockModel stock) {
    final probability = (analysis.probability * 100).round();

    Color probColor;
    String probLabel;
    if (probability >= 70) {
      probColor = AppColors.positive;
      probLabel = '높음';
    } else if (probability >= 40) {
      probColor = AppColors.accentWarm;
      probLabel = '보통';
    } else {
      probColor = AppColors.negative;
      probLabel = '낮음';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: AppColors.accent, size: 18),
              const SizedBox(width: 6),
              const Text('이 종목 단독으로 목표 달성',
                  style: TextStyle(
                    color: Colors.white, fontSize: 14,
                    fontWeight: FontWeight.w700,
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
                    Text(
                      '월 ${formatKRW(goal.monthlyTarget)} 받으려면',
                      style: const TextStyle(
                        color: Colors.white60, fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${analysis.sharesNeeded}주',
                      style: const TextStyle(
                        color: Colors.white, fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      formatKRW(analysis.investmentRequired),
                      style: const TextStyle(
                        color: AppColors.accent, fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: probColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: probColor, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$probability%',
                      style: TextStyle(
                        color: probColor, fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '달성도 $probLabel',
                      style: TextStyle(
                        color: probColor, fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 자체 공식 설명 카드
  Widget _buildFormulaCard(
      StockModel stock, List<DividendForecast> forecasts) {
    final next = forecasts.isNotEmpty ? forecasts.first : null;
    if (next == null) return const SizedBox();

    return Container(
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
              const Icon(Icons.functions_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              const Text('예측 공식',
                  style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                  )),
              const Spacer(),
              Text(
                '신뢰도 ${(next.confidenceLevel * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bgPage,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'E[D] = D₀ × (1 + g) × C × R',
                  style: TextStyle(
                    fontSize: 14, fontFamily: 'monospace',
                    fontWeight: FontWeight.w700, color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                _FormulaRow(label: 'D₀ (최근 배당)', value: formatKRW(stock.history.last.amount)),
                _FormulaRow(label: 'g (가중 성장률)', value: '+${(_calculateGrowth(stock) * 100).toStringAsFixed(1)}%'),
                _FormulaRow(label: 'C (안정성 보정)', value: stock.riskLevel == '낮음' ? '0.98' : '0.92'),
                _FormulaRow(label: 'R (ROE 회귀)', value: stock.roe > 10 ? '1.05' : '0.97'),
                const Divider(height: 16),
                _FormulaRow(
                  label: '${next.year}년 예상 배당',
                  value: formatKRW(next.predictedAmount),
                  isBold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateGrowth(StockModel stock) {
    final history = stock.history;
    if (history.length < 2) return 0;
    final sorted = [...history]..sort((a, b) => a.year.compareTo(b.year));
    final start = sorted.first.amount;
    final end = sorted.last.amount;
    if (start == 0) return 0;
    return ((end - start) / start) / (sorted.length - 1);
  }

  // 연도별 배당 표
  Widget _buildHistoryTable(
      StockModel stock, List<DividendForecast> forecasts) {
    final history = [...stock.history]..sort((a, b) => b.year.compareTo(a.year));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('연도별 배당 내역 (예측 포함)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          // 예측치 (미래)
          ...forecasts.reversed.map((f) => _HistoryRow(
                year: '${f.year}',
                amount: f.predictedAmount,
                yieldVal: f.predictedYield,
                isPredicted: true,
                trend: f.trend,
              )),
          // 실제 (과거)
          ...history.map((h) => _HistoryRow(
                year: '${h.year}',
                amount: h.amount,
                yieldVal: h.yieldPercent,
                isPredicted: false,
              )),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  const _MetricBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(
                fontSize: 10, color: AppColors.textSecondary,
              )),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDashed;
  const _ChartLegend({
    required this.color,
    required this.label,
    this.isDashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14, height: 3,
          decoration: BoxDecoration(
            color: isDashed ? null : color,
            border: isDashed ? Border.all(color: color) : null,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _FormulaRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  const _FormulaRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 12,
                color: isBold ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              )),
          Text(value,
              style: TextStyle(
                fontSize: 12,
                color: isBold ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                fontFamily: isBold ? null : 'monospace',
              )),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final String year;
  final int amount;
  final double yieldVal;
  final bool isPredicted;
  final String? trend;

  const _HistoryRow({
    required this.year,
    required this.amount,
    required this.yieldVal,
    required this.isPredicted,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isPredicted ? AppColors.bgPage : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isPredicted
            ? Border.all(color: AppColors.accent.withOpacity(0.3), width: 1)
            : Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          if (isPredicted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '예측',
                style: TextStyle(
                  color: AppColors.primary, fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Text(year,
              style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
              )),
          const Spacer(),
          if (trend != null && trend != '예측불가') ...[
            Icon(
              trend == '상승'
                  ? Icons.trending_up_rounded
                  : trend == '하락'
                      ? Icons.trending_down_rounded
                      : Icons.trending_flat_rounded,
              size: 14,
              color: trend == '상승'
                  ? AppColors.positive
                  : trend == '하락'
                      ? AppColors.negative
                      : AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
          ],
          Text(formatKRW(amount),
              style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
              )),
          const SizedBox(width: 8),
          Text(formatPct(yieldVal),
              style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary,
              )),
        ],
      ),
    );
  }
}
