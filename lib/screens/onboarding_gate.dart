import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'main_scaffold.dart';
import 'quiz_screen.dart';

class OnboardingGate extends ConsumerWidget {
  const OnboardingGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final persona = ref.watch(personaProfileProvider);
    if (persona == null) return const _WelcomeScreen();
    return const MainScaffold();
  }
}

class _WelcomeScreen extends StatelessWidget {
  const _WelcomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단: 작은 라벨
              Row(
                children: [
                  Container(width: 32, height: 1.5, color: AppColors.wine),
                  const SizedBox(width: 10),
                  Text(
                    'EST. 2026',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.wine,
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),

              const Spacer(flex: 2),

              // 로고/심볼
              Text(
                '※',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 80,
                  color: AppColors.wine,
                  fontWeight: FontWeight.w400,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

              const SizedBox(height: 24),

              // 메인 헤드라인
              Text(
                '배당나무',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -2,
                  height: 1,
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 480.ms)
                  .slideY(begin: 0.05),

              const SizedBox(height: 12),

              Text(
                'Baedang Namu',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.5,
                ),
              ).animate().fadeIn(delay: 600.ms, duration: 320.ms),

              const SizedBox(height: 40),

              // 설명
              Container(
                width: 32,
                height: 1,
                color: AppColors.wine.withValues(alpha: 0.4),
              ).animate().fadeIn(delay: 700.ms),

              const SizedBox(height: 20),

              Text(
                '8가지 질문으로\n당신의 투자 본능을\n발견합니다',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                  height: 1.4,
                ),
              )
                  .animate()
                  .fadeIn(delay: 800.ms, duration: 480.ms)
                  .slideY(begin: 0.03),

              const SizedBox(height: 12),

              Text(
                '시간이 당신의 자산을 익혀줍니다',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
              ).animate().fadeIn(delay: 1000.ms),

              const Spacer(flex: 3),

              // CTA
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const QuizScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: AppColors.wine,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 24),
                        Text(
                          '시작하기',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.surface,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.wineDeep,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                            color: AppColors.surface,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 1200.ms, duration: 480.ms),

              const SizedBox(height: 16),

              Center(
                child: Text(
                  '· 약 2분 소요 ·',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textTertiary,
                    letterSpacing: 0.3,
                  ),
                ),
              ).animate().fadeIn(delay: 1400.ms),
            ],
          ),
        ),
      ),
    );
  }
}