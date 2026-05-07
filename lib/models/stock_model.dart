import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════
///  StockSector — GICS 11개 표준 섹터 + all
///
///  GICS (Global Industry Classification Standard) 기반:
///   1) Energy       에너지     (정유·가스·석탄)
///   2) Materials    소재       (화학·철강·비철금속)
///   3) Industrials  산업재     (기계·건설·운송·항공·방산)
///   4) ConsumerDisc 경기소비재 (자동차·의류·여행·미디어 일부)
///   5) ConsumerStpl 필수소비재 (식품·생활용품·담배·주류)
///   6) HealthCare   헬스케어   (제약·바이오·의료기기)
///   7) Financials   금융       (은행·증권·보험)
///   8) IT           IT         (반도체·SW·HW)
///   9) CommSvc      커뮤니케이션(통신·미디어·엔터)
///  10) Utilities    유틸리티   (전력·수도·가스공급)
///  11) RealEstate   부동산     (REIT·부동산개발)
/// ═══════════════════════════════════════════════════════════
enum StockSector {
  all('전체', '전체', 'ALL', Color(0xFF8E8E93)),
  energy('에너지', '에너지', 'ENERGY', Color(0xFF1F2E47)),
  materials('소재', '소재', 'MATERIALS', Color(0xFF7A5C3D)),
  industrial('산업재', '산업재', 'INDUSTRIALS', Color(0xFF555A5C)),
  consumerDisc('경기소비재', '경기소비재', 'CONSUMER DISC.', Color(0xFFB8542F)),
  consumerStpl('필수소비재', '필수소비재', 'CONSUMER STAPLES', Color(0xFFC9A227)),
  healthcare('헬스케어', '헬스케어', 'HEALTH CARE', Color(0xFFE8B5BE)),
  finance('금융', '금융', 'FINANCIALS', Color(0xFF722F37)),
  tech('IT', 'IT', 'INFO TECH', Color(0xFF3D5A7A)),
  telecom('커뮤니케이션', '커뮤니케이션', 'COMM. SVC.', Color(0xFF6B5B95)),
  utilities('유틸리티', '유틸리티', 'UTILITIES', Color(0xFF6B7A5F)),
  reit('부동산', '리츠·부동산', 'REAL ESTATE', Color(0xFFA85962));

  const StockSector(this.label, this.fullLabel, this.englishLabel, this.defaultColor);

  /// 짧은 한글 라벨
  final String label;
  /// 풀 한글 라벨
  final String fullLabel;
  /// 영문 라벨 (display용)
  final String englishLabel;
  final Color defaultColor;

  /// 더 이상 emoji 안 씀 — 시그니처 컬러 + 큰 영문 타이포로 구분
  String get emoji => '';
}

enum InvestmentProfile {
  stable('안정형', '안정적인 수익을 중시하는 투자자'),
  balanced('균형형', '성장과 수익의 균형을 추구하는 투자자'),
  growth('성장형', '장기 자본 이득을 추구하는 투자자'),
  highYield('고배당형', '높은 배당수익률을 최우선으로 하는 투자자');

  const InvestmentProfile(this.label, this.description);
  final String label;
  final String description;
}

enum DividendFrequency {
  annual('연간 배당'),
  semiAnnual('반기 배당'),
  quarterly('분기 배당'),
  monthly('월 배당');

  const DividendFrequency(this.label);
  final String label;
}

class StockModel {
  final String code;
  final String name;
  final String nameEn;
  final StockSector sector;
  final double price;
  final double dividendYield;
  final int dividendPerShare;
  final int latestDividend;
  final DividendFrequency frequency;
  final List<int> paymentMonths;
  final double per;
  final double pbr;
  final double roe;
  final double eps;
  final List<DividendHistory> history;
  final bool isRecommended;
  final List<InvestmentProfile> suitableFor;
  final String riskLevel;
  final int marketCap;
  final Color sectorColor;

  const StockModel({
    required this.code,
    required this.name,
    this.nameEn = '',
    required this.sector,
    required this.price,
    this.dividendYield = 0,
    this.dividendPerShare = 0,
    this.latestDividend = 0,
    required this.frequency,
    required this.paymentMonths,
    this.per = 0,
    this.pbr = 0,
    this.roe = 0,
    this.eps = 0,
    this.history = const [],
    this.isRecommended = false,
    this.suitableFor = const [],
    this.riskLevel = '중간',
    this.marketCap = 0,
    this.sectorColor = const Color(0xFF8E8E93),
  });

  StockModel copyWith({
    String? code, String? name, String? nameEn, StockSector? sector, double? price,
    double? dividendYield, int? dividendPerShare, int? latestDividend,
    DividendFrequency? frequency, List<int>? paymentMonths, double? per, double? pbr,
    double? roe, double? eps, List<DividendHistory>? history, bool? isRecommended,
    List<InvestmentProfile>? suitableFor, String? riskLevel, int? marketCap, Color? sectorColor,
  }) {
    return StockModel(
      code: code ?? this.code, name: name ?? this.name, nameEn: nameEn ?? this.nameEn,
      sector: sector ?? this.sector, price: price ?? this.price,
      dividendYield: dividendYield ?? this.dividendYield,
      dividendPerShare: dividendPerShare ?? this.dividendPerShare,
      latestDividend: latestDividend ?? this.latestDividend,
      frequency: frequency ?? this.frequency,
      paymentMonths: paymentMonths ?? this.paymentMonths,
      per: per ?? this.per, pbr: pbr ?? this.pbr, roe: roe ?? this.roe,
      eps: eps ?? this.eps, history: history ?? this.history,
      isRecommended: isRecommended ?? this.isRecommended,
      suitableFor: suitableFor ?? this.suitableFor,
      riskLevel: riskLevel ?? this.riskLevel,
      marketCap: marketCap ?? this.marketCap,
      sectorColor: sectorColor ?? this.sectorColor,
    );
  }

  double monthlyDividend(int shares) {
    final perShare = dividendPerShare > 0 ? dividendPerShare : latestDividend;
    return (perShare * shares) / 12;
  }

  double dividendForMonth(int shares, int month) {
    final perShare = dividendPerShare > 0 ? dividendPerShare : latestDividend;
    if (perShare == 0 || !paymentMonths.contains(month)) return 0;
    return (perShare / paymentMonths.length) * shares;
  }

  int sharesNeededForMonthly(int monthlyGoal) {
    final perShareMonthly = monthlyDividend(1);
    if (perShareMonthly <= 0) return 0;
    return (monthlyGoal / perShareMonthly).ceil();
  }
}

class DividendHistory {
  final int year;
  final int amount;
  final double yieldPercent;
  final bool isPaid;
  final DateTime? exDate;

  const DividendHistory({
    required this.year,
    required this.amount,
    this.yieldPercent = 0,
    this.isPaid = true,
    this.exDate,
  });
}

class PortfolioItem {
  final StockModel stock;
  final int shares;
  final double avgPrice;

  const PortfolioItem({
    required this.stock,
    required this.shares,
    required this.avgPrice,
  });

  double get totalValue => stock.price * shares;
  double get totalCost => avgPrice * shares;
  double get gainLoss => totalValue - totalCost;
  double get gainLossPct =>
      totalCost == 0 ? 0 : ((totalValue - totalCost) / totalCost) * 100;

  double get monthlyDividend => stock.monthlyDividend(shares);
  double get annualDividend => monthlyDividend * 12;

  double getActualDividendForMonth(int month) {
    if (stock.paymentMonths.contains(month)) {
      final annualPerShare = stock.dividendPerShare > 0
          ? stock.dividendPerShare
          : stock.latestDividend;
      return (annualPerShare / stock.paymentMonths.length) * shares;
    }
    return 0.0;
  }
}

class UserGoal {
  final int monthlyTarget;
  final InvestmentProfile profile;
  final List<StockSector> preferredSectors;
  final int investmentBudget;

  const UserGoal({
    required this.monthlyTarget,
    required this.profile,
    required this.preferredSectors,
    required this.investmentBudget,
  });
}
