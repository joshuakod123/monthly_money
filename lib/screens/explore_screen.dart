import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/stock_model.dart';
import '../services/stock_data_service.dart';
import '../theme/app_theme.dart';
import 'sector_detail_screen.dart';

/// ═══════════════════════════════════════════════════════════
///  ExploreScreen v2 — GICS 11개 섹터 도감
///   ▸ 평균 수익률은 시총 가중 평균 + 0배당 종목 제외
///   ▸ 단순 평균이 만들어낸 34070% 같은 이상치 방지
/// ═══════════════════════════════════════════════════════════
class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allStocks = StockDataService.allStocks;

    final sectorGroups = <StockSector, List<StockModel>>{};
    for (final s in allStocks) {
      if (s.sector == StockSector.all) continue;
      sectorGroups.putIfAbsent(s.sector, () => []).add(s);
    }

    // GICS 11개 섹터 표시 순서 (Energy → Real Estate)
    const orderedSectors = [
      StockSector.energy,
      StockSector.materials,
      StockSector.industrial,
      StockSector.consumerDisc,
      StockSector.consumerStpl,
      StockSector.healthcare,
      StockSector.finance,
      StockSector.tech,
      StockSector.telecom,
      StockSector.utilities,
      StockSector.reit,
    ];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24, height: 1.5, color: AppColors.wine,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          AppCopy.exploreLabel,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.wine,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 280.ms),
                    const SizedBox(height: 14),
                    Text(
                      AppCopy.exploreTitle,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 38,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -1.2,
                        height: 1.1,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 320.ms)
                        .slideY(begin: 0.05, end: 0),
                    const SizedBox(height: 6),
                    Text(
                      AppCopy.exploreSub,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textTertiary,
                        letterSpacing: 0.3,
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 320.ms),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '${orderedSectors.length}개 섹터',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 3, height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.textTertiary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${allStocks.length}개 종목',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                delegate: SliverChildBuilderDelegate(
                      (context, i) {
                    final sector = orderedSectors[i];
                    final stocks = sectorGroups[sector] ?? [];
                    return _SectorCard(
                      sector: sector,
                      stockCount: stocks.length,
                      stocks: stocks,
                      indexNumber: i + 1,
                    )
                        .animate()
                        .fadeIn(
                      delay: Duration(milliseconds: 400 + i * 60),
                      duration: 380.ms,
                    )
                        .slideY(begin: 0.08, end: 0);
                  },
                  childCount: orderedSectors.length,
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
//  Sector Card
// ═══════════════════════════════════════════════════════════
class _SectorCard extends StatelessWidget {
  final StockSector sector;
  final int stockCount;
  final List<StockModel> stocks;
  final int indexNumber;

  const _SectorCard({
    required this.sector,
    required this.stockCount,
    required this.stocks,
    required this.indexNumber,
  });

  /// ⭐ 시총 가중 평균 + 0배당 종목 제외
  /// 단순 평균은 0% + 100%를 50%로 보여줘서 왜곡 큼
  double _calculateAvgYield() {
    final paying = stocks.where((s) => s.dividendYield > 0).toList();
    if (paying.isEmpty) return 0.0;

    // 시총 합
    final totalCap = paying.fold<int>(0, (a, b) => a + b.marketCap);
    if (totalCap <= 0) {
      // 시총 데이터 없으면 단순 평균
      return paying.map((s) => s.dividendYield).reduce((a, b) => a + b) /
          paying.length;
    }

    // 시총 가중 평균
    double weighted = 0;
    for (final s in paying) {
      weighted += s.dividendYield * (s.marketCap / totalCap);
    }
    // 비현실적 이상치 클립 (한국 시장 실제 평균 ~2-7%)
    return weighted.clamp(0, 99).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.paletteFor(sector.name);
    final avgYield = _calculateAvgYield();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SectorDetailScreen(
            sector: sector,
            stocks: stocks,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: palette.bg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Stack(
          children: [
            // 백그라운드: 거대한 영문 라벨이 흐리게
            Positioned(
              right: -8,
              bottom: -16,
              child: Opacity(
                opacity: 0.07,
                child: Text(
                  palette.label.split(' ').first,
                  style: GoogleFonts.inter(
                    fontSize: 90,
                    fontWeight: FontWeight.w900,
                    color: palette.onBg,
                    letterSpacing: -4,
                    height: 0.85,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        indexNumber.toString().padLeft(2, '0'),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: palette.onBg.withValues(alpha: 0.6),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 12, height: 1,
                        color: palette.onBg.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          palette.label,
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: palette.onBg.withValues(alpha: 0.7),
                            letterSpacing: 1.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    sector.label,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: palette.onBg,
                      letterSpacing: -1,
                      height: 1.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    palette.label.toLowerCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: palette.onBg.withValues(alpha: 0.6),
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 1,
                    color: palette.onBg.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 8),
                  _MetricRow(
                    label: '종목',
                    value: '$stockCount',
                    color: palette.onBg,
                  ),
                  const SizedBox(height: 4),
                  _MetricRow(
                    label: '평균 수익률',
                    value: avgYield > 0
                        ? '${avgYield.toStringAsFixed(2)}%'
                        : '—',
                    color: palette.onBg,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: palette.onBg.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                          color: palette.onBg.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: palette.onBg,
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
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: color.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
