/// ═══════════════════════════════════════════════════════════
///  TaxCalculator v2 — 2026년 한국 세제 정확 반영
///
///  [핵심 룰]
///  1) 원천징수: 14% + 지방세 1.4% = 15.4%
///  2) 종합과세: 연 금융소득(이자+배당) 2,000만 원 초과 시
///     - 2,000만 원까지는 14% (분리과세분)
///     - 초과분은 다른 종합소득과 합산해 누진세율 6.6~49.5%
///     - 비교산출세액 적용 (둘 중 큰 금액 채택)
///  3) ⭐ 2026년 신설: 고배당 상장사 배당 분리과세 선택
///     · 2,000만 원 이하       : 15.4% (지방세 포함)
///     · 2,000만 ~ 3억 원      : 22.0% (지방세 포함)
///     · 3억 ~ 50억 원         : 27.5%
///     · 50억 원 초과          : 33.0%
///     ※ 조세특례제한법 제104조의27 (2026.1.1 ~ 2028)
///     ※ 리츠·펀드는 분리과세 대상에서 제외
///
///  ⚠️ 정확한 세금 = 세무사 상담 필요 — 추정치임
/// ═══════════════════════════════════════════════════════════

class TaxBreakdown {
  /// 연간 배당 총액 (세전)
  final int annualDividendGross;

  /// 원천징수액 (15.4%)
  final int withholdingTax;

  /// 종합과세 추가 부담분 (2,000만 원 초과분)
  final int comprehensiveTaxAdditional;

  /// 종합과세 시 총 세금
  final int totalTax;

  /// 종합과세 시 연 실수령
  final int annualDividendNet;

  /// 종합과세 시 월 실수령
  final int monthlyNet;

  /// 종합과세 대상 여부 (연 금융소득 2천만 원 초과)
  final bool isComprehensiveTaxable;

  /// 적용 한계세율 (종합과세 시)
  final double comprehensiveRate;

  /// ⭐ 2026 신설: 분리과세 선택 시 총 세금
  final int separateTaxAmount;

  /// 분리과세 선택 시 연 실수령
  final int separateNetAnnual;

  /// 분리과세 선택 시 월 실수령
  final int separateNetMonthly;

  /// 분리과세 적용 세율 (실효)
  final double separateEffectiveRate;

  /// 분리과세가 더 유리한가
  final bool isSeparateBetter;

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
    required this.separateTaxAmount,
    required this.separateNetAnnual,
    required this.separateNetMonthly,
    required this.separateEffectiveRate,
    required this.isSeparateBetter,
    required this.tips,
  });

  /// 종합과세 시 유효세율
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
  /// 원천징수율 (14% + 지방세 1.4%)
  static const double withholdingRate = 0.154;

  /// 종합과세 기준선
  static const int comprehensiveTaxThreshold = 20000000; // 2,000만 원

  /// 종합소득세 누진세율 표 (지방세 포함, 2025 귀속분 기준)
  /// (한도, 세율) — 한도는 누적 과세표준 상한
  static const List<_TaxBracket> brackets = [
    _TaxBracket(limit: 14000000,    rate: 0.066), // 6% + 0.6%
    _TaxBracket(limit: 50000000,    rate: 0.165), // 15% + 1.5%
    _TaxBracket(limit: 88000000,    rate: 0.264), // 24% + 2.4%
    _TaxBracket(limit: 150000000,   rate: 0.385), // 35% + 3.5%
    _TaxBracket(limit: 300000000,   rate: 0.418), // 38% + 3.8%
    _TaxBracket(limit: 500000000,   rate: 0.440), // 40% + 4.0%
    _TaxBracket(limit: 1000000000,  rate: 0.462), // 42% + 4.2%
    _TaxBracket(limit: double.infinity, rate: 0.495), // 45% + 4.5%
  ];

  /// ⭐ 2026 고배당 분리과세 누진 구간 (지방세 포함)
  /// 조세특례제한법 제104조의27 (확정, 2025.11.30 국회 기재위 의결)
  static const List<_TaxBracket> separateBrackets = [
    _TaxBracket(limit: 20000000,    rate: 0.154), // 2,000만 이하
    _TaxBracket(limit: 300000000,   rate: 0.220), // 2,000만 ~ 3억
    _TaxBracket(limit: 5000000000,  rate: 0.275), // 3억 ~ 50억
    _TaxBracket(limit: double.infinity, rate: 0.330), // 50억 초과
  ];

  /// 메인 계산 함수
  static TaxBreakdown calculate({
    required int monthlyDividend,
    int otherFinancialIncome = 0,
    int otherTaxableIncome = 30000000, // 다른 종합소득 (근로소득 등) 기본값
    bool hasIsa = false,
    bool isHighYieldEligible = true,    // 고배당 분리과세 자격 여부 (디폴트 yes)
  }) {
    final annualGross = monthlyDividend * 12;

    // ① 원천징수 (15.4%)
    final withholding = (annualGross * withholdingRate).round();

    // ② 종합과세 판정
    final totalFinancialIncome = annualGross + otherFinancialIncome;
    final isComprehensive = totalFinancialIncome > comprehensiveTaxThreshold;

    int additional = 0;
    double appliedRate = withholdingRate;

    if (isComprehensive) {
      // 비교산출세액 방식
      // 일반산출세액 = (기타종합소득 + 2,000만 초과분) × 누진세율 + 2,000만 × 14%
      // 비교산출세액 = 기타종합소득 × 누진세율 + 금융소득 × 14%
      // → 둘 중 큰 금액 채택
      final excess = totalFinancialIncome - comprehensiveTaxThreshold;
      final base1 = otherTaxableIncome + excess;
      final tax1 = _progressiveTax(base1, brackets) +
          (comprehensiveTaxThreshold * 0.154).round();
      final tax2 = _progressiveTax(otherTaxableIncome, brackets) +
          (totalFinancialIncome * 0.154).round();
      final combinedTax = tax1 > tax2 ? tax1 : tax2;
      // 위 계산은 전체 종합소득세 — 배당 부분만 떼어내려면 비례배분
      // 단순화: 배당분 추가 부담 = (종합세 - 기타소득만의 세금)
      final baseOnly = _progressiveTax(otherTaxableIncome, brackets);
      additional = (combinedTax - baseOnly - withholding).clamp(0, annualGross).toInt();
      appliedRate = _estimateMarginalRate(otherTaxableIncome + excess);
    }

    final totalTax = withholding + additional;
    final netAnnual = annualGross - totalTax;
    final netMonthly = (netAnnual / 12).round();

    // ③ ⭐ 분리과세 선택 시 (2026 신설)
    int separateTax = 0;
    if (isHighYieldEligible) {
      separateTax = _progressiveTax(annualGross, separateBrackets);
    } else {
      separateTax = withholding; // 자격 없으면 원천징수만
    }
    final separateNet = annualGross - separateTax;
    final separateMonthly = (separateNet / 12).round();
    final separateRate =
    annualGross > 0 ? separateTax / annualGross : withholdingRate;

    // ④ 분리과세가 더 유리한가
    final isSeparateBetter = isComprehensive &&
        isHighYieldEligible &&
        separateTax < totalTax;

    // ⑤ 절세 팁
    final tips = _buildTips(
      annualGross: annualGross,
      isComprehensive: isComprehensive,
      isSeparateBetter: isSeparateBetter,
      isHighYieldEligible: isHighYieldEligible,
      hasIsa: hasIsa,
      totalFinancialIncome: totalFinancialIncome,
      saving: isComprehensive && isHighYieldEligible
          ? (totalTax - separateTax)
          : 0,
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
      separateTaxAmount: separateTax,
      separateNetAnnual: separateNet,
      separateNetMonthly: separateMonthly,
      separateEffectiveRate: separateRate,
      isSeparateBetter: isSeparateBetter,
      tips: tips,
    );
  }

  /// 누진세 계산 (구간별 한계세율)
  /// 단순화: 각 구간 상한까지의 차액에 해당 세율 적용 후 합산
  static int _progressiveTax(int taxableIncome, List<_TaxBracket> bracketList) {
    if (taxableIncome <= 0) return 0;
    double remaining = taxableIncome.toDouble();
    double prevLimit = 0;
    double tax = 0;
    for (final b in bracketList) {
      final segCap = b.limit == double.infinity
          ? remaining
          : (b.limit - prevLimit).toDouble();
      final segAmt = remaining < segCap ? remaining : segCap;
      tax += segAmt * b.rate;
      remaining -= segAmt;
      prevLimit = b.limit.toDouble();
      if (remaining <= 0) break;
    }
    return tax.round();
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
    required bool isSeparateBetter,
    required bool isHighYieldEligible,
    required bool hasIsa,
    required int totalFinancialIncome,
    required int saving,
  }) {
    final tips = <TaxTip>[];

    // 분리과세가 더 유리한 경우 우선 안내
    if (isSeparateBetter && saving > 0) {
      tips.add(TaxTip(
        title: '분리과세 신청하면 ₩${_fmtKrw(saving)} 절세',
        description:
        '연 금융소득 2,000만 원 초과 종합과세 대상이지만, 2026년부터 고배당 상장사 배당은 분리과세를 선택할 수 있어요. 5월 종합소득세 신고 시 신청',
        priority: TaxTipPriority.high,
      ));
    }

    if (isComprehensive && !isSeparateBetter) {
      tips.add(TaxTip(
        title: '종합과세 대상',
        description:
        '연 금융소득 ${_fmtKrw(totalFinancialIncome)}으로 종합과세 대상. 부부 명의 분산이나 ISA 활용을 고려해보세요',
        priority: TaxTipPriority.high,
      ));
    }

    if (annualGross > 15000000 && !hasIsa) {
      tips.add(const TaxTip(
        title: 'ISA 계좌 활용',
        description:
        '연 200만 원까지 비과세 (서민형 400만 원). 5년 이상 유지 시 세제 혜택',
        priority: TaxTipPriority.high,
      ));
    }

    if (annualGross > 5000000) {
      tips.add(const TaxTip(
        title: '국내 주식형 ETF',
        description:
        '국내 주식형 ETF는 매매차익 비과세, 배당만 15.4% 분리과세로 종합과세 회피 가능',
        priority: TaxTipPriority.medium,
      ));
    }

    if (totalFinancialIncome > comprehensiveTaxThreshold * 0.8 &&
        totalFinancialIncome < comprehensiveTaxThreshold) {
      tips.add(const TaxTip(
        title: '종합과세 임박',
        description:
        '연 2,000만 원에 가까워요. 추가 매수 시 명의 분산을 고려해보세요',
        priority: TaxTipPriority.medium,
      ));
    }

    tips.add(const TaxTip(
      title: '연금저축·IRP',
      description:
      '세액공제 + 과세이연. 장기 보유 시 16.5% 분리과세로 절세 가능',
      priority: TaxTipPriority.low,
    ));

    return tips;
  }

  static String _fmtKrw(int v) {
    if (v >= 100000000) return '${(v / 100000000).toStringAsFixed(1)}억';
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(0)}만 원';
    return '${v}원';
  }
}

class _TaxBracket {
  final num limit;
  final double rate;
  const _TaxBracket({required this.limit, required this.rate});
}
