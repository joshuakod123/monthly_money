import 'package:flutter/material.dart';
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
  late List<StockSector> _sectors;

  @override
  void initState() {
    super.initState();
    final goal = ref.read(userGoalProvider);
    _monthlyTarget = goal.monthlyTarget;
    _profile = goal.profile;
    _sectors = List.from(goal.preferredSectors);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        title: const Text('목표 설정'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(title: '월 배당 목표', subtitle: '얼마를 목표로 하시나요?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    '${formatKRW(_monthlyTarget)} / 월',
                    style: const TextStyle(
                      color: Colors.white, fontSize: 28,
                      fontWeight: FontWeight.w700, letterSpacing: -1,
                    ),
                  ),
                  Text(
                    '연 ${formatKRW(_monthlyTarget * 12)}',
                    style: const TextStyle(color: AppColors.accent, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.accent,
                      inactiveTrackColor: Colors.white.withOpacity(0.15),
                      thumbColor: AppColors.accent,
                      overlayColor: AppColors.accent.withOpacity(0.2),
                    ),
                    child: Slider(
                      value: _monthlyTarget.toDouble(),
                      min: 100000,
                      max: 10000000,
                      divisions: 99,
                      onChanged: (v) => setState(() => _monthlyTarget = v.round()),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('10만원', style: TextStyle(color: Colors.white38, fontSize: 11)),
                      Text('1,000만원', style: TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [500000, 1000000, 2000000, 3000000, 5000000].map((v) {
                final selected = _monthlyTarget == v;
                return GestureDetector(
                  onTap: () => setState(() => _monthlyTarget = v),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.accent : Colors.white,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: selected ? AppColors.accent : AppColors.border,
                      ),
                    ),
                    child: Text(
                      formatKRW(v),
                      style: TextStyle(
                        fontSize: 12,
                        color: selected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            const _SectionTitle(
              title: '투자 성향',
              subtitle: '어떤 스타일의 투자를 선호하시나요?',
            ),
            const SizedBox(height: 12),
            ...InvestmentProfile.values.map((p) => _ProfileCard(
              profile: p,
              selected: _profile == p,
              onTap: () => setState(() => _profile = p),
            )),

            const SizedBox(height: 32),

            const _SectionTitle(
              title: '선호 섹터',
              subtitle: '어떤 섹터의 주식에 관심 있으신가요? (복수 선택)',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: StockSector.values.map((s) {
                final selected = _sectors.contains(s);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (s == StockSector.all) {
                        _sectors = [StockSector.all];
                      } else {
                        _sectors.remove(StockSector.all);
                        if (selected) {
                          _sectors.remove(s);
                        } else {
                          _sectors.add(s);
                        }
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(s.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          s.label,
                          style: TextStyle(
                            color: selected ? AppColors.accent : AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(userGoalProvider.notifier).updateMonthlyTarget(_monthlyTarget);
                  ref.read(userGoalProvider.notifier).updateProfile(_profile);
                  ref.read(userGoalProvider.notifier).updateSectors(_sectors);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text(
                  '저장하고 추천 받기',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(subtitle,
            style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary,
            )),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final InvestmentProfile profile;
  final bool selected;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.profile,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.accent : AppColors.border,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                child: Container(
                  width: 10, height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.label,
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: selected ? AppColors.accent : AppColors.textPrimary,
                      )),
                  const SizedBox(height: 3),
                  Text(profile.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: selected ? Colors.white60 : AppColors.textSecondary,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}