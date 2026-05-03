import '../models/stock_model.dart';

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
    // ───────────────────────────────────────────
    // 🏦 금융 (분기배당)
    // ───────────────────────────────────────────
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

    // ───────────────────────────────────────────
    // 📡 통신 (반기배당, 다른 달)
    // ───────────────────────────────────────────
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

    // ───────────────────────────────────────────
    // ⚡ 에너지
    // ───────────────────────────────────────────
    StockMaster(
      code: '015760', name: '한국전력', sector: StockSector.energy,
      frequency: DividendFrequency.annual, paymentMonths: [4],
      fallbackPrice: 22300, fallbackDividend: 0, fallbackYield: 0,
      fallbackPer: 0, fallbackMarketCap: 14300000,
    ),
    StockMaster(
      code: '034020', name: '두산에너빌리티', sector: StockSector.energy,
      frequency: DividendFrequency.annual, paymentMonths: [4],
      fallbackPrice: 18900, fallbackDividend: 600, fallbackYield: 3.2,
      fallbackPer: 18, fallbackMarketCap: 12000000,
    ),

    // ───────────────────────────────────────────
    // 🏢 리츠 (다양한 지급월)
    // ───────────────────────────────────────────
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

    // ───────────────────────────────────────────
    // 💎 월배당 ETF (이게 있어야 매달 커버 가능)
    // ───────────────────────────────────────────
    StockMaster(
      code: '432320', name: 'KODEX 한국부동산리츠인프라', sector: StockSector.reit,
      frequency: DividendFrequency.monthly,
      paymentMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
      fallbackPrice: 5240, fallbackDividend: 320, fallbackYield: 6.1,
      fallbackPer: 0, fallbackMarketCap: 320000,
    ),
    StockMaster(
      code: '472160', name: 'TIGER 미국배당다우존스', sector: StockSector.consumer,
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
      code: '481460', name: 'KODEX 미국배당커버드콜', sector: StockSector.consumer,
      frequency: DividendFrequency.monthly,
      paymentMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
      fallbackPrice: 10380, fallbackDividend: 1100, fallbackYield: 10.5,
      fallbackPer: 0, fallbackMarketCap: 950000,
    ),
    StockMaster(
      code: '441680', name: 'TIGER 미국S&P500배당귀족', sector: StockSector.consumer,
      frequency: DividendFrequency.monthly,
      paymentMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
      fallbackPrice: 12450, fallbackDividend: 360, fallbackYield: 2.9,
      fallbackPer: 0, fallbackMarketCap: 420000,
    ),
    StockMaster(
      code: '466920', name: 'SOL 미국배당다우존스', sector: StockSector.consumer,
      frequency: DividendFrequency.monthly,
      paymentMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
      fallbackPrice: 11680, fallbackDividend: 470, fallbackYield: 4.0,
      fallbackPer: 0, fallbackMarketCap: 680000,
    ),

    // ───────────────────────────────────────────
    // 🚗 산업재
    // ───────────────────────────────────────────
    StockMaster(
      code: '005380', name: '현대차', sector: StockSector.industrial,
      frequency: DividendFrequency.semiAnnual, paymentMonths: [4, 11],
      fallbackPrice: 218500, fallbackDividend: 11400, fallbackYield: 5.2,
      fallbackPer: 4.9, fallbackMarketCap: 45900000,
    ),
    StockMaster(
      code: '000270', name: '기아', sector: StockSector.industrial,
      frequency: DividendFrequency.semiAnnual, paymentMonths: [4, 9],
      fallbackPrice: 98700, fallbackDividend: 5600, fallbackYield: 5.7,
      fallbackPer: 4.4, fallbackMarketCap: 38400000,
    ),

    // ───────────────────────────────────────────
    // 🛒 소비재
    // ───────────────────────────────────────────
    StockMaster(
      code: '033780', name: 'KT&G', sector: StockSector.consumer,
      frequency: DividendFrequency.annual, paymentMonths: [4],
      fallbackPrice: 102500, fallbackDividend: 5200, fallbackYield: 5.1,
      fallbackPer: 11.2, fallbackMarketCap: 13800000,
    ),
  ];

  static StockMaster? byCode(String code) {
    for (final s in all) {
      if (s.code == code) return s;
    }
    return null;
  }
}