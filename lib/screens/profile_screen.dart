import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../algorithms/persona_profile.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'quiz_screen.dart';

/// ═══════════════════════════════════════════════════════════
///  ProfileScreen — Linear 톤
///   - 8차원을 레이더 차트 하나로 압축
///   - 목표/예산 한 줄 row
///   - 컴팩트
/// ═══════════════════════════════════════════════════════════
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final persona = ref.watch(personaProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text(
          '내 정보',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
          child: persona == null
              ? const Center(
            child: Text(
              '퀴즈를 먼저 완료해주세요',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          )
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 페르소나 라벨
              const Text(
                'INVESTMENT PROFILE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                  letterSpacing: 1.2,
                ),
              ).animate().fadeIn(duration: 280.ms),
              const SizedBox(height: 10),
              Text(
                persona.summarize(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.8,
                  height: 1.2,
                ),
              ).animate().fadeIn(delay: 100.ms, duration: 320.ms),

              const SizedBox(height: 28),

              // ── 레이더 차트
              Center(
                child: _PersonaRadar(persona: persona),
              ).animate().fadeIn(delay: 200.ms, duration: 480.ms),

              const SizedBox(height: 24),

              // ── 목표 + 예산 (한 줄)
              _GoalsCompact(persona: persona)
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 320.ms),

              const Spacer(),

              // ── 퀴즈 다시 풀기
              _RetakeButton(onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuizScreen()),
                );
              }).animate().fadeIn(delay: 500.ms, duration: 320.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  레이더 차트 — 8차원 한 번에 시각화
// ═══════════════════════════════════════════════════════════
class _PersonaRadar extends StatelessWidget {
  final PersonaProfile persona;

  const _PersonaRadar({required this.persona});

  @override
  Widget build(BuildContext context) {
    // 차원별 라벨 + 값 (-1 ~ +1을 0 ~ 1로 정규화)
    final dimensions = [
      _Dim('시간 지평', (persona.horizon + 1) / 2, '단기', '장기'),
      _Dim('현금흐름', (persona.cashflowPreference + 1) / 2, '월급', '보너스'),
      _Dim('하방 방어', (persona.downsideTolerance + 1) / 2, '방어', '공격'),
      _Dim('세금', (-persona.taxSensitivity + 1) / 2, '편하게', '회피'),
      _Dim('유동성', (persona.liquidityNeed + 1) / 2, '필요', '묶어둠'),
      _Dim('윤리', (-persona.ethicsLooseness + 1) / 2, '느슨', '엄격'),
      _Dim('분산도', (persona.diversificationDemand + 1) / 2, '집중', '분산'),
      _Dim('인플레', (persona.inflationHedge + 1) / 2, '약함', '강함'),
    ];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return SizedBox(
          width: 280,
          height: 280,
          child: CustomPaint(
            painter: _RadarPainter(dimensions: dimensions, animation: t),
          ),
        );
      },
    );
  }
}

class _Dim {
  final String label;
  final double value; // 0 ~ 1
  final String low, high;
  const _Dim(this.label, this.value, this.low, this.high);
}

class _RadarPainter extends CustomPainter {
  final List<_Dim> dimensions;
  final double animation;

  _RadarPainter({required this.dimensions, required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 32;
    final n = dimensions.length;

    // ── 배경 격자 (4단계)
    final gridPaint = Paint()
      ..color = AppColors.border
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

    // ── 축선
    final axisPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;

    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + (2 * math.pi / n) * i;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), axisPaint);
    }

    // ── 데이터 폴리곤 (애니메이션)
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

    // 채우기
    canvas.drawPath(
      dataPath,
      Paint()..color = AppColors.accent.withValues(alpha: 0.15),
    );

    // 외곽선
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 데이터 포인트 (작은 점)
    for (final p in dataPoints) {
      canvas.drawCircle(
        p,
        2.5,
        Paint()..color = AppColors.accent,
      );
    }

    // ── 라벨
    final labelStyle = const TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
      letterSpacing: -0.1,
    );

    for (int i = 0; i < n; i++) {
      final angle = -math.pi / 2 + (2 * math.pi / n) * i;
      final labelRadius = radius + 18;
      final x = center.dx + labelRadius * math.cos(angle);
      final y = center.dy + labelRadius * math.sin(angle);

      final tp = TextPainter(
        text: TextSpan(text: dimensions[i].label, style: labelStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      tp.layout();
      tp.paint(
        canvas,
        Offset(x - tp.width / 2, y - tp.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.animation != animation || old.dimensions != dimensions;
}

// ═══════════════════════════════════════════════════════════
//  목표/예산 컴팩트 row
// ═══════════════════════════════════════════════════════════
class _GoalsCompact extends StatelessWidget {
  final PersonaProfile persona;
  const _GoalsCompact({required this.persona});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          _Row(
            label: '월 배당 목표',
            value: formatKRW(persona.monthlyTarget),
          ),
          Container(height: 1, color: AppColors.border),
          _Row(
            label: '투자 예산',
            value: formatKRW(persona.budget),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  퀴즈 다시 풀기 — 미니멀 ghost 버튼
// ═══════════════════════════════════════════════════════════
class _RetakeButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RetakeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: const Icon(
          Icons.refresh_rounded,
          size: 16,
          color: AppColors.textSecondary,
        ),
        label: const Text(
          '퀴즈 다시 풀기',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppColors.border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }
}