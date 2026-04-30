import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../algorithms/persona_profile.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

/// ═══════════════════════════════════════════════════════════
///  QuizScreen — 스무고개 식 개인화 질문 흐름
///
///  특징:
///   - 한 화면 한 질문 (집중)
///   - 진행률 바 (얼마 남았나 시각화)
///   - 각 답변 후 미세한 햅틱 + 다음 질문 자동 전환
///   - 마지막 질문 후 PersonaProfile 빌드 → 홈 화면 갱신
/// ═══════════════════════════════════════════════════════════
class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _currentIndex = 0;
  final Map<String, List<int>> _answers = {};
  final PageController _pageController = PageController();

  // 마지막 화면(목표 + 예산)
  int _monthlyTarget = 2000000;
  int _budget = 50000000;
  final List<String> _preferredSectors = [];

  int get _totalSteps => QuizBank.questions.length + 1; // +1 for goal screen

  void _onAnswer(QuizQuestion q, int optionIdx) {
    setState(() {
      if (q.type == QuestionType.multiChoice) {
        final list = _answers[q.id] ?? [];
        if (list.contains(optionIdx)) {
          list.remove(optionIdx);
        } else {
          list.add(optionIdx);
        }
        _answers[q.id] = list;
      } else {
        _answers[q.id] = [optionIdx];
        _goNext();
      }
    });
  }

  void _goNext() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_currentIndex < _totalSteps - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
        setState(() => _currentIndex++);
      }
    });
  }

  void _goPrev() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      setState(() => _currentIndex--);
    }
  }

  void _finish() {
    final profile = QuizBank.buildProfile(
      answers: _answers,
      monthlyTarget: _monthlyTarget,
      budget: _budget,
      preferredSectors: _preferredSectors,
    );
    ref.read(personaProfileProvider.notifier).state = profile;
    Navigator.pop(context, profile);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentIndex + 1) / _totalSteps;
    final isLast = _currentIndex == _totalSteps - 1;

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        backgroundColor: AppColors.bgPage,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _currentIndex == 0
              ? () => Navigator.pop(context)
              : _goPrev,
        ),
        title: Text(
          '${_currentIndex + 1} / $_totalSteps',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.border,
            valueColor:
            const AlwaysStoppedAnimation<Color>(AppColors.accent),
            minHeight: 3,
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          ...QuizBank.questions.map((q) => _QuestionPage(
            question: q,
            selected: _answers[q.id] ?? [],
            onTap: (idx) => _onAnswer(q, idx),
            onContinue: q.type == QuestionType.multiChoice
                ? _goNext
                : null,
          )),
          _GoalPage(
            monthlyTarget: _monthlyTarget,
            budget: _budget,
            preferredSectors: _preferredSectors,
            onTargetChanged: (v) => setState(() => _monthlyTarget = v),
            onBudgetChanged: (v) => setState(() => _budget = v),
            onSectorsChanged: (v) =>
                setState(() {
                  _preferredSectors..clear()..addAll(v);
                }),
            onFinish: _finish,
          ),
        ],
      ),
    );
  }
}

class _QuestionPage extends StatelessWidget {
  final QuizQuestion question;
  final List<int> selected;
  final ValueChanged<int> onTap;
  final VoidCallback? onContinue;

  const _QuestionPage({
    required this.question,
    required this.selected,
    required this.onTap,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
              height: 1.3,
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
          if (question.subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              question.subtitle!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
          ],
          const SizedBox(height: 28),
          ...question.options.asMap().entries.map((entry) {
            final idx = entry.key;
            final opt = entry.value;
            final isSelected = selected.contains(idx);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OptionTile(
                option: opt,
                isSelected: isSelected,
                onTap: () => onTap(idx),
              )
                  .animate()
                  .fadeIn(
                delay: Duration(milliseconds: 100 + idx * 60),
                duration: 320.ms,
              )
                  .slideY(begin: 0.15, end: 0),
            );
          }),
          if (onContinue != null && selected.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '다음',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ).animate().fadeIn(duration: 200.ms),
          ],
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final QuizOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withOpacity(0.2)
                    : AppColors.bgPage,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(option.emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (option.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      option.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? Colors.white60
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.accent, size: 22),
          ],
        ),
      ),
    );
  }
}

/// ─────────────────────────────────────────
/// 마지막 페이지: 목표 금액 + 예산
/// ─────────────────────────────────────────
class _GoalPage extends StatelessWidget {
  final int monthlyTarget;
  final int budget;
  final List<String> preferredSectors;
  final ValueChanged<int> onTargetChanged;
  final ValueChanged<int> onBudgetChanged;
  final ValueChanged<List<String>> onSectorsChanged;
  final VoidCallback onFinish;

  const _GoalPage({
    required this.monthlyTarget,
    required this.budget,
    required this.preferredSectors,
    required this.onTargetChanged,
    required this.onBudgetChanged,
    required this.onSectorsChanged,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text(
            '마지막으로,\n목표와 예산을 알려주세요',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
              height: 1.3,
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 32),

          // 월 배당 목표
          const Text('월 배당 목표',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          _AmountCard(
            label: formatKRW(monthlyTarget),
            secondary: '연 ${formatKRW(monthlyTarget * 12)}',
            slider: Slider(
              value: monthlyTarget.toDouble(),
              min: 100000,
              max: 10000000,
              divisions: 99,
              onChanged: (v) => onTargetChanged(v.round()),
            ),
            quick: [500000, 1000000, 2000000, 3000000, 5000000],
            current: monthlyTarget,
            onPick: onTargetChanged,
          ),

          const SizedBox(height: 28),

          const Text('투자 가능 예산',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          _AmountCard(
            label: formatKRW(budget),
            secondary: '추가 투자 가능액',
            slider: Slider(
              value: budget.toDouble(),
              min: 1000000,
              max: 500000000,
              divisions: 100,
              onChanged: (v) => onBudgetChanged(v.round()),
            ),
            quick: [10000000, 30000000, 50000000, 100000000, 200000000],
            current: budget,
            onPick: onBudgetChanged,
          ),

          const SizedBox(height: 28),

          const Text('선호 섹터 (있다면)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text(
            '비워두셔도 됩니다 — 알고리즘이 자동으로 분산해드려요',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _SectorOption(id: 'finance', label: '금융', emoji: '🏦'),
              _SectorOption(id: 'telecom', label: '통신', emoji: '📡'),
              _SectorOption(id: 'reit', label: '리츠', emoji: '🏢'),
              _SectorOption(id: 'consumer', label: '소비재', emoji: '🛒'),
              _SectorOption(id: 'energy', label: '에너지', emoji: '⚡'),
              _SectorOption(id: 'healthcare', label: '헬스케어', emoji: '💊'),
            ].map((opt) {
              final selected = preferredSectors.contains(opt.id);
              return GestureDetector(
                onTap: () {
                  final next = [...preferredSectors];
                  if (selected) {
                    next.remove(opt.id);
                  } else {
                    next.add(opt.id);
                  }
                  onSectorsChanged(next);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
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
                      Text(opt.emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        opt.label,
                        style: TextStyle(
                          color: selected
                              ? AppColors.accent
                              : AppColors.textPrimary,
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
              onPressed: onFinish,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '내 맞춤 포트폴리오 보기',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
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

class _AmountCard extends StatelessWidget {
  final String label;
  final String secondary;
  final Widget slider;
  final List<int> quick;
  final int current;
  final ValueChanged<int> onPick;

  const _AmountCard({
    required this.label,
    required this.secondary,
    required this.slider,
    required this.quick,
    required this.current,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
              )),
          Text(secondary,
              style: const TextStyle(color: AppColors.accent, fontSize: 12)),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: Colors.white.withOpacity(0.15),
              thumbColor: AppColors.accent,
              overlayColor: AppColors.accent.withOpacity(0.2),
            ),
            child: slider,
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: quick.map((v) {
              final selected = current == v;
              return GestureDetector(
                onTap: () => onPick(v),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.accent
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    formatKRW(v),
                    style: TextStyle(
                      fontSize: 11,
                      color:
                      selected ? AppColors.primary : Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SectorOption {
  final String id;
  final String label;
  final String emoji;
  const _SectorOption(
      {required this.id, required this.label, required this.emoji});
}