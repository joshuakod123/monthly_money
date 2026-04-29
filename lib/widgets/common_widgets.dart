import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/stock_model.dart';
import '../services/forecast_engine.dart';
import '../theme/app_theme.dart';

final _krw = NumberFormat('#,###', 'ko_KR');
String formatKRW(num value) => '₩${_krw.format(value.round())}';
String formatPct(double v) => '${v.toStringAsFixed(1)}%';

// ─────────────────────────────────────────
// 목표 달성률 카드 (홈 상단)
// ─────────────────────────────────────────
class GoalProgressCard extends StatelessWidget {
  final int targetAmount;
  final int currentAmount;
  final int futureExpected;
  final int targetYear;

  const GoalProgressCard({
    super.key,
    required this.targetAmount,
    required this.currentAmount,
    required this.futureExpected,
    required this.targetYear,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentAmount / targetAmount).clamp(0.0, 1.0);
    final futureProgress = (futureExpected / targetAmount).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '월 배당 목표',
                style: TextStyle(
                  color: Colors.white54, fontSize: 11,
                  letterSpacing: 1, fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$targetYear년 예상',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 10, fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: formatKRW(targetAmount),
                  style: const TextStyle(
                    color: Colors.white, fontSize: 32,
                    fontWeight: FontWeight.w700, letterSpacing: -1,
                  ),
                ),
                const TextSpan(
                  text: ' / 월',
                  style: TextStyle(
                    color: AppColors.accent, fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '현재 ${formatKRW(currentAmount)} · ${(progress * 100).toStringAsFixed(0)}% 달성',
            style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12),
          ),
          const SizedBox(height: 14),
          // 이중 프로그레스 바 (현재 + 미래 예측)
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  color: Colors.white.withOpacity(0.12),
                ),
                FractionallySizedBox(
                  widthFactor: futureProgress,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.4),
                    ),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 8,
                    color: AppColors.accent,
                  ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.3, end: 0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _LegendDot(color: AppColors.accent, label: '현재'),
              const SizedBox(width: 12),
              _LegendDot(
                color: AppColors.accent.withOpacity(0.4),
                label: '$targetYear년 예측',
              ),
            ],
          ),
        ],
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
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
      ],
    );
  }
}

// ─────────────────────────────────────────
// 투자금 계산 카드 (AI 추정)
// ─────────────────────────────────────────
class InvestmentCalcCard extends StatelessWidget {
  final int totalInvestment;
  final double avgYield;
  final double confidence;

  const InvestmentCalcCard({
    super.key,
    required this.totalInvestment,
    required this.avgYield,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
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
              Text(
                '목표 달성에 필요한 투자금',
                style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 12, color: AppColors.primary),
                    SizedBox(width: 4),
                    Text(
                      'AI 예측',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11, fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatKRW(totalInvestment),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26, fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  '추정',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MiniInfoChip(
                label: '평균 수익률',
                value: formatPct(avgYield),
              ),
              const SizedBox(width: 8),
              _MiniInfoChip(
                label: '신뢰도',
                value: '${(confidence * 100).toStringAsFixed(0)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniInfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _MiniInfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// 주식 카드 (예측 정보 포함)
// ─────────────────────────────────────────
class StockCard extends StatelessWidget {
  final StockModel stock;
  final VoidCallback? onTap;

  const StockCard({super.key, required this.stock, this.onTap});

  @override
  Widget build(BuildContext context) {
    final forecasts = ForecastEngine.forecast(stock, years: 3);
    final futureForecast = forecasts.isNotEmpty ? forecasts.last : null;
    final trendColor = _trendColor(futureForecast?.trend);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: stock.sectorColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(stock.sector.emoji, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            stock.name,
                            style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (stock.isRecommended)
                            const Icon(Icons.star_rounded, color: AppColors.accentWarm, size: 16),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${stock.code} · ${stock.sector.label}',
                        style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.positiveBg,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          stock.frequency.label,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.positive,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatPct(stock.dividendYield),
                      style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                    const Text(
                      '배당수익률',
                      style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatKRW(stock.price),
                      style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // 예측 정보 미니 푸터
            if (futureForecast != null && futureForecast.predictedAmount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.bgPage,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(_trendIcon(futureForecast.trend), size: 14, color: trendColor),
                    const SizedBox(width: 6),
                    Text(
                      '${futureForecast.year}년 예상',
                      style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '주당 ${formatKRW(futureForecast.predictedAmount)}',
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: trendColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '· ${formatPct(futureForecast.predictedYield)}',
                      style: TextStyle(
                        fontSize: 11, color: trendColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _trendColor(String? trend) {
    switch (trend) {
      case '상승': return AppColors.positive;
      case '하락': return AppColors.negative;
      default: return AppColors.textSecondary;
    }
  }

  IconData _trendIcon(String trend) {
    switch (trend) {
      case '상승': return Icons.trending_up_rounded;
      case '하락': return Icons.trending_down_rounded;
      default: return Icons.trending_flat_rounded;
    }
  }
}

// ─────────────────────────────────────────
// 섹터 칩
// ─────────────────────────────────────────
class SectorChip extends StatelessWidget {
  final StockSector sector;
  final bool isActive;
  final VoidCallback onTap;

  const SectorChip({
    super.key,
    required this.sector,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(sector.emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              sector.label,
              style: TextStyle(
                color: isActive ? AppColors.accent : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 성향 칩
// ─────────────────────────────────────────
class ProfileChip extends StatelessWidget {
  final InvestmentProfile profile;
  final bool isActive;
  final VoidCallback onTap;

  const ProfileChip({
    super.key,
    required this.profile,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.only(right: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFF0DB) : Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: isActive ? AppColors.accentWarm : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          profile.label,
          style: TextStyle(
            color: isActive ? const Color(0xFF9A5E00) : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
