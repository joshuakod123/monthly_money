import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../algorithms/persona_animal.dart';
import '../algorithms/persona_profile.dart';
import '../algorithms/recommendation_engine.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/animal_illustration.dart';

/// ═══════════════════════════════════════════════════════════
///  QuizResultScreen v2 — Image 3 ANIMAL PLANET 영감
///   페이지 1: 풀스크린 컬러 + 거대 픽셀풍 타이포 + 흑백 동물
///   페이지 2: 영수증
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
            _TopBar(
              page: _page,
              total: 2,
              animal: animal,
              isFirstPage: _page == 0,
              onRetake: _retake,
            ),
            Expanded(
              child: PageView(
                controller: _pc,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _AnimalPosterPage(animal: animal),
                  _ReceiptPage(persona: persona, rec: rec, animal: animal),
                ],
              ),
            ),
            _BottomCta(
              page: _page,
              animal: animal,
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Top Bar
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
          // 인덱스 (Image 3 좌상단 4/10 스타일)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isFirstPage ? fg.withValues(alpha: 0.18) : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: fg.withValues(alpha: 0.4), width: 1),
            ),
            child: Text(
              '${animal.index} / 8',
              style: GoogleFonts.spaceMono(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: fg,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Spacer(),
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
                      fontWeight: FontWeight.w600,
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
//  ⭐ Page 1: ANIMAL PLANET 스타일 포스터
//   Image 3 영감 — 강한 컬러 풀배경 + 거대 픽셀풍 타이포
//   + 흑백 동물 일러스트 + 사이드 'Discover' 텍스트
// ═══════════════════════════════════════════════════════════
class _AnimalPosterPage extends StatelessWidget {
  final PersonaAnimal animal;
  const _AnimalPosterPage({required this.animal});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── 바둑판 배경 패턴 (Image 3 텍스처)
        Positioned.fill(
          child: CustomPaint(
            painter: _GridBackgroundPainter(
              color: animal.signatureText.withValues(alpha: 0.06),
            ),
          ),
        ),

        // ── 거대 타이포가 화면 위에서 쪼개지는 듯한 레이아웃
        // 이름을 두 줄로 자르거나 한 줄로 — 글자 길이에 따라
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: LayoutBuilder(
            builder: (context, c) {
              return Stack(
                children: [
                  // 거대 타이포
                  Positioned(
                    left: 0, right: 0, top: 0,
                    child: _GiantStackedName(
                      name: animal.displayName,
                      color: animal.signatureText,
                      maxWidth: c.maxWidth,
                    )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 500.ms)
                        .slideY(begin: -0.05, end: 0),
                  ),

                  // 동물 일러스트 (중앙)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 80),
                      child: Center(
                        child: AnimalIllustration(
                          illustrationId: animal.illustrationId,
                          ink: animal.illustrationInk,
                          size: math.min(c.maxWidth * 0.85, c.maxHeight * 0.55),
                        )
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 800.ms)
                            .scale(begin: const Offset(0.9, 0.9)),
                      ),
                    ),
                  ),

                  // ── 좌측 세로 'Discover' (Image 3 영감)
                  Positioned(
                    left: 0,
                    top: c.maxHeight * 0.45,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Text(
                        'Discover',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          color: animal.signatureText.withValues(alpha: 0.85),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms),
                  ),

                  // ── 하단: 한글 이름 + 설명
                  Positioned(
                    left: 0, right: 0, bottom: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          animal.name,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: animal.signatureText,
                            letterSpacing: -1,
                            height: 1,
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 700.ms, duration: 400.ms),
                        const SizedBox(height: 4),
                        Text(
                          animal.latinName,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: animal.signatureText.withValues(alpha: 0.7),
                          ),
                        ).animate().fadeIn(delay: 800.ms),
                        const SizedBox(height: 14),
                        Text(
                          animal.tagline,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: animal.signatureText,
                            height: 1.4,
                          ),
                        ).animate().fadeIn(delay: 900.ms),
                        const SizedBox(height: 8),
                        Text(
                          animal.description,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: animal.signatureText.withValues(alpha: 0.85),
                            height: 1.5,
                          ),
                        ).animate().fadeIn(delay: 1000.ms),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  거대 이름 (Image 3 처럼 두 줄로 쌓기)
//   ANI / MAL / PLA / NET 처럼 분할해서 거대하게
// ═══════════════════════════════════════════════════════════
class _GiantStackedName extends StatelessWidget {
  final String name;
  final Color color;
  final double maxWidth;
  const _GiantStackedName({
    required this.name,
    required this.color,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    // 길이에 따라 한 줄/두 줄 결정
    // 짧으면 (≤5자) 한 줄, 길면 반으로 쪼개기
    final pieces = _split(name);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: pieces.map((p) {
        return _PixelGiantText(
          text: p,
          color: color,
          maxWidth: maxWidth,
        );
      }).toList(),
    );
  }

  List<String> _split(String s) {
    if (s.length <= 5) return [s];
    final mid = (s.length / 2).ceil();
    return [s.substring(0, mid), s.substring(mid)];
  }
}

class _PixelGiantText extends StatelessWidget {
  final String text;
  final Color color;
  final double maxWidth;
  const _PixelGiantText({
    required this.text,
    required this.color,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    // 글자 수에 비례해 폰트크기 자동 조정 (전 폭을 채움)
    // 평균 너비 ~ fontSize × 0.55 (Inter Black 기준)
    final fontSize = (maxWidth / (text.length * 0.55))
        .clamp(64.0, 130.0).toDouble();

    return SizedBox(
      width: maxWidth,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: -fontSize * 0.06,
          height: 0.85,
        ),
      ),
    );
  }
}

// 격자 배경
class _GridBackgroundPainter extends CustomPainter {
  final Color color;
  _GridBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    const cell = 14.0;
    for (double x = 0; x <= size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y <= size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _GridBackgroundPainter old) => old.color != color;
}

// ═══════════════════════════════════════════════════════════
//  Page 2: 영수증 (기존 디자인 유지)
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
    final dateStr =
        '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      physics: const BouncingScrollPhysics(),
      children: [
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
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.wine,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  AppCopy.resultPersona,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.surface,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _ReceiptRow(label: '동물', value: animal.name),
              _ReceiptRow(label: '본능', value: animal.archetype),
              _ReceiptRow(label: '발급일', value: dateStr),
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
              const SizedBox(height: 18),
              _Divider(),
              const SizedBox(height: 14),
              Text(
                AppCopy.resultRecommended,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              ...rec.picks.take(6).map((pick) {
                final stock = pick.stock;
                final palette = AppColors.paletteFor(stock.sector.name);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 14,
                        decoration: BoxDecoration(
                          color: palette.bg,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
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
                  padding: const EdgeInsets.only(top: 6, left: 16),
                  child: Text(
                    '외 ${rec.picks.length - 6}개 종목',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              _Divider(),
              const SizedBox(height: 14),
              Text(
                AppCopy.resultSummary,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              _ReceiptRow(
                  label: '월 배당 목표',
                  value: '₩${_fmt(persona.monthlyTarget)}'),
              _ReceiptRow(
                  label: '필요 투자금',
                  value: '₩${_fmt(rec.totalInvestment)}'),
              _ReceiptRow(
                  label: '커버리지',
                  value: '${rec.coverageCount} / 12개월'),
              const SizedBox(height: 12),
              _Divider(),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppCopy.resultMonthly,
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
                    '$pct${AppCopy.resultGoalSuffix}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: pct >= 100
                          ? AppColors.gold
                          : AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            '· ${AppCopy.resultReceiptHint} ·',
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
    final path = Path()..addRRect(rect);
    final dashed = _dashedPath(path, dashLength: 4, gapLength: 4);
    canvas.drawPath(dashed, paint);
  }

  Path _dashedPath(Path source,
      {required double dashLength, required double gapLength}) {
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

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: const BoxDecoration(color: AppColors.borderSoft),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Bottom CTA
// ═══════════════════════════════════════════════════════════
class _BottomCta extends StatelessWidget {
  final int page;
  final PersonaAnimal animal;
  final VoidCallback onNext;

  const _BottomCta({
    required this.page,
    required this.animal,
    required this.onNext,
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
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onNext,
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  const SizedBox(width: 24),
                  Text(
                    isFirst ? AppCopy.resultCtaToReceipt : AppCopy.resultCtaToHome,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: fg,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: fg.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                        color: fg.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: fg,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
