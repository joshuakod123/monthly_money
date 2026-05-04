import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../algorithms/persona_profile.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'quiz_result_screen.dart';

/// ═══════════════════════════════════════════════════════════
///  QuizScreen — Linear/Vercel 톤
///   - 다크 테마 정착 (흰 배경 카드 제거)
///   - 보더 기반 선택 표시
///   - 절제된 액센트 사용
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

  void _finish() async {
    final profile = QuizBank.buildProfile(
      answers: _answers,
      monthlyTarget: _monthlyTarget,
      budget: _budget,
      preferredSectors: _preferredSectors,
    );
    await ref.read(personaProfileProvider.notifier).setProfile(profile);

    if (!mounted) return;

    // 기존 Navigator.pop 대신 → 영수증 결과 화면으로 push
    // pushReplacement 쓰면 뒤로가기 시 퀴즈로 안 돌아감 (의도)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const QuizResultScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentIndex + 1) / _totalSteps;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
          onPressed: _currentIndex == 0 ? () => Navigator.pop(context) : _goPrev,
        ),
        title: Text(
          '${_currentIndex + 1} / $_totalSteps',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textTertiary,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Stack(
            children: [
              Container(height: 2, color: AppColors.border),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                widthFactor: progress,
                child: Container(height: 2, color: AppColors.accent),
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

// ═══════════════════════════════════════════════════════════
//  질문 페이지
// ═══════════════════════════════════════════════════════════
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
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 질문
          Text(
            question.question,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
              height: 1.35,
            ),
          ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.05),
          if (question.subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              question.subtitle!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textTertiary,
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 80.ms, duration: 280.ms),
          ],
          const SizedBox(height: 32),

          // 옵션들
          ...question.options.asMap().entries.map((entry) {
            final idx = entry.key;
            final opt = entry.value;
            final isSelected = selected.contains(idx);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _OptionTile(
                option: opt,
                isSelected: isSelected,
                onTap: () => onTap(idx),
              )
                  .animate()
                  .fadeIn(
                delay: Duration(milliseconds: 80 + idx * 40),
                duration: 280.ms,
              )
                  .slideY(begin: 0.08),
            );
          }),

          // multi-choice일 때만 다음 버튼
          if (onContinue != null && selected.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ContinueButton(onPressed: onContinue!)
                .animate()
                .fadeIn(duration: 200.ms),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  옵션 타일 — Linear 톤 (다크, 보더 기반 선택)
// ═══════════════════════════════════════════════════════════
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
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentGhost : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // 이모지 컨테이너
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: isSelected
                      ? AppColors.accent.withValues(alpha: 0.3)
                      : AppColors.border,
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(option.emoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            // 라벨 + 설명
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (option.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      option.description!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // 선택 표시 — 작은 점만
            if (isSelected)
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 11, color: AppColors.bg),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  공통 다음/완료 버튼
// ═══════════════════════════════════════════════════════════
class _ContinueButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData? icon;

  const _ContinueButton({
    required this.onPressed,
    this.label = '다음',
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textPrimary,
          foregroundColor: AppColors.bg,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  마지막 페이지 — 목표 + 예산
// ═══════════════════════════════════════════════════════════
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
      setState(() {});
    });
    _budgetFocus.addListener(() {
      if (!_budgetFocus.hasFocus) _commitBudget();
      setState(() {});
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
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '마지막으로,\n목표와 예산을 알려주세요',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
                height: 1.35,
              ),
            ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.05),
            const SizedBox(height: 8),
            const Text(
              '직접 입력하거나 슬라이더로 조절',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textTertiary,
                height: 1.5,
              ),
            ).animate().fadeIn(delay: 80.ms),
            const SizedBox(height: 32),

            _AmountInput(
              label: '월 배당 목표',
              controller: _targetCtrl,
              focusNode: _targetFocus,
              hint: '연 ${formatKRW(widget.monthlyTarget * 12)}',
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
            const SizedBox(height: 20),

            _AmountInput(
              label: '투자 예산',
              controller: _budgetCtrl,
              focusNode: _budgetFocus,
              hint: '한 번에 투자 가능한 총액',
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

            // ── 선호 섹터
            const Text(
              '선호 섹터',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '선택사항 — 비워두면 자동 분산',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: const [
                _SectorOption(id: 'finance', label: '금융', emoji: '🏦'),
                _SectorOption(id: 'telecom', label: '통신', emoji: '📡'),
                _SectorOption(id: 'reit', label: '리츠', emoji: '🏢'),
                _SectorOption(id: 'consumer', label: '소비재', emoji: '🛒'),
                _SectorOption(id: 'energy', label: '에너지', emoji: '⚡'),
                _SectorOption(id: 'industrial', label: '산업재', emoji: '🏭'),
              ].map((opt) {
                final selected = widget.preferredSectors.contains(opt.id);
                return _SectorChip(
                  option: opt,
                  isSelected: selected,
                  onTap: () {
                    final next = [...widget.preferredSectors];
                    if (selected) {
                      next.remove(opt.id);
                    } else {
                      next.add(opt.id);
                    }
                    widget.onSectorsChanged(next);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 36),

            _ContinueButton(
              onPressed: widget.onFinish,
              label: '내 포트폴리오 보기',
              icon: Icons.arrow_forward_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountInput extends StatelessWidget {
  final String label;
  final String hint;
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

  const _AmountInput({
    required this.label,
    required this.hint,
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
    final isFocused = focusNode.hasFocus;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isFocused ? AppColors.accent : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                hint,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textDisabled,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
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
                    hintStyle: TextStyle(color: AppColors.textDisabled),
                  ),
                  onChanged: onTextChanged,
                  onSubmitted: (_) => onCommit(),
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(bottom: 5),
                child: Text(
                  '원',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.textPrimary,
              overlayColor: AppColors.accent.withValues(alpha: 0.15),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: sliderValue.clamp(sliderMin, sliderMax),
              min: sliderMin,
              max: sliderMax,
              divisions: sliderDivisions,
              onChanged: onSliderChanged,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: quick.map((v) {
              final isSel = current == v;
              return GestureDetector(
                onTap: () => onPick(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.accentGhost : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: isSel ? AppColors.accent : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    formatKRW(v),
                    style: TextStyle(
                      fontSize: 11,
                      color: isSel ? AppColors.accent : AppColors.textSecondary,
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

class _SectorChip extends StatelessWidget {
  final _SectorOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _SectorChip({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentGhost : AppColors.bgElevated,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(option.emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              option.label,
              style: TextStyle(
                color: isSelected ? AppColors.accent : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
  const _SectorOption({
    required this.id,
    required this.label,
    required this.emoji,
  });
}