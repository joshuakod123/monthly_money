import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/stock_model.dart';
import '../data/stock_master.dart';
import 'api/kis_client.dart';
import 'api/opendart_client.dart';
import 'api/api_config.dart';

/// ═══════════════════════════════════════════════════════════
///  StockDataService v5
///
///  설계 철학:
///   1. **이름·섹터는 절대로 비지 않는다** — 마스터 DB 폴백
///   2. API 성공 시에만 동적 데이터(가격·PER) 덮어씀
///   3. 부분 실패 허용 — 한 종목 실패해도 다른 종목 정상 표시
///   4. **정적 메서드 (`allStocks`, `getBySector`, `recommendPortfolio`)
///      를 제공해 동기 UI 코드와도 호환**
///        → providers/UI 가 비동기로 다시 짜이기 전까지의 어댑터
/// ═══════════════════════════════════════════════════════════
class StockDataService {
  StockDataService._();
  static final StockDataService instance = StockDataService._();

  final KisClient _kis = KisClient();
  final OpenDartClient _dart = OpenDartClient();

  Box<dynamic>? _cache;

  Future<void> init() async {
    await Hive.initFlutter();
    _cache = await Hive.openBox('stock_cache');
  }

  // ════════════════════════════════════════════════════════════
  // 🟢 인스턴스 메서드 (실 API 호출)
  // ════════════════════════════════════════════════════════════

  /// 단일 종목 조회 — 마스터 DB 기반 + API 동적 데이터 덮어쓰기
  Future<StockModel?> fetchStock(String code) async {
    final master = StockMasterDB.byCode(code);
    if (master == null) return null;

    // 캐시 확인
    final cached = _cache?.get('stock_$code');
    if (cached is Map) {
      final ts = cached['ts'] as int?;
      if (ts != null) {
        final age = DateTime.now().millisecondsSinceEpoch - ts;
        if (age < ApiConfig.priceCacheDuration.inMilliseconds) {
          return _modelFromCache(master, Map<String, dynamic>.from(cached));
        }
      }
    }

    // 1) 폴백 데이터로 기본 모델 생성
    var model = _modelFromMaster(master);

    // 2) KIS 가격 시도
    if (ApiConfig.isConfigured) {
      try {
        final priceData = await _kis.getCurrentPrice(code);
        if (priceData != null && priceData.currentPrice > 0) {
          model = model.copyWith(
            price: priceData.currentPrice.toDouble(),
            per: priceData.per > 0 ? priceData.per : model.per,
            pbr: priceData.pbr > 0 ? priceData.pbr : model.pbr,
            marketCap: priceData.marketCap ?? model.marketCap,
          );
        }
      } catch (_) {
        debugPrint('KIS 실패 (폴백 사용): $code');
      }

      // 3) OpenDART 배당 이력
      try {
        final dividendData = await _dart.getDividendHistory(
          stockCode: code,
          years: ApiConfig.dividendHistoryYears,
        );
        if (dividendData.isNotEmpty) {
          final history = dividendData
              .where((d) =>
          d.cashDividendPerShare != null &&
              d.cashDividendPerShare! > 0)
              .map((d) => DividendHistory(
            year: d.year,
            amount: d.cashDividendPerShare!,
            yieldPercent: d.cashDividendYield ?? 0,
            exDate: DateTime(d.year, 12, 28),
          ))
              .toList();
          if (history.isNotEmpty) {
            final latest = history.last;
            model = model.copyWith(
              history: history,
              latestDividend: latest.amount,
              dividendPerShare: latest.amount,
              dividendYield: model.price > 0
                  ? (latest.amount / model.price) * 100
                  : model.dividendYield,
            );
          }
        }
      } catch (_) {
        debugPrint('DART 실패 (폴백 사용): $code');
      }
    }

    // 캐시 저장
    _cache?.put('stock_$code', {
      'ts': DateTime.now().millisecondsSinceEpoch,
      'price': model.price,
      'per': model.per,
      'marketCap': model.marketCap,
    });

    return model;
  }

  /// 추천 종목 목록 (전체 마스터 DB → API 호출)
  Future<List<StockModel>> getRecommendedStocks() async {
    final results = <StockModel>[];
    for (final m in StockMasterDB.all) {
      final stock = await fetchStock(m.code);
      if (stock != null) results.add(stock);
    }
    return results;
  }

  // ════════════════════════════════════════════════════════════
  // 🟡 정적 호환 메서드 — 동기 UI 코드 호환용
  //
  // 기존 providers / screens 코드는 동기 호출을 가정.
  // 이를 깨지 않기 위해 마스터 DB 폴백 데이터로 구성된 동기 API를 제공.
  // 추후 점진적으로 비동기로 마이그레이션 권장.
  // ════════════════════════════════════════════════════════════

  /// 모든 종목 (폴백 데이터 기반)
  static List<StockModel> get allStocks {
    return StockMasterDB.all.map(_staticModelFromMaster).toList();
  }

  /// 섹터별 필터
  static List<StockModel> getBySector(StockSector sector) {
    if (sector == StockSector.all) return allStocks;
    return allStocks.where((s) => s.sector == sector).toList();
  }

  /// 단순 추천 알고리즘 (성향 + 섹터 + 목표 기반)
  static Map<StockModel, int> recommendPortfolio({
    required int monthlyGoal,
    required InvestmentProfile profile,
    required List<StockSector> preferredSectors,
  }) {
    var candidates = allStocks;

    // 섹터 필터 (전체가 아니면)
    if (!preferredSectors.contains(StockSector.all) &&
        preferredSectors.isNotEmpty) {
      candidates = candidates
          .where((s) => preferredSectors.contains(s.sector))
          .toList();
    }
    if (candidates.isEmpty) candidates = allStocks;

    // 성향별 정렬
    candidates.sort((a, b) {
      switch (profile) {
        case InvestmentProfile.stable:
        // 낮은 PER + 높은 시총
          final aScore = (a.per > 0 ? 30 / a.per : 0) + a.marketCap / 1e7;
          final bScore = (b.per > 0 ? 30 / b.per : 0) + b.marketCap / 1e7;
          return bScore.compareTo(aScore);
        case InvestmentProfile.balanced:
          return b.dividendYield.compareTo(a.dividendYield);
        case InvestmentProfile.growth:
          return b.roe.compareTo(a.roe);
        case InvestmentProfile.highYield:
          return b.dividendYield.compareTo(a.dividendYield);
      }
    });

    // 상위 5종목으로 균등 분배
    final picks = candidates.take(5).toList();
    if (picks.isEmpty) return {};

    final perStockMonthlyGoal = monthlyGoal / picks.length;
    final result = <StockModel, int>{};
    for (final stock in picks) {
      final shares = stock.sharesNeededForMonthly(perStockMonthlyGoal.round());
      if (shares > 0) result[stock] = shares;
    }
    return result;
  }

  // ════════════════════════════════════════════════════════════
  // 내부 헬퍼
  // ════════════════════════════════════════════════════════════

  StockModel _modelFromMaster(StockMaster m) {
    return _staticModelFromMaster(m);
  }

  /// 마스터 → StockModel (정적 / 인스턴스 공통)
  static StockModel _staticModelFromMaster(StockMaster m) {
    // 가짜 5년 배당 이력 (DART 실패 시 폴백)
    final now = DateTime.now();
    final history = <DividendHistory>[];
    for (int i = 4; i >= 0; i--) {
      final year = now.year - i;
      final factor = 0.85 +
          (i * 0.04) +
          (math.Random(m.code.hashCode + i).nextDouble() * 0.1);
      final amount = (m.fallbackDividend * factor).round();
      history.add(DividendHistory(
        year: year,
        amount: amount,
        yieldPercent: m.fallbackPrice > 0
            ? (amount / m.fallbackPrice) * 100
            : m.fallbackYield,
        exDate: DateTime(year, 12, 28),
      ));
    }

    final latest = history.last.amount;

    return StockModel(
      code: m.code,
      name: m.name,
      nameEn: '',
      sector: m.sector,
      price: m.fallbackPrice,
      dividendYield: m.fallbackYield,
      dividendPerShare: latest,
      latestDividend: latest,
      frequency: m.frequency,
      per: m.fallbackPer,
      pbr: 0.6,
      roe: m.fallbackPer > 0 ? 100 / m.fallbackPer : 8,
      eps: m.fallbackPer > 0 ? m.fallbackPrice / m.fallbackPer : 0,
      history: history,
      isRecommended: true,
      suitableFor: _suitableForFromSector(m.sector, m.fallbackYield),
      riskLevel: _riskFromSector(m.sector),
      marketCap: m.fallbackMarketCap,
      sectorColor: m.sector.defaultColor,
    );
  }

  static List<InvestmentProfile> _suitableForFromSector(
      StockSector sector, double yieldVal) {
    final list = <InvestmentProfile>[];
    if (yieldVal >= 5.5) list.add(InvestmentProfile.highYield);
    if (yieldVal >= 3.5) list.add(InvestmentProfile.balanced);
    switch (sector) {
      case StockSector.finance:
      case StockSector.telecom:
      case StockSector.energy:
        list.add(InvestmentProfile.stable);
        break;
      case StockSector.healthcare:
      case StockSector.industrial:
        list.add(InvestmentProfile.growth);
        break;
      case StockSector.reit:
        list.add(InvestmentProfile.highYield);
        break;
      default:
        break;
    }
    return list.isEmpty ? [InvestmentProfile.balanced] : list;
  }

  static String _riskFromSector(StockSector sector) {
    switch (sector) {
      case StockSector.finance:
      case StockSector.telecom:
        return '낮음';
      case StockSector.reit:
      case StockSector.consumer:
      case StockSector.energy:
        return '중간';
      default:
        return '중간';
    }
  }

  StockModel _modelFromCache(StockMaster m, Map<String, dynamic> cache) {
    var model = _staticModelFromMaster(m);
    if (cache['price'] is num) {
      model = model.copyWith(price: (cache['price'] as num).toDouble());
    }
    if (cache['per'] is num && (cache['per'] as num) > 0) {
      model = model.copyWith(per: (cache['per'] as num).toDouble());
    }
    if (cache['marketCap'] is num) {
      model = model.copyWith(marketCap: (cache['marketCap'] as num).toInt());
    }
    return model;
  }
}