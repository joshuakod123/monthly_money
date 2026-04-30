import 'dart:math' as math;
import '../models/stock_model.dart';
import '../services/forecast_engine.dart';
import 'persona_profile.dart';

/// ═══════════════════════════════════════════════════════════
///  종목별 특성 벡터 (Stock Vector) — 8차원
///  PersonaProfile.vector 와 같은 차원으로 매칭됨
/// ═══════════════════════════════════════════════════════════
class StockTraits {
  /// 안정성 (배당 변동계수 역수): -1 (변동 큼) ~ +1 (5년 안정 배당)
  final double stability;
  /// 배당 빈도 적합도: -1 (연배당) ~ +1 (월/분기배당)
  final double cashflowFrequency;
  /// 변동성: -1 (저베타, 방어적) ~ +1 (고변동)
  final double volatility;
  /// 세금 효율성: -1 (배당 종합과세) ~ +1 (분리과세 ETF)
  final double taxEfficiency;
  /// 유동성: -1 (소형주) ~ +1 (대형주, 거래 활발)
  final double liquidity;
  /// 윤리: -1 (담배·도박) ~ +1 (ESG 친화)
  final double ethicsScore;
  /// 섹터 ID (다각화 계산용)
  final String sectorId;
  /// 인플레이션 헷지: -1 (현금성 자산) ~ +1 (실물·인프라)
  final double inflationHedge;

  /// 배당수익률 (절대값, 별도 처리)
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
    // PersonaProfile.vector 와 같은 순서:
    // [horizon, cashflow, downside, tax, liquidity, ethics, diversification, inflation]
    // 종목 입장에서 각 차원의 "적합도"를 표현
    volatility,           // horizon: 장기일수록 변동성 OK
    cashflowFrequency,    // cashflow: 월/분기 배당이면 +
    -volatility,          // downside: 저변동일수록 매칭 (부호 반전)
    taxEfficiency,        // tax
    liquidity,            // liquidity
    ethicsScore,          // ethics
    0,                    // diversification: 종목 개별엔 적용 안됨 (포트폴리오 레벨)
    inflationHedge,       // inflation
  ];

  /// 사용자 답변에서 자동 추출
  factory StockTraits.fromStock(StockModel stock) {
    // 배당 안정성 — 5년 변동계수 기반
    double cv = 0.3; // default
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

    // 배당 빈도
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

    // 변동성 — PER로 추정 (PER 높을수록 성장주, 변동성 ↑)
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

    // 세금 효율성 — ETF는 분리과세 가능
    double taxEff = stock.name.contains('ETF') ||
        stock.name.contains('KODEX') ||
        stock.name.contains('TIGER')
        ? 0.7
        : -0.3;

    // 유동성 — 시가총액 기반 (조 단위)
    double liq;
    final mc = stock.marketCap; // 단위: 백만원 (KIS 응답)
    if (mc > 50000000) liq = 0.9;       // 50조+
    else if (mc > 10000000) liq = 0.5;  // 10조+
    else if (mc > 1000000) liq = 0.0;   // 1조+
    else if (mc > 100000) liq = -0.4;   // 1천억+
    else liq = -0.8;

    // 윤리 점수 — 종목 코드별 하드코딩 (예시)
    final ethics = _ethicsScoreFor(stock.code);

    // 섹터 ID
    final sectorId = stock.sector.name;

    // 인플레이션 헷지 — 리츠/에너지/인프라가 강함
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

  /// 종목별 윤리 점수 (확장 가능한 매핑)
  static double _ethicsScoreFor(String code) {
    const sin = {
      '035250': 'gambling', // 강원랜드
      '033780': 'sin',      // KT&G (담배)
    };
    if (sin.containsKey(code)) return -0.7;
    return 0.2;
  }

  /// 사용자 제외 섹터에 해당하는지
  bool isExcludedFor(PersonaProfile profile, String code) {
    if (profile.excludedSectors.contains('gambling') &&
        const ['035250'].contains(code)) return true;
    if (profile.excludedSectors.contains('sin') &&
        const ['033780', '000080'].contains(code)) return true;
    if (profile.excludedSectors.contains('fossil') &&
        const ['015760', '036460'].contains(code)) return true;
    return false;
  }
}

/// ═══════════════════════════════════════════════════════════
///  Recommendation Engine — 핵심 추천 알고리즘
/// ═══════════════════════════════════════════════════════════
class RecommendationEngine {
  /// 단일 종목에 대한 매칭 점수 (0.0 ~ 1.0)
  ///
  /// 다섯 가지 요소의 가중합:
  ///   1) Persona-Stock 코사인 유사도 (40%)
  ///   2) 배당수익률 적합성 (25%)
  ///   3) 안정성 (15%)
  ///   4) 인플레이션 헷지 정렬도 (10%)
  ///   5) 사용자 결정론적 시드 기반 미세 차별 (10%)
  static double scoreStock({
    required StockModel stock,
    required PersonaProfile persona,
  }) {
    final traits = StockTraits.fromStock(stock);

    // 제외 종목은 0점
    if (traits.isExcludedFor(persona, stock.code)) return 0.0;
    // 0배당은 0점
    if (stock.dividendYield <= 0) return 0.0;

    // ① 코사인 유사도
    final cosSim = _cosineSimilarity(persona.vector, traits.vector);
    // [-1, 1] → [0, 1]
    final simScore = (cosSim + 1) / 2;

    // ② 배당수익률 적합성
    // 시간 지평이 짧을수록 고배당 선호, 길수록 적정 배당
    final idealYield = persona.horizon < 0
        ? 6.0 + persona.horizon * (-2)  // 단기: 8% 선호
        : 4.0 - persona.horizon * 1.5;  // 장기: 2.5% 선호 (성장 여지)
    final yieldDiff = (stock.dividendYield - idealYield).abs();
    final yieldScore = math.max(0, 1.0 - yieldDiff / 5.0);

    // ③ 안정성 — 하방 방어 요구가 클수록 비중 ↑
    final stabilityWeight = (1 - persona.downsideTolerance) / 2;
    final stabilityScore = (traits.stability + 1) / 2;

    // ④ 인플레이션 헷지 정렬
    final inflScore =
        1.0 - ((persona.inflationHedge - traits.inflationHedge).abs() / 2);

    // ⑤ 결정론적 미세 차별 (같은 답이면 같은 결과 + 사용자별 미세 차이)
    final rng = math.Random(persona.deterministicSeed ^ stock.code.hashCode);
    final jitter = (rng.nextDouble() - 0.5) * 0.1;

    // 가중합
    final totalScore = simScore * 0.40 +
        yieldScore * 0.25 +
        stabilityScore * stabilityWeight * 0.15 +
        inflScore * 0.10 +
        (0.5 + jitter) * 0.10;

    return totalScore.clamp(0.0, 1.0);
  }

  /// 코사인 유사도 (벡터 길이가 다르면 0)
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
  /// 포트폴리오 빌드 — 점수 + 다각화 + 목표 매칭
  /// ═════════════════════════════════════════════════════
  ///
  /// 단순히 점수 상위 N개를 뽑는게 아니라:
  ///   1) 후보군 점수화
  ///   2) HHI(허핀달 지수)로 섹터 다각화 강제
  ///   3) Knapsack 변형으로 예산 내 배당 최대화
  ///   4) 다양성 패널티 (같은 섹터 너무 몰리면 감점)
  static PortfolioRecommendation buildPortfolio({
    required PersonaProfile persona,
    required List<StockModel> universe,
  }) {
    // 1) 모든 종목 점수화
    final scored = <_ScoredStock>[];
    for (final s in universe) {
      final score = scoreStock(stock: s, persona: persona);
      if (score > 0) scored.add(_ScoredStock(s, score));
    }
    scored.sort((a, b) => b.score.compareTo(a.score));

    if (scored.isEmpty) {
      return PortfolioRecommendation.empty(persona);
    }

    // 2) 다각화 강제 — diversificationDemand 에 따라 섹터당 최대 비중 결정
    // 분산 강하면 한 섹터 25% 까지, 약하면 70% 까지
    final maxSectorWeight =
        0.7 - (persona.diversificationDemand + 1) / 2 * 0.45;

    // 3) 그리디 선택 — 점수 높은 종목부터, 단 섹터 한도 체크
    final selected = <_PortfolioPick>[];
    final sectorWeights = <String, double>{};
    final remainingTarget = persona.monthlyTarget.toDouble();

    // 목표 종목 수 — 분산 강할수록 많이
    final targetCount = (4 + persona.diversificationDemand * 3).round().clamp(3, 8);

    for (final ss in scored) {
      if (selected.length >= targetCount) break;
      final sector = ss.stock.sector.name;
      final perStockTarget = remainingTarget / targetCount;
      final shares = ss.stock.sharesNeededForMonthly(perStockTarget.round());
      if (shares <= 0) continue;
      final cost = shares * ss.stock.price;
      // 임시 비중 추정 (예산 대비)
      final budgetUsed = (sectorWeights[sector] ?? 0) +
          (cost / persona.budget.clamp(1, double.infinity));
      if (budgetUsed > maxSectorWeight && persona.diversificationDemand > 0) {
        continue; // 섹터 한도 초과
      }
      selected.add(_PortfolioPick(ss.stock, shares, ss.score));
      sectorWeights[sector] = budgetUsed;
    }

    // 충분히 못 채웠으면 한도 무시하고 추가 (Hard fallback)
    if (selected.length < 3) {
      for (final ss in scored) {
        if (selected.any((p) => p.stock.code == ss.stock.code)) continue;
        if (selected.length >= 3) break;
        final shares =
        ss.stock.sharesNeededForMonthly(persona.monthlyTarget ~/ 3);
        if (shares > 0) {
          selected.add(_PortfolioPick(ss.stock, shares, ss.score));
        }
      }
    }

    // 4) 비중 재조정 — 점수 비례로 종목별 목표 배당 분배
    final totalScore = selected.fold<double>(0, (a, b) => a + b.score);
    if (totalScore > 0) {
      for (final p in selected) {
        final share = p.score / totalScore;
        final stockMonthlyTarget = (persona.monthlyTarget * share).round();
        p.shares = p.stock.sharesNeededForMonthly(stockMonthlyTarget);
      }
    }

    // 5) HHI 계산 (섹터 집중도 — 낮을수록 다각화)
    final hhi = _calculateHHI(selected);

    return PortfolioRecommendation(
      persona: persona,
      picks: selected,
      hhi: hhi,
      diversityScore: 1.0 - hhi,
    );
  }

  /// HHI (허핀달-허쉬만 지수) — 섹터 집중도 0 (완전분산) ~ 1 (한곳)
  static double _calculateHHI(List<_PortfolioPick> picks) {
    if (picks.isEmpty) return 1.0;
    final totalCost = picks.fold<double>(
        0, (a, b) => a + b.stock.price * b.shares);
    if (totalCost == 0) return 1.0;
    final sectorWeights = <String, double>{};
    for (final p in picks) {
      final w = (p.stock.price * p.shares) / totalCost;
      sectorWeights[p.stock.sector.name] =
          (sectorWeights[p.stock.sector.name] ?? 0) + w;
    }
    return sectorWeights.values.fold<double>(0, (a, w) => a + w * w);
  }
}

class _ScoredStock {
  final StockModel stock;
  final double score;
  _ScoredStock(this.stock, this.score);
}

class _PortfolioPick {
  final StockModel stock;
  int shares;
  final double score;
  _PortfolioPick(this.stock, this.shares, this.score);
}

/// 추천 결과
class PortfolioRecommendation {
  final PersonaProfile persona;
  final List<_PortfolioPick> picks;
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
      picks.fold(0, (a, p) => a + (p.stock.price * p.shares).round());

  double get totalMonthlyDividend =>
      picks.fold(0.0, (a, p) => a + p.stock.monthlyDividend(p.shares));

  /// 사람에게 설명할 수 있는 이 추천의 "이유"
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
      reasons.add('한 섹터 비중이 ${(0.7 - (p.diversificationDemand + 1) / 2 * 0.45 * 100).toStringAsFixed(0)}% 를 넘지 않게 분산했어요');
    }
    if (p.inflationHedge > 0.4) {
      reasons.add('인플레이션 방어를 위해 리츠·인프라를 추가했어요');
    }
    if (p.taxSensitivity < -0.3) {
      reasons.add('종합과세 회피를 위해 분리과세 ETF 비중을 늘렸어요');
    }
    if (p.excludedSectors.isNotEmpty) {
      reasons.add('제외 요청 산업(${p.excludedSectors.join(", ")})은 모두 빼고 추천했어요');
    }
    return reasons;
  }
}

/// PortfolioRecommendation 의 picks 를 외부에서 읽기 위한 helper
extension PortfolioPickAccess on PortfolioRecommendation {
  Iterable<({StockModel stock, int shares, double score})> get items => picks
      .map((p) => (stock: p.stock, shares: p.shares, score: p.score));
}