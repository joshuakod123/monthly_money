import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../algorithms/persona_profile.dart';
import '../algorithms/recommendation_engine.dart';
import '../models/stock_model.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'stock_detail_screen.dart';
import 'quiz_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final persona = ref.watch(personaProfileProvider);
    final selectedSector = ref.watch(selectedSectorProvider);
    final stocksAsync = ref.watch(filteredStocksProvider);
    final recAsync = ref.watch(personalizedRecommendationProvider);
    final forecastAsync = ref.watch(portfolioForecastProvider);

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(allStocksProvider);
            ref.invalidate(personalizedRecommendationProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 상단 헤더
                Container(
                  color: AppColors.primary,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '배당나무',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.notifications_none_rounded,
                                color: Colors.white70, size: 22),
                            onPressed: () {},
                          ),
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              '김',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 페르소나 요약 또는 퀴즈 CTA
                      if (persona == null)
                        _QuizCTA().animate().fadeIn(duration: 400.ms)
                      else
                        _PersonaSummary(persona: persona)
                            .animate()
                            .fadeIn(duration: 400.ms),
                    ],
                  ),
                ),

                // ── 추천 결과 (페르소나 있을 때만)
                if (persona != null) ...[
                  Transform.translate(
                    offset: const Offset(0, -16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: recAsync.when(
                        data: (rec) => rec == null || rec.picks.isEmpty
                            ? const SizedBox.shrink()
                            : _RecommendationCard(rec: rec),
                        loading: () =>
                            _ShimmerBox(height: 160, radius: 20),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),
                  ),

                  // 미래 예측
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: forecastAsync.when(
                      data: (f) => f == null
                          ? const SizedBox.shrink()
                          : _ForecastSummaryCard(forecast: f),
                      loading: () => _ShimmerBox(height: 100, radius: 16),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),

                  // 추천 이유
                  recAsync.when(
                    data: (rec) {
                      if (rec == null || rec.picks.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      final reasons = rec.rationale();
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: _RationaleCard(reasons: reasons),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],

                // 퀴즈 다시하기 버튼 (페르소나 있을 때)
                if (persona != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: _RetakeQuizTile(persona: persona),
                  ),

                // 섹션 헤더
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                  child: Row(
                    children: [
                      Text(
                        persona == null ? '인기 배당주' : '내 점수 순',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (persona != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentWarm.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            persona.summarize(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF9A5E00),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // 섹터 가로 스크롤
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: StockSector.values
                        .map((s) => SectorChip(
                      sector: s,
                      isActive: selectedSector == s,
                      onTap: () => ref
                          .read(selectedSectorProvider.notifier)
                          .state = s,
                    ))
                        .toList(),
                  ),
                ),

                const SizedBox(height: 14),

                // 주식 리스트 (페르소나 점수로 정렬됨)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  child: stocksAsync.when(
                    data: (stocks) {
                      if (stocks.isEmpty) return const _EmptyState();
                      return Column(
                        children: stocks
                            .asMap()
                            .entries
                            .take(20)
                            .map((entry) => _ScoredStockCard(
                          stock: entry.value,
                          persona: persona,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StockDetailScreen(
                                  stock: entry.value),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(
                          delay: Duration(
                              milliseconds: entry.key * 50),
                          duration: 350.ms,
                        )
                            .slideY(begin: 0.1, end: 0))
                            .toList(),
                      );
                    },
                    loading: () => Column(
                      children: List.generate(
                          5, (_) => _ShimmerBox(height: 110, radius: 16)),
                    ),
                    error: (e, _) => _ErrorCard(
                      message: '데이터 로드 실패\n$e',
                      onRetry: () => ref.invalidate(allStocksProvider),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 퀴즈 CTA (페르소나 없을 때)
// ─────────────────────────────────────────
class _QuizCTA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QuizScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2A5A40), Color(0xFF1A3A2A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accent.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const Text(
                      '8문항 · 1분',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                '나에게 딱 맞는\n배당주 찾기',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '같은 목표라도 사람마다 다른 답.\n8가지 차원으로 분석해 정확한 종목을 추천해드려요.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      color: AppColors.accent, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '시작하기',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded,
                      color: AppColors.accent, size: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 페르소나 요약
// ─────────────────────────────────────────
class _PersonaSummary extends StatelessWidget {
  final PersonaProfile persona;
  const _PersonaSummary({required this.persona});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '내 투자 성향',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text(
                  '8차원 분석',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            persona.summarize(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '월 ${formatKRW(persona.monthlyTarget)} 목표 · 예산 ${formatKRW(persona.budget)}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// 추천 결과 카드
// ─────────────────────────────────────────
class _RecommendationCard extends StatelessWidget {
  final PortfolioRecommendation rec;
  const _RecommendationCard({required this.rec});

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
          Row(
            children: [
              Text(
                '맞춤 포트폴리오',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shield_rounded,
                        size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '분산도 ${(rec.diversityScore * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${rec.picks.length}개 종목',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '필요 투자금 ${formatKRW(rec.totalInvestment)}',
            style: const TextStyle(color: AppColors.accent, fontSize: 13),
          ),
          const SizedBox(height: 14),
          // 종목 미리보기
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: rec.picks.take(5).map((pick) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(pick.stock.sector.emoji,
                        style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      pick.stock.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${pick.shares}주',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// 추천 이유
// ─────────────────────────────────────────
class _RationaleCard extends StatelessWidget {
  final List<String> reasons;
  const _RationaleCard({required this.reasons});

  @override
  Widget build(BuildContext context) {
    if (reasons.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.psychology_alt_rounded,
                  size: 18, color: AppColors.primary),
              SizedBox(width: 6),
              Text('이렇게 추천한 이유',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          ...reasons.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Icon(Icons.check_rounded,
                      size: 14, color: AppColors.accent),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    r,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// 점수 표시 종목 카드 (StockCard 확장)
// ─────────────────────────────────────────
class _ScoredStockCard extends StatelessWidget {
  final StockModel stock;
  final PersonaProfile? persona;
  final VoidCallback? onTap;

  const _ScoredStockCard({
    required this.stock,
    required this.persona,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final score = persona == null
        ? null
        : RecommendationEngine.scoreStock(stock: stock, persona: persona!);

    return Stack(
      children: [
        StockCard(stock: stock, onTap: onTap),
        if (score != null)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _scoreColor(score),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '매칭 ${(score * 100).toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _scoreColor(double s) {
    if (s >= 0.75) return AppColors.positive;
    if (s >= 0.55) return AppColors.accentWarm;
    if (s >= 0.35) return AppColors.textSecondary;
    return AppColors.negative;
  }
}

// ─────────────────────────────────────────
// 퀴즈 다시하기
// ─────────────────────────────────────────
class _RetakeQuizTile extends StatelessWidget {
  final PersonaProfile persona;
  const _RetakeQuizTile({required this.persona});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QuizScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.refresh_rounded,
                color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('투자 성향 다시 분석',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      )),
                  SizedBox(height: 2),
                  Text(
                    '상황이 바뀌었나요? 8문항을 다시 풀어보세요',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 보조 위젯들
// ─────────────────────────────────────────
class _ShimmerBox extends StatelessWidget {
  final double height;
  final double radius;
  const _ShimmerBox({required this.height, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Shimmer.fromColors(
        baseColor: AppColors.border.withOpacity(0.4),
        highlightColor: AppColors.border.withOpacity(0.15),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.negativeBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.negative.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.negative, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textPrimary)),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('재시도',
                style: TextStyle(
                  color: AppColors.negative,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: AppColors.border),
          SizedBox(height: 12),
          Text('해당 조건의 종목이 없어요',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}

class _ForecastSummaryCard extends StatelessWidget {
  final dynamic forecast;
  const _ForecastSummaryCard({required this.forecast});

  @override
  Widget build(BuildContext context) {
    final growth = forecast.growthRate;
    final isPositive = growth >= 0;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              const Text('3년 후 예상 월 배당',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: isPositive
                      ? AppColors.positiveBg
                      : AppColors.negativeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${isPositive ? '+' : ''}${growth.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isPositive
                        ? AppColors.positive
                        : AppColors.negative,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatKRW(forecast.expectedMonthly),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  )),
              const SizedBox(width: 6),
              const Padding(
                padding: EdgeInsets.only(bottom: 3),
                child: Text('/ 월',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}