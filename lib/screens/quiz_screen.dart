import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../algorithms/persona_profile.dart';
import '../models/stock_model.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'quiz_result_screen.dart';

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

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const QuizResultScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentIndex + 1) / _totalSteps;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 24, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _currentIndex == 0
                        ? () => Navigator.pop(context)
                        : _goPrev,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_currentIndex + 1} / $_totalSteps',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                      letterSpacing: 0.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 36),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Stack(
                children: [
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.borderSoft,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    widthFactor: progress,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: AppColors.wine,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: PageView(
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
                    onTargetChanged: (v) =>
                        setState(() => _monthlyTarget = v),
                    onBudgetChanged: (v) => setState(() => _budget = v),
                    onSectorsChanged: (v) => setState(() {
                      _preferredSectors
                        ..clear()
                        ..addAll(v);
                    }),
                    onFinish: _finish,
                  ),
                ],
              ),
            ),
          ],
        ),
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
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 20, height: 1.5, color: AppColors.wine),
              const SizedBox(width: 8),
              Text(
                AppCopy.quizLabel,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.wine,
                  letterSpacing: 2,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 280.ms),
          const SizedBox(height: 12),
          Text(
            question.question,
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: -0.6,
              height: 1.3,
            ),
          ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.05),
          if (question.subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              question.subtitle!,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textTertiary,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ).animate().fadeIn(delay: 80.ms, duration: 280.ms),
          ],
          const SizedBox(height: 28),
          ...question.options.asMap().entries.map((entry) {
            final idx = entry.key;
            final opt = entry.value;
            final isSelected = selected.contains(idx);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _OptionTile(
                option: opt,
                isSelected: isSelected,
                index: idx + 1,
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

class _OptionTile extends StatelessWidget {
  final QuizOption option;
  final bool isSelected;
  final int index;
  final VoidCallback onTap;

  const _OptionTile({
    required this.option,
    required this.isSelected,
    required this.index,
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
          color: isSelected ? AppColors.accentGhost : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected ? AppColors.wine : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // 인덱스 (영수증 라인 번호 스타일)
            SizedBox(
              width: 28,
              child: Text(
                index.toString().padLeft(2, '0'),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppColors.wine
                      : AppColors.textTertiary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Container(
              width: 1,
              height: 22,
              color: isSelected
                  ? AppColors.wine.withValues(alpha: 0.3)
                  : AppColors.borderSoft,
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: GoogleFonts.inter(
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
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: AppColors.wine,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check,
                    size: 11, color: AppColors.surface),
              ),
          ],
        ),
      ),
    );
  }
}

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
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.wine,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: AppColors.surface),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.surface,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

    _targetFocus.addListener(() => setState(() {}));
    _budgetFocus.addListener(() => setState(() {}));
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

  String _shortKrw(int v) {
    if (v >= 100000000) return '${(v / 100000000).toStringAsFixed(1)}억';
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(0)}만원';
    return '${v}원';
  }

  int _parse(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(cleaned) ?? 0;
  }

  void _onTargetTextChanged(String text) {
    final v = _parse(text).clamp(0, 50000000);
    widget.onTargetChanged(v);
  }

  void _onBudgetTextChanged(String text) {
    final v = _parse(text).clamp(0, 2000000000);
    widget.onBudgetChanged(v);
  }

  @override
  Widget build(BuildContext context) {
    // 11개 GICS 섹터 (StockSector.all 제외)
    final sectorOptions = StockSector.values
        .where((s) => s != StockSector.all)
        .toList();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 20, height: 1.5, color: AppColors.wine),
                const SizedBox(width: 8),
                Text(
                  AppCopy.quizGoalLabel,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.wine,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 280.ms),
            const SizedBox(height: 12),
            Text(
              AppCopy.quizGoalTitle,
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: -0.8,
                height: 1.25,
              ),
            ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.05),
            const SizedBox(height: 8),
            Text(
              AppCopy.quizGoalSub,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textTertiary,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ).animate().fadeIn(delay: 80.ms),

            const SizedBox(height: 28),

            _DirectInput(
              label: AppCopy.quizMonthlyLbl,
              controller: _targetCtrl,
              focusNode: _targetFocus,
              hint: _shortKrw(widget.monthlyTarget * 12) + ' (연)',
              onChanged: _onTargetTextChanged,
              quick: const [500000, 1000000, 2000000, 3000000, 5000000],
              current: widget.monthlyTarget,
              onPick: (v) {
                widget.onTargetChanged(v);
                _targetCtrl.text = _formatPlain(v);
                _targetCtrl.selection = TextSelection.fromPosition(
                  TextPosition(offset: _targetCtrl.text.length),
                );
              },
            ),

            const SizedBox(height: 16),

            _DirectInput(
              label: AppCopy.quizBudgetLbl,
              controller: _budgetCtrl,
              focusNode: _budgetFocus,
              hint: '한 번에 투자 가능한 총액',
              onChanged: _onBudgetTextChanged,
              quick: const [
                10000000,
                30000000,
                50000000,
                100000000,
                200000000,
              ],
              current: widget.budget,
              onPick: (v) {
                widget.onBudgetChanged(v);
                _budgetCtrl.text = _formatPlain(v);
                _budgetCtrl.selection = TextSelection.fromPosition(
                  TextPosition(offset: _budgetCtrl.text.length),
                );
              },
            ),

            const SizedBox(height: 24),

            Text(
              AppCopy.quizSectorLbl,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              AppCopy.quizSectorSub,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: sectorOptions.map((sector) {
                final selected = widget.preferredSectors.contains(sector.name);
                final palette = AppColors.paletteFor(sector.name);
                return _SectorChip(
                  sector: sector,
                  palette: palette,
                  isSelected: selected,
                  onTap: () {
                    final next = [...widget.preferredSectors];
                    if (selected) {
                      next.remove(sector.name);
                    } else {
                      next.add(sector.name);
                    }
                    widget.onSectorsChanged(next);
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            _ContinueButton(
              onPressed: widget.onFinish,
              label: AppCopy.quizCta,
              icon: Icons.arrow_forward_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectInput extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final List<int> quick;
  final int current;
  final ValueChanged<int> onPick;

  const _DirectInput({
    required this.label,
    required this.hint,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isFocused ? AppColors.wine : AppColors.border,
          width: isFocused ? 1.5 : 1,
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
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textTertiary,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                hint,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '₩',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: AppColors.wine,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.left,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1,
                    height: 1,
                  ),
                  cursorColor: AppColors.wine,
                  cursorWidth: 2,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ThousandsFormatter(),
                  ],
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(
                      color: AppColors.textDisabled,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onChanged: onChanged,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  AppCopy.unitWon,
                  style: GoogleFonts.inter(
                    color: AppColors.textTertiary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.borderSoft),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: quick.map((v) {
              final isSel = current == v;
              return GestureDetector(
                onTap: () => onPick(v),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.wine : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: isSel ? AppColors.wine : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _short(v),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isSel ? AppColors.surface : AppColors.textSecondary,
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

  String _short(int v) {
    if (v >= 100000000) return '${(v / 100000000).toStringAsFixed(1)}억';
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(0)}만';
    return '$v';
  }
}

class _SectorChip extends StatelessWidget {
  final StockSector sector;
  final SectorPalette palette;
  final bool isSelected;
  final VoidCallback onTap;

  const _SectorChip({
    required this.sector,
    required this.palette,
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
          color: isSelected ? palette.bg : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? palette.bg : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isSelected ? palette.onBg : palette.bg,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              sector.label,
              style: GoogleFonts.inter(
                color: isSelected ? palette.onBg : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
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
