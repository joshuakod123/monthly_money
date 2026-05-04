import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../algorithms/persona_animal.dart';
import '../algorithms/persona_profile.dart';
import '../algorithms/recommendation_engine.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';

/// ═══════════════════════════════════════════════════════════
///  QuizResultScreen — 2단계 결과 (PageView)
///   페이지 1: 동물 페르소나 (Image 2 스타일)
///   페이지 2: 영수증 (Image 1 스타일)
///   완료 시 홈으로 이동 (퀴즈 결과 저장됨)
/// ═══════════════════════════════════════════════════════════
class QuizResultScreen extends ConsumerStatefulWidget {
  const QuizResultScreen({super.key});

  @override
  ConsumerState<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends ConsumerState<QuizResultScreen> {
  final PageController _pc = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == 0) {
      _pc.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
      setState(() => _page = 1);
    } else {
      // 영수증 confirm → 홈으로
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _retake() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final persona = ref.watch(personaProfileProvider);
    final rec = ref.watch(portfolioRecommendationProvider);

    if (persona == null || rec == null) {
      return const Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(child: CircularProgressIndicator(color: AppColors.wine)),
      );
    }

    final animal = PersonaAnimal.fromProfile(persona);

    return Scaffold(
      backgroundColor: _page == 0 ? animal.signatureBg : AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // ── 상단 바 (페이지 인디케이터 + retake)
            _TopBar(
              page: _page,
              total: 2,
              animal: animal,
              isFirstPage: _page == 0,
              onRetake: _retake,
            ),

            // ── 콘텐츠
            Expanded(
              child: PageView(
                controller: _pc,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _AnimalPage(animal: animal, persona: persona),
                  _ReceiptPage(
                    persona: persona,
                    rec: rec,
                    animal: animal,
                  ),
                ],
              ),
            ),

            // ── 하단 CTA
            _BottomCta(
              page: _page,
              animal: animal,
              onNext: _next,
              onRetake: _retake,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// 상단 바
// ═══════════════════════════════════════════════════════════
class _TopBar extends StatelessWidget {
  final int page;
  final int total;
  final PersonaAnimal animal;
  final bool isFirstPage;
  final VoidCallback onRetake;

  const _TopBar({
    required this.page,
    required this.total,
    required this.animal,
    required this.isFirstPage,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isFirstPage ? animal.signatureText : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          // 페이지 인디케이터 (1/2)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(
                color: fg.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              '${page + 1} / $total',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: fg,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Spacer(),
          // 다시 풀기
          GestureDetector(
            onTap: onRetake,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  Icon(Icons.refresh_rounded, size: 14, color: fg),
                  const SizedBox(width: 4),
                  Text(
                    '다시',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  [Page 1] 동물 페르소나 페이지 (Image 2 영감)
//  - 거대한 동물 이름 (Sans display, 음수 tracking)
//  - 동물 이모지를 거대하게 중앙 배치
//  - 시그니처 배경 + 동물 위 latin name 작게
// ═══════════════════════════════════════════════════════════
class _AnimalPage extends StatelessWidget {
  final PersonaAnimal animal;
  final PersonaProfile persona;

  const _AnimalPage({required this.animal, required this.persona});

  @override
  Widget build(BuildContext context) {
    final fg = animal.signatureText;
    final accent = animal.signatureBg == AppColors.wine
        ? AppColors.wineSoft
        : fg.withValues(alpha: 0.7);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // ── 라벨
          Row(
            children: [
              Container(width: 20, height: 1.5, color: fg),
              const SizedBox(width: 8),
              Text(
                'YOUR INVESTMENT SPIRIT',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: fg,
                  letterSpacing: 2,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          // ── 거대한 이름 (Sans display)
          Text(
            animal.name.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 80,
              fontWeight: FontWeight.w800,
              color: fg,
              letterSpacing: -4,
              height: 0.95,
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 600.ms)
              .slideY(begin: 0.05, end: 0),

          const SizedBox(height: 8),

          // ── Latin name (작게, italic)
          Text(
            animal.latinName,
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: accent,
              letterSpacing: 0.3,
            ),
          ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

          const SizedBox(height: 32),

          // ── 거대한 이모지 (중앙)
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 백그라운드 텍스처
                  Opacity(
                    opacity: 0.05,
                    child: Text(
                      animal.archetype,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 180,
                        fontWeight: FontWeight.w900,
                        color: fg,
                      ),
                    ),
                  ),
                  Text(
                    animal.emoji,
                    style: const TextStyle(fontSize: 200),
                  )
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 800.ms)
                      .scale(begin: const Offset(0.7, 0.7))
                      .then()
                      .shimmer(
                    duration: 2400.ms,
                    color: fg.withValues(alpha: 0.3),
                  ),
                ],
              ),
            ),
          ),

          // ── 태그라인 (Serif)
          Text(
            animal.tagline,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: -0.4,
              height: 1.3,
            ),
          )
              .animate()
              .fadeIn(delay: 900.ms, duration: 480.ms)
              .slideY(begin: 0.1, end: 0),

          const SizedBox(height: 12),

          // ── 설명 (작게)
          Text(
            animal.description,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: fg.withValues(alpha: 0.85),
              height: 1.55,
            ),
          ).animate().fadeIn(delay: 1100.ms, duration: 400.ms),

          const SizedBox(height: 20),

          // ── Traits 키워드 (3개 칩)
          Wrap(
            spacing: 8,
            children: animal.traits.map((t) {
              return Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: fg.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                    color: fg.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  t,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: fg,
                    letterSpacing: -0.1,
                  ),
                ),
              );
            }).toList(),
          ).animate().fadeIn(delay: 1300.ms, duration: 400.ms),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  [Page 2] 영수증 페이지 (Image 1 영감)
//   - 점선 라운드 박스
//   - DETAILS 라벨 (오렌지/와인)
//   - 페르소나 + 목표 + 추천 종목 리스트
// ═══════════════════════════════════════════════════════════
class _ReceiptPage extends StatelessWidget {
  final PersonaProfile persona;
  final PortfolioRecommendation rec;
  final PersonaAnimal animal;

  const _ReceiptPage({
    required this.persona,
    required this.rec,
    required this.animal,
  });

  @override
  Widget build(BuildContext context) {
    final monthly = rec.totalMonthlyDividend.round();
    final pct = persona.monthlyTarget > 0
        ? ((rec.totalMonthlyDividend / persona.monthlyTarget) * 100).round()
        : 0;

    final dt = DateTime.now();
    final dateStr = '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      physics: const BouncingScrollPhysics(),
      children: [
        // ── 영수증 카드
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceWarm,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── DETAILS 라벨 (Image 1의 오렌지 박스 → wine)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.wine,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  'PERSONA',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.surface,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── 페르소나 행
              _ReceiptRow(
                label: '동물',
                value: '${animal.emoji}  ${animal.name}',
              ),
              _ReceiptRow(
                label: '본능',
                value: animal.archetype,
              ),
              _ReceiptRow(
                label: '발급일',
                value: dateStr,
              ),

              // ── 점선 박스 (스무고개 결과)
              const SizedBox(height: 14),
              _DashedBox(
                child: Text(
                  persona.summarize(),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),

              // ── 구분선
              const SizedBox(height: 18),
              _Divider(),
              const SizedBox(height: 14),

              // ── PORTFOLIO 라벨
              Text(
                'RECOMMENDED PORTFOLIO',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),

              // ── 종목 리스트 (영수증 형식)
              ...rec.picks.take(6).map((pick) {
                final stock = pick.stock;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(stock.sector.emoji,
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          stock.name,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${pick.shares}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (rec.picks.length > 6)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 22),
                  child: Text(
                    '외 ${rec.picks.length - 6}개 종목',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

              // ── 구분선
              const SizedBox(height: 18),
              _Divider(),
              const SizedBox(height: 14),

              // ── 합계 영역
              Text(
                'SUMMARY',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),

              _ReceiptRow(label: '월 배당 목표', value: '₩${_fmt(persona.monthlyTarget)}'),
              _ReceiptRow(label: '필요 투자금', value: '₩${_fmt(rec.totalInvestment)}'),
              _ReceiptRow(label: '커버리지', value: '${rec.coverageCount} / 12개월'),

              const SizedBox(height: 12),
              _Divider(),
              const SizedBox(height: 14),

              // ── 거대한 합계 (Image 1의 Total Value)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'MONTHLY',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '₩${_fmt(monthly)}',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.wineDeep,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Spacer(),
                  Text(
                    '목표 달성 $pct%',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: pct >= 100 ? AppColors.gold : AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── 영수증 하단 italic 카피
        const SizedBox(height: 16),
        Center(
          child: Text(
            '· 발급된 영수증은 언제든 다시 확인할 수 있어요 ·',
            style: GoogleFonts.playfairDisplay(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: AppColors.textTertiary,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
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

// ═════════════════════════════════════════════
//  영수증 row
// ═════════════════════════════════════════════
class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReceiptRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
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

// ═════════════════════════════════════════════
//  점선 박스 (Image 1의 위치 박스 영감)
// ═════════════════════════════════════════════
class _DashedBox extends StatelessWidget {
  final Widget child;
  const _DashedBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const radius = 99.0;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(radius),
    );

    final paint = Paint()
      ..color = AppColors.borderStrong
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // 점선 효과 (수동)
    final path = Path()..addRRect(rect);
    final dashed = _dashedPath(path, dashLength: 4, gapLength: 4);
    canvas.drawPath(dashed, paint);
  }

  Path _dashedPath(Path source, {required double dashLength, required double gapLength}) {
    final result = Path();
    for (final metric in source.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final next = (dist + dashLength).clamp(0, metric.length);
        result.addPath(metric.extractPath(dist, next.toDouble()), Offset.zero);
        dist = next.toDouble() + gapLength;
      }
    }
    return result;
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═════════════════════════════════════════════
//  영수증 구분선
// ═════════════════════════════════════════════
class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: const BoxDecoration(
        color: AppColors.borderSoft,
      ),
    );
  }
}

// ═════════════════════════════════════════════
//  하단 CTA 버튼
// ═════════════════════════════════════════════
class _BottomCta extends StatelessWidget {
  final int page;
  final PersonaAnimal animal;
  final VoidCallback onNext;
  final VoidCallback onRetake;

  const _BottomCta({
    required this.page,
    required this.animal,
    required this.onNext,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final isFirst = page == 0;
    final bg = isFirst ? animal.signatureText : AppColors.wine;
    final fg = isFirst ? animal.signatureBg : AppColors.surface;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onNext,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  Text(
                    isFirst ? '내 영수증 보기' : '포트폴리오로 이동',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: fg,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isFirst
                          ? animal.signatureBg
                          : AppColors.wineDeep,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: isFirst ? animal.signatureText : AppColors.surface,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}