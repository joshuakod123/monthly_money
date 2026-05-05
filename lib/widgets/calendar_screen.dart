import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../algorithms/recommendation_engine.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';

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
      barrierColor: AppColors.textPrimary.withValues(alpha: 0.25),
      builder: (context) => _MonthDetailSheet(
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
        body: const Center(
          child: Text(
            '퀴즈를 먼저 완료해주세요',
            style: TextStyle(color: AppColors.textTertiary),
          ),
        ),
      );
    }

    final yearTotal = monthly.fold(0.0, (a, b) => a + b);
    final coverage = rec.coverageCount;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
          children: [
            // ── 헤더 라벨
            Row(
              children: [
                Container(width: 24, height: 1.5, color: AppColors.wine),
                const SizedBox(width: 10),
                Text(
                  'CALENDAR',
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
              '배당 캘린더',
              style: GoogleFonts.playfairDisplay(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -1,
                height: 1.1,
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 320.ms),

            const SizedBox(height: 4),

            Text(
              'Calendarium Dividendi',
              style: GoogleFonts.playfairDisplay(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppColors.textTertiary,
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 320.ms),

            const SizedBox(height: 20),

            // ── 헤더 카드
            _Header(yearTotal: yearTotal, coverage: coverage)
                .animate()
                .fadeIn(delay: 300.ms, duration: 380.ms)
                .slideY(begin: 0.05),

            const SizedBox(height: 24),

            // ── CASH FLOW 라벨
            Row(
              children: [
                Text(
                  'CASH FLOW',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(height: 1, color: AppColors.borderSoft),
                ),
                const SizedBox(width: 8),
                Text(
                  '월별 탭 →',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── 12개월 그리드 (전체 표시 - 가리지 않음)
            _MonthGrid(
              monthly: monthly,
              rec: rec,
              highlightedMonth: _highlightedMonth,
              onTap: (month) =>
                  _showMonthDetail(month, monthly[month - 1], rec),
            ),

            const SizedBox(height: 24),

            // ── 영수증 섹션 (월별 합계)
            _AnnualReceipt(monthly: monthly, rec: rec)
                .animate()
                .fadeIn(delay: 600.ms, duration: 380.ms),

            const SizedBox(height: 24),

            Center(
              child: Text(
                '· 시간이 자산을 익혀줍니다 ·',
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

// ═══════════════════════════════════════════════════════════
//  Header — Annual + Coverage
// ═══════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final double yearTotal;
  final int coverage;

  const _Header({required this.yearTotal, required this.coverage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ANNUAL',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '₩',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.wine,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _fmt(yearTotal.round()),
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.wineDeep,
                            letterSpacing: -1.2,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '월 평균 ₩${_fmt((yearTotal / 12).round())}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 60,
            color: AppColors.borderSoft,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'COVERAGE',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$coverage',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: coverage == 12
                          ? AppColors.gold
                          : AppColors.wineDeep,
                      letterSpacing: -1.2,
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 2),
                    child: Text(
                      '/12',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                coverage == 12 ? '매달 들어옴' : '${12 - coverage}개월 비어있음',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: coverage == 12
                      ? AppColors.gold
                      : AppColors.textTertiary,
                  fontStyle: FontStyle.italic,
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

// ═══════════════════════════════════════════════════════════
//  Month Grid (12 months, 4 cols × 3 rows)
// ═══════════════════════════════════════════════════════════
class _MonthGrid extends StatelessWidget {
  final List<double> monthly;
  final PortfolioRecommendation rec;
  final int? highlightedMonth;
  final ValueChanged<int> onTap;

  const _MonthGrid({
    required this.monthly,
    required this.rec,
    required this.highlightedMonth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final maxV = monthly.fold(0.0, (a, b) => a > b ? a : b);

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.9,
      ),
      itemCount: 12,
      itemBuilder: (context, i) {
        final month = i + 1;
        final amount = monthly[i];
        return _MonthTile(
          month: month,
          amount: amount,
          maxAmount: maxV,
          isHighlighted: highlightedMonth == month,
          rec: rec,
          onTap: () => onTap(month),
        ).animate().fadeIn(
          delay: Duration(milliseconds: 30 + i * 20),
          duration: 240.ms,
        );
      },
    );
  }
}

class _MonthTile extends StatelessWidget {
  final int month;
  final double amount;
  final double maxAmount;
  final bool isHighlighted;
  final PortfolioRecommendation rec;
  final VoidCallback onTap;

  const _MonthTile({
    required this.month,
    required this.amount,
    required this.maxAmount,
    required this.isHighlighted,
    required this.rec,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = amount == 0;
    final intensity =
    maxAmount > 0 ? (amount / maxAmount).clamp(0.0, 1.0) : 0.0;
    final stockCount = rec.picks
        .where((p) => p.stock.paymentMonths.contains(month))
        .length;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isHighlighted
              ? AppColors.accentGhost
              : isEmpty
              ? Colors.transparent
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isHighlighted
                ? AppColors.wine
                : isEmpty
                ? AppColors.borderSoft
                : AppColors.border,
            width: isHighlighted ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            if (!isEmpty)
              Positioned(
                left: 0,
                top: 8,
                bottom: 8,
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                    color: AppColors.wine
                        .withValues(alpha: 0.3 + intensity * 0.7),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$month',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isEmpty
                              ? AppColors.textTertiary
                              : AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (stockCount > 0)
                        Text(
                          '$stockCount',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textTertiary,
                          ),
                        ),
                    ],
                  ),
                  if (isEmpty)
                    Text(
                      '—',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textDisabled,
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  else
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        _shortKRW(amount),
                        style: GoogleFonts.inter(
                          color: intensity > 0.5
                              ? AppColors.wine
                              : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortKRW(double v) {
    if (v >= 100000000) return '${(v / 100000000).toStringAsFixed(1)}억';
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}천만';
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(0)}만';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}천';
    return '${v.round()}';
  }
}

// ═══════════════════════════════════════════════════════════
//  ⭐ Modal Bottom Sheet (그리드 안 가림)
// ═══════════════════════════════════════════════════════════
class _MonthDetailSheet extends StatelessWidget {
  final int month;
  final double amount;
  final PortfolioRecommendation rec;

  const _MonthDetailSheet({
    required this.month,
    required this.amount,
    required this.rec,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = amount == 0;
    final picks = rec.picks
        .where((p) => p.stock.paymentMonths.contains(month))
        .toList()
      ..sort((a, b) => b.weightOfTotal.compareTo(a.weightOfTotal));

    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── 손잡이
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Container(width: 20, height: 1.5, color: AppColors.wine),
                  const SizedBox(width: 8),
                  Text(
                    monthNames[month - 1].toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.wine,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(color: AppColors.border, width: 1),
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

            // ── 월 + 금액
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$month월',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -1.2,
                      height: 1,
                    ),
                  ),
                  const Spacer(),
                  if (!isEmpty) ...[
                    Text(
                      '₩',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.wine,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _fmt(amount.round()),
                      style: GoogleFonts.inter(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: AppColors.wineDeep,
                        letterSpacing: -1,
                        height: 1,
                      ),
                    ),
                  ] else
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

            // ── 종목 리스트 또는 비어있음 안내
            if (picks.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: const Icon(
                        Icons.event_busy_rounded,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$month월에는 배당이 없어요',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '월배당 ETF를 추가하면 이 달도 채울 수 있어요',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: picks.length,
                  itemBuilder: (context, i) {
                    final pick = picks[i];
                    return _DetailRow(
                      pick: pick,
                      index: i + 1,
                      isLast: i == picks.length - 1,
                    );
                  },
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

class _DetailRow extends StatelessWidget {
  final PortfolioPick pick;
  final int index;
  final bool isLast;

  const _DetailRow({
    required this.pick,
    required this.index,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final stock = pick.stock;
    final annual = stock.dividendPerShare > 0
        ? stock.dividendPerShare
        : stock.latestDividend;
    final amount = stock.paymentMonths.isNotEmpty
        ? (annual / stock.paymentMonths.length) * pick.shares
        : 0.0;

    return Container(
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
          // 인덱스 (영수증 라인)
          SizedBox(
            width: 22,
            child: Text(
              index.toString().padLeft(2, '0'),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Text(stock.sector.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stock.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${pick.shares}주 · ${stock.frequency.label}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+₩${_fmt(amount.round())}',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.wine,
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

// ═══════════════════════════════════════════════════════════
//  연간 영수증 (요약)
// ═══════════════════════════════════════════════════════════
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.wine,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              'YEARLY REPORT',
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
            label: '가장 많이 받는 달',
            value: maxMonth > 0
                ? '$maxMonth월 (₩${_fmt(monthly[maxMonth - 1].round())})'
                : '—',
          ),
          _ReceiptRow(
            label: '비어있는 달',
            value: emptyMonths.isEmpty
                ? '없음'
                : emptyMonths.map((m) => '$m월').join(', '),
          ),
          _ReceiptRow(
            label: '평균 종목 수',
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
  const _ReceiptRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
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
              child: Container(
                height: 1,
                decoration: const BoxDecoration(
                  color: AppColors.borderSoft,
                ),
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}