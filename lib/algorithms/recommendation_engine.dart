import 'dart:math' as math;
import '../models/stock_model.dart';
import 'persona_profile.dart';

/// ═══════════════════════════════════════════════════════════
///  StockTraits — 종목 8차원 벡터
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
      case DividendFrequency.monthly:
        freq = 1.0;
        break;
      case DividendFrequency.quarterly:
        freq = 0.5;
        break;
      case DividendFrequency.semiAnnual:
        freq = -0.2;
        break;
      case DividendFrequency.annual:
        freq = -0.8;
        break;
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

    double taxEff = stock.name.contains('ETF') ||
        stock.name.contains('KODEX') ||
        stock.name.contains('TIGER') ||
        stock.name.contains('SOL')
        ? 0.7
        : -0.3;

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

    double inflHedge;
    switch (stock.sector) {
      case StockSector.reit:
        inflHedge = 0.85;
        break;
      case StockSector.energy:
        inflHedge = 0.6;
        break;
      case StockSector.consumer:
        inflHedge = 0.3;
        break;
      case StockSector.finance:
        inflHedge = -0.2;
        break;
      case StockSector.telecom:
        inflHedge = -0.1;
        break;
      default:
        inflHedge = 0.0;
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
    const sin = {
      '033780': 'sin',
    };
    if (sin.containsKey(code)) return -0.7;
    return 0.2;
  }

  bool isExcludedFor(PersonaProfile profile, String code) {
    if (profile.excludedSectors.contains('sin') &&
        const ['033780'].contains(code)) {
      return true;
    }
    if (profile.excludedSectors.contains('fossil') &&
        const ['015760', '034020'].contains(code)) {
      return true;
    }
    return false;
  }
}

/// ═══════════════════════════════════════════════════════════
///  PortfolioPick
/// ═══════════════════════════════════════════════════════════
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

/// ═══════════════════════════════════════════════════════════
///  RecommendationEngine
/// ═══════════════════════════════════════════════════════════
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

  /// ═════════════════════════════════════════════════════
  ///  메인 빌더 — 사용자 성향에 따라 분기
  /// ═════════════════════════════════════════════════════
  static PortfolioRecommendation buildPortfolio({
    required PersonaProfile persona,
    required List<StockModel> universe,
  }) {
    // 후보 점수화
    final scored = <_ScoredStock>[];
    for (final s in universe) {
      final score = scoreStock(stock: s, persona: persona);
      if (score > 0) scored.add(_ScoredStock(s, score));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));

    if (scored.isEmpty) {
      return PortfolioRecommendation.empty(persona);
    }

    // ⭐ 핵심 분기: 월급형(매달 균등) 선호 시 커버리지 최적화
    if (persona.cashflowPreference < -0.4) {
      return _buildCoverageOptimized(persona, scored);
    }

    return _buildScoreOptimized(persona, scored);
  }

  /// ═════════════════════════════════════════════════════
  ///  ⭐ 커버리지 최적화 빌더 (월급형 사용자용)
  ///
  ///  목표: 12개월 모두 배당이 들어오도록 종목 조합
  ///  알고리즘: Weighted Set Cover (NP-hard 근사)
  ///   - Step 1: 점수 ≥ 임계치인 후보만 필터
  ///   - Step 2: 매 라운드마다 "(새로 커버되는 달 수 × 점수)" 최대 종목 선택
  ///   - Step 3: 12개월 모두 커버되거나 최대 종목 수 도달 시 중단
  ///   - Step 4: 점수 비례 비중 분배
  /// ═════════════════════════════════════════════════════
  static PortfolioRecommendation _buildCoverageOptimized(
      PersonaProfile persona,
      List<_ScoredStock> scored,
      ) {
    // 월배당 ETF는 단독으로 12개월 커버 → 최우선
    // 그 외는 다양한 지급월 조합으로 메꿈

    final targetMonths = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12};
    final coveredMonths = <int>{};
    final selected = <_ScoredStock>[];
    final maxPicks = 8;

    // Step 1: 후보 풀 (점수 0.25 이상)
    final candidates = scored.where((s) => s.score >= 0.25).toList();
    if (candidates.isEmpty) {
      // 폴백: 점수 무관 상위 사용
      candidates.addAll(scored.take(15));
    }

    // Step 2: 그리디 - 매 라운드마다 marginal coverage gain 최대 종목 선택
    while (coveredMonths.length < 12 && selected.length < maxPicks) {
      _ScoredStock? bestPick;
      double bestGain = -1;

      for (final c in candidates) {
        if (selected.any((s) => s.stock.code == c.stock.code)) continue;

        // 이 종목이 새로 커버하는 달 수
        final newMonths = c.stock.paymentMonths
            .toSet()
            .difference(coveredMonths)
            .length;

        // gain = 새 커버 달 수 × (1 + 점수)
        // 새 달이 없어도 점수 높으면 약간의 가치
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

      // 12개월 다 채웠고 4종목 이상이면 종료
      if (coveredMonths.length == 12 && selected.length >= 4) break;
    }

    // 최소 4종목 보장
    if (selected.length < 4) {
      for (final c in scored) {
        if (selected.any((s) => s.stock.code == c.stock.code)) continue;
        if (selected.length >= 4) break;
        selected.add(c);
      }
    }

    return _allocateWeights(persona, selected, coveredMonths);
  }

  /// ═════════════════════════════════════════════════════
  ///  점수 최적화 빌더 (분기형/연배당 OK인 사용자용)
  /// ═════════════════════════════════════════════════════
  static PortfolioRecommendation _buildScoreOptimized(
      PersonaProfile persona,
      List<_ScoredStock> scored,
      ) {
    final targetCount = (5 + persona.diversificationDemand * 3).round().clamp(5, 8);
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

  /// ═════════════════════════════════════════════════════
  ///  공통: 점수 비례로 주식 수 분배
  /// ═════════════════════════════════════════════════════
  /// ═════════════════════════════════════════════════════
  ///  공통: 예산 기반 비중 분배 (수정됨)
  ///
  ///  핵심 변경:
  ///   - monthlyTarget만 보고 주식 수 계산하던 옛 로직 제거
  ///   - persona.budget 안에서 점수 비례로 분배
  ///   - 한 종목당 최소 1주는 사도록 보장
  ///   - "예산 부족해서 목표 미달"인 경우도 정직하게 표시
  /// ═════════════════════════════════════════════════════
  static PortfolioRecommendation _allocateWeights(
      PersonaProfile persona,
      List<_ScoredStock> selected,
      Set<int> coveredMonths,
      ) {
    if (selected.isEmpty) return PortfolioRecommendation.empty(persona);

    final budget = persona.budget;
    final totalScore = selected.fold<double>(0, (a, b) => a + b.score);

    // ── 1단계: 점수 비례로 예산 분배 + 살 수 있는 주식 수 계산
    final preliminary = <_PreliminaryPick>[];
    int totalSpent = 0;

    for (final ss in selected) {
      final stock = ss.stock;
      if (stock.price <= 0) continue; // 가격 0이면 스킵

      // 이 종목에 할당할 예산 비중
      final allocRatio = totalScore > 0 ? ss.score / totalScore : 1.0 / selected.length;
      final allocBudget = budget * allocRatio;

      // 그 예산으로 살 수 있는 주식 수 (최소 1주는 보장)
      int shares = (allocBudget / stock.price).floor();
      if (shares < 1 && allocBudget >= stock.price * 0.3) {
        // 예산 비중은 부족하지만 한 주 가격에 가까우면 1주 사도록
        shares = 1;
      }
      if (shares < 1) continue; // 그래도 못 사면 스킵

      final cost = shares * stock.price;
      preliminary.add(_PreliminaryPick(
        stock: stock,
        shares: shares,
        score: ss.score,
        cost: cost,
        monthlyDividend: stock.monthlyDividend(shares),
      ));
      totalSpent += cost.round();
    }

    // ── 2단계: 예산 잔여분으로 추가 매수 (점수 높은 종목부터)
    int remaining = budget - totalSpent;
    preliminary.sort((a, b) => b.score.compareTo(a.score));
    bool changed = true;
    while (changed && remaining > 0) {
      changed = false;
      for (var i = 0; i < preliminary.length; i++) {
        final p = preliminary[i];
        if (p.stock.price <= remaining) {
          final newShares = p.shares + 1;
          final newCost = newShares * p.stock.price;
          preliminary[i] = _PreliminaryPick(
            stock: p.stock,
            shares: newShares,
            score: p.score,
            cost: newCost,
            monthlyDividend: p.stock.monthlyDividend(newShares),
          );
          remaining -= p.stock.price.round();
          changed = true;
        }
      }
    }

    // ── 3단계: 비중% 계산
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

  static double _calculateHHI(List<PortfolioPick> picks) {
    if (picks.isEmpty) return 1.0;
    final sectorWeights = <String, double>{};
    for (final p in picks) {
      sectorWeights[p.stock.sector.name] =
          (sectorWeights[p.stock.sector.name] ?? 0) + p.weightOfTotal;
    }
    return sectorWeights.values.fold<double>(0, (a, w) => a + w * w);
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

/// ═══════════════════════════════════════════════════════════
///  PortfolioRecommendation — 결과 (coveredMonths 추가)
/// ═══════════════════════════════════════════════════════════
class PortfolioRecommendation {
  final PersonaProfile persona;
  final List<PortfolioPick> picks;
  final double hhi;
  final double diversityScore;
  final Set<int> coveredMonths; // ⭐ 캘린더 UI가 사용

  PortfolioRecommendation({
    required this.persona,
    required this.picks,
    required this.hhi,
    required this.diversityScore,
    this.coveredMonths = const {},
  });

  factory PortfolioRecommendation.empty(PersonaProfile p) =>
      PortfolioRecommendation(
        persona: p, picks: [], hhi: 1.0, diversityScore: 0,
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

  /// 커버리지 점수 (0-12)
  int get coverageCount => coveredMonths.length;

  /// 커버리지 비율 (0.0-1.0)
  double get coverageRate => coveredMonths.length / 12.0;

  List<String> rationale() {
    final reasons = <String>[];
    final p = persona;
    final achievementPct = (totalMonthlyDividend / p.monthlyTarget * 100).round();

    if (achievementPct >= 95) {
      reasons.add('예산 ${formatBudget(p.budget)}으로 목표 월 ${formatBudget(p.monthlyTarget)}을 거의 달성할 수 있어요');
    } else if (achievementPct >= 60) {
      reasons.add('현재 예산으로는 월 ${formatBudget(totalMonthlyDividend.round())} (목표의 $achievementPct%) 받을 수 있어요');
    } else if (achievementPct >= 30) {
      final neededBudget = (p.budget / (achievementPct / 100)).round();
      reasons.add('월 ${formatBudget(p.monthlyTarget)} 달성하려면 ${formatBudget(neededBudget)} 필요해요. 현재는 월 ${formatBudget(totalMonthlyDividend.round())} 받을 수 있어요');
    } else {
      reasons.add('지금 예산으로는 월 ${formatBudget(totalMonthlyDividend.round())} 정도예요. 매달 적립식 투자를 추천드려요');
    }
    // ⭐ 월급형 사용자는 커버리지 강조
    if (p.cashflowPreference < -0.4) {
      if (coveredMonths.length == 12) {
        reasons.add('1월부터 12월까지 매달 배당이 들어오도록 종목을 조합했어요');
      } else if (coveredMonths.length >= 9) {
        reasons.add('${coveredMonths.length}개월 커버 — 거의 매달 배당이 들어와요');
      } else {
        reasons.add('${coveredMonths.length}개월 커버 (월배당 ETF를 더 추가하면 12개월 커버 가능)');
      }
    }

    if (p.horizon < -0.3) {
      reasons.add('단기 목표 달성을 위해 배당수익률 높은 종목을 우선 배치했어요');
    } else if (p.horizon > 0.3) {
      reasons.add('긴 시간 지평을 활용해 안정 성장형도 함께 담았어요');
    }
    if (p.downsideTolerance < -0.3) {
      reasons.add('하방 방어를 위해 변동성 낮은 종목 위주로 골랐어요');
    }
    if (p.diversificationDemand > 0.5) {
      reasons.add('${picks.length}개 종목으로 섹터를 분산해 리스크를 낮췄어요');
    }
    if (p.inflationHedge > 0.4) {
      reasons.add('인플레이션 방어를 위해 리츠·인프라를 추가했어요');
    }
    if (p.taxSensitivity < -0.3) {
      reasons.add('종합과세 회피를 위해 분리과세 ETF 비중을 늘렸어요');
    }
    if (p.excludedSectors.isNotEmpty) {
      final excluded = p.excludedSectors.map((s) {
        switch (s) {
          case 'gambling': return '도박';
          case 'sin': return '담배·주류';
          case 'fossil': return '화석연료';
          case 'defense': return '방산';
          default: return s;
        }
      }).join(', ');
      reasons.add('제외 요청 산업($excluded)은 모두 빼고 추천했어요');
    }
    return reasons;
  }

  String formatBudget(int v) {
    if (v >= 100000000) return '${(v / 100000000).toStringAsFixed(1)}억';
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(0)}만원';
    return '$v원';
  }
}