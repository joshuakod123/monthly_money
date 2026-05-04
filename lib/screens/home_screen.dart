import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../algorithms/persona_animal.dart';
import '../algorithms/recommendation_engine.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'stock_detail_screen.dart';
import 'quiz_result_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final persona = ref.watch(personaProfileProvider);
    final rec = ref.watch(portfolioRecommendationProvider);

    if (persona == null || rec == null) {
      return const Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(child: CircularProgressIndicator(color: AppColors.wine)),
      );
    }

    final animal = PersonaAnimal.fromProfile(persona);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: _Greeting(animal: animal),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: _AnimalBanner(animal: animal),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: _MonthlyHero(persona: persona, rec: rec),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: _WineCard(rec: rec, animal: animal)
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 480.ms)
                    .slideY(begin: 0.05, end: 0),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: _PortfolioHeader(count: rec.picks.length),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, i) {
                    return _PickRow(
                      pick: rec.picks[i],
                      isLast: i == rec.picks.length - 1,
                    )
                        .animate()
                        .fadeIn(
                      delay: Duration(milliseconds: 700 + i * 50),
                      duration: 320.ms,
                    )
                        .slideX(begin: 0.03, end: 0);
                  },
                  childCount: rec.picks.length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
                child: Center(
                  child: Text(
                    '· 천천히 익어가는 자산 ·',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  final PersonaAnimal animal;
  const _Greeting({required this.animal});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 24, height: 1.5, color: AppColors.wine),
        const SizedBox(width: 10),
        Text(
          'BAEDANG NAMU',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.wine,
            letterSpacing: 2.5,
          ),
        ),
        const Spacer(),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: const Icon(
            Icons.notifications_outlined,
            size: 16,
            color: AppColors.wine,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 280.ms);
  }
}

class _AnimalBanner extends StatelessWidget {
  final PersonaAnimal animal;
  const _AnimalBanner({required this.animal});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QuizResultScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: animal.signatureBg,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              top: -10,
              child: Opacity(
                opacity: 0.15,
                child: Text(
                  animal.emoji,
                  style: const TextStyle(fontSize: 100),
                ),
              ),
            ),
            Row(
              children: [
                Text(animal.emoji, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 14,
                            height: 1,
                            color: animal.signatureText.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'YOUR SPIRIT',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: animal.signatureText.withValues(alpha: 0.7),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        animal.name,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: animal.signatureText,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        animal.tagline,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: animal.signatureText.withValues(alpha: 0.85),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: animal.signatureText.withValues(alpha: 0.7),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.05);
  }
}

class _MonthlyHero extends StatelessWidget {
  final dynamic persona;
  final PortfolioRecommendation rec;

  const _MonthlyHero({required this.persona, required this.rec});

  @override
  Widget build(BuildContext context) {
    final monthly = rec.totalMonthlyDividend.round();
    final target = persona.monthlyTarget;
    final pct = target > 0
        ? ((rec.totalMonthlyDividend / target) * 100).round()
        : 0;
    final progress = target > 0
        ? (rec.totalMonthlyDividend / target).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('·',
                style: TextStyle(
                    color: AppColors.wine,
                    fontSize: 14,
                    fontWeight: FontWeight.w900)),
            const SizedBox(width: 6),
            Text(
              'MONTHLY DIVIDEND',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.wine,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 6),
            Text('·',
                style: TextStyle(
                    color: AppColors.wine,
                    fontSize: 14,
                    fontWeight: FontWeight.w900)),
          ],
        ).animate().fadeIn(delay: 200.ms, duration: 280.ms),
        const SizedBox(height: 14),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: monthly.toDouble()),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '₩',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: AppColors.wine,
                    letterSpacing: -1,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _fmt(value.round()),
                  style: GoogleFonts.inter(
                    fontSize: 52,
                    fontWeight: FontWeight.w700,
                    color: AppColors.wineDeep,
                    letterSpacing: -2.5,
                    height: 1,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.borderSoft,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 1100),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return FractionallySizedBox(
                        widthFactor: value,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: AppColors.wine,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Text(
              '$pct%',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: pct >= 100 ? AppColors.gold : AppColors.wine,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 600.ms, duration: 320.ms),
        const SizedBox(height: 8),
        Text(
          '목표 ₩${_fmt(target)}',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textTertiary,
            fontStyle: FontStyle.italic,
          ),
        ).animate().fadeIn(delay: 700.ms),
      ],
    );
  }

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _WineCard extends StatelessWidget {
  final PortfolioRecommendation rec;
  final PersonaAnimal animal;
  const _WineCard({required this.rec, required this.animal});

  @override
  Widget build(BuildContext context) {
    final picks = rec.picks.take(5).toList();
    final coverage = rec.coverageCount;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.wine, AppColors.wineDeep],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.wine.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Opacity(
              opacity: 0.06,
              child: Text(
                '※',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 130,
                  color: AppColors.surface,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 1,
                    color: AppColors.surface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'YOUR PICKS',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.surface.withValues(alpha: 0.8),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                coverage == 12
                    ? '매달 들어오는\n배당'
                    : '$coverage개월 배당이\n흘러들어옵니다',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.surface,
                  letterSpacing: -0.5,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  SizedBox(
                    width: picks.length * 28.0 + 14,
                    height: 38,
                    child: Stack(
                      children: List.generate(picks.length, (i) {
                        return Positioned(
                          left: i * 24.0,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius:
                              BorderRadius.circular(AppRadius.full),
                              border: Border.all(
                                  color: AppColors.wineDeep, width: 2),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              picks[i].stock.sector.emoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(
                          color: AppColors.surface.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${rec.picks.length}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.surface,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: AppColors.surface.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PortfolioHeader extends StatelessWidget {
  final int count;
  const _PortfolioHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Portfolio',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textTertiary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Text(
                '비중순',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_drop_down_rounded,
                  size: 14, color: AppColors.textTertiary),
            ],
          ),
        ),
      ],
    );
  }
}

class _PickRow extends StatelessWidget {
  final PortfolioPick pick;
  final bool isLast;
  const _PickRow({required this.pick, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final stock = pick.stock;
    final monthly = pick.monthlyDividend.round();
    final pct = (pick.weightOfTotal * 100).round();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => StockDetailScreen(stock: stock)),
      ),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
            bottom: BorderSide(color: AppColors.borderSoft, width: 1),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                stock.sector.emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stock.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${pick.shares}주 · ${stock.frequency.label} · ${stock.dividendYield.toStringAsFixed(1)}%',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+₩${_fmt(monthly)}',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.wine,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$pct%',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}