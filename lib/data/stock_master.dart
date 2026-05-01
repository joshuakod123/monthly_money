import '../models/stock_model.dart';

/// ═══════════════════════════════════════════════════════════
///  종목 마스터 데이터 (하드코딩 폴백)
///
///  KIS API 가 실패해도 이름·섹터·기본 정보를 항상 표시할 수 있게
///  20개 핵심 배당주의 메타데이터를 내장.
///
///  API 가 성공하면 가격·PER·시총 등 동적 데이터로 덮어씀.
/// ═══════════════════════════════════════════════════════════

class StockMaster {
  final String code;
  final String name;
  final StockSector sector;
  final DividendFrequency frequency;
  final double fallbackPrice;        // KIS 실패 시
  final double fallbackDividend;     // 작년 주당 배당금
  final double fallbackYield;        // 배당수익률 %
  final double fallbackPer;
  final int fallbackMarketCap;       // 백만원

  const StockMaster({
    required this.code,
    required this.name,
    required this.sector,
    required this.frequency,
    required this.fallbackPrice,
    required this.fallbackDividend,
    required this.fallbackYield,
    required this.fallbackPer,
    required this.fallbackMarketCap,
  });
}

class StockMasterDB {
  static const List<StockMaster> all = [
    // ── 금융 ─────────────────────────
    StockMaster(
      code: '105560',
      name: 'KB금융',
      sector: StockSector.finance,
      frequency: DividendFrequency.quarterly,
      fallbackPrice: 86500,
      fallbackDividend: 3200,
      fallbackYield: 3.7,
      fallbackPer: 6.2,
      fallbackMarketCap: 33000000,
    ),
    StockMaster(
      code: '055550',
      name: '신한지주',
      sector: StockSector.finance,
      frequency: DividendFrequency.quarterly,
      fallbackPrice: 51200,
      fallbackDividend: 2100,
      fallbackYield: 4.1,
      fallbackPer: 5.8,
      fallbackMarketCap: 26000000,
    ),
    StockMaster(
      code: '086790',
      name: '하나금융지주',
      sector: StockSector.finance,
      frequency: DividendFrequency.quarterly,
      fallbackPrice: 64500,
      fallbackDividend: 3400,
      fallbackYield: 5.3,
      fallbackPer: 5.4,
      fallbackMarketCap: 18800000,
    ),
    StockMaster(
      code: '316140',
      name: '우리금융지주',
      sector: StockSector.finance,
      frequency: DividendFrequency.quarterly,
      fallbackPrice: 16800,
      fallbackDividend: 1000,
      fallbackYield: 5.9,
      fallbackPer: 4.9,
      fallbackMarketCap: 12500000,
    ),
    StockMaster(
      code: '138930',
      name: 'BNK금융지주',
      sector: StockSector.finance,
      frequency: DividendFrequency.quarterly,
      fallbackPrice: 11200,
      fallbackDividend: 720,
      fallbackYield: 6.4,
      fallbackPer: 4.1,
      fallbackMarketCap: 3600000,
    ),

    // ── 통신 ─────────────────────────
    StockMaster(
      code: '030200',
      name: 'KT',
      sector: StockSector.telecom,
      frequency: DividendFrequency.semiAnnual,
      fallbackPrice: 41200,
      fallbackDividend: 2000,
      fallbackYield: 4.9,
      fallbackPer: 7.8,
      fallbackMarketCap: 10700000,
    ),
    StockMaster(
      code: '017670',
      name: 'SK텔레콤',
      sector: StockSector.telecom,
      frequency: DividendFrequency.quarterly,
      fallbackPrice: 56800,
      fallbackDividend: 3540,
      fallbackYield: 6.2,
      fallbackPer: 10.1,
      fallbackMarketCap: 12300000,
    ),
    StockMaster(
      code: '032640',
      name: 'LG유플러스',
      sector: StockSector.telecom,
      frequency: DividendFrequency.semiAnnual,
      fallbackPrice: 9800,
      fallbackDividend: 650,
      fallbackYield: 6.6,
      fallbackPer: 6.5,
      fallbackMarketCap: 4300000,
    ),

    // ── 에너지 / 유틸리티 ──────────────
    StockMaster(
      code: '015760',
      name: '한국전력',
      sector: StockSector.energy,
      frequency: DividendFrequency.annual,
      fallbackPrice: 22300,
      fallbackDividend: 0,
      fallbackYield: 0,
      fallbackPer: 0,
      fallbackMarketCap: 14300000,
    ),
    StockMaster(
      code: '036460',
      name: '한국가스공사',
      sector: StockSector.energy,
      frequency: DividendFrequency.annual,
      fallbackPrice: 35400,
      fallbackDividend: 1200,
      fallbackYield: 3.4,
      fallbackPer: 5.8,
      fallbackMarketCap: 3270000,
    ),

    // ── 리츠 / 인프라 ─────────────────
    StockMaster(
      code: '088980',
      name: '맥쿼리인프라',
      sector: StockSector.reit,
      frequency: DividendFrequency.semiAnnual,
      fallbackPrice: 12800,
      fallbackDividend: 770,
      fallbackYield: 6.0,
      fallbackPer: 13.2,
      fallbackMarketCap: 4600000,
    ),
    StockMaster(
      code: '395400',
      name: 'SK리츠',
      sector: StockSector.reit,
      frequency: DividendFrequency.quarterly,
      fallbackPrice: 4865,
      fallbackDividend: 320,
      fallbackYield: 6.6,
      fallbackPer: 11.4,
      fallbackMarketCap: 950000,
    ),
    StockMaster(
      code: '432320',
      name: 'KODEX 한국부동산리츠인프라',
      sector: StockSector.reit,
      frequency: DividendFrequency.monthly,
      fallbackPrice: 5240,
      fallbackDividend: 320,
      fallbackYield: 6.1,
      fallbackPer: 0,
      fallbackMarketCap: 320000,
    ),
    StockMaster(
      code: '357870',
      name: '디앤디플랫폼리츠',
      sector: StockSector.reit,
      frequency: DividendFrequency.semiAnnual,
      fallbackPrice: 3620,
      fallbackDividend: 240,
      fallbackYield: 6.6,
      fallbackPer: 9.4,
      fallbackMarketCap: 290000,
    ),

    // ── 소비재 ─────────────────────────
    StockMaster(
      code: '000080',
      name: '하이트진로',
      sector: StockSector.consumer,
      frequency: DividendFrequency.annual,
      fallbackPrice: 19200,
      fallbackDividend: 800,
      fallbackYield: 4.2,
      fallbackPer: 11.2,
      fallbackMarketCap: 1340000,
    ),
    StockMaster(
      code: '271560',
      name: '오리온',
      sector: StockSector.consumer,
      frequency: DividendFrequency.annual,
      fallbackPrice: 95000,
      fallbackDividend: 1100,
      fallbackYield: 1.2,
      fallbackPer: 9.8,
      fallbackMarketCap: 3760000,
    ),

    // ── 산업재 ─────────────────────────
    StockMaster(
      code: '005490',
      name: 'POSCO홀딩스',
      sector: StockSector.industrial,
      frequency: DividendFrequency.semiAnnual,
      fallbackPrice: 285000,
      fallbackDividend: 12000,
      fallbackYield: 4.2,
      fallbackPer: 7.4,
      fallbackMarketCap: 24100000,
    ),
    StockMaster(
      code: '000270',
      name: '기아',
      sector: StockSector.industrial,
      frequency: DividendFrequency.annual,
      fallbackPrice: 105800,
      fallbackDividend: 5000,
      fallbackYield: 4.7,
      fallbackPer: 4.6,
      fallbackMarketCap: 41700000,
    ),
    StockMaster(
      code: '005380',
      name: '현대차',
      sector: StockSector.industrial,
      frequency: DividendFrequency.semiAnnual,
      fallbackPrice: 218500,
      fallbackDividend: 11400,
      fallbackYield: 5.2,
      fallbackPer: 4.9,
      fallbackMarketCap: 45900000,
    ),
    StockMaster(
      code: '034730',
      name: 'SK',
      sector: StockSector.industrial,
      frequency: DividendFrequency.semiAnnual,
      fallbackPrice: 153600,
      fallbackDividend: 8000,
      fallbackYield: 5.2,
      fallbackPer: 6.8,
      fallbackMarketCap: 11200000,
    ),

    // ── 카지노 (윤리 필터링용) ──────────
    StockMaster(
      code: '035250',
      name: '강원랜드',
      sector: StockSector.consumer,
      frequency: DividendFrequency.annual,
      fallbackPrice: 17200,
      fallbackDividend: 845,
      fallbackYield: 4.9,
      fallbackPer: 13.4,
      fallbackMarketCap: 3680000,
    ),
  ];

  static StockMaster? byCode(String code) {
    for (final s in all) {
      if (s.code == code) return s;
    }
    return null;
  }
}