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

// (GoalProgressCard 및 StockCard는 기존과 동일 구조 유지, 테마만 AppColors 활용)