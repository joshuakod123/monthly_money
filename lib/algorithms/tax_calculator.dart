/// ═══════════════════════════════════════════════════════════
///  TaxCalculator — 한국 배당소득세 계산
///
///  세제 (2025년 기준):
///   1) 일반 배당: 15.4% 원천징수 (소득세 14% + 지방세 1.4%)
///   2) 분리과세 ETF: 15.4% (국내주식형 일부)
///   3) 종합과세: 연 2,000만원 초과분은 종합소득세율 적용 (6.6% ~ 49.5%)
///
///  📌 참고: 정확한 세금 계산은 세무사 상담 필요
///         이 계산은 일반적 추정치
/// ═══════════════════════════════════════════════════════════

class TaxBreakdown {
  /// 연간 배당 총액 (세전)
  final int annualDividendGross;

  /// 원천징수 (15.4%)
  final int withholdingTax;

  /// 종합과세 추가분 (2000만원 초과시)
  final int comprehensiveTaxAdditional;

  /// 총 세금
  final int totalTax;

  /// 실수령 (세후)
  final int annualDividendNet;

  /// 월 평균 실수령
  final int monthlyNet;

  /// 종합과세 대상 여부
  final bool isComprehensiveTaxable;

  /// 적용 종합소득세율
  final double comprehensiveRate;

  /// 절세 팁
  final List<TaxTip> tips;

  const TaxBreakdown({
    required this.annualDividendGross,
    required this.withholdingTax,
    required this.comprehensiveTaxAdditional,
    required this.totalTax,
    required this.annualDividendNet,
    required this.monthlyNet,
    required this.isComprehensiveTaxable,
    required this.comprehensiveRate,
    required this.tips,
  });

  /// 총 유효세율
  double get effectiveTaxRate =>
      annualDividendGross > 0 ? totalTax / annualDividendGross : 0;
}

class TaxTip {
  final String title;
  final String description;
  final TaxTipPriority priority;

  const TaxTip({
    required this.title,
    required this.description,
    required this.priority,
  });
}

enum TaxTipPriority { high, medium, low }

class TaxCalculator {
  /// 원천징수율
  static const double withholdingRate = 0.154; // 14% + 지방세 1.4%

  /// 종합과세 기준선
  static const int comprehensiveTaxThreshold = 20000000; // 2,000만원

  /// 종합소득세 구간 (단순화)
  /// 실제로는 누진공제액 적용해야 정확함
  static const List<_TaxBracket> brackets = [
    _TaxBracket(limit: 14000000, rate: 0.066), // 6% + 0.6%
    _TaxBracket(limit: 50000000, rate: 0.165), // 15% + 1.5%
    _TaxBracket(limit: 88000000, rate: 0.264), // 24% + 2.4%
    _TaxBracket(limit: 150000000, rate: 0.385), // 35% + 3.5%
    _TaxBracket(limit: 300000000, rate: 0.418),
    _TaxBracket(limit: 500000000, rate: 0.440),
    _TaxBracket(limit: 1000000000, rate: 0.462),
    _TaxBracket(limit: double.infinity, rate: 0.495),
  ];

  /// 메인 계산 함수
  static TaxBreakdown calculate({
    required int monthlyDividend,
    int otherFinancialIncome = 0,
    bool hasIsa = false,
  }) {
    final annualGross = monthlyDividend * 12;

    // 1) 원천징수 (모든 배당에 일단 적용)
    final withholding = (annualGross * withholdingRate).round();

    // 2) 종합과세 판정
    final totalFinancialIncome = annualGross + otherFinancialIncome;
    final isComprehensive = totalFinancialIncome > comprehensiveTaxThreshold;

    int additional = 0;
    double appliedRate = withholdingRate;

    if (isComprehensive) {
      // 2,000만원 초과분에 대해 종합소득세율 적용
      // 단순화: 평균 종합소득세율 ~22% 가정 (대부분 사용자)
      final excessAmount = totalFinancialIncome - comprehensiveTaxThreshold;
      final estimatedComprehensiveRate = _estimateMarginalRate(totalFinancialIncome);

      // 종합과세 추가 부담 = 초과분 × (종합세율 - 원천징수율)
      additional = (excessAmount *
          (estimatedComprehensiveRate - withholdingRate))
          .round()
          .clamp(0, excessAmount);
      appliedRate = estimatedComprehensiveRate;
    }

    final totalTax = withholding + additional;
    final netAnnual = annualGross - totalTax;
    final netMonthly = (netAnnual / 12).round();

    // 3) 절세 팁 생성
    final tips = _buildTips(
      annualGross: annualGross,
      isComprehensive: isComprehensive,
      hasIsa: hasIsa,
      totalFinancialIncome: totalFinancialIncome,
    );

    return TaxBreakdown(
      annualDividendGross: annualGross,
      withholdingTax: withholding,
      comprehensiveTaxAdditional: additional,
      totalTax: totalTax,
      annualDividendNet: netAnnual,
      monthlyNet: netMonthly,
      isComprehensiveTaxable: isComprehensive,
      comprehensiveRate: appliedRate,
      tips: tips,
    );
  }

  static double _estimateMarginalRate(int income) {
    for (final b in brackets) {
      if (income <= b.limit) return b.rate;
    }
    return 0.495;
  }

  static List<TaxTip> _buildTips({
    required int annualGross,
    required bool isComprehensive,
    required bool hasIsa,
    required int totalFinancialIncome,
  }) {
    final tips = <TaxTip>[];

    if (isComprehensive) {
      tips.add(TaxTip(
        title: '종합과세 대상이에요',
        description:
        '연 금융소득 ${_fmtKrw(totalFinancialIncome)}으로 종합과세 대상입니다. 부부 명의 분산이나 ISA 활용을 고려해보세요',
        priority: TaxTipPriority.high,
      ));
    }

    if (annualGross > 15000000 && !hasIsa) {
      tips.add(const TaxTip(
        title: 'ISA 계좌 활용',
        description: '연 200만원까지 비과세 (서민형 400만원). 5년 이상 유지 시 세제 혜택',
        priority: TaxTipPriority.high,
      ));
    }

    if (annualGross > 5000000) {
      tips.add(const TaxTip(
        title: '분리과세 ETF 활용',
        description: '국내주식형 ETF는 매매차익 비과세, 배당만 15.4% 분리과세로 종합과세 회피',
        priority: TaxTipPriority.medium,
      ));
    }

    if (totalFinancialIncome > comprehensiveTaxThreshold * 0.8 &&
        totalFinancialIncome < comprehensiveTaxThreshold) {
      tips.add(const TaxTip(
        title: '종합과세 임박',
        description: '연 2,000만원에 가까워요. 추가 매수 시 명의 분산을 고려해보세요',
        priority: TaxTipPriority.medium,
      ));
    }

    tips.add(const TaxTip(
      title: '연금저축·IRP 활용',
      description: '세액공제 + 과세이연. 장기 보유 시 16.5% 분리과세로 절세 가능',
      priority: TaxTipPriority.low,
    ));

    return tips;
  }

  static String _fmtKrw(int v) {
    if (v >= 100000000) return '${(v / 100000000).toStringAsFixed(1)}억';
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(0)}만원';
    return '${v}원';
  }
}

class _TaxBracket {
  final num limit;
  final double rate;
  const _TaxBracket({required this.limit, required this.rate});
}