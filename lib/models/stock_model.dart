import 'package:flutter/material.dart';

enum StockSector {
  all('전체', '🌿', Color(0xFF8E8E93)),
  finance('금융', '🏦', Color(0xFF4A6FA5)),
  telecom('통신', '📡', Color(0xFF6B5B95)),
  energy('에너지', '⚡', Color(0xFFE8A33D)),
  reit('리츠', '🏢', Color(0xFF7BA098)),
  consumer('소비재', '🛒', Color(0xFFC97B63)),
  industrial('산업재', '🔧', Color(0xFF5A6E7C)),
  healthcare('헬스케어', '💊', Color(0xFFB85C7A));

  const StockSector(this.label, this.emoji, this.defaultColor);
  final String label;
  final String emoji;
  final Color defaultColor;
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
  final List<int> paymentMonths; // 👈 캘린더를 위한 배당 지급월 추가
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
    required this.paymentMonths, // 필수
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

  // 기존: 목표 달성률 확인을 위한 '월평균' (Average)
  double monthlyDividend(int shares) {
    final perShare = dividendPerShare > 0 ? dividendPerShare : latestDividend;
    return (perShare * shares) / 12;
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

  const DividendHistory({required this.year, required this.amount, this.yieldPercent = 0, this.isPaid = true, this.exDate});
}

class PortfolioItem {
  final StockModel stock;
  final int shares;
  final double avgPrice;

  const PortfolioItem({required this.stock, required this.shares, required this.avgPrice});

  double get totalValue => stock.price * shares;
  double get totalCost => avgPrice * shares;
  double get gainLoss => totalValue - totalCost;
  double get gainLossPct => totalCost == 0 ? 0 : ((totalValue - totalCost) / totalCost) * 100;

  // 평균 기준
  double get monthlyDividend => stock.monthlyDividend(shares);
  double get annualDividend => monthlyDividend * 12;

  // 👈 캘린더용 실제 지급월 기준 계산
  double getActualDividendForMonth(int month) {
    if (stock.paymentMonths.contains(month)) {
      final annualPerShare = stock.dividendPerShare > 0 ? stock.dividendPerShare : stock.latestDividend;
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

  const UserGoal({required this.monthlyTarget, required this.profile, required this.preferredSectors, required this.investmentBudget});
}