import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../algorithms/recommendation_engine.dart';   // ⭐ 이 한 줄 추가
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

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
        backgroundColor: AppColors.bgPage,
        appBar: AppBar(title: const Text('배당 캘린더')),
        body: const Center(
          child: Text('퀴즈를 먼저 완료해주세요',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    final yearTotal = monthly.fold(0.0, (a, b) => a + b);
    final coverage = rec.coverageCount;
    final emptyMonths = List.generate(12, (i) => i + 1)
        .where((m) => monthly[m - 1] == 0)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        backgroundColor: AppColors.bgPage,
        elevation: 0,
        title: const Text('배당 캘린더',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ───── 히어로 카드: 연 합계 + 커버리지 링
            _HeroCard(yearTotal: yearTotal, coverage: coverage)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.05),

            const SizedBox(height: 20),

            // ───── 빈 달 경고 (있을 때만)
            if (emptyMonths.isNotEmpty)
              _EmptyMonthsAlert(emptyMonths: emptyMonths)
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 350.ms),

            if (emptyMonths.isNotEmpty) const SizedBox(height: 20),

            // ───── 12개월 그리드
            const Text('월별 현금흐름',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                )),
            const SizedBox(height: 12),

            _MonthGrid(
              monthly: monthly,
              rec: rec,
              selectedMonth: _selectedMonth,
              onTap: (m) => setState(() {
                _selectedMonth = _selectedMonth == m ? null : m;
              }),
            ),

            const SizedBox(height: 20),

            // ───── 선택된 달 상세 (있을 때만)
            if (_selectedMonth != null)
              _SelectedMonthDetail(
                month: _selectedMonth!,
                amount: monthly[_selectedMonth! - 1],
                rec: rec,
              ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.04),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 히어로 카드 — 연 합계 + 커버리지 링
// ═══════════════════════════════════════════
class _HeroCard extends StatelessWidget {
  final double yearTotal;
  final int coverage; // 0-12

  const _HeroCard({required this.yearTotal, required this.coverage});

  @override
  Widget build(BuildContext context) {
    final monthly = yearTotal / 12;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.22),
            AppColors.bgCard,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('연 예상 배당',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 6),
                Text(
                  formatKRW(yearTotal.round()),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '월 평균 ${formatKRW(monthly.round())}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // ── 커버리지 링
          _CoverageRing(coverage: coverage),
        ],
      ),
    );
  }
}

class _CoverageRing extends StatelessWidget {
  final int coverage;
  const _CoverageRing({required this.coverage});

  @override
  Widget build(BuildContext context) {
    final pct = coverage / 12;
    final color = coverage == 12
        ? AppColors.primary
        : coverage >= 9
        ? AppColors.accent
        : AppColors.accentWarm;

    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 배경 원
          SizedBox(
            width: 84,
            height: 84,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 6,
              valueColor: AlwaysStoppedAnimation(
                  AppColors.border.withValues(alpha: 0.5)),
            ),
          ),
          // 진행 원
          SizedBox(
            width: 84,
            height: 84,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0, end: pct),
              builder: (context, v, _) => CircularProgressIndicator(
                value: v,
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
                valueColor: AlwaysStoppedAnimation(color),
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$coverage',
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              Text(
                '/ 12개월',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 빈 달 경고
// ═══════════════════════════════════════════
class _EmptyMonthsAlert extends StatelessWidget {
  final List<int> emptyMonths;
  const _EmptyMonthsAlert({required this.emptyMonths});

  @override
  Widget build(BuildContext context) {
    final monthsStr = emptyMonths.map((m) => '$m월').join(', ');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentWarm.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.accentWarm.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.accentWarm, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('비어있는 달',
                    style: TextStyle(
                      color: AppColors.accentWarm,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 2),
                Text('$monthsStr 에는 배당이 없어요',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      height: 1.4,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 12개월 그리드 (4×3)
// ═══════════════════════════════════════════
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
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.0,
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
          delay: Duration(milliseconds: 50 + i * 30),
          duration: 300.ms,
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
    final intensity = maxAmount > 0 ? (amount / maxAmount).clamp(0.0, 1.0) : 0.0;

    // 그달에 배당 주는 종목 이모지 모음 (최대 3개)
    final emojis = isEmpty
        ? <String>[]
        : rec.picks
        .where((p) => p.stock.paymentMonths.contains(month))
        .map((p) => p.stock.sector.emoji)
        .toSet()
        .take(3)
        .toList();

    final bgColor = isEmpty
        ? AppColors.bgCard
        : Color.lerp(
      AppColors.bgCard,
      AppColors.primary.withValues(alpha: 0.5),
      0.2 + intensity * 0.5,
    )!;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : isEmpty
                ? AppColors.border.withValues(alpha: 0.6)
                : AppColors.primary.withValues(alpha: 0.25),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ]
              : null,
        ),
        child: Stack(
          children: [
            // 왼쪽 위: 월 숫자
            Positioned(
              top: 0,
              left: 0,
              child: Text(
                '$month',
                style: TextStyle(
                  color: isEmpty
                      ? AppColors.textHint
                      : AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            // 오른쪽 위: 이모지
            if (emojis.isNotEmpty)
              Positioned(
                top: 0,
                right: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: emojis
                      .map((e) => Padding(
                    padding: const EdgeInsets.only(left: 1),
                    child: Text(e, style: const TextStyle(fontSize: 11)),
                  ))
                      .toList(),
                ),
              ),
            // 하단: 금액 또는 점선
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: isEmpty
                  ? const Text(
                '—',
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              )
                  : FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomLeft,
                child: Text(
                  _shortKRW(amount),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortKRW(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)}천만';
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(0)}만';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}천';
    return '${v.round()}';
  }
}

// ═══════════════════════════════════════════
// 선택된 달 상세 패널
// ═══════════════════════════════════════════
class _SelectedMonthDetail extends StatelessWidget {
  final int month;
  final double amount;
  final PortfolioRecommendation rec;

  const _SelectedMonthDetail({
    required this.month,
    required this.amount,
    required this.rec,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = amount == 0;
    final picks = rec.picks
        .where((p) => p.stock.paymentMonths.contains(month))
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEmpty
              ? AppColors.border
              : AppColors.primary.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$month월',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -1,
                ),
              ),
              const Spacer(),
              if (!isEmpty)
                Text(
                  formatKRW(amount.round()),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                )
              else
                const Text(
                  '배당 없음',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          if (picks.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 12),
            ...picks.map((pick) => _PickRow(month: month, pick: pick)),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgPage,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '월배당 ETF를 추가하면 이 달도 채울 수 있어요',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PickRow extends StatelessWidget {
  final int month;
  final PortfolioPick pick;
  const _PickRow({required this.month, required this.pick});

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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: stock.sectorColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(stock.sector.emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stock.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    )),
                const SizedBox(height: 2),
                Text('${pick.shares}주 · ${stock.frequency.label}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    )),
              ],
            ),
          ),
          Text(formatKRW(amount.round()),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              )),
        ],
      ),
    );
  }
}