import '../models/stock_model.dart';

class StockMaster {
  final String code;
  final String name;
  final StockSector sector;
  final DividendFrequency frequency;
  final List<int> paymentMonths; // 👈 추가됨
  final double fallbackPrice;
  final double fallbackDividend;
  final double fallbackYield;
  final double fallbackPer;
  final int fallbackMarketCap;

  const StockMaster({
    required this.code, required this.name, required this.sector,
    required this.frequency, required this.paymentMonths, required this.fallbackPrice,
    required this.fallbackDividend, required this.fallbackYield,
    required this.fallbackPer, required this.fallbackMarketCap,
  });
}

class StockMasterDB {
  static const List<StockMaster> all = [
    StockMaster(
      code: '105560', name: 'KB금융', sector: StockSector.finance,
      frequency: DividendFrequency.quarterly, paymentMonths: [4, 5, 8, 11], // 분기배당 (통상 4월 결산 + 1,2,3분기)
      fallbackPrice: 86500, fallbackDividend: 3200, fallbackYield: 3.7, fallbackPer: 6.2, fallbackMarketCap: 33000000,
    ),
    StockMaster(
      code: '055550', name: '신한지주', sector: StockSector.finance,
      frequency: DividendFrequency.quarterly, paymentMonths: [4, 5, 8, 11],
      fallbackPrice: 51200, fallbackDividend: 2100, fallbackYield: 4.1, fallbackPer: 5.8, fallbackMarketCap: 26000000,
    ),
    StockMaster(
      code: '030200', name: 'KT', sector: StockSector.telecom,
      frequency: DividendFrequency.semiAnnual, paymentMonths: [4, 8],
      fallbackPrice: 41200, fallbackDividend: 2000, fallbackYield: 4.9, fallbackPer: 7.8, fallbackMarketCap: 10700000,
    ),
    StockMaster(
      code: '015760', name: '한국전력', sector: StockSector.energy,
      frequency: DividendFrequency.annual, paymentMonths: [4],
      fallbackPrice: 22300, fallbackDividend: 0, fallbackYield: 0, fallbackPer: 0, fallbackMarketCap: 14300000,
    ),
    StockMaster(
      code: '088980', name: '맥쿼리인프라', sector: StockSector.reit,
      frequency: DividendFrequency.semiAnnual, paymentMonths: [2, 8], // 2월, 8월 지급
      fallbackPrice: 12800, fallbackDividend: 770, fallbackYield: 6.0, fallbackPer: 13.2, fallbackMarketCap: 4600000,
    ),
    StockMaster(
      code: '432320', name: 'KODEX 한국부동산리츠인프라', sector: StockSector.reit,
      frequency: DividendFrequency.monthly, paymentMonths: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], // 월배당 ETF
      fallbackPrice: 5240, fallbackDividend: 320, fallbackYield: 6.1, fallbackPer: 0, fallbackMarketCap: 320000,
    ),
    StockMaster(
      code: '005380', name: '현대차', sector: StockSector.industrial,
      frequency: DividendFrequency.semiAnnual, paymentMonths: [4, 11],
      fallbackPrice: 218500, fallbackDividend: 11400, fallbackYield: 5.2, fallbackPer: 4.9, fallbackMarketCap: 45900000,
    ),
  ];

  static StockMaster? byCode(String code) {
    for (final s in all) {
      if (s.code == code) return s;
    }
    return null;
  }
}