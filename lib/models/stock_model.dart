import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// Sector enum (UI 표기용 라벨/이모지/색)
// ─────────────────────────────────────────────
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

// 투자 성향
enum InvestmentProfile {
  stable('안정형', '안정적인 수익을 중시하는 투자자'),
  balanced('균형형', '성장과 수익의 균형을 추구하는 투자자'),
  growth('성장형', '장기 자본 이득을 추구하는 투자자'),
  highYield('고배당형', '높은 배당수익률을 최우선으로 하는 투자자');

  const InvestmentProfile(this.label, this.description);
  final String label;
  final String description;
}

// 배당 주기
enum DividendFrequency {
  annual('연간 배당'),
  semiAnnual('반기 배당'),
  quarterly('분기 배당'),
  monthly('월 배당');

  const DividendFrequency(this.label);
  final String label;
}

// ─────────────────────────────────────────────
// StockModel — 단일 종목
//
// 필수 항목은 code/name/sector/price/frequency 만 남기고
// 나머지는 모두 기본값을 두어 API/마스터 둘 다에서 안전하게 생성 가능하게 함.
// ─────────────────────────────────────────────
class StockModel {
  final String code;
  final String name;
  final String nameEn;
  final StockSector sector;
  final double price;
  final double dividendYield;            // %
  final int dividendPerShare;            // 원 (주당 연간)
  final int latestDividend;              // 직전년도 배당 (서비스 호환용)
  final DividendFrequency frequency;
  final double per;
  final double pbr;
  final double roe;
  final double eps;
  final List<DividendHistory> history;
  final bool isRecommended;
  final List<InvestmentProfile> suitableFor;
  final String riskLevel;                // 낮음 / 중간 / 높음
  final int marketCap;                   // 시가총액 (백만원)
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

  // ─────────────────────────────────────────
  // copyWith — 부분 업데이트 (KIS/DART 응답 덮어쓰기)
  // ─────────────────────────────────────────
  StockModel copyWith({
    String? code,
    String? name,
    String? nameEn,
    StockSector? sector,
    double? price,
    double? dividendYield,
    int? dividendPerShare,
    int? latestDividend,
    DividendFrequency? frequency,
    double? per,
    double? pbr,
    double? roe,
    double? eps,
    List<DividendHistory>? history,
    bool? isRecommended,
    List<InvestmentProfile>? suitableFor,
    String? riskLevel,
    int? marketCap,
    Color? sectorColor,
  }) {
    return StockModel(
      code: code ?? this.code,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      sector: sector ?? this.sector,
      price: price ?? this.price,
      dividendYield: dividendYield ?? this.dividendYield,
      dividendPerShare: dividendPerShare ?? this.dividendPerShare,
      latestDividend: latestDividend ?? this.latestDividend,
      frequency: frequency ?? this.frequency,
      per: per ?? this.per,
      pbr: pbr ?? this.pbr,
      roe: roe ?? this.roe,
      eps: eps ?? this.eps,
      history: history ?? this.history,
      isRecommended: isRecommended ?? this.isRecommended,
      suitableFor: suitableFor ?? this.suitableFor,
      riskLevel: riskLevel ?? this.riskLevel,
      marketCap: marketCap ?? this.marketCap,
      sectorColor: sectorColor ?? this.sectorColor,
    );
  }

  // 월 환산 배당금 (보유 주식 수 기준)
  double monthlyDividend(int shares) {
    final perShare = dividendPerShare > 0 ? dividendPerShare : latestDividend;
    switch (frequency) {
      case DividendFrequency.monthly:
        return perShare * shares.toDouble();
      case DividendFrequency.quarterly:
        return (perShare * shares) / 3;
      case DividendFrequency.semiAnnual:
        return (perShare * shares) / 6;
      case DividendFrequency.annual:
        return (perShare * shares) / 12;
    }
  }

  int sharesNeededForMonthly(int monthlyGoal) {
    final perShareMonthly = monthlyDividend(1);
    if (perShareMonthly <= 0) return 0;
    return (monthlyGoal / perShareMonthly).ceil();
  }

  double investmentNeededForMonthly(int monthlyGoal) {
    return sharesNeededForMonthly(monthlyGoal) * price;
  }
}

// ─────────────────────────────────────────────
// DividendHistory — 배당 내역
// yieldPercent / exDate 모두 옵셔널 (서비스/모델 둘 다 호환)
// ─────────────────────────────────────────────
class DividendHistory {
  final int year;
  final int amount;             // 주당 배당금 (원)
  final double yieldPercent;    // 배당수익률 (%)
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

// ─────────────────────────────────────────────
// PortfolioItem — 보유 종목
// ─────────────────────────────────────────────
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
}

// ─────────────────────────────────────────────
// UserGoal — 사용자 목표
// ─────────────────────────────────────────────
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