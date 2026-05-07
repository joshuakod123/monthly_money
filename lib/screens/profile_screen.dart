import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../algorithms/persona_animal.dart';
import '../algorithms/persona_profile.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/animal_illustration.dart';
import 'quiz_result_screen.dart';
import 'quiz_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final persona = ref.watch(personaProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: persona == null
            ? const Center(
          child: Text(
            '먼저 퀴즈를 완료해주세요',
            style: TextStyle(color: AppColors.textTertiary),
          ),
        )
            : ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 100),
          children: [
            _Header(),
            const SizedBox(height: 18),
            _SummaryHeadline(persona: persona),
            const SizedBox(height: 24),
            _AnimalCard(animal: PersonaAnimal.fromProfile(persona))
                .animate()
                .fadeIn(delay: 150.ms, duration: 400.ms)
                .slideY(begin: 0.05),
            const SizedBox(height: 28),
            const _SectionLabel(label: AppCopy.profileTraits),
            const SizedBox(height: 12),
            _RadarCard(persona: persona)
                .animate()
                .fadeIn(delay: 350.ms, duration: 480.ms),
            const SizedBox(height: 28),
            const _SectionLabel(label: AppCopy.profileGoals),
            const SizedBox(height: 12),
            _GoalsCard(persona: persona)
                .animate()
                .fadeIn(delay: 500.ms, duration: 320.ms),
            const SizedBox(height: 28),
            const _SectionLabel(label: AppCopy.profileActions),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.refresh_rounded,
              label: AppCopy.profileRetake,
              subtitle: AppCopy.profileRetakeSub,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuizScreen()),
              ),
            ).animate().fadeIn(delay: 600.ms, duration: 320.ms),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.receipt_long_rounded,
              label: AppCopy.profileReceipt,
              subtitle: '동물 카드와 추천 결과',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const QuizResultScreen()),
              ),
            ).animate().fadeIn(delay: 650.ms, duration: 320.ms),
            const SizedBox(height: 8),
            _ActionTile(
              icon: Icons.info_outline_rounded,
              label: AppCopy.profileAppInfo,
              subtitle: 'v1.0.0',
              onTap: () {},
            ).animate().fadeIn(delay: 700.ms, duration: 320.ms),
            const SizedBox(height: 32),
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

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 24, height: 1.5, color: AppColors.wine),
        const SizedBox(width: 10),
        Text(
          AppCopy.profileLabel,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.wine,
            letterSpacing: 2.5,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 280.ms);
  }
}

class _SummaryHeadline extends StatelessWidget {
  final PersonaProfile persona;
  const _SummaryHeadline({required this.persona});

  @override
  Widget build(BuildContext context) {
    final traits = persona.summarize().split(' · ');

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (int i = 0; i < traits.length; i++) ...[
          Text(
            traits[i],
            style: GoogleFonts.playfairDisplay(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.6,
              height: 1.2,
            ),
          ),
          if (i < traits.length - 1)
            Text(
              '·',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: AppColors.wine,
              ),
            ),
        ],
      ],
    ).animate().fadeIn(delay: 80.ms, duration: 320.ms);
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
        Expanded(
          child: Container(height: 1, color: AppColors.borderSoft),
        ),
      ],
    );
  }
}

class _AnimalCard extends StatelessWidget {
  final PersonaAnimal animal;
  const _AnimalCard({required this.animal});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QuizResultScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: animal.signatureBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Stack(
          children: [
            // 워터마크 grid
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: CustomPaint(painter: _GridPainter(color: animal.illustrationInk)),
              ),
            ),
            // 우상단 mini animal (B&W)
            Positioned(
              right: -6,
              top: -6,
              child: Opacity(
                opacity: 0.18,
                child: SizedBox(
                  width: 110,
                  height: 110,
                  child: AnimalIllustration(
                    illustrationId: animal.illustrationId,
                    ink: animal.illustrationInk,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 16,
                      height: 1,
                      color: animal.signatureText.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppCopy.personaSpiritLabel,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: animal.signatureText.withValues(alpha: 0.8),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: AnimalIllustration(
                        illustrationId: animal.illustrationId,
                        ink: animal.signatureText,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            animal.name,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: animal.signatureText,
                              letterSpacing: -0.8,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            animal.latinName,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: animal.signatureText.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  height: 1,
                  color: animal.signatureText.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 12),
                Text(
                  animal.tagline,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: animal.signatureText,
                    letterSpacing: -0.3,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: animal.traits.map((t) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: animal.signatureText.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                          color: animal.signatureText.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        t,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: animal.signatureText,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      AppCopy.profileReceipt,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: animal.signatureText.withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: animal.signatureText.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const step = 18.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _RadarCard extends StatelessWidget {
  final PersonaProfile persona;
  const _RadarCard({required this.persona});

  @override
  Widget build(BuildContext context) {
    final dimensions = [
      _Dim('시간', (persona.horizon + 1) / 2),
      _Dim('현금흐름', (persona.cashflowPreference + 1) / 2),
      _Dim('하방방어', (persona.downsideTolerance + 1) / 2),
      _Dim('세금', (-persona.taxSensitivity + 1) / 2),
      _Dim('유동성', (persona.liquidityNeed + 1) / 2),
      _Dim('윤리', (-persona.ethicsLooseness + 1) / 2),
      _Dim('분산', (persona.diversificationDemand + 1) / 2),
      _Dim('인플레', (persona.inflationHedge + 1) / 2),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, t, _) {
                return CustomPaint(
                  painter: _RadarPainter(
                    dimensions: dimensions,
                    animation: t,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.borderSoft),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final colWidth = (constraints.maxWidth - 16) / 2;
              return Wrap(
                spacing: 16,
                runSpacing: 10,
                children: dimensions.map((d) {
                  return SizedBox(
                    width: colWidth,
                    child: _ScoreRow(d: d),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final _Dim d;
  const _ScoreRow({required this.d});

  @override
  Widget build(BuildContext context) {
    final pct = (d.value * 100).round();
    return Row(
      children: [
        Container(
          width: 4,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.wine.withValues(alpha: 0.3 + d.value * 0.7),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            d.label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '$pct',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.wine,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _Dim {
  final String label;
  final double value;
  const _Dim(this.label, this.value);
}

class _RadarPainter extends CustomPainter {
  final List<_Dim> dimensions;
  final double animation;

  _RadarPainter({required this.dimensions, required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 44;
    final n = dimensions.length;

    final gridPaint = Paint()
      ..color = AppColors.borderSoft
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int level = 1; level <= 4; level++) {
      final r = radius * (level / 4);
      final path = Path();
      for (int i = 0; i < n; i++) {
        final angle = -math.pi / 2 + (2 * math.pi / n) * i;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    final axisPaint = Paint()
      ..color = AppColors.borderSoft
      ..strokeWidth = 1;

    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + (2 * math.pi / n) * i;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), axisPaint);
    }

    final dataPath = Path();
    final dataPoints = <Offset>[];

    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + (2 * math.pi / n) * i;
      final v = dimensions[i].value.clamp(0.0, 1.0) * animation;
      final r = radius * v;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      dataPoints.add(Offset(x, y));
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();

    canvas.drawPath(
      dataPath,
      Paint()..color = AppColors.wine.withValues(alpha: 0.18),
    );
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = AppColors.wine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    for (final p in dataPoints) {
      canvas.drawCircle(p, 3, Paint()..color = AppColors.wine);
    }

    final labelStyle = GoogleFonts.inter(
      fontSize: 10.5,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
      letterSpacing: 0.1,
    );

    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + (2 * math.pi / n) * i;
      final cosA = math.cos(angle);
      final sinA = math.sin(angle);

      final anchorRadius = radius + 10;
      final ax = center.dx + anchorRadius * cosA;
      final ay = center.dy + anchorRadius * sinA;

      final tp = TextPainter(
        text: TextSpan(text: dimensions[i].label, style: labelStyle),
        textDirection: TextDirection.ltr,
      );
      tp.layout();

      double dx;
      double dy;

      if (cosA.abs() < 0.15) {
        dx = ax - tp.width / 2;
        dy = sinA < 0 ? ay - tp.height : ay;
      } else if (cosA > 0) {
        dx = ax;
        dy = ay - tp.height / 2;
      } else {
        dx = ax - tp.width;
        dy = ay - tp.height / 2;
      }

      tp.paint(canvas, Offset(dx, dy));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.animation != animation;
}

class _GoalsCard extends StatelessWidget {
  final PersonaProfile persona;
  const _GoalsCard({required this.persona});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          _GoalRow(
            label: AppCopy.quizMonthlyLbl,
            value: '₩${_fmt(persona.monthlyTarget)}',
          ),
          Container(height: 1, color: AppColors.borderSoft),
          _GoalRow(
            label: AppCopy.quizBudgetLbl,
            value: '₩${_fmt(persona.budget)}',
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

class _GoalRow extends StatelessWidget {
  final String label;
  final String value;
  const _GoalRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 16, color: AppColors.wine),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}