import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../algorithms/persona_profile.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

/// ═══════════════════════════════════════════════════════════
///  QuizScreen v4
///   - 9번째 질문: 타이핑 + 슬라이더 hybrid
///   - 더 깔끔한 시각 위계
///   - 진행률바 상단 고정
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

  int _monthlyTarget = 2000000;
  int _budget = 50000000;
  final List<String> _preferredSectors = [];

  int get _totalSteps => QuizBank.questions.length + 1;

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
    Future.delayed(const Duration(milliseconds: 220), () {
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Stack(
            children: [
              Container(height: 3, color: AppColors.border),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                widthFactor: progress,
                child: Container(height: 3, color: AppColors.accent),
              ),
            ],
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
            onContinue: q.type == QuestionType.multiChoice ? _goNext : null,
          )),
          _GoalPage(
            monthlyTarget: _monthlyTarget,
            budget: _budget,
            preferredSectors: _preferredSectors,
            onTargetChanged: (v) => setState(() => _monthlyTarget = v),
            onBudgetChanged: (v) => setState(() => _budget = v),
            onSectorsChanged: (v) => setState(() {
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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
              height: 1.35,
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
          if (question.subtitle != null) ...[
            const SizedBox(height: 10),
            Text(
              question.subtitle!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
          ],
          const SizedBox(height: 32),
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
  const _OptionTile(
      {required this.option, required this.isSelected, required this.onTap});

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
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.18),
              blurRadius: 14,
              offset: const Offset(0, 5),
            )
          ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withOpacity(0.18)
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
                      color: isSelected ? AppColors.accent : AppColors.textPrimary,
                    ),
                  ),
                  if (option.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      option.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? Colors.white.withOpacity(0.65)
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
/// 9번째: 목표 + 예산 (타이핑 입력 hybrid)
/// ─────────────────────────────────────────
class _GoalPage extends StatefulWidget {
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
  State<_GoalPage> createState() => _GoalPageState();
}

class _GoalPageState extends State<_GoalPage> {
  late TextEditingController _targetCtrl;
  late TextEditingController _budgetCtrl;
  final FocusNode _targetFocus = FocusNode();
  final FocusNode _budgetFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _targetCtrl = TextEditingController(text: _formatPlain(widget.monthlyTarget));
    _budgetCtrl = TextEditingController(text: _formatPlain(widget.budget));

    _targetFocus.addListener(() {
      if (!_targetFocus.hasFocus) _commitTarget();
    });
    _budgetFocus.addListener(() {
      if (!_budgetFocus.hasFocus) _commitBudget();
    });
  }

  @override
  void didUpdateWidget(_GoalPage old) {
    super.didUpdateWidget(old);
    if (!_targetFocus.hasFocus && widget.monthlyTarget != old.monthlyTarget) {
      _targetCtrl.text = _formatPlain(widget.monthlyTarget);
    }
    if (!_budgetFocus.hasFocus && widget.budget != old.budget) {
      _budgetCtrl.text = _formatPlain(widget.budget);
    }
  }

  @override
  void dispose() {
    _targetCtrl.dispose();
    _budgetCtrl.dispose();
    _targetFocus.dispose();
    _budgetFocus.dispose();
    super.dispose();
  }

  String _formatPlain(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  int _parse(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  void _commitTarget() {
    final v = _parse(_targetCtrl.text).clamp(100000, 50000000);
    widget.onTargetChanged(v);
    _targetCtrl.text = _formatPlain(v);
  }

  void _commitBudget() {
    final v = _parse(_budgetCtrl.text).clamp(1000000, 2000000000);
    widget.onBudgetChanged(v);
    _budgetCtrl.text = _formatPlain(v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text(
              '마지막으로,\n목표와 예산을 알려주세요',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
                height: 1.35,
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 8),
            const Text(
              '직접 입력하거나 슬라이더로 조절할 수 있어요',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 32),

            // ── 월 배당 목표 ─────
            _AmountInputCard(
              label: '월 배당 목표',
              suffix: '원',
              controller: _targetCtrl,
              focusNode: _targetFocus,
              secondary: '연 ${formatKRW(widget.monthlyTarget * 12)}',
              onCommit: _commitTarget,
              onTextChanged: (text) {
                final v = _parse(text);
                widget.onTargetChanged(v);
              },
              sliderValue: widget.monthlyTarget.toDouble(),
              sliderMin: 100000,
              sliderMax: 10000000,
              sliderDivisions: 99,
              onSliderChanged: (v) => widget.onTargetChanged(v.round()),
              quick: const [500000, 1000000, 2000000, 3000000, 5000000],
              current: widget.monthlyTarget,
              onPick: (v) {
                widget.onTargetChanged(v);
                _targetCtrl.text = _formatPlain(v);
              },
            ),
            const SizedBox(height: 24),

            // ── 예산 ─────
            _AmountInputCard(
              label: '투자 가능 예산',
              suffix: '원',
              controller: _budgetCtrl,
              focusNode: _budgetFocus,
              secondary: '한 번에 투자 가능한 총액',
              onCommit: _commitBudget,
              onTextChanged: (text) {
                final v = _parse(text);
                widget.onBudgetChanged(v);
              },
              sliderValue: widget.budget.toDouble(),
              sliderMin: 1000000,
              sliderMax: 500000000,
              sliderDivisions: 100,
              onSliderChanged: (v) => widget.onBudgetChanged(v.round()),
              quick: const [10000000, 30000000, 50000000, 100000000, 200000000],
              current: widget.budget,
              onPick: (v) {
                widget.onBudgetChanged(v);
                _budgetCtrl.text = _formatPlain(v);
              },
            ),
            const SizedBox(height: 28),

            // ── 선호 섹터 ─────
            const Text('선호 섹터 (선택사항)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text(
              '비워두셔도 됩니다 — 알고리즘이 자동 분산해드려요',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _SectorOption(id: 'finance', label: '금융', emoji: '🏦'),
                _SectorOption(id: 'telecom', label: '통신', emoji: '📡'),
                _SectorOption(id: 'reit', label: '리츠', emoji: '🏢'),
                _SectorOption(id: 'consumer', label: '소비재', emoji: '🛒'),
                _SectorOption(id: 'energy', label: '에너지', emoji: '⚡'),
                _SectorOption(id: 'industrial', label: '산업재', emoji: '🏭'),
              ].map((opt) {
                final selected = widget.preferredSectors.contains(opt.id);
                return GestureDetector(
                  onTap: () {
                    final next = [...widget.preferredSectors];
                    if (selected) {
                      next.remove(opt.id);
                    } else {
                      next.add(opt.id);
                    }
                    widget.onSectorsChanged(next);
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
                            fontWeight: FontWeight.w600,
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
                onPressed: widget.onFinish,
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
                      style:
                      TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountInputCard extends StatelessWidget {
  final String label;
  final String suffix;
  final String secondary;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onCommit;
  final ValueChanged<String> onTextChanged;
  final double sliderValue;
  final double sliderMin;
  final double sliderMax;
  final int sliderDivisions;
  final ValueChanged<double> onSliderChanged;
  final List<int> quick;
  final int current;
  final ValueChanged<int> onPick;

  const _AmountInputCard({
    required this.label,
    required this.suffix,
    required this.secondary,
    required this.controller,
    required this.focusNode,
    required this.onCommit,
    required this.onTextChanged,
    required this.sliderValue,
    required this.sliderMin,
    required this.sliderMax,
    required this.sliderDivisions,
    required this.onSliderChanged,
    required this.quick,
    required this.current,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          // ── 타이핑 입력 영역 ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: focusNode.hasFocus
                    ? AppColors.accent.withOpacity(0.6)
                    : Colors.white.withOpacity(0.12),
                width: 1.2,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                    ),
                    cursorColor: AppColors.accent,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _ThousandsFormatter(),
                    ],
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle: TextStyle(color: Colors.white24),
                    ),
                    onChanged: onTextChanged,
                    onSubmitted: (_) => onCommit(),
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    suffix,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            secondary,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          // ── 슬라이더 ──
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: Colors.white.withOpacity(0.12),
              thumbColor: AppColors.accent,
              overlayColor: AppColors.accent.withOpacity(0.2),
              trackHeight: 3,
            ),
            child: Slider(
              value: sliderValue.clamp(sliderMin, sliderMax),
              min: sliderMin,
              max: sliderMax,
              divisions: sliderDivisions,
              onChanged: onSliderChanged,
            ),
          ),
          // ── 빠른 선택 칩 ──
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: quick.map((v) {
              final selected = current == v;
              return GestureDetector(
                onTap: () => onPick(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.accent
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    formatKRW(v),
                    style: TextStyle(
                      fontSize: 11,
                      color: selected ? AppColors.primary : Colors.white70,
                      fontWeight: FontWeight.w700,
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

class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final cleaned = newValue.text.replaceAll(',', '');
    final n = int.tryParse(cleaned) ?? 0;
    final formatted = StringBuffer();
    final s = n.toString();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) formatted.write(',');
      formatted.write(s[i]);
    }
    return TextEditingValue(
      text: formatted.toString(),
      selection: TextSelection.collapsed(offset: formatted.length),
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