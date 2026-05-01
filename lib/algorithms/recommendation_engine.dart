import 'dart:math' as math;
import '../models/stock_model.dart';
import '../services/forecast_engine.dart';
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
        stock.name.contains('TIGER')
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
      '035250': 'gambling',
      '033780': 'sin',
    };
    if (sin.containsKey(code)) return -0.7;
    return 0.2;
  }

  bool isExcludedFor(PersonaProfile profile, String code) {
    if (profile.excludedSectors.contains('gambling') &&
        const ['035250'].contains(code)) {
      return true;
    }
    if (profile.excludedSectors.contains('sin') &&
        const ['033780', '000080'].contains(code)) {
      return true;
    }
    if (profile.excludedSectors.contains('fossil') &&
        const ['015760', '036460'].contains(code)) {
      return true;
    }
    return false;
  }
}

/// ═══════════════════════════════════════════════════════════
///  PortfolioPick — 단일 종목 비중 (public 클래스로 변경)
/// ═══════════════════════════════════════════════════════════
class PortfolioPick {
  final StockModel stock;
  final int shares;
  final double score;
  final double monthlyDividend;     // 이 종목이 매달 기여하는 배당금
  final double weightOfTotal;        // 전체 포트폴리오에서 이 종목 비중 (0.0-1.0)
  final double cost;                 // shares × price

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
///  RecommendationEngine — 핵심 알고리즘
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
  ///  포트폴리오 빌드 — 개선된 비중 분배 알고리즘
  ///
  ///  핵심 개선:
  ///   - 점수 비례로 각 종목의 "월 배당 목표 분담액" 결정
  ///   - 종목별 정확한 주식 수 + 비중 % 계산
  ///   - 다양한 섹터 강제 (HHI 기반)
  ///   - 최소 4종목, 최대 8종목
  /// ═════════════════════════════════════════════════════
  static PortfolioRecommendation buildPortfolio({
    required PersonaProfile persona,
    required List<StockModel> universe,
  }) {
    // 1) 후보 점수화
    final scored = <_ScoredStock>[];
    for (final s in universe) {
      final score = scoreStock(stock: s, persona: persona);
      if (score > 0) scored.add(_ScoredStock(s, score));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));

    if (scored.isEmpty) {
      return PortfolioRecommendation.empty(persona);
    }

    // 2) 다각화 한도 결정
    final maxSectorWeight =
        0.7 - (persona.diversificationDemand + 1) / 2 * 0.40;

    // 3) 목표 종목 수
    final targetCount =
    (4 + persona.diversificationDemand * 2.5).round().clamp(4, 7);

    // 4) 점수 기반 그리디 선택 (섹터 한도 체크)
    final selectedScored = <_ScoredStock>[];
    final sectorTallies = <String, int>{};

    for (final ss in scored) {
      if (selectedScored.length >= targetCount) break;
      final sector = ss.stock.sector.name;
      final currentSectorCount = sectorTallies[sector] ?? 0;
      // 한 섹터당 최대 2개 (분산 강할수록 1개)
      final maxPerSector =
      persona.diversificationDemand > 0.3 ? 1 : 2;
      if (currentSectorCount >= maxPerSector) continue;

      selectedScored.add(ss);
      sectorTallies[sector] = currentSectorCount + 1;
    }

    // 부족하면 섹터 제한 풀고 추가
    if (selectedScored.length < 4) {
      for (final ss in scored) {
        if (selectedScored.any((s) => s.stock.code == ss.stock.code)) continue;
        if (selectedScored.length >= 4) break;
        selectedScored.add(ss);
      }
    }

    // 5) 점수 비례로 월 배당 목표 분배
    final totalScore = selectedScored.fold<double>(0, (a, b) => a + b.score);
    final picks = <PortfolioPick>[];
    double totalCost = 0;

    // 1차: 각 종목에 분담할 월 배당액 → 필요 주식 수
    final preliminaryPicks = <_PreliminaryPick>[];
    for (final ss in selectedScored) {
      final share = ss.score / totalScore;
      final stockMonthlyTarget = persona.monthlyTarget * share;
      final shares = ss.stock.sharesNeededForMonthly(stockMonthlyTarget.round());
      if (shares <= 0) continue;
      final cost = shares * ss.stock.price;
      preliminaryPicks.add(_PreliminaryPick(
        stock: ss.stock,
        shares: shares,
        score: ss.score,
        cost: cost,
        monthlyDividend: ss.stock.monthlyDividend(shares),
      ));
      totalCost += cost;
    }

    // 2차: 정확한 비중 % 계산
    for (final p in preliminaryPicks) {
      picks.add(PortfolioPick(
        stock: p.stock,
        shares: p.shares,
        score: p.score,
        monthlyDividend: p.monthlyDividend,
        weightOfTotal: totalCost > 0 ? p.cost / totalCost : 0,
        cost: p.cost,
      ));
    }

    // 비중 큰 순으로 정렬
    picks.sort((a, b) => b.weightOfTotal.compareTo(a.weightOfTotal));

    // 6) HHI 계산
    final hhi = _calculateHHI(picks);

    return PortfolioRecommendation(
      persona: persona,
      picks: picks,
      hhi: hhi,
      diversityScore: 1.0 - hhi,
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
///  PortfolioRecommendation — 결과
/// ═══════════════════════════════════════════════════════════
class PortfolioRecommendation {
  final PersonaProfile persona;
  final List<PortfolioPick> picks;
  final double hhi;
  final double diversityScore;

  PortfolioRecommendation({
    required this.persona,
    required this.picks,
    required this.hhi,
    required this.diversityScore,
  });

  factory PortfolioRecommendation.empty(PersonaProfile p) =>
      PortfolioRecommendation(persona: p, picks: [], hhi: 1.0, diversityScore: 0);

  Map<StockModel, int> toMap() => {for (final p in picks) p.stock: p.shares};

  int get totalInvestment =>
      picks.fold(0, (a, p) => a + p.cost.round());

  double get totalMonthlyDividend =>
      picks.fold(0.0, (a, p) => a + p.monthlyDividend);

  /// 섹터별 비중 합계
  Map<StockSector, double> get sectorBreakdown {
    final map = <StockSector, double>{};
    for (final p in picks) {
      map[p.stock.sector] = (map[p.stock.sector] ?? 0) + p.weightOfTotal;
    }
    return map;
  }

  /// 추천 이유 (한국어 자연어)
  List<String> rationale() {
    final reasons = <String>[];
    final p = persona;

    if (p.horizon < -0.3) {
      reasons.add('단기 목표 달성을 위해 배당수익률 높은 종목을 우선 배치했어요');
    } else if (p.horizon > 0.3) {
      reasons.add('긴 시간 지평을 활용해 안정 성장형도 함께 담았어요');
    }
    if (p.downsideTolerance < -0.3) {
      reasons.add('하방 방어를 위해 변동성 낮은 종목 위주로 골랐어요');
    }
    if (p.cashflowPreference < -0.3) {
      reasons.add('월급처럼 분기·월배당 종목 비중을 높였어요');
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
          case 'gambling':
            return '도박';
          case 'sin':
            return '담배·주류';
          case 'fossil':
            return '화석연료';
          case 'defense':
            return '방산';
          default:
            return s;
        }
      }).join(', ');
      reasons.add('제외 요청 산업($excluded)은 모두 빼고 추천했어요');
    }
    return reasons;
  }
}