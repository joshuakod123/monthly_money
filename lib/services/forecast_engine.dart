import 'dart:math' as math;
import '../models/stock_model.dart';

/// ═══════════════════════════════════════════════════════════
/// 배당금 예측 엔진 (Dividend Forecast Engine)
/// ═══════════════════════════════════════════════════════════
///
/// 자체 예측 공식 (Custom Formula):
///
///   E[D_t+1] = D_t × (1 + g_blend) × C_stability × R_payout
///
///   여기서:
///   - D_t          : 최근 연도 배당금
///   - g_blend      : 가중 배당 성장률 (CAGR + 단기성장률 가중평균)
///   - C_stability  : 안정성 보정계수 (변동성 기반)
///   - R_payout     : 배당성향 회귀 보정 (ROE 반영)
///
/// 이 공식은 한국 배당주의 특성을 반영해 설계됨:
///  1) 최근 3년 추세를 더 무겁게 (52주 모멘텀 효과)
///  2) 변동성이 클수록 미래값을 보수적으로 추정
///  3) 코로나(2020) 같은 outlier 영향 자동 완화
///
/// ═══════════════════════════════════════════════════════════

class DividendForecast {
  final int year;
  final int predictedAmount;     // 예상 주당 배당금 (원)
  final double predictedYield;   // 예상 배당수익률 (%)
  final double confidenceLevel;  // 신뢰도 (0.0 ~ 1.0)
  final int lowerBound;          // 95% 신뢰구간 하한
  final int upperBound;          // 95% 신뢰구간 상한
  final String trend;            // '상승' / '안정' / '하락'

  const DividendForecast({
    required this.year,
    required this.predictedAmount,
    required this.predictedYield,
    required this.confidenceLevel,
    required this.lowerBound,
    required this.upperBound,
    required this.trend,
  });
}

class ForecastEngine {

  /// ─────────────────────────────────────────────────
  /// 메인 함수: 향후 N년치 배당금 예측
  /// ─────────────────────────────────────────────────
  static List<DividendForecast> forecast(StockModel stock, {int years = 3}) {
    if (stock.history.isEmpty) return [];

    final history = [...stock.history]..sort((a, b) => a.year.compareTo(b.year));

    // 0배당 종목은 예측 불가
    if (history.last.amount == 0) {
      return List.generate(years, (i) => DividendForecast(
        year: history.last.year + i + 1,
        predictedAmount: 0,
        predictedYield: 0.0,
        confidenceLevel: 0.0,
        lowerBound: 0,
        upperBound: 0,
        trend: '예측불가',
      ));
    }

    // ① 가중 성장률 계산
    final gBlend = _weightedGrowthRate(history);

    // ② 안정성 보정계수 (변동계수 CV 기반)
    final cStability = _stabilityCoefficient(history);

    // ③ 배당성향 회귀 보정 (ROE 기반)
    final rPayout = _payoutRegression(stock);

    // ④ 추세 결정
    final trend = _determineTrend(gBlend, cStability);

    // ⑤ 변동성 (신뢰구간 계산용)
    final volatility = _historicalVolatility(history);

    List<DividendForecast> forecasts = [];
    double currentAmount = history.last.amount.toDouble();

    for (int i = 1; i <= years; i++) {
      // 핵심 공식 적용
      double predicted = currentAmount *
          (1 + gBlend) *
          cStability *
          rPayout;

      // 시간이 지날수록 신뢰도는 감소
      double confidence = math.max(0.4, 1.0 - (i * 0.15) - (volatility * 0.5));

      // 95% 신뢰구간 (시간 경과에 따라 폭이 넓어짐)
      double margin = predicted * volatility * math.sqrt(i.toDouble()) * 1.96;
      int lower = math.max(0, (predicted - margin).round());
      int upper = (predicted + margin).round();

      // 다음 해 예상 수익률 (현재가 기준)
      double yield = (predicted * _frequencyMultiplier(stock.frequency)) /
          stock.price * 100;

      forecasts.add(DividendForecast(
        year: history.last.year + i,
        predictedAmount: predicted.round(),
        predictedYield: yield,
        confidenceLevel: confidence,
        lowerBound: lower,
        upperBound: upper,
        trend: trend,
      ));

      currentAmount = predicted;
    }

    return forecasts;
  }

  /// ─────────────────────────────────────────────────
  /// ① 가중 성장률 (Weighted Growth Rate)
  /// 최근 데이터에 더 큰 가중치 부여
  /// ─────────────────────────────────────────────────
  static double _weightedGrowthRate(List<DividendHistory> history) {
    if (history.length < 2) return 0.0;

    // YoY 성장률 계산
    List<double> growthRates = [];
    for (int i = 1; i < history.length; i++) {
      double prev = history[i - 1].amount.toDouble();
      double curr = history[i].amount.toDouble();
      if (prev > 0) {
        growthRates.add((curr - prev) / prev);
      }
    }

    if (growthRates.isEmpty) return 0.0;

    // 가중치: 최근일수록 무거움 (1, 2, 3, 4, 5...)
    double weightSum = 0;
    double weightedSum = 0;
    for (int i = 0; i < growthRates.length; i++) {
      double weight = (i + 1).toDouble();
      weightedSum += growthRates[i] * weight;
      weightSum += weight;
    }

    double weightedAvg = weightedSum / weightSum;

    // CAGR (장기 성장률) 계산
    double startVal = history.first.amount.toDouble();
    double endVal = history.last.amount.toDouble();
    double cagr = 0;
    if (startVal > 0) {
      double years = (history.length - 1).toDouble();
      cagr = math.pow(endVal / startVal, 1 / years).toDouble() - 1;
    }

    // 가중평균(70%) + CAGR(30%)
    double blended = weightedAvg * 0.7 + cagr * 0.3;

    // 이상치 클리핑: -30% ~ +50% 범위로 제한 (현실성 보정)
    return blended.clamp(-0.30, 0.50);
  }

  /// ─────────────────────────────────────────────────
  /// ② 안정성 보정계수 (Stability Coefficient)
  /// 변동성이 클수록 미래값을 보수적으로 추정
  /// ─────────────────────────────────────────────────
  static double _stabilityCoefficient(List<DividendHistory> history) {
    if (history.length < 2) return 1.0;

    final amounts = history.map((h) => h.amount.toDouble()).toList();
    final mean = amounts.reduce((a, b) => a + b) / amounts.length;
    if (mean == 0) return 1.0;

    // 표준편차
    double variance = 0;
    for (var v in amounts) {
      variance += math.pow(v - mean, 2).toDouble();
    }
    variance /= amounts.length;
    double std = math.sqrt(variance);

    // 변동계수 (CV)
    double cv = std / mean;

    // CV가 낮으면 1.0에 가까움 (안정), 높으면 0.85로 (보수적 추정)
    // 0.05 (5%변동) → 1.00 / 0.30 (30%변동) → 0.85
    return (1.0 - (cv * 0.5)).clamp(0.85, 1.0);
  }

  /// ─────────────────────────────────────────────────
  /// ③ 배당성향 회귀 보정 (Payout Regression)
  /// 고ROE 기업은 배당여력 ↑, 저ROE 기업은 ↓ 반영
  /// ─────────────────────────────────────────────────
  static double _payoutRegression(StockModel stock) {
    // ROE 10% 기준선 → 1.0
    // ROE 15%+ → 1.05 (배당 여력 증가)
    // ROE  5% → 0.95 (배당 압박)
    double roeFactor = 1.0 + ((stock.roe - 10) * 0.01).clamp(-0.10, 0.10);

    // PBR 1.0 미만이면 저평가 → 자사주매입/배당 가능성 ↑ 약간 보정
    double pbrFactor = stock.pbr < 1.0 ? 1.02 : 1.0;

    return roeFactor * pbrFactor;
  }

  /// 변동성 계산 (수익률 표준편차)
  static double _historicalVolatility(List<DividendHistory> history) {
    if (history.length < 2) return 0.1;

    List<double> returns = [];
    for (int i = 1; i < history.length; i++) {
      double prev = history[i - 1].amount.toDouble();
      double curr = history[i].amount.toDouble();
      if (prev > 0) returns.add((curr - prev) / prev);
    }

    if (returns.isEmpty) return 0.1;

    double mean = returns.reduce((a, b) => a + b) / returns.length;
    double variance = returns
        .map((r) => math.pow(r - mean, 2).toDouble())
        .reduce((a, b) => a + b) /
        returns.length;
    return math.sqrt(variance);
  }

  /// 추세 판정
  static String _determineTrend(double growth, double stability) {
    if (growth > 0.05 && stability > 0.95) return '상승';
    if (growth < -0.03) return '하락';
    return '안정';
  }

  /// 배당 주기 → 연간 횟수
  static double _frequencyMultiplier(DividendFrequency freq) {
    switch (freq) {
      case DividendFrequency.monthly: return 12;
      case DividendFrequency.quarterly: return 4;
      case DividendFrequency.semiAnnual: return 2;
      case DividendFrequency.annual: return 1;
    }
  }

  /// ─────────────────────────────────────────────────
  /// 목표 달성 가능성 분석
  /// "현재 가격으로 매수했을 때, X년 뒤 월 N만원 받을 수 있는가?"
  /// ─────────────────────────────────────────────────
  static GoalProbability analyzeGoalAchievability({
    required StockModel stock,
    required int monthlyGoal,
    required int targetYears,
  }) {
    final forecasts = forecast(stock, years: targetYears);
    if (forecasts.isEmpty || forecasts.last.predictedAmount == 0) {
      return GoalProbability(
        probability: 0.0,
        sharesNeeded: 0,
        investmentRequired: 0,
        expectedMonthly: 0,
      );
    }

    final futureForecast = forecasts.last;
    final futureMonthlyPerShare =
        (futureForecast.predictedAmount * _frequencyMultiplier(stock.frequency)) / 12;

    if (futureMonthlyPerShare <= 0) {
      return GoalProbability(
        probability: 0.0,
        sharesNeeded: 0,
        investmentRequired: 0,
        expectedMonthly: 0,
      );
    }

    final sharesNeeded = (monthlyGoal / futureMonthlyPerShare).ceil();
    final investment = sharesNeeded * stock.price;

    // 신뢰구간 기반 확률 추정
    double probability = futureForecast.confidenceLevel;
    if (futureForecast.trend == '하락') probability *= 0.7;
    if (futureForecast.trend == '상승') probability *= 1.1;
    probability = probability.clamp(0.0, 0.95);

    return GoalProbability(
      probability: probability,
      sharesNeeded: sharesNeeded,
      investmentRequired: investment.round(),
      expectedMonthly: futureMonthlyPerShare.round(),
    );
  }

  /// ─────────────────────────────────────────────────
  /// 포트폴리오 종합 예측: 여러 종목의 N년 후 월 배당금 예측
  /// ─────────────────────────────────────────────────
  static PortfolioForecast forecastPortfolio({
    required Map<StockModel, int> portfolio,
    required int targetYears,
  }) {
    double totalCurrentMonthly = 0;
    double totalFutureMonthly = 0;
    double totalFutureLow = 0;
    double totalFutureHigh = 0;
    double totalInvestment = 0;
    double weightedConfidence = 0;
    double totalWeight = 0;

    portfolio.forEach((stock, shares) {
      totalInvestment += stock.price * shares;
      totalCurrentMonthly += stock.monthlyDividend(shares);

      final forecasts = forecast(stock, years: targetYears);
      if (forecasts.isNotEmpty) {
        final f = forecasts.last;
        final futurePerYear = f.predictedAmount * _frequencyMultiplier(stock.frequency);
        final futureMonthly = (futurePerYear / 12) * shares;
        final lowMonthly =
            (f.lowerBound * _frequencyMultiplier(stock.frequency) / 12) * shares;
        final highMonthly =
            (f.upperBound * _frequencyMultiplier(stock.frequency) / 12) * shares;

        totalFutureMonthly += futureMonthly;
        totalFutureLow += lowMonthly;
        totalFutureHigh += highMonthly;

        double weight = stock.price * shares;
        weightedConfidence += f.confidenceLevel * weight;
        totalWeight += weight;
      }
    });

    return PortfolioForecast(
      currentMonthly: totalCurrentMonthly.round(),
      expectedMonthly: totalFutureMonthly.round(),
      lowerBoundMonthly: totalFutureLow.round(),
      upperBoundMonthly: totalFutureHigh.round(),
      totalInvestment: totalInvestment.round(),
      avgConfidence: totalWeight > 0 ? weightedConfidence / totalWeight : 0,
      targetYear: DateTime.now().year + targetYears,
    );
  }
}

/// 목표 달성 분석 결과
class GoalProbability {
  final double probability;        // 달성 확률 (0.0 ~ 1.0)
  final int sharesNeeded;          // 필요한 주식 수
  final int investmentRequired;    // 필요 투자금
  final int expectedMonthly;       // 예상 주당 월 배당금

  const GoalProbability({
    required this.probability,
    required this.sharesNeeded,
    required this.investmentRequired,
    required this.expectedMonthly,
  });
}

/// 포트폴리오 종합 예측
class PortfolioForecast {
  final int currentMonthly;
  final int expectedMonthly;
  final int lowerBoundMonthly;
  final int upperBoundMonthly;
  final int totalInvestment;
  final double avgConfidence;
  final int targetYear;

  const PortfolioForecast({
    required this.currentMonthly,
    required this.expectedMonthly,
    required this.lowerBoundMonthly,
    required this.upperBoundMonthly,
    required this.totalInvestment,
    required this.avgConfidence,
    required this.targetYear,
  });

  double get growthRate =>
      currentMonthly > 0
          ? ((expectedMonthly - currentMonthly) / currentMonthly) * 100
          : 0;
}