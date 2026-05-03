import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'quiz_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final persona = ref.watch(personaProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: const Text('내 정보',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (persona != null) ...[
              const Text('내 투자 성향',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  )),
              const SizedBox(height: 4),
              Text(persona.summarize(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  )),
              const SizedBox(height: 24),

              // 8차원 점수 카드
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _DimRow(label: '시간 지평', value: persona.horizon, lo: '단기', hi: '장기'),
                    _DimRow(label: '현금흐름', value: persona.cashflowPreference, lo: '월급형', hi: '보너스형'),
                    _DimRow(label: '하방 방어', value: persona.downsideTolerance, lo: '방어', hi: '공격'),
                    _DimRow(label: '세금 민감도', value: -persona.taxSensitivity, lo: '신경 안 씀', hi: '회피'),
                    _DimRow(label: '유동성', value: persona.liquidityNeed, lo: '필요', hi: '묶어둠'),
                    _DimRow(label: 'ESG 윤리', value: -persona.ethicsLooseness, lo: '느슨', hi: '엄격'),
                    _DimRow(label: '분산도', value: persona.diversificationDemand, lo: '집중', hi: '분산'),
                    _DimRow(label: '인플레이션 헷지', value: persona.inflationHedge, lo: '약함', hi: '강함'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 목표 카드
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _GoalRow(label: '월 배당 목표', value: formatKRW(persona.monthlyTarget)),
                    const SizedBox(height: 12),
                    _GoalRow(label: '투자 예산', value: formatKRW(persona.budget)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QuizScreen()),
                  );
                },
                icon: const Icon(Icons.refresh_rounded,
                    color: AppColors.primary),
                label: const Text('퀴즈 다시 풀기',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    )),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DimRow extends StatelessWidget {
  final String label;
  final double value; // -1 ~ +1
  final String lo, hi;
  const _DimRow({
    required this.label,
    required this.value,
    required this.lo,
    required this.hi,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = ((value + 1) / 2).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    )),
              ),
              Text(lo,
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 10,
                  )),
              const SizedBox(width: 6),
              Text(hi,
                  style: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 10,
                  )),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              FractionallySizedBox(
                widthFactor: normalized,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final String label;
  final String value;
  const _GoalRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          )),
      Text(value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          )),
    ],
  );
}