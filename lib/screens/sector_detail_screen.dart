import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/stock_model.dart';
import '../theme/app_theme.dart';
import 'stock_detail_screen.dart';

/// ═══════════════════════════════════════════════════════════
///  SectorDetailScreen
///   상단: 섹터 시그니처 컬러 풀스크린 + 거대 영문 타이포
///   하단: Dutch White 시트 + 종목 리스트
/// ═══════════════════════════════════════════════════════════
class SectorDetailScreen extends StatefulWidget {
  final StockSector sector;
  final List<StockModel> stocks;

  const SectorDetailScreen({
    super.key,
    required this.sector,
    required this.stocks,
  });

  @override
  State<SectorDetailScreen> createState() => _SectorDetailScreenState();
}

enum _SortMode { yieldDesc, yieldAsc, marketCap, name }

class _SectorDetailScreenState extends State<SectorDetailScreen> {
  _SortMode _sort = _SortMode.yieldDesc;

  List<StockModel> get _sortedStocks {
    final list = [...widget.stocks];
    switch (_sort) {
      case _SortMode.yieldDesc:
        list.sort((a, b) => b.dividendYield.compareTo(a.dividendYield));
        break;
      case _SortMode.yieldAsc:
        list.sort((a, b) => a.dividendYield.compareTo(b.dividendYield));
        break;
      case _SortMode.marketCap:
        list.sort((a, b) => b.marketCap.compareTo(a.marketCap));
        break;
      case _SortMode.name:
        list.sort((a, b) => a.name.compareTo(b.name));
        break;
    }
    return list;
  }

  String get _sortLabel {
    switch (_sort) {
      case _SortMode.yieldDesc: return '수익률 ↓';
      case _SortMode.yieldAsc:  return '수익률 ↑';
      case _SortMode.marketCap: return '시총 큰 순';
      case _SortMode.name:      return '가나다순';
    }
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '정렬',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ..._SortMode.values.map((mode) {
                final selected = mode == _sort;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    _sortLabelFor(mode),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? AppColors.wine
                          : AppColors.textPrimary,
                    ),
                  ),
                  trailing: selected
                      ? const Icon(Icons.check_rounded,
                      color: AppColors.wine, size: 18)
                      : null,
                  onTap: () {
                    setState(() => _sort = mode);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _sortLabelFor(_SortMode m) {
    switch (m) {
      case _SortMode.yieldDesc: return '수익률 높은 순';
      case _SortMode.yieldAsc:  return '수익률 낮은 순';
      case _SortMode.marketCap: return '시총 큰 순';
      case _SortMode.name:      return '이름 가나다순';
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.paletteFor(widget.sector.name);
    final sorted = _sortedStocks;

    final avgYield = _weightedAvgYield(widget.stocks);

    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _ColorHero(
              palette: palette,
              sector: widget.sector,
              stockCount: widget.stocks.length,
              avgYield: avgYield,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: _StockListSheet(
                stocks: sorted,
                sortLabel: _sortLabel,
                onSortTap: _showSortSheet,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 시총 가중 평균 + 0배당 제외 + 클립 (explore_screen과 동일 방식)
  double _weightedAvgYield(List<StockModel> stocks) {
    final positive =
    stocks.where((s) => s.dividendYield > 0 && s.dividendYield < 99).toList();
    if (positive.isEmpty) return 0.0;

    double totalCap = 0;
    double weightedSum = 0;
    for (final s in positive) {
      final w = s.marketCap > 0 ? s.marketCap.toDouble() : 1.0;
      totalCap += w;
      weightedSum += s.dividendYield * w;
    }
    if (totalCap == 0) {
      final mean =
          positive.map((s) => s.dividendYield).reduce((a, b) => a + b) /
              positive.length;
      return mean.clamp(0.0, 99.0);
    }
    return (weightedSum / totalCap).clamp(0.0, 99.0);
  }
}

class _ColorHero extends StatelessWidget {
  final SectorPalette palette;
  final StockSector sector;
  final int stockCount;
  final double avgYield;
  final VoidCallback onBack;

  const _ColorHero({
    required this.palette,
    required this.sector,
    required this.stockCount,
    required this.avgYield,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final fg = palette.onBg;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Stack(
        children: [
          // 거대 영문 워터마크 (오른쪽 cropped)
          Positioned(
            right: -20,
            top: 60,
            child: Opacity(
              opacity: 0.07,
              child: Text(
                palette.label.split(' ').first,
                style: GoogleFonts.inter(
                  fontSize: 220,
                  fontWeight: FontWeight.w900,
                  color: fg,
                  letterSpacing: -8,
                  height: 0.85,
                ),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: fg.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                          color: fg.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(Icons.arrow_back_rounded,
                          size: 18, color: fg),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: fg.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      palette.label,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: fg,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Text(
                palette.label,
                style: GoogleFonts.inter(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  color: fg,
                  letterSpacing: -2.5,
                  height: 0.9,
                ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.05, end: 0),

              const SizedBox(height: 8),

              Row(
                children: [
                  Text(
                    sector.label,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: fg,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: fg.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$stockCount stocks',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: fg.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _MetricBox(
                      label: 'AVG YIELD',
                      value: '${avgYield.toStringAsFixed(2)}%',
                      fg: fg,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricBox(
                      label: 'STOCKS',
                      value: '$stockCount',
                      fg: fg,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color fg;

  const _MetricBox({
    required this.label,
    required this.value,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: fg.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: fg.withValues(alpha: 0.7),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: fg,
              letterSpacing: -0.8,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StockListSheet extends StatelessWidget {
  final List<StockModel> stocks;
  final String sortLabel;
  final VoidCallback onSortTap;

  const _StockListSheet({
    required this.stocks,
    required this.sortLabel,
    required this.onSortTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                Text(
                  '종목 ${stocks.length}',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onSortTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tune_rounded,
                            size: 12, color: AppColors.textSecondary),
                        const SizedBox(width: 5),
                        Text(
                          sortLabel,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              physics: const BouncingScrollPhysics(),
              itemCount: stocks.length,
              itemBuilder: (context, i) {
                final stock = stocks[i];
                return _StockRow(
                  stock: stock,
                  index: i + 1,
                  isLast: i == stocks.length - 1,
                )
                    .animate()
                    .fadeIn(
                  delay: Duration(milliseconds: 60 * i),
                  duration: 280.ms,
                )
                    .slideX(begin: 0.03, end: 0);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StockRow extends StatelessWidget {
  final StockModel stock;
  final int index;
  final bool isLast;

  const _StockRow({
    required this.stock,
    required this.index,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.paletteFor(stock.sector.name);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StockDetailScreen(stock: stock)),
      ),
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
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 4,
              height: 32,
              decoration: BoxDecoration(
                color: palette.bg,
                borderRadius: BorderRadius.circular(2),
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
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${stock.code} · ${stock.frequency.label}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₩${_fmt(stock.price.round())}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${stock.dividendYield.toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.wine,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
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
