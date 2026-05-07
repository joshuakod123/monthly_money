import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../algorithms/recommendation_engine.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'stock_detail_screen.dart';

/// ═══════════════════════════════════════════════════════════════════
///  CalendarScreen v3 — "월별 캐시플로우 다이어리"
///   • 12개월을 행(row) 단위로 표시 — 그리드보다 정보 밀도 ↑
///   • 막대 게이지로 월별 강도 시각화
///   • 월 번호 = 거대한 세리프 숫자 / 금액 = 모노폰트
///   • 비어있는 달은 점선으로 표시 (정보 위계 구분)
///   • 상단: ANNUAL × COVERAGE 두 메트릭
///   • 하단: 가장 많이 받는 달 / 비어있는 달 / 월별 평균
/// ═══════════════════════════════════════════════════════════════════
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  int? _highlightedMonth;

  void _showMonthDetail(int month, double amount, PortfolioRecommendation rec) {
    setState(() => _highlightedMonth = month);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: AppColors.textPrimary.withValues(alpha: 0.35),
      builder: (_) => _MonthDetailSheet(
        month: month,
        amount: amount,
        rec: rec,
      ),
    ).then((_) {
      if (mounted) setState(() => _highlightedMonth = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final rec = ref.watch(portfolioRecommendationProvider);
    final monthly = ref.watch(monthlyDividendCalendarProvider);

    if (rec == null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(
          child: Text(
            '퀴즈를 먼저 완료해주세요',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      );
    }

    final yearTotal = monthly.fold(0.0, (a, b) => a + b);
    final coverage = rec.coverageCount;
    final maxV = monthly.fold(0.0, (a, b) => a > b ? a : b);
    final avgMonth = yearTotal / 12;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 100),
          children: [
            // ─── HEADER ───
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: _PageHeader(
                yearTotal: yearTotal,
                coverage: coverage,
                avgMonth: avgMonth,
              ),
            ),
            const SizedBox(height: 24),

            // ─── SECTION LABEL ───
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: Row(
                children: [
                  Text(
                    AppCopy.calCashflow,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textTertiary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(height: 1, color: AppColors.borderSoft),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    AppCopy.calTapHint,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // ─── MONTH ROWS (the centerpiece) ───
            ...List.generate(12, (i) {
              final month = i + 1;
              return _MonthRow(
                month: month,
                amount: monthly[i],
                maxAmount: maxV,
                rec: rec,
                isHighlighted: _highlightedMonth == month,
                onTap: () => _showMonthDetail(month, monthly[i], rec),
              )
                  .animate()
                  .fadeIn(
                delay: Duration(milliseconds: 100 + i * 35),
                duration: 280.ms,
              )
                  .slideX(begin: 0.04, end: 0);
            }),

            const SizedBox(height: 32),

            // ─── ANNUAL RECEIPT ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _AnnualReceipt(monthly: monthly, rec: rec)
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 380.ms),
            ),

            const SizedBox(height: 24),
            Center(
              child: Text(
                AppCopy.footerSlow,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Page Header — 라벨 + 큰 제목 + 두 메트릭 박스
// ═══════════════════════════════════════════════════════════════════
class _PageHeader extends StatelessWidget {
  final double yearTotal;
  final int coverage;
  final double avgMonth;

  const _PageHeader({
    required this.yearTotal,
    required this.coverage,
    required this.avgMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 24, height: 1.5, color: AppColors.wine),
            const SizedBox(width: 10),
            Text(
              AppCopy.calLabel,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.wine,
                letterSpacing: 2.5,
              ),
            ),
            const Spacer(),
            Text(
              '${DateTime.now().year}',
              style: GoogleFonts.spaceMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 280.ms),
        const SizedBox(height: 14),
        Text(
          AppCopy.calTitle,
          style: GoogleFonts.playfairDisplay(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -1.2,
            height: 1.05,
          ),
        ).animate().fadeIn(delay: 100.ms, duration: 320.ms),
        const SizedBox(height: 4),
        Text(
          AppCopy.calSub,
          style: GoogleFonts.playfairDisplay(
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: AppColors.textTertiary,
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _StatBlock(
                label: AppCopy.calAnnual,
                primary: '₩${_fmtKRW(yearTotal.round())}',
                secondary: '월 평균 ₩${_fmtKRW(avgMonth.round())}',
                isPrimary: true,
              ),
            ),
            const SizedBox(width: 10),
            _CoverageBlock(coverage: coverage),
          ],
        ).animate().fadeIn(delay: 300.ms, duration: 380.ms).slideY(begin: 0.05),
      ],
    );
  }

  String _fmtKRW(int v) {
    if (v >= 100000000) return '${(v / 100000000).toStringAsFixed(2)}억';
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(0)}만';
    return _fmt(v);
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

class _StatBlock extends StatelessWidget {
  final String label;
  final String primary;
  final String secondary;
  final bool isPrimary;

  const _StatBlock({
    required this.label,
    required this.primary,
    required this.secondary,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: isPrimary ? AppColors.wineDeep : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: isPrimary
            ? null
            : Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isPrimary
                  ? AppColors.surface.withValues(alpha: 0.65)
                  : AppColors.textTertiary,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              primary,
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: isPrimary ? AppColors.surface : AppColors.wineDeep,
                letterSpacing: -1.2,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            secondary,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: isPrimary
                  ? AppColors.surface.withValues(alpha: 0.55)
                  : AppColors.textTertiary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverageBlock extends StatelessWidget {
  final int coverage;
  const _CoverageBlock({required this.coverage});

  @override
  Widget build(BuildContext context) {
    final isFull = coverage == 12;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isFull ? AppColors.gold : AppColors.border,
          width: isFull ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            AppCopy.calCoverage,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.textTertiary,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$coverage',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: isFull ? AppColors.gold : AppColors.wineDeep,
                  letterSpacing: -1.5,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4, left: 1),
                child: Text(
                  '/12',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isFull ? '완벽' : '${12 - coverage}월 비어있음',
            style: GoogleFonts.inter(
              fontSize: 9,
              color: isFull ? AppColors.gold : AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Month Row — 한 달을 한 줄로
//   ┌────────────────────────────────────────────────┐
//   │ 03월  ▓▓▓▓▓▓▓▓░░  ₩125,000   3종목 →         │
//   │ March                                          │
//   └────────────────────────────────────────────────┘
// ═══════════════════════════════════════════════════════════════════
class _MonthRow extends StatelessWidget {
  final int month;
  final double amount;
  final double maxAmount;
  final PortfolioRecommendation rec;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _MonthRow({
    required this.month,
    required this.amount,
    required this.maxAmount,
    required this.rec,
    required this.isHighlighted,
    required this.onTap,
  });

  static const _monthNamesEn = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final isEmpty = amount == 0;
    final intensity =
    maxAmount > 0 ? (amount / maxAmount).clamp(0.0, 1.0) : 0.0;
    final stockCount = rec.picks
        .where((p) => p.stock.paymentMonths.contains(month))
        .length;

    final isCurrentMonth = month == DateTime.now().month;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.symmetric(
          horizontal: isHighlighted ? 18 : 24,
          vertical: 1,
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: isHighlighted
              ? AppColors.surface
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: isHighlighted
              ? Border.all(color: AppColors.wine, width: 1.5)
              : Border(
            bottom: BorderSide(
              color: AppColors.borderSoft.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── 월 번호 (큰 세리프) + 영문월
            SizedBox(
              width: 56,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        month.toString().padLeft(2, '0'),
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: isEmpty
                              ? AppColors.textDisabled
                              : AppColors.textPrimary,
                          letterSpacing: -1.5,
                          height: 1,
                        ),
                      ),
                      if (isCurrentMonth) ...[
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: AppColors.wine,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _monthNamesEn[month - 1].toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                      letterSpacing: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),

            // ── 게이지 + 금액 + 종목수
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 금액
                  Row(
                    children: [
                      if (isEmpty)
                        Text(
                          '배당 없음',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textDisabled,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else
                        Text(
                          '₩${_fmt(amount.round())}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: intensity > 0.6
                                ? AppColors.wineDeep
                                : AppColors.textPrimary,
                            letterSpacing: -0.4,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      const Spacer(),
                      if (stockCount > 0)
                        Text(
                          '$stockCount종목',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textTertiary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 게이지
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Container(
                      height: 4,
                      color: AppColors.borderSoft.withValues(alpha: 0.5),
                      child: isEmpty
                          ? CustomPaint(
                        painter: _DashedLinePainter(
                          color: AppColors.borderStrong,
                        ),
                      )
                          : Align(
                        alignment: Alignment.centerLeft,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: intensity),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (context, v, _) {
                            return FractionallySizedBox(
                              widthFactor: v,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.wine,
                                      AppColors.wineDeep,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isEmpty
                  ? AppColors.textDisabled
                  : AppColors.textTertiary,
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

// 점선 게이지 (배당 없는 달)
class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    const dash = 3.0;
    const gap = 3.0;
    double x = 0;
    final y = size.height / 2;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dash, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) => old.color != color;
}

// ═══════════════════════════════════════════════════════════════════
//  Month Detail Sheet — 월별 종목 상세
// ═══════════════════════════════════════════════════════════════════
class _MonthDetailSheet extends StatelessWidget {
  final int month;
  final double amount;
  final PortfolioRecommendation rec;

  const _MonthDetailSheet({
    required this.month,
    required this.amount,
    required this.rec,
  });

  static const _monthNamesEn = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final isEmpty = amount == 0;
    final picks = rec.picks
        .where((p) => p.stock.paymentMonths.contains(month))
        .toList()
      ..sort((a, b) => b.weightOfTotal.compareTo(a.weightOfTotal));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.canvas,
            borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Top bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
                child: Row(
                  children: [
                    Container(width: 18, height: 1.5, color: AppColors.wine),
                    const SizedBox(width: 8),
                    Text(
                      _monthNamesEn[month - 1].toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.wine,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                          BorderRadius.circular(AppRadius.full),
                          border:
                          Border.all(color: AppColors.border, width: 1),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Big month + amount
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$month',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 56,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -2.5,
                        height: 0.9,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 2),
                      child: Text(
                        '월',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textTertiary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (!isEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'TOTAL',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textTertiary,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₩${_fmt(amount.round())}',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppColors.wineDeep,
                              letterSpacing: -0.8,
                              height: 1,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        '배당 없음',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textTertiary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                height: 1,
                color: AppColors.borderSoft,
              ),
              // List of stocks
              Expanded(
                child: isEmpty || picks.isEmpty
                    ? _EmptyState()
                    : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  itemCount: picks.length,
                  itemBuilder: (context, i) {
                    final pick = picks[i];
                    return _DetailRow(
                      pick: pick,
                      index: i + 1,
                      isLast: i == picks.length - 1,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StockDetailScreen(
                              stock: pick.stock,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                color: AppColors.textTertiary,
                size: 22,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              AppCopy.calNoDividend,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              AppCopy.calNoDivHint,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final PortfolioPick pick;
  final int index;
  final bool isLast;
  final VoidCallback onTap;

  const _DetailRow({
    required this.pick,
    required this.index,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final stock = pick.stock;
    final palette = AppColors.paletteFor(stock.sector.name);
    final annual = stock.dividendPerShare > 0
        ? stock.dividendPerShare
        : stock.latestDividend;
    final amount = stock.paymentMonths.isNotEmpty
        ? (annual / stock.paymentMonths.length) * pick.shares
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
            bottom: BorderSide(color: AppColors.borderSoft, width: 1),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                index.toString().padLeft(2, '0'),
                style: GoogleFonts.spaceMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 5,
              height: 36,
              decoration: BoxDecoration(
                color: palette.bg,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stock.name,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        palette.label,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: palette.bg,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        ' · ${pick.shares}주 · ${stock.frequency.label}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '+₩${_fmt(amount.round())}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.wine,
                letterSpacing: -0.2,
                fontFeatures: const [FontFeature.tabularFigures()],
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

// ═══════════════════════════════════════════════════════════════════
//  Annual Receipt — 영수증 스타일
// ═══════════════════════════════════════════════════════════════════
class _AnnualReceipt extends StatelessWidget {
  final List<double> monthly;
  final PortfolioRecommendation rec;

  const _AnnualReceipt({required this.monthly, required this.rec});

  @override
  Widget build(BuildContext context) {
    final maxMonth = _findMaxMonth(monthly);
    final emptyMonths = <int>[];
    for (var i = 0; i < monthly.length; i++) {
      if (monthly[i] == 0) emptyMonths.add(i + 1);
    }

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.wine,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  AppCopy.calYearReport,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.surface,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'NO. ${DateTime.now().year}',
                style: GoogleFonts.spaceMono(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ReceiptRow(
            label: '가장 많이 받는 달',
            value: maxMonth > 0
                ? '$maxMonth월 · ₩${_fmt(monthly[maxMonth - 1].round())}'
                : '—',
            highlight: true,
          ),
          _ReceiptRow(
            label: '비어있는 달',
            value: emptyMonths.isEmpty
                ? '없음'
                : emptyMonths.map((m) => '$m').join(', ') + '월',
          ),
          _ReceiptRow(
            label: '종목 수',
            value: '${rec.picks.length}개',
          ),
        ],
      ),
    );
  }

  int _findMaxMonth(List<double> monthly) {
    int idx = -1;
    double max = 0;
    for (var i = 0; i < monthly.length; i++) {
      if (monthly[i] > max) {
        max = monthly[i];
        idx = i;
      }
    }
    return idx + 1;
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
  final bool highlight;
  const _ReceiptRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: CustomPaint(
                size: const Size.fromHeight(1),
                painter: _DashedLinePainter(color: AppColors.borderStrong),
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: highlight ? AppColors.wineDeep : AppColors.textPrimary,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: -0.2,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
