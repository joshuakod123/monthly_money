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
  int? _selectedMonth;

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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 라벨
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

              // 헤더 카드
              _Header(yearTotal: yearTotal, coverage: coverage)
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 380.ms)
                  .slideY(begin: 0.05),

              const SizedBox(height: 24),

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
                    child: Container(
                      height: 1,
                      color: AppColors.borderSoft,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Expanded(
                child: _MonthGrid(
                  monthly: monthly,
                  rec: rec,
                  selectedMonth: _selectedMonth,
                  onTap: (m) => setState(() {
                    _selectedMonth = _selectedMonth == m ? null : m;
                  }),
                ),
              ),

              if (_selectedMonth != null) ...[
                const SizedBox(height: 12),
                _DetailPanel(
                  month: _selectedMonth!,
                  amount: monthly[_selectedMonth! - 1],
                  rec: rec,
                  onClose: () => setState(() => _selectedMonth = null),
                )
                    .animate()
                    .fadeIn(duration: 200.ms)
                    .slideY(begin: 0.1, end: 0),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

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
                    Text(
                      _fmt(yearTotal.round()),
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.wineDeep,
                        letterSpacing: -1.2,
                        height: 1,
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

class _MonthGrid extends StatelessWidget {
  final List<double> monthly;
  final PortfolioRecommendation rec;
  final int? selectedMonth;
  final ValueChanged<int> onTap;

  const _MonthGrid({
    required this.monthly,
    required this.rec,
    required this.selectedMonth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final maxV = monthly.reduce((a, b) => a > b ? a : b);

    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.95,
      ),
      itemCount: 12,
      itemBuilder: (context, i) {
        final month = i + 1;
        final amount = monthly[i];
        return _MonthTile(
          month: month,
          amount: amount,
          maxAmount: maxV,
          isSelected: selectedMonth == month,
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
  final bool isSelected;
  final PortfolioRecommendation rec;
  final VoidCallback onTap;

  const _MonthTile({
    required this.month,
    required this.amount,
    required this.maxAmount,
    required this.isSelected,
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
          color: isSelected
              ? AppColors.accentGhost
              : isEmpty
              ? Colors.transparent
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected
                ? AppColors.wine
                : isEmpty
                ? AppColors.borderSoft
                : AppColors.border,
            width: isSelected ? 1.5 : 1,
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

class _DetailPanel extends StatelessWidget {
  final int month;
  final double amount;
  final PortfolioRecommendation rec;
  final VoidCallback onClose;

  const _DetailPanel({
    required this.month,
    required this.amount,
    required this.rec,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = amount == 0;
    final picks = rec.picks
        .where((p) => p.stock.paymentMonths.contains(month))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$month월',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 10),
              if (!isEmpty)
                Text(
                  '₩${_fmt(amount.round())}',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.wine,
                    letterSpacing: -0.5,
                  ),
                )
              else
                Text(
                  '배당 없음',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              const Spacer(),
              GestureDetector(
                onTap: onClose,
                child: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          if (picks.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...picks.map((pick) => _DetailRow(month: month, pick: pick)),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              '월배당 ETF를 추가하면 이 달도 채울 수 있어요',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textTertiary,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
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

class _DetailRow extends StatelessWidget {
  final int month;
  final PortfolioPick pick;
  const _DetailRow({required this.month, required this.pick});

  @override
  Widget build(BuildContext context) {
    final stock = pick.stock;
    final annual = stock.dividendPerShare > 0
        ? stock.dividendPerShare
        : stock.latestDividend;
    final amount = stock.paymentMonths.isNotEmpty
        ? (annual / stock.paymentMonths.length) * pick.shares
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(stock.sector.emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              stock.name,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${pick.shares}주',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '₩${_fmt(amount.round())}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
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