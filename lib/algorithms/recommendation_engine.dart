import 'dart:math' as math;
import '../models/stock_model.dart';
import 'persona_profile.dart';

/// ═══════════════════════════════════════════════════════════
///  StockTraits — 종목 8차원 벡터 (GICS 11 섹터 대응)
/// ═══════════════════════════════════════════════════════════
class StockTraits {
  final double stability;
  final double cashflowFrequency;
  final double volatility;
  final double taxEfficiency;
  final double liquidity;
  final double ethicsScore;
  final String sectorId;
  final double inflationHedge;
  final double yieldPercent;

  const StockTraits({
    required this.stability,
    required this.cashflowFrequency,
    required this.volatility,
    required this.taxEfficiency,
    required this.liquidity,
    required this.ethicsScore,
    required this.sectorId,
    required this.inflationHedge,
    required this.yieldPercent,
  });

  List<double> get vector => [
    volatility,
    cashflowFrequency,
    -volatility,
    taxEfficiency,
    liquidity,
    ethicsScore,
    0,
    inflationHedge,
  ];

  factory StockTraits.fromStock(StockModel stock) {
    double cv = 0.3;
    if (stock.history.length >= 3) {
      final amounts = stock.history.map((h) => h.amount.toDouble()).toList();
      final mean = amounts.reduce((a, b) => a + b) / amounts.length;
      if (mean > 0) {
        final variance = amounts
            .map((v) => math.pow(v - mean, 2).toDouble())
            .reduce((a, b) => a + b) /
            amounts.length;
        cv = math.sqrt(variance) / mean;
      }
    }
    final stability = (1.0 - cv * 2).clamp(-1.0, 1.0);

    double freq;
    switch (stock.frequency) {
      case DividendFrequency.monthly:    freq = 1.0;  break;
      case DividendFrequency.quarterly:  freq = 0.5;  break;
      case DividendFrequency.semiAnnual: freq = -0.2; break;
      case DividendFrequency.annual:     freq = -0.8; break;
    }

    double vol;
    if (stock.per <= 0) {
      vol = 0.5;
    } else if (stock.per < 8) {
      vol = -0.6;
    } else if (stock.per < 15) {
      vol = -0.1;
    } else if (stock.per < 25) {
      vol = 0.4;
    } else {
      vol = 0.8;
    }

    final isEtf = stock.name.contains('ETF') ||
        stock.name.contains('KODEX') ||
        stock.name.contains('TIGER') ||
        stock.name.contains('SOL') ||
        stock.name.contains('ACE') ||
        stock.name.contains('PLUS');
    final taxEff = isEtf ? 0.7 : -0.3;

    double liq;
    final mc = stock.marketCap;
    if (mc > 50000000) {
      liq = 0.9;
    } else if (mc > 10000000) {
      liq = 0.5;
    } else if (mc > 1000000) {
      liq = 0.0;
    } else if (mc > 100000) {
      liq = -0.4;
    } else {
      liq = -0.8;
    }

    final ethics = _ethicsScoreFor(stock.code);
    final sectorId = stock.sector.name;

    // 섹터별 인플레이션 헷지 점수 (GICS 11 sector)
    double inflHedge;
    switch (stock.sector) {
      case StockSector.reit:         inflHedge = 0.85; break;
      case StockSector.energy:       inflHedge = 0.70; break;
      case StockSector.materials:    inflHedge = 0.60; break;
      case StockSector.utilities:    inflHedge = 0.40; break;
      case StockSector.consumerStpl: inflHedge = 0.30; break;
      case StockSector.industrial:   inflHedge = 0.10; break;
      case StockSector.healthcare:   inflHedge = 0.05; break;
      case StockSector.consumerDisc: inflHedge = 0.00; break;
      case StockSector.tech:         inflHedge = -0.10; break;
      case StockSector.telecom:      inflHedge = -0.10; break;
      case StockSector.finance:      inflHedge = -0.20; break;
      case StockSector.all:          inflHedge = 0.0;  break;
    }

    return StockTraits(
      stability: stability,
      cashflowFrequency: freq,
      volatility: vol,
      taxEfficiency: taxEff,
      liquidity: liq,
      ethicsScore: ethics,
      sectorId: sectorId,
      inflationHedge: inflHedge,
      yieldPercent: stock.dividendYield,
    );
  }

  static double _ethicsScoreFor(String code) {
    // 담배·주류
    const sin = {'033780'};
    if (sin.contains(code)) return -0.7;
    return 0.2;
  }

  bool isExcludedFor(PersonaProfile profile, String code) {
    if (profile.excludedSectors.contains('sin') &&
        const ['033780'].contains(code)) {
      return true;
    }
    if (profile.excludedSectors.contains('fossil') &&
        const ['096770', '267250', '015760'].contains(code)) {
      return true;
    }
    return false;
  }
}

class PortfolioPick {
  final StockModel stock;
  final int shares;
  final double score;
  final double monthlyDividend;
  final double weightOfTotal;
  final double cost;

  const PortfolioPick({
    required this.stock,
    required this.shares,
    required this.score,
    required this.monthlyDividend,
    required this.weightOfTotal,
    required this.cost,
  });
}

class GoalGapAnalysis {
  final int actualMonthly;
  final int targetMonthly;
  final double achievementRate;
  final int requiredBudget;
  final int budgetGap;
  final List<MonthlyBuildPlan> buildPlans;
  final List<GoalRecommendation> recommendations;
  final bool hasSignificantGap;

  const GoalGapAnalysis({
    required this.actualMonthly,
    required this.targetMonthly,
    required this.achievementRate,
    required this.requiredBudget,
    required this.budgetGap,
    required this.buildPlans,
    required this.recommendations,
    required this.hasSignificantGap,
  });
}

class MonthlyBuildPlan {
  final int monthlyContribution;
  final int monthsToGoal;
  final double yearsToGoal;
  final int expectedMonthlyAtGoal;

  const MonthlyBuildPlan({
    required this.monthlyContribution,
    required this.monthsToGoal,
    required this.yearsToGoal,
    required this.expectedMonthlyAtGoal,
  });
}

class GoalRecommendation {
  final String title;
  final String description;
  final String actionLabel;
  final RecommendationType type;

  const GoalRecommendation({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.type,
  });
}

enum RecommendationType {
  lowerTarget,
  increaseBudget,
  monthlyBuild,
  highYield,
}

class RecommendationEngine {
  static double scoreStock({
    required StockModel stock,
    required PersonaProfile persona,
  }) {
    final traits = StockTraits.fromStock(stock);
    if (traits.isExcludedFor(persona, stock.code)) return 0.0;
    if (stock.dividendYield <= 0) return 0.0;

    final cosSim = _cosineSimilarity(persona.vector, traits.vector);
    final simScore = (cosSim + 1) / 2;

    final idealYield = persona.horizon < 0
        ? 6.0 + persona.horizon * (-2)
        : 4.0 - persona.horizon * 1.5;
    final yieldDiff = (stock.dividendYield - idealYield).abs();
    final yieldScore = math.max(0, 1.0 - yieldDiff / 5.0);

    final stabilityWeight = (1 - persona.downsideTolerance) / 2;
    final stabilityScore = (traits.stability + 1) / 2;

    final inflScore =
        1.0 - ((persona.inflationHedge - traits.inflationHedge).abs() / 2);

    final rng = math.Random(persona.deterministicSeed ^ stock.code.hashCode);
    final jitter = (rng.nextDouble() - 0.5) * 0.1;

    final totalScore = simScore * 0.40 +
        yieldScore * 0.25 +
        stabilityScore * stabilityWeight * 0.15 +
        inflScore * 0.10 +
        (0.5 + jitter) * 0.10;

    return totalScore.clamp(0.0, 1.0).toDouble();
  }

  static double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length || a.isEmpty) return 0;
    double dot = 0, magA = 0, magB = 0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      magA += a[i] * a[i];
      magB += b[i] * b[i];
    }
    if (magA == 0 || magB == 0) return 0;
    return dot / (math.sqrt(magA) * math.sqrt(magB));
  }

  static PortfolioRecommendation buildPortfolio({
    required PersonaProfile persona,
    required List<StockModel> universe,
  }) {
    final scored = <_ScoredStock>[];
    for (final s in universe) {
      final score = scoreStock(stock: s, persona: persona);
      if (score > 0) scored.add(_ScoredStock(s, score));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));

    if (scored.isEmpty) {
      return PortfolioRecommendation.empty(persona);
    }

    if (persona.cashflowPreference < -0.4) {
      return _buildCoverageOptimized(persona, scored);
    }

    return _buildScoreOptimized(persona, scored);
  }

  static PortfolioRecommendation _buildCoverageOptimized(
      PersonaProfile persona,
      List<_ScoredStock> scored,
      ) {
    final coveredMonths = <int>{};
    final selected = <_ScoredStock>[];
    final maxPicks = 8;

    final candidates = scored.where((s) => s.score >= 0.25).toList();
    if (candidates.isEmpty) {
      candidates.addAll(scored.take(15));
    }

    while (coveredMonths.length < 12 && selected.length < maxPicks) {
      _ScoredStock? bestPick;
      double bestGain = -1;

      for (final c in candidates) {
        if (selected.any((s) => s.stock.code == c.stock.code)) continue;

        final newMonths =
            c.stock.paymentMonths.toSet().difference(coveredMonths).length;

        final gain = newMonths * (1.0 + c.score) +
            (newMonths == 0 ? c.score * 0.3 : 0);

        if (gain > bestGain) {
          bestGain = gain;
          bestPick = c;
        }
      }

      if (bestPick == null) break;
      selected.add(bestPick);
      coveredMonths.addAll(bestPick.stock.paymentMonths);

      if (coveredMonths.length == 12 && selected.length >= 4) break;
    }

    if (selected.length < 4) {
      for (final c in scored) {
        if (selected.any((s) => s.stock.code == c.stock.code)) continue;
        if (selected.length >= 4) break;
        selected.add(c);
      }
    }

    return _allocateWeights(persona, selected, coveredMonths);
  }

  static PortfolioRecommendation _buildScoreOptimized(
      PersonaProfile persona,
      List<_ScoredStock> scored,
      ) {
    final targetCount =
    (5 + persona.diversificationDemand * 3).round().clamp(5, 8);
    final selected = <_ScoredStock>[];
    final sectorTallies = <String, int>{};

    for (final ss in scored) {
      if (selected.length >= targetCount) break;
      final sector = ss.stock.sector.name;
      final currentSectorCount = sectorTallies[sector] ?? 0;
      final maxPerSector = persona.diversificationDemand > 0.5 ? 2 : 3;
      if (currentSectorCount >= maxPerSector) continue;
      selected.add(ss);
      sectorTallies[sector] = currentSectorCount + 1;
    }

    if (selected.length < 5) {
      for (final ss in scored) {
        if (selected.any((s) => s.stock.code == ss.stock.code)) continue;
        if (selected.length >= 5) break;
        selected.add(ss);
      }
    }

    final coveredMonths = <int>{};
    for (final ss in selected) {
      coveredMonths.addAll(ss.stock.paymentMonths);
    }

    return _allocateWeights(persona, selected, coveredMonths);
  }

  static PortfolioRecommendation _allocateWeights(
      PersonaProfile persona,
      List<_ScoredStock> selected,
      Set<int> coveredMonths,
      ) {
    if (selected.isEmpty) return PortfolioRecommendation.empty(persona);

    final budget = persona.budget;

    const maxWeight = 0.30;
    const minWeight = 0.05;

    final rawWeights = selected.map((s) => s.score).toList();
    final totalScore = rawWeights.fold<double>(0, (a, b) => a + b);

    List<double> targetWeights;
    if (totalScore > 0) {
      targetWeights = rawWeights.map((w) => w / totalScore).toList();
    } else {
      targetWeights = List.filled(selected.length, 1.0 / selected.length);
    }

    targetWeights = _normalizeWeights(targetWeights, minWeight, maxWeight);

    final preliminary = <_PreliminaryPick>[];

    for (var i = 0; i < selected.length; i++) {
      final ss = selected[i];
      final stock = ss.stock;
      if (stock.price <= 0) continue;

      final targetBudget = budget * targetWeights[i];
      int shares = (targetBudget / stock.price).floor();

      if (shares < 1 && stock.price <= budget * 0.5) {
        shares = 1;
      }
      if (shares < 1) continue;

      final cost = shares * stock.price;
      preliminary.add(_PreliminaryPick(
        stock: stock,
        shares: shares,
        score: ss.score,
        cost: cost,
        monthlyDividend: stock.monthlyDividend(shares),
      ));
    }

    int totalSpent = preliminary.fold(0, (a, p) => a + p.cost.round());
    int remaining = budget - totalSpent;

    int iter = 0;
    while (remaining > 0 && iter < 1000) {
      iter++;
      final actualTotal = preliminary.fold<double>(0, (a, p) => a + p.cost);
      if (actualTotal == 0) break;

      int? bestIdx;
      double biggestUnderweight = 0;

      for (var i = 0; i < preliminary.length; i++) {
        final p = preliminary[i];
        if (p.stock.price > remaining) continue;

        final selectedIdx =
        selected.indexWhere((s) => s.stock.code == p.stock.code);
        if (selectedIdx < 0) continue;

        final targetW = targetWeights[selectedIdx];
        final actualW = p.cost / actualTotal;
        final underweight = targetW - actualW;

        if (underweight > biggestUnderweight) {
          biggestUnderweight = underweight;
          bestIdx = i;
        }
      }

      if (bestIdx == null || biggestUnderweight < 0.01) break;

      final p = preliminary[bestIdx];
      final newShares = p.shares + 1;
      final newCost = newShares * p.stock.price;
      preliminary[bestIdx] = _PreliminaryPick(
        stock: p.stock,
        shares: newShares,
        score: p.score,
        cost: newCost,
        monthlyDividend: p.stock.monthlyDividend(newShares),
      );
      remaining -= p.stock.price.round();
    }

    final actualTotal = preliminary.fold<double>(0, (a, p) => a + p.cost);
    final picks = <PortfolioPick>[];
    for (final p in preliminary) {
      picks.add(PortfolioPick(
        stock: p.stock,
        shares: p.shares,
        score: p.score,
        monthlyDividend: p.monthlyDividend,
        weightOfTotal: actualTotal > 0 ? p.cost / actualTotal : 0,
        cost: p.cost,
      ));
    }
    picks.sort((a, b) => b.weightOfTotal.compareTo(a.weightOfTotal));

    return PortfolioRecommendation(
      persona: persona,
      picks: picks,
      hhi: _calculateHHI(picks),
      diversityScore: 1.0 - _calculateHHI(picks),
      coveredMonths: coveredMonths,
    );
  }

  static List<double> _normalizeWeights(
      List<double> weights,
      double min,
      double max,
      ) {
    if (weights.isEmpty) return weights;

    var result = [...weights];

    for (var i = 0; i < result.length; i++) {
      if (result[i] > max) result[i] = max;
    }

    var sum = result.reduce((a, b) => a + b);
    if (sum < 1.0) {
      final shortfall = 1.0 - sum;
      final eligible = <int>[];
      for (var i = 0; i < result.length; i++) {
        if (result[i] < max) eligible.add(i);
      }
      if (eligible.isNotEmpty) {
        final addPerStock = shortfall / eligible.length;
        for (final i in eligible) {
          result[i] = (result[i] + addPerStock).clamp(0.0, max);
        }
      }
    }

    sum = result.reduce((a, b) => a + b);
    if (sum > 1.0) {
      result = result.map((w) => w / sum).toList();
    }

    for (var i = 0; i < result.length; i++) {
      if (result[i] < min) result[i] = min;
    }

    sum = result.reduce((a, b) => a + b);
    if (sum > 0) {
      result = result.map((w) => w / sum).toList();
    }

    return result;
  }

  static double _calculateHHI(List<PortfolioPick> picks) {
    if (picks.isEmpty) return 1.0;
    final sectorWeights = <String, double>{};
    for (final p in picks) {
      sectorWeights[p.stock.sector.name] =
          (sectorWeights[p.stock.sector.name] ?? 0) + p.weightOfTotal;
    }
    return sectorWeights.values.fold<double>(0, (a, w) => a + w * w);
  }

  static GoalGapAnalysis analyzeGoalGap({
    required PersonaProfile persona,
    required PortfolioRecommendation rec,
  }) {
    final actualMonthly = rec.totalMonthlyDividend.round();
    final targetMonthly = persona.monthlyTarget;
    final achievementRate =
    targetMonthly > 0 ? actualMonthly / targetMonthly : 0.0;

    double avgYield = 0;
    if (rec.picks.isNotEmpty) {
      final totalCost = rec.picks.fold<double>(0, (a, p) => a + p.cost);
      if (totalCost > 0) {
        avgYield = rec.picks.fold<double>(
          0,
              (a, p) => a + p.stock.dividendYield * p.cost,
        ) /
            totalCost /
            100;
      }
    }
    if (avgYield <= 0) avgYield = 0.05;

    final requiredBudget = (targetMonthly * 12 / avgYield).round();
    final budgetGap = requiredBudget - persona.budget;

    final buildPlans = <MonthlyBuildPlan>[];
    for (final monthly in [100000, 300000, 500000]) {
      final months = budgetGap > 0
          ? (budgetGap / monthly).ceil()
          : 0;
      if (months > 0 && months <= 360) {
        buildPlans.add(MonthlyBuildPlan(
          monthlyContribution: monthly,
          monthsToGoal: months,
          yearsToGoal: months / 12.0,
          expectedMonthlyAtGoal: targetMonthly,
        ));
      }
    }

    final recommendations = <GoalRecommendation>[];

    if (achievementRate < 0.5) {
      final realisticTarget = (actualMonthly / 10000).floor() * 10000;
      recommendations.add(GoalRecommendation(
        title: '목표를 ₩${_fmtKrw(realisticTarget)}으로',
        description:
        '지금 예산으로 닿을 수 있는 현실적인 숫자. 도달한 후 차근차근 키워가도 늦지 않아요',
        actionLabel: '목표 낮추기',
        type: RecommendationType.lowerTarget,
      ));

      if (buildPlans.isNotEmpty) {
        final mid = buildPlans[1];
        recommendations.add(GoalRecommendation(
          title: '월 ₩${_fmtKrw(mid.monthlyContribution)} 적립',
          description:
          '약 ${mid.yearsToGoal.toStringAsFixed(1)}년 뒤 목표 도달. 시간이 자산을 익혀줍니다',
          actionLabel: '적립 계획 보기',
          type: RecommendationType.monthlyBuild,
        ));
      }

      recommendations.add(GoalRecommendation(
        title: '추가 ₩${_fmtKrw(budgetGap)} 투자',
        description: '한 번에 목표에 도달. 예산을 늘리고 추천을 다시 받아보세요',
        actionLabel: '예산 조정',
        type: RecommendationType.increaseBudget,
      ));
    } else if (achievementRate < 0.95) {
      recommendations.add(GoalRecommendation(
        title: '${(achievementRate * 100).round()}% 달성',
        description: '목표에 가까워졌어요. 고배당 ETF 비중을 살짝 키우면 100%에 닿아요',
        actionLabel: '고배당 비중 ↑',
        type: RecommendationType.highYield,
      ));
    }

    return GoalGapAnalysis(
      actualMonthly: actualMonthly,
      targetMonthly: targetMonthly,
      achievementRate: achievementRate,
      requiredBudget: requiredBudget,
      budgetGap: budgetGap > 0 ? budgetGap : 0,
      buildPlans: buildPlans,
      recommendations: recommendations,
      hasSignificantGap: achievementRate < 0.5,
    );
  }

  static String _fmtKrw(int v) {
    if (v >= 100000000) return '${(v / 100000000).toStringAsFixed(1)}억';
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(0)}만';
    return v.toString();
  }
}

class _ScoredStock {
  final StockModel stock;
  final double score;
  _ScoredStock(this.stock, this.score);
}

class _PreliminaryPick {
  final StockModel stock;
  final int shares;
  final double score;
  final double cost;
  final double monthlyDividend;
  _PreliminaryPick({
    required this.stock,
    required this.shares,
    required this.score,
    required this.cost,
    required this.monthlyDividend,
  });
}

class PortfolioRecommendation {
  final PersonaProfile persona;
  final List<PortfolioPick> picks;
  final double hhi;
  final double diversityScore;
  final Set<int> coveredMonths;

  PortfolioRecommendation({
    required this.persona,
    required this.picks,
    required this.hhi,
    required this.diversityScore,
    this.coveredMonths = const {},
  });

  factory PortfolioRecommendation.empty(PersonaProfile p) =>
      PortfolioRecommendation(
        persona: p,
        picks: [],
        hhi: 1.0,
        diversityScore: 0,
        coveredMonths: {},
      );

  Map<StockModel, int> toMap() => {for (final p in picks) p.stock: p.shares};

  int get totalInvestment => picks.fold(0, (a, p) => a + p.cost.round());

  double get totalMonthlyDividend =>
      picks.fold(0.0, (a, p) => a + p.monthlyDividend);

  Map<StockSector, double> get sectorBreakdown {
    final map = <StockSector, double>{};
    for (final p in picks) {
      map[p.stock.sector] = (map[p.stock.sector] ?? 0) + p.weightOfTotal;
    }
    return map;
  }

  int get coverageCount => coveredMonths.length;
  double get coverageRate => coveredMonths.length / 12.0;

  List<String> rationale() {
    final reasons = <String>[];
    final p = persona;
    final achievementPct =
    (totalMonthlyDividend / p.monthlyTarget * 100).round();

    if (achievementPct >= 95) {
      reasons.add(
          '예산 ${formatBudget(p.budget)}으로 목표 월 ${formatBudget(p.monthlyTarget)}에 거의 닿아요');
    } else if (achievementPct >= 60) {
      reasons.add(
          '지금 예산이면 월 ${formatBudget(totalMonthlyDividend.round())} (목표의 $achievementPct%)');
    } else if (achievementPct >= 30) {
      final neededBudget = (p.budget / (achievementPct / 100)).round();
      reasons.add(
          '월 ${formatBudget(p.monthlyTarget)} 받으려면 ${formatBudget(neededBudget)} 필요. 현재는 월 ${formatBudget(totalMonthlyDividend.round())}');
    } else {
      reasons.add(
          '지금 예산으로는 월 ${formatBudget(totalMonthlyDividend.round())}. 매달 적립을 함께 추천해요');
    }

    if (p.cashflowPreference < -0.4) {
      if (coveredMonths.length == 12) {
        reasons.add('1월부터 12월까지 매달 배당이 들어와요');
      } else if (coveredMonths.length >= 9) {
        reasons.add('${coveredMonths.length}개월 커버. 거의 매달 배당');
      } else {
        reasons.add('${coveredMonths.length}개월 커버 (월배당 ETF 추가하면 12개월 가능)');
      }
    }

    if (p.horizon < -0.3) {
      reasons.add('단기 목표라 배당수익률 높은 종목 위주');
    } else if (p.horizon > 0.3) {
      reasons.add('긴 시간 활용해 안정 성장형도 함께');
    }
    if (p.downsideTolerance < -0.3) {
      reasons.add('하방 방어 위주, 변동성 낮은 종목');
    }
    if (p.diversificationDemand > 0.5) {
      reasons.add('${picks.length}개 종목으로 섹터 분산');
    }
    if (p.inflationHedge > 0.4) {
      reasons.add('인플레이션 방어용 리츠·인프라 추가');
    }
    if (p.taxSensitivity < -0.3) {
      reasons.add('종합과세 회피 위해 분리과세 ETF 비중 ↑');
    }
    if (p.excludedSectors.isNotEmpty) {
      final excluded = p.excludedSectors.map((s) {
        switch (s) {
          case 'gambling': return '도박';
          case 'sin':      return '담배·주류';
          case 'fossil':   return '화석연료';
          case 'defense':  return '방산';
          default:         return s;
        }
      }).join(', ');
      reasons.add('제외 요청 산업($excluded) 빼고 추천');
    }
    return reasons;
  }

  String formatBudget(int v) {
    if (v >= 100000000) return '${(v / 100000000).toStringAsFixed(1)}억';
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(0)}만원';
    return '$v원';
  }
}
