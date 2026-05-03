import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stock_model.dart';
import '../services/forecast_engine.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class StockDetailScreen extends ConsumerWidget {
  final StockModel stock;
  const StockDetailScreen({super.key, required this.stock});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecasts = ForecastEngine.forecast(stock, years: 3);

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: Text(stock.name),
        backgroundColor: AppColors.bgPage,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 종목 헤더
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: stock.sectorColor.withValues(alpha: 0.18),
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
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
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
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              )),
                          Text(formatPct(stock.dividendYield),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              )),
                        ],
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.border, height: 24),
                  Row(
                    children: [
                      _MetricBox(label: 'PER', value: '${stock.per}'),
                      _MetricBox(label: 'PBR', value: '${stock.pbr}'),
                      _MetricBox(label: 'ROE', value: '${stock.roe.toStringAsFixed(1)}%'),
                      _MetricBox(label: '리스크', value: stock.riskLevel),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 배당 차트
            if (stock.history.isNotEmpty)
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
                    const Text('배당금 추세',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        )),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: _HistoryChart(stock: stock, forecasts: forecasts),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // 배당 이력 테이블
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
                  const Text('연도별 배당',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      )),
                  const SizedBox(height: 12),
                  ...forecasts.reversed.map((f) => _HistoryRow(
                    year: '${f.year}',
                    amount: f.predictedAmount,
                    isPredicted: true,
                  )),
                  ...([...stock.history].reversed).map((h) => _HistoryRow(
                    year: '${h.year}',
                    amount: h.amount,
                    isPredicted: false,
                  )),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _HistoryChart extends StatelessWidget {
  final StockModel stock;
  final List<DividendForecast> forecasts;
  const _HistoryChart({required this.stock, required this.forecasts});

  @override
  Widget build(BuildContext context) {
    final history = [...stock.history]..sort((a, b) => a.year.compareTo(b.year));
    final spots = history
        .map((h) => FlSpot(h.year.toDouble(), h.amount.toDouble()))
        .toList();
    final forecastSpots = forecasts.isNotEmpty
        ? [
      spots.last,
      ...forecasts.map((f) => FlSpot(f.year.toDouble(), f.predictedAmount.toDouble())),
    ]
        : <FlSpot>[];

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (v, _) => Text("'${v.toInt() % 100}",
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textHint,
                  )),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
          if (forecastSpots.isNotEmpty)
            LineChartBarData(
              spots: forecastSpots,
              isCurved: true,
              color: AppColors.accent,
              barWidth: 2,
              dashArray: [6, 4],
              dotData: const FlDotData(show: true),
            ),
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
                fontSize: 10,
                color: AppColors.textSecondary,
              )),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final String year;
  final int amount;
  final bool isPredicted;
  const _HistoryRow(
      {required this.year, required this.amount, required this.isPredicted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (isPredicted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('예측',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  )),
            ),
          Text(year,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              )),
          const Spacer(),
          Text(formatKRW(amount),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
        ],
      ),
    );
  }
}