import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stock_model.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class GoalSetupScreen extends ConsumerStatefulWidget {
  const GoalSetupScreen({super.key});

  @override
  ConsumerState<GoalSetupScreen> createState() => _GoalSetupScreenState();
}

class _GoalSetupScreenState extends ConsumerState<GoalSetupScreen> {
  late int _monthlyTarget;
  late InvestmentProfile _profile;

  @override
  void initState() {
    super.initState();
    final goal = ref.read(userGoalProvider);
    _monthlyTarget = goal.monthlyTarget;
    _profile = goal.profile;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('투자 목표 설정', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('월 배당 목표액', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('은퇴 후 매월 받고 싶은 금액을 설정해주세요.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 32),

            // 깔끔한 금액 표시부
            Center(
              child: Text(
                formatKRW(_monthlyTarget),
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: -1),
              ),
            ),
            const SizedBox(height: 16),

            // 미니멀한 슬라이더
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.border,
                thumbColor: Colors.white,
                trackHeight: 4,
              ),
              child: Slider(
                value: _monthlyTarget.toDouble(),
                min: 100000,
                max: 10000000,
                divisions: 99,
                onChanged: (v) => setState(() => _monthlyTarget = v.round()),
              ),
            ),
            const SizedBox(height: 24),

            // 빠른 선택 버튼들
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [500000, 1000000, 2000000, 3000000].map((v) {
                final isSelected = _monthlyTarget == v;
                return GestureDetector(
                  onTap: () => setState(() => _monthlyTarget = v),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(formatKRW(v), style: TextStyle(fontSize: 13, color: isSelected ? AppColors.primary : AppColors.textPrimary, fontWeight: FontWeight.w500)),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 56),

            const Text('투자 성향', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 16),

            // 깔끔한 리스트 형태의 성향 선택
            ...InvestmentProfile.values.map((p) => _ProfileRow(
              profile: p,
              isSelected: _profile == p,
              onTap: () => setState(() => _profile = p),
            )),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: () {
              ref.read(userGoalProvider.notifier).updateMonthlyTarget(_monthlyTarget);
              ref.read(userGoalProvider.notifier).updateProfile(_profile);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('저장하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final InvestmentProfile profile;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProfileRow({required this.profile, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isSelected ? AppColors.primary : AppColors.textHint,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(profile.description, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}