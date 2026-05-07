import '../models/stock_model.dart';

/// ═══════════════════════════════════════════════════════════
///  StockMaster — Supabase 폴백용 마스터 데이터
///   GICS 11 섹터로 전면 재분류
/// ═══════════════════════════════════════════════════════════
class StockMaster {
  final String code;
  final String name;
  final StockSector sector;
  final DividendFrequency frequency;
  final List<int> paymentMonths;
  final double fallbackPrice;
  final double fallbackDividend;
  final double fallbackYield;
  final double fallbackPer;
  final int fallbackMarketCap;

  const StockMaster({
    required this.code,
    required this.name,
    required this.sector,
    required this.frequency,
    required this.paymentMonths,
    required this.fallbackPrice,
    required this.fallbackDividend,
    required this.fallbackYield,
    required this.fallbackPer,
    required this.fallbackMarketCap,
  });
}

class StockMasterDB {
  static const List<StockMaster> all = [
    // ─── Financials (금융) ───────────────────────────
    StockMaster(
      code: '105560', name: 'KB금융', sector: StockSector.finance,
      frequency: DividendFrequency.quarterly, paymentMonths: [4, 5, 8, 11],
      fallbackPrice: 86500, fallbackDividend: 3200, fallbackYield: 3.7,
      fallbackPer: 6.2, fallbackMarketCap: 33000000,
    ),
    StockMaster(
      code: '055550', name: '신한지주', sector: StockSector.finance,
      frequency: DividendFrequency.quarterly, paymentMonths: [4, 5, 8, 11],
      fallbackPrice: 51200, fallbackDividend: 2100, fallbackYield: 4.1,
      fallbackPer: 5.8, fallbackMarketCap: 26000000,
    ),
    StockMaster(
      code: '086790', name: '하나금융지주', sector: StockSector.finance,
      frequency: DividendFrequency.quarterly, paymentMonths: [3, 6, 9, 12],
      fallbackPrice: 65400, fallbackDividend: 3400, fallbackYield: 5.2,
      fallbackPer: 5.5, fallbackMarketCap: 19500000,
    ),
    StockMaster(
      code: '316140', name: '우리금융지주', sector: StockSector.finance,
      frequency: DividendFrequency.quarterly, paymentMonths: [3, 6, 9, 12],
      fallbackPrice: 16800, fallbackDividend: 1000, fallbackYield: 6.0,
      fallbackPer: 4.2, fallbackMarketCap: 12500000,
    ),
    StockMaster(
      code: '032830', name: '삼성생명', sector: StockSector.finance,
      frequency: DividendFrequency.annual, paymentMonths: [4],
      fallbackPrice: 95300, fallbackDividend: 3700, fallbackYield: 3.9,
      fallbackPer: 8.1, fallbackMarketCap: 17000000,
    ),

    // ─── Communication Services (커뮤니케이션) ───────
    StockMaster(
      code: '030200', name: 'KT', sector: StockSector.telecom,
      frequency: DividendFrequency.semiAnnual, paymentMonths: [4, 9],
      fallbackPrice: 41200, fallbackDividend: 2000, fallbackYield: 4.9,
      fallbackPer: 7.8, fallbackMarketCap: 10700000,
    ),
    StockMaster(
      code: '017670', name: 'SK텔레콤', sector: StockSector.telecom,
      frequency: DividendFrequency.quarterly, paymentMonths: [3, 6, 9, 12],
      fallbackPrice: 56800, fallbackDividend: 3540, fallbackYield: 6.2,
      fallbackPer: 9.5, fallbackMarketCap: 12400000,
    ),
    StockMaster(
      code: '032640', name: 'LG유플러스', sector: StockSector.telecom,
      frequency: DividendFrequency.semiAnnual, paymentMonths: [4, 9],
      fallbackPrice: 9620, fallbackDividend: 650, fallbackYield: 6.7,
      fallbackPer: 5.2, fallbackMarketCap: 4200000,
    ),

    // ─── Energy (에너지) ───────────────────────────
    StockMaster(
      code: '015760', name: '한국전력', sector: StockSector.utilities,
      frequency: DividendFrequency.annual, paymentMonths: [4],
      fallbackPrice: 22300, fallbackDividend: 0, fallbackYield: 0,
      fallbackPer: 0, fallbackMarketCap: 14300000,
    ),
    StockMaster(
      code: '034020', name: '두산에너빌리티', sector: StockSector.industrial,
      frequency: DividendFrequency.annual, paymentMonths: [4],
      fallbackPrice: 18900, fallbackDividend: 600, fallbackYield: 3.2,
      fallbackPer: 18, fallbackMarketCap: 12000000,
    ),
    StockMaster(
      code: '096770', name: 'SK이노베이션', sector: StockSector.energy,
      frequency: DividendFrequency.annual, paymentMonths: [4],
      fallbackPrice: 105500, fallbackDividend: 2000, fallbackYield: 1.9,
      fallbackPer: 11.0, fallbackMarketCap: 9500000,
    ),
    StockMaster(
      code: '267250', name: 'HD현대', sector: StockSector.energy,
      frequency: DividendFrequency.annual, paymentMonths: [4],
      fallbackPrice: 76300, fallbackDividend: 3700, fallbackYield: 4.8,
      fallbackPer: 6.5, fallbackMarketCap: 6300000,
    ),

    // ─── Real Estate (REIT·부동산) ─────────────────
    StockMaster(
      code: '088980', name: '맥쿼리인프라', sector: StockSector.reit,
      frequency: DividendFrequency.semiAnnual, paymentMonths: [2, 8],
      fallbackPrice: 12800, fallbackDividend: 770, fallbackYield: 6.0,
      fallbackPer: 13.2, fallbackMarketCap: 4600000,
    ),
    StockMaster(
      code: '330590', name: '롯데리츠', sector: StockSector.reit,
      frequency: DividendFrequency.semiAnnual, paymentMonths: [1, 7],
      fallbackPrice: 3450, fallbackDividend: 280, fallbackYield: 8.1,
      fallbackPer: 0, fallbackMarketCap: 750000,
    ),
    StockMaster(
      code: '293940', name: '신한알파리츠', sector: StockSector.reit,
      frequency: DividendFrequency.semiAnnual, paymentMonths: [3, 9],
      fallbackPrice: 6120, fallbackDividend: 380, fallbackYield: 6.2,
      fallbackPer: 0, fallbackMarketCap: 480000,
    ),
    StockMaster(
      code: '357250', name: '미래에셋맵스리츠', sector: StockSector.reit,
      frequency: DividendFrequency.semiAnnual, paymentMonths: [5, 11],
      fallbackPrice: 4380, fallbackDividend: 320, fallbackYield: 7.3,
      fallbackPer: 0, fallbackMarketCap: 290000,
    ),

    // ─── 월배당 ETF (대부분 REIT/배당주 묶음) ─────
    StockMaster(
      code: '432320', name: 'KODEX 한국부동산리츠인프라', sector: StockSector.reit,
      frequency: DividendFrequency.monthly,
      paymentMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
      fallbackPrice: 5240, fallbackDividend: 320, fallbackYield: 6.1,
      fallbackPer: 0, fallbackMarketCap: 320000,
    ),
    StockMaster(
      code: '472160', name: 'TIGER 미국배당다우존스', sector: StockSector.consumerStpl,
      frequency: DividendFrequency.monthly,
      paymentMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
      fallbackPrice: 11250, fallbackDividend: 480, fallbackYield: 4.3,
      fallbackPer: 0, fallbackMarketCap: 1850000,
    ),
    StockMaster(
      code: '458730', name: 'TIGER 리츠부동산인프라', sector: StockSector.reit,
      frequency: DividendFrequency.monthly,
      paymentMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
      fallbackPrice: 4980, fallbackDividend: 320, fallbackYield: 6.4,
      fallbackPer: 0, fallbackMarketCap: 280000,
    ),
    StockMaster(
      code: '481460', name: 'KODEX 미국배당커버드콜', sector: StockSector.consumerStpl,
      frequency: DividendFrequency.monthly,
      paymentMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
      fallbackPrice: 10380, fallbackDividend: 1100, fallbackYield: 10.5,
      fallbackPer: 0, fallbackMarketCap: 950000,
    ),
    StockMaster(
      code: '441680', name: 'TIGER 미국S&P500배당귀족', sector: StockSector.consumerStpl,
      frequency: DividendFrequency.monthly,
      paymentMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
      fallbackPrice: 12450, fallbackDividend: 360, fallbackYield: 2.9,
      fallbackPer: 0, fallbackMarketCap: 420000,
    ),
    StockMaster(
      code: '466920', name: 'SOL 미국배당다우존스', sector: StockSector.consumerStpl,
      frequency: DividendFrequency.monthly,
      paymentMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
      fallbackPrice: 11680, fallbackDividend: 470, fallbackYield: 4.0,
      fallbackPer: 0, fallbackMarketCap: 680000,
    ),

    // ─── Consumer Discretionary (경기소비재: 자동차·여행·미디어) ───
    StockMaster(
      code: '005380', name: '현대차', sector: StockSector.consumerDisc,
      frequency: DividendFrequency.semiAnnual, paymentMonths: [4, 11],
      fallbackPrice: 218500, fallbackDividend: 11400, fallbackYield: 5.2,
      fallbackPer: 4.9, fallbackMarketCap: 45900000,
    ),
    StockMaster(
      code: '000270', name: '기아', sector: StockSector.consumerDisc,
      frequency: DividendFrequency.semiAnnual, paymentMonths: [4, 9],
      fallbackPrice: 98700, fallbackDividend: 5600, fallbackYield: 5.7,
      fallbackPer: 4.4, fallbackMarketCap: 38400000,
    ),
    StockMaster(
      code: '012330', name: '현대모비스', sector: StockSector.consumerDisc,
      frequency: DividendFrequency.annual, paymentMonths: [4],
      fallbackPrice: 252000, fallbackDividend: 4500, fallbackYield: 1.8,
      fallbackPer: 6.2, fallbackMarketCap: 23800000,
    ),

    // ─── Consumer Staples (필수소비재: 식품·생필품·담배) ────────
    StockMaster(
      code: '033780', name: 'KT&G', sector: StockSector.consumerStpl,
      frequency: DividendFrequency.annual, paymentMonths: [4],
      fallbackPrice: 102500, fallbackDividend: 5200, fallbackYield: 5.1,
      fallbackPer: 11.2, fallbackMarketCap: 13800000,
    ),
    StockMaster(
      code: '097950', name: 'CJ제일제당', sector: StockSector.consumerStpl,
      frequency: DividendFrequency.annual, paymentMonths: [4],
      fallbackPrice: 320000, fallbackDividend: 5000, fallbackYield: 1.6,
      fallbackPer: 9.8, fallbackMarketCap: 4800000,
    ),

    // ─── Industrials (산업재: 기계·건설·운송) ────────────
    StockMaster(
      code: '006360', name: 'GS건설', sector: StockSector.industrial,
      frequency: DividendFrequency.annual, paymentMonths: [4],
      fallbackPrice: 21800, fallbackDividend: 800, fallbackYield: 3.7,
      fallbackPer: 4.5, fallbackMarketCap: 1850000,
    ),
    StockMaster(
      code: '000720', name: '현대건설', sector: StockSector.industrial,
      frequency: DividendFrequency.annual, paymentMonths: [4],
      fallbackPrice: 35200, fallbackDividend: 600, fallbackYield: 1.7,
      fallbackPer: 6.0, fallbackMarketCap: 3950000,
    ),

    // ─── Materials (소재: 화학·철강) ─────────────
    StockMaster(
      code: '005490', name: 'POSCO홀딩스', sector: StockSector.materials,
      frequency: DividendFrequency.quarterly, paymentMonths: [3, 6, 9, 12],
      fallbackPrice: 295000, fallbackDividend: 10000, fallbackYield: 3.4,
      fallbackPer: 14.0, fallbackMarketCap: 24800000,
    ),
    StockMaster(
      code: '011170', name: '롯데케미칼', sector: StockSector.materials,
      frequency: DividendFrequency.annual, paymentMonths: [4],
      fallbackPrice: 88600, fallbackDividend: 2000, fallbackYield: 2.3,
      fallbackPer: 0, fallbackMarketCap: 3800000,
    ),

    // ─── Health Care (헬스케어) ─────────────────
    StockMaster(
      code: '000100', name: '유한양행', sector: StockSector.healthcare,
      frequency: DividendFrequency.annual, paymentMonths: [4],
      fallbackPrice: 132000, fallbackDividend: 400, fallbackYield: 0.3,
      fallbackPer: 28.0, fallbackMarketCap: 9100000,
    ),
    StockMaster(
      code: '128940', name: '한미약품', sector: StockSector.healthcare,
      frequency: DividendFrequency.annual, paymentMonths: [4],
      fallbackPrice: 295500, fallbackDividend: 500, fallbackYield: 0.2,
      fallbackPer: 0, fallbackMarketCap: 3600000,
    ),

    // ─── Information Technology (IT) ─────────────
    StockMaster(
      code: '005930', name: '삼성전자', sector: StockSector.tech,
      frequency: DividendFrequency.quarterly, paymentMonths: [4, 5, 8, 11],
      fallbackPrice: 73500, fallbackDividend: 1444, fallbackYield: 2.0,
      fallbackPer: 13.5, fallbackMarketCap: 438000000,
    ),
    StockMaster(
      code: '000660', name: 'SK하이닉스', sector: StockSector.tech,
      frequency: DividendFrequency.quarterly, paymentMonths: [4, 5, 8, 11],
      fallbackPrice: 198000, fallbackDividend: 1500, fallbackYield: 0.8,
      fallbackPer: 12.5, fallbackMarketCap: 144000000,
    ),

    // ─── Utilities (유틸리티) ────────────────
    StockMaster(
      code: '036460', name: '한국가스공사', sector: StockSector.utilities,
      frequency: DividendFrequency.annual, paymentMonths: [4],
      fallbackPrice: 36500, fallbackDividend: 1100, fallbackYield: 3.0,
      fallbackPer: 0, fallbackMarketCap: 3300000,
    ),
  ];

  static StockMaster? byCode(String code) {
    for (final s in all) {
      if (s.code == code) return s;
    }
    return null;
  }
}
