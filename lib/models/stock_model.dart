import 'package:flutter/material.dart';

// 섹터 enum
enum StockSector {
  all('전체', '🌿'),
  finance('금융', '🏦'),
  telecom('통신', '📡'),
  energy('에너지', '⚡'),
  reit('리츠', '🏢'),
  consumer('소비재', '🛒'),
  industrial('산업재', '🔧'),
  healthcare('헬스케어', '💊');

  const StockSector(this.label, this.emoji);
  final String label;
  final String emoji;
}

// 투자 성향 enum
enum InvestmentProfile {
  stable('안정형', '안정적인 수익을 중시하는 투자자'),
  balanced('균형형', '성장과 수익의 균형을 추구하는 투자자'),
  growth('성장형', '장기 자본 이득을 추구하는 투자자'),
  highYield('고배당형', '높은 배당수익률을 최우선으로 하는 투자자');

  const InvestmentProfile(this.label, this.description);
  final String label;
  final String description;
}

// 배당 주기 enum
enum DividendFrequency {
  annual('연간 배당'),
  semiAnnual('반기 배당'),
  quarterly('분기 배당'),
  monthly('월 배당');

  const DividendFrequency(this.label);
  final String label;
}

// 주식 모델
class StockModel {
  final String code;
  final String name;
  final String nameEn;
  final StockSector sector;
  final double price;
  final double dividendYield;          // 배당수익률 (%)
  final int dividendPerShare;          // 주당 배당금 (원)
  final DividendFrequency frequency;
  final double per;
  final double pbr;
  final double roe;
  final List<DividendHistory> history; // 최근 5년 배당 히스토리
  final bool isRecommended;
  final List<InvestmentProfile> suitableFor;
  final String riskLevel;              // 낮음 / 중간 / 높음
  final double marketCap;             // 시가총액 (억원)
  final Color sectorColor;

  const StockModel({
    required this.code,
    required this.name,
    required this.nameEn,
    required this.sector,
    required this.price,
    required this.dividendYield,
    required this.dividendPerShare,
    required this.frequency,
    required this.per,
    required this.pbr,
    required this.roe,
    required this.history,
    this.isRecommended = false,
    required this.suitableFor,
    required this.riskLevel,
    required this.marketCap,
    required this.sectorColor,
  });

  // 월 배당금 환산 (주식 수 기준)
  double monthlyDividend(int shares) {
    switch (frequency) {
      case DividendFrequency.monthly:
        return dividendPerShare * shares.toDouble();
      case DividendFrequency.quarterly:
        return (dividendPerShare * shares) / 3;
      case DividendFrequency.semiAnnual:
        return (dividendPerShare * shares) / 6;
      case DividendFrequency.annual:
        return (dividendPerShare * shares) / 12;
    }
  }

  // 목표 월 배당금 달성을 위한 필요 주식 수
  int sharesNeededForMonthly(int monthlyGoal) {
    double monthlyPerShare = monthlyDividend(1);
    if (monthlyPerShare <= 0) return 0;
    return (monthlyGoal / monthlyPerShare).ceil();
  }

  // 목표 달성을 위한 총 투자금
  double investmentNeeded(int monthlyGoal) {
    return sharesNeededForMonthly(monthlyGoal) * price;
  }
}

// 배당 히스토리
class DividendHistory {
  final int year;
  final int amount;       // 주당 배당금 (원)
  final double yieldPercent;    // 배당수익률 (%)
  final bool isPaid;

  const DividendHistory({
    required this.year,
    required this.amount,
    required this.yieldPercent,
    this.isPaid = true,
  });
}

// 사용자 포트폴리오 보유 종목
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
  double get gainLossPct => ((totalValue - totalCost) / totalCost) * 100;
  double get monthlyDividend => stock.monthlyDividend(shares);
  double get annualDividend => monthlyDividend * 12;
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

  // 초기 상태를 위한 factory 메서드
  factory UserGoal.initial() => const UserGoal(
    monthlyTarget: 2000000,
    profile: InvestmentProfile.balanced,
    preferredSectors: [StockSector.all],
    investmentBudget: 50000000,
  );

  UserGoal copyWith({
    int? monthlyTarget,
    InvestmentProfile? profile,
    List<StockSector>? preferredSectors,
    int? investmentBudget,
  }) {
    return UserGoal(
      monthlyTarget: monthlyTarget ?? this.monthlyTarget,
      profile: profile ?? this.profile,
      preferredSectors: preferredSectors ?? this.preferredSectors,
      investmentBudget: investmentBudget ?? this.investmentBudget,
    );
  }
}
