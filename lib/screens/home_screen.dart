import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/stock_model.dart';
import '../providers/app_providers.dart';
import '../algorithms/recommendation_engine.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'stock_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final persona = ref.watch(personaProfileProvider);
    final rec = ref.watch(portfolioRecommendationProvider);
    final forecast = ref.watch(portfolioForecastProvider);

    if (persona == null || rec == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 헤더 — 퍼소나 요약
              Text('당신은',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  )),
              const SizedBox(height: 4),
              Text(
                persona.summarize(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(duration: 300.ms),
              const SizedBox(height: 4),
              Text(
                '${persona.picks(rec)}개 종목으로 월 ${formatKRW(rec.totalMonthlyDividend.round())} 받는 포트폴리오를 추천해요',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 28),

              // ── 핵심 KPI 카드 (월 배당 / 총 투자금 / 분산도)
              _SummaryCard(rec: rec, forecast: forecast),

              const SizedBox(height: 24),

              // ── 도넛 차트 (섹터별 비중)
              _SectorDonut(rec: rec)
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 400.ms),

              const SizedBox(height: 24),

              // ── 추천 이유
              _RationaleCard(reasons: rec.rationale())
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: 24),

              // ── 종목 리스트 (비중 큰 순)
              const Text('포트폴리오 구성',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  )),
              const SizedBox(height: 12),
              ...rec.picks.asMap().entries.map((entry) {
                final i = entry.key;
                final pick = entry.value;
                return _PickCard(pick: pick)
                    .animate()
                    .fadeIn(
                  delay: Duration(milliseconds: 300 + i * 60),
                  duration: 380.ms,
                )
                    .slideY(begin: 0.08);
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── helper extension ─────────────────────────────
extension on dynamic {
  int picks(PortfolioRecommendation rec) => rec.picks.length;
}

// ─── 요약 카드 ────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final PortfolioRecommendation rec;
  final dynamic forecast; // PortfolioForecast?
  const _SummaryCard({required this.rec, required this.forecast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.18),
            AppColors.bgCard,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('월 예상 배당',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            formatKRW(rec.totalMonthlyDividend.round()),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          Text('목표 ${formatKRW(rec.persona.monthlyTarget)} 대비 '
              '${((rec.totalMonthlyDividend / rec.persona.monthlyTarget) * 100).round()}%',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              )),
          const Divider(color: AppColors.border, height: 28),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: '필요 투자금',
                  value: formatKRW(rec.totalInvestment),
                ),
              ),
              Container(width: 1, height: 30, color: AppColors.border),
              Expanded(
                child: _MiniStat(
                  label: '분산 점수',
                  value: '${(rec.diversityScore * 100).round()}점',
                ),
              ),
              Container(width: 1, height: 30, color: AppColors.border),
              Expanded(
                child: _MiniStat(
                  label: '종목 수',
                  value: '${rec.picks.length}개',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
          )),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          )),
    ],
  );
}

// ─── 섹터 도넛 차트 ──────────────────────────────
class _SectorDonut extends StatelessWidget {
  final PortfolioRecommendation rec;
  const _SectorDonut({required this.rec});

  @override
  Widget build(BuildContext context) {
    final breakdown = rec.sectorBreakdown;
    if (breakdown.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('섹터별 비중',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: PieChart(
                  PieChartData(
                    sections: breakdown.entries.map((e) {
                      return PieChartSectionData(
                        value: e.value,
                        color: e.key.defaultColor,
                        radius: 26,
                        showTitle: false,
                      );
                    }).toList(),
                    centerSpaceRadius: 38,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: breakdown.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: e.key.defaultColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${e.key.emoji} ${e.key.label}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              )),
                          const Spacer(),
                          Text('${(e.value * 100).round()}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              )),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── 추천 이유 ────────────────────────────────────
class _RationaleCard extends StatelessWidget {
  final List<String> reasons;
  const _RationaleCard({required this.reasons});

  @override
  Widget build(BuildContext context) {
    if (reasons.isEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome_rounded,
                  color: AppColors.accent, size: 18),
              SizedBox(width: 6),
              Text('이렇게 추천한 이유',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          ...reasons.map((r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(Icons.circle,
                      color: AppColors.accent, size: 5),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(r,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      )),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ─── 종목 카드 ────────────────────────────────────
class _PickCard extends StatelessWidget {
  final PortfolioPick pick;
  const _PickCard({required this.pick});

  @override
  Widget build(BuildContext context) {
    final stock = pick.stock;
    final weightPct = (pick.weightOfTotal * 100).round();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StockDetailScreen(stock: stock)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: stock.sectorColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(stock.sector.emoji,
                      style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stock.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          )),
                      const SizedBox(height: 2),
                      Text('${pick.shares}주 매수 · ${stock.frequency.label}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          )),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('$weightPct%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 비중 바
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: pick.weightOfTotal,
                minHeight: 4,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(stock.sectorColor),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _PickStat(
                    label: '매수금', value: formatKRW(pick.cost.round())),
                const SizedBox(width: 16),
                _PickStat(
                    label: '월 배당',
                    value: formatKRW(pick.monthlyDividend.round())),
                const Spacer(),
                _PickStat(
                    label: '수익률',
                    value: formatPct(stock.dividendYield),
                    highlight: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PickStat extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _PickStat(
      {required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            )),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: highlight ? AppColors.primary : AppColors.textPrimary,
            )),
      ],
    );
  }
}