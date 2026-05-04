import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/stock_model.dart';
import '../services/stock_data_service.dart';
import '../theme/app_theme.dart';
import 'sector_detail_screen.dart';

/// ═══════════════════════════════════════════════════════════
///  ExploreScreen — 박물관 동물 도감
///   8개 섹터를 시그니처 컬러 카드로 진열
///   각 카드는 거대한 타이포 + 종목 수 + → 화살표
/// ═══════════════════════════════════════════════════════════
class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allStocks = StockDataService.allStocks;

    // 섹터별 종목 그룹핑
    final sectorGroups = <StockSector, List<StockModel>>{};
    for (final s in allStocks) {
      if (s.sector == StockSector.all) continue;
      sectorGroups.putIfAbsent(s.sector, () => []).add(s);
    }

    final sectors = StockSector.values
        .where((s) => s != StockSector.all)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ─── 헤더
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 작은 라벨
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 1.5,
                          color: AppColors.wine,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'EXPLORE',
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

                    // 거대한 헤드라인 (Serif)
                    Text(
                      '섹터 도감',
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

                    // 부제목 (italic)
                    Text(
                      'Sectorum Compendium',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textTertiary,
                        letterSpacing: 0.3,
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 320.ms),

                    const SizedBox(height: 12),

                    // 메타 정보
                    Row(
                      children: [
                        Text(
                          '${sectors.length}개 섹터',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
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

            // ─── 섹터 카드 그리드 (2 columns)
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
                    final sector = sectors[i];
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
                  childCount: sectors.length,
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
//  섹터 카드 — Image 2 + 4 영감
//   거대한 타이포 + 시그니처 컬러 풀 배경
//   하단 → 화살표
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

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.paletteFor(sector.name);

    // 평균 배당수익률
    final avgYield = stocks.isEmpty
        ? 0.0
        : stocks.map((s) => s.dividendYield).reduce((a, b) => a + b) /
        stocks.length;

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
            // 백그라운드 워터마크 (큰 emoji 살짝)
            Positioned(
              right: -16,
              top: -16,
              child: Opacity(
                opacity: 0.1,
                child: Text(
                  sector.emoji,
                  style: const TextStyle(fontSize: 110),
                ),
              ),
            ),

            // 콘텐츠
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 상단: 인덱스 번호 + 라틴 라벨
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
                        width: 12,
                        height: 1,
                        color: palette.onBg.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        palette.label,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: palette.onBg.withValues(alpha: 0.7),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // ── 거대한 한글 이름 (Serif)
                  Text(
                    sector.label,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: palette.onBg,
                      letterSpacing: -1.2,
                      height: 1.0,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // 영문 sub
                  Text(
                    palette.label.toLowerCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: palette.onBg.withValues(alpha: 0.6),
                      letterSpacing: 0.2,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── 메트릭 (영수증 스타일)
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
                    value: '${avgYield.toStringAsFixed(1)}%',
                    color: palette.onBg,
                  ),

                  const SizedBox(height: 12),

                  // ── 하단: → 화살표 (Image 4 영감)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 32,
                      height: 32,
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