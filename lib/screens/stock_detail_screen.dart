import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/stock_model.dart';
import '../services/forecast_engine.dart';
import '../theme/app_theme.dart';

class StockDetailScreen extends ConsumerWidget {
  final StockModel stock;
  const StockDetailScreen({super.key, required this.stock});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecasts = ForecastEngine.forecast(stock, years: 3);
    final palette = AppColors.paletteFor(stock.sector.name);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                              borderRadius:
                              BorderRadius.circular(AppRadius.full),
                              border: Border.all(
                                  color: AppColors.border, width: 1),
                            ),
                            child: const Icon(Icons.arrow_back_rounded,
                                size: 16, color: AppColors.textPrimary),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: palette.bg,
                            borderRadius:
                            BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(
                            palette.label,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: palette.onBg,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Container(
                            width: 18, height: 1, color: AppColors.wine),
                        const SizedBox(width: 6),
                        Text(
                          AppCopy.stockLabel,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.wine,
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          stock.code,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 280.ms),

                    const SizedBox(height: 8),
                    Text(
                      stock.name,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -1.2,
                        height: 1.05,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 320.ms)
                        .slideY(begin: 0.05),

                    const SizedBox(height: 4),
                    Text(
                      stock.sector.label,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textTertiary,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border:
                        Border.all(color: AppColors.border, width: 1),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppCopy.stockPrice,
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textTertiary,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '₩${_fmt(stock.price.round())}',
                                  style: GoogleFonts.inter(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.8,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 50,
                            color: AppColors.borderSoft,
                            margin:
                            const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  AppCopy.stockYield,
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textTertiary,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${stock.dividendYield.toStringAsFixed(2)}%',
                                  style: GoogleFonts.inter(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.wine,
                                    letterSpacing: -0.8,
                                    height: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 380.ms),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        _SmallMetric(label: 'PER', value: '${stock.per}'),
                        const SizedBox(width: 8),
                        _SmallMetric(label: 'PBR', value: '${stock.pbr}'),
                        const SizedBox(width: 8),
                        _SmallMetric(
                            label: 'ROE',
                            value: '${stock.roe.toStringAsFixed(1)}%'),
                        const SizedBox(width: 8),
                        _SmallMetric(label: 'RISK', value: stock.riskLevel),
                      ],
                    ).animate().fadeIn(delay: 300.ms, duration: 380.ms),
                  ],
                ),
              ),
            ),

            if (stock.history.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              AppCopy.stockHistory,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textTertiary,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const Spacer(),
                            _LegendDot(
                                color: AppColors.wine,
                                label: AppCopy.stockHistoryReal),
                            const SizedBox(width: 8),
                            _LegendDot(
                                color: AppColors.gold,
                                label: AppCopy.stockHistoryEst),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 160,
                          child: _HistoryChart(
                              stock: stock, forecasts: forecasts),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 380.ms),
              ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                child: Container(
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.wine,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          AppCopy.stockYearly,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.surface,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...forecasts.reversed.map((f) => _YearRow(
                        year: '${f.year}',
                        amount: f.predictedAmount,
                        isPredicted: true,
                      )),
                      ...([...stock.history].reversed).map((h) => _YearRow(
                        year: '${h.year}',
                        amount: h.amount,
                        isPredicted: false,
                      )),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 380.ms),
              ),
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

class _SmallMetric extends StatelessWidget {
  final String label;
  final String value;
  const _SmallMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.borderSoft, width: 1),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
    final forecastSpots = forecasts.isNotEmpty && spots.isNotEmpty
        ? [
      spots.last,
      ...forecasts.map(
              (f) => FlSpot(f.year.toDouble(), f.predictedAmount.toDouble())),
    ]
        : <FlSpot>[];

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
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
              getTitlesWidget: (v, _) => Text(
                "'${v.toInt() % 100}",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.wine,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 3.5,
                color: AppColors.wine,
                strokeWidth: 0,
              ),
            ),
          ),
          if (forecastSpots.isNotEmpty)
            LineChartBarData(
              spots: forecastSpots,
              isCurved: true,
              color: AppColors.gold,
              barWidth: 2,
              dashArray: [5, 4],
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 3,
                  color: AppColors.gold,
                  strokeWidth: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _YearRow extends StatelessWidget {
  final String year;
  final int amount;
  final bool isPredicted;
  const _YearRow({
    required this.year,
    required this.amount,
    required this.isPredicted,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          if (isPredicted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Text(
                'EST',
                style: GoogleFonts.inter(
                  color: AppColors.gold,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          Text(
            year,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const Spacer(),
          Text(
            '₩${_fmt(amount)}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isPredicted ? AppColors.gold : AppColors.textPrimary,
              letterSpacing: -0.2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
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
