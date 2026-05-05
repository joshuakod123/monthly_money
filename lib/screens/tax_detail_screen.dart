import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../algorithms/tax_calculator.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';

class TaxDetailScreen extends ConsumerWidget {
  const TaxDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rec = ref.watch(portfolioRecommendationProvider);

    if (rec == null) {
      return const Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(child: Text('포트폴리오가 없어요')),
      );
    }

    final tax = TaxCalculator.calculate(
      monthlyDividend: rec.totalMonthlyDividend.round(),
    );

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
          children: [
            // ── 상단 바
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        size: 16, color: AppColors.textPrimary),
                  ),
                ),
                const Spacer(),
              ],
            ),

            const SizedBox(height: 20),

            // ── 라벨
            Row(
              children: [
                Container(width: 24, height: 1.5, color: AppColors.wine),
                const SizedBox(width: 10),
                Text(
                  'TAX BREAKDOWN',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.wine,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 280.ms),

            const SizedBox(height: 12),

            Text(
              '세후 실수령',
              style: GoogleFonts.playfairDisplay(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -1,
                height: 1.1,
              ),
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 4),
            Text(
              'After-Tax Income',
              style: GoogleFonts.playfairDisplay(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppColors.textTertiary,
              ),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 24),

            // ── 메인 카드: 세전 vs 세후
            _MainCard(tax: tax)
                .animate()
                .fadeIn(delay: 300.ms, duration: 380.ms)
                .slideY(begin: 0.05),

            const SizedBox(height: 24),

            // ── 세금 분해 영수증
            _SectionLabel(label: 'BREAKDOWN'),
            const SizedBox(height: 12),
            _ReceiptCard(tax: tax)
                .animate()
                .fadeIn(delay: 450.ms, duration: 380.ms),

            const SizedBox(height: 24),

            // ── 종합과세 경고
            if (tax.isComprehensiveTaxable)
              _ComprehensiveWarning(tax: tax)
                  .animate()
                  .fadeIn(delay: 550.ms, duration: 380.ms),

            if (tax.isComprehensiveTaxable) const SizedBox(height: 24),

            // ── 절세 팁
            _SectionLabel(label: 'TAX SAVING TIPS'),
            const SizedBox(height: 12),
            ...tax.tips.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _TipCard(tip: entry.value)
                    .animate()
                    .fadeIn(
                  delay: Duration(milliseconds: 650 + entry.key * 80),
                  duration: 320.ms,
                )
                    .slideX(begin: 0.03),
              );
            }),

            const SizedBox(height: 16),

            // ── 면책 조항
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceWarm,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.borderSoft, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '이 계산은 일반적 추정치예요. 정확한 세금은 개인 상황(부양가족·의료비·기부금 등)에 따라 달라지므로 세무사 상담을 권장합니다.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Center(
              child: Text(
                '· 천천히 익어가는 자산 ·',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainCard extends StatelessWidget {
  final TaxBreakdown tax;
  const _MainCard({required this.tax});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.wine, AppColors.wineDeep],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 1,
                color: AppColors.surface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                'NET MONTHLY',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.surface.withValues(alpha: 0.8),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '₩',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  color: AppColors.surface,
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _fmt(tax.monthlyNet),
                style: GoogleFonts.inter(
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                  color: AppColors.surface,
                  letterSpacing: -2,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 1,
            color: AppColors.surface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  label: '세전 월',
                  value: '₩${_fmt(tax.annualDividendGross ~/ 12)}',
                  fg: AppColors.surface,
                ),
              ),
              Expanded(
                child: _MiniMetric(
                  label: '세금 비율',
                  value: '${(tax.effectiveTaxRate * 100).toStringAsFixed(1)}%',
                  fg: AppColors.surface,
                ),
              ),
              Expanded(
                child: _MiniMetric(
                  label: '연 세후',
                  value: '₩${_fmt(tax.annualDividendNet)}',
                  fg: AppColors.surface,
                  alignEnd: true,
                ),
              ),
            ],
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

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color fg;
  final bool alignEnd;

  const _MiniMetric({
    required this.label,
    required this.value,
    required this.fg,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9,
            color: fg.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: fg,
            letterSpacing: -0.3,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: AppColors.borderSoft)),
      ],
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  final TaxBreakdown tax;
  const _ReceiptCard({required this.tax});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.wine,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              'TAX RECEIPT',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.surface,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _ReceiptRow(
            label: '연 배당 (세전)',
            value: '₩${_fmt(tax.annualDividendGross)}',
            isPositive: true,
          ),
          const SizedBox(height: 8),
          _Dotted(),
          const SizedBox(height: 8),
          _ReceiptRow(
            label: '원천징수 (15.4%)',
            value: '−₩${_fmt(tax.withholdingTax)}',
            isNegative: true,
          ),
          if (tax.comprehensiveTaxAdditional > 0)
            _ReceiptRow(
              label: '종합과세 추가분',
              value: '−₩${_fmt(tax.comprehensiveTaxAdditional)}',
              isNegative: true,
            ),
          const SizedBox(height: 8),
          _Dotted(),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '실수령 (연)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '₩${_fmt(tax.annualDividendNet)}',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.wineDeep,
                  letterSpacing: -0.5,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
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

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isPositive;
  final bool isNegative;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.isPositive = false,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    Color valueColor = AppColors.textPrimary;
    if (isNegative) valueColor = AppColors.wine;
    if (isPositive) valueColor = AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor,
              letterSpacing: -0.2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dotted extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final dotCount = (c.maxWidth / 4).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dotCount,
                (i) => Container(
              width: 1.5,
              height: 1.5,
              decoration: const BoxDecoration(
                color: AppColors.borderStrong,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ComprehensiveWarning extends StatelessWidget {
  final TaxBreakdown tax;
  const _ComprehensiveWarning({required this.tax});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '종합과세 대상',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '연 금융소득 2,000만원 초과로 종합과세 대상이에요. 적용 세율 ${(tax.comprehensiveRate * 100).toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final TaxTip tip;
  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    Color priorityColor;
    switch (tip.priority) {
      case TaxTipPriority.high:
        priorityColor = AppColors.wine;
        break;
      case TaxTipPriority.medium:
        priorityColor = AppColors.gold;
        break;
      case TaxTipPriority.low:
        priorityColor = AppColors.textTertiary;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: priorityColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip.description,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}