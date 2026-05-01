import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import '../main_scaffold.dart';
import '../quiz_screen.dart';

/// ═══════════════════════════════════════════════════════════
///  OnboardingGate — 퀴즈 완료 여부에 따라 분기
///   - 퀴즈 완료 → MainScaffold (홈)
///   - 미완료 → QuizScreen (강제 온보딩)
/// ═══════════════════════════════════════════════════════════
class OnboardingGate extends ConsumerWidget {
  const OnboardingGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final persona = ref.watch(personaProfileProvider);

    // SharedPreferences 로딩 중이면 잠깐 빈 화면 (수십 ms)
    // null 이면 퀴즈 미완료 → 퀴즈 진입
    if (persona == null) {
      return const _WelcomeScreen();
    }
    return const MainScaffold();
  }
}

/// 환영 + 퀴즈 시작 화면
class _WelcomeScreen extends StatelessWidget {
  const _WelcomeScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              const Text('🌱', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              const Text(
                '배당나무',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '8가지 질문으로\n나에게 딱 맞는\n배당 포트폴리오를 만들어요',
                style: TextStyle(
                  fontSize: 18,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QuizScreen()),
                    );
                    // 퀴즈에서 setProfile 호출되면 OnboardingGate가 자동 리빌드돼서 MainScaffold로 감
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '시작하기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}