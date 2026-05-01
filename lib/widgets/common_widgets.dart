import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/stock_model.dart';
import '../theme/app_theme.dart';

final _krw = NumberFormat('#,###', 'ko_KR');
String formatKRW(num value) => '₩${_krw.format(value.round())}';
String formatPct(double v) => '${v.toStringAsFixed(1)}%';

// ─────────────────────────────────────────
// AI 투자금 계산 카드 (에러 해결)
// ─────────────────────────────────────────
class InvestmentCalcCard extends StatelessWidget {
  final int totalInvestment;
  final double avgYield;
  final double confidence;

  const InvestmentCalcCard({super.key, required this.totalInvestment, required this.avgYield, required this.confidence});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('목표 달성에 필요한 총 투자금', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(formatKRW(totalInvestment), style: const TextStyle(color: AppColors.primary, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -1)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// 섹터 칩 (에러 해결)
// ─────────────────────────────────────────
class SectorChip extends StatelessWidget {
  final StockSector sector;
  final bool isActive;
  final VoidCallback onTap;

  const SectorChip({super.key, required this.sector, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.bgCard,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: isActive ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            Text(sector.emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(sector.label, style: TextStyle(
              color: isActive ? Colors.black : AppColors.textSecondary,
              fontSize: 13, fontWeight: FontWeight.w600,
            )),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 목표 달성률 카드
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
    final progress = targetAmount == 0
        ? 0.0
        : (currentAmount / targetAmount).clamp(0.0, 1.0);
    final percent = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('월 배당 목표 달성률',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatKRW(currentAmount),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  )),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('/ ${formatKRW(targetAmount)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$percent% 달성',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  )),
              Text('$targetYear년 예상 ${formatKRW(futureExpected)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// 종목 카드 (홈 리스트용)
// ─────────────────────────────────────────
class StockCard extends StatelessWidget {
  final StockModel stock;
  final VoidCallback onTap;

  const StockCard({super.key, required this.stock, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
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
                  Text('${stock.code} · ${stock.frequency.label}',
                      style: const TextStyle(
                        fontSize: 11,
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
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 2),
                Text(formatPct(stock.dividendYield),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 섹터 칩에 'all' 처리 추가 (선택 표시 개선)
// ─────────────────────────────────────────