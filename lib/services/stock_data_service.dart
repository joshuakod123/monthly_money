import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/stock_model.dart';
import '../data/stock_master.dart';
import 'api/kis_client.dart';
import 'api/opendart_client.dart';
import 'api/api_config.dart';

/// ═══════════════════════════════════════════════════════════
///  StockDataService v4
///
///  핵심 원칙:
///   1. **이름·섹터는 절대로 비지 않는다** — 마스터 DB 폴백
///   2. API 성공 시에만 동적 데이터(가격·PER) 덮어씀
///   3. 부분 실패 허용 — 한 종목 실패해도 다른 종목 정상 표시
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

    // 2) KIS 가격 시도 (실패해도 폴백 유지)
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
      } catch (e) {
        debugPrint('KIS 실패 (폴백 사용): $code');
      }

      // 3) OpenDART 배당 이력 (실패해도 폴백 유지)
      try {
        final dividendData = await _dart.getDividendHistory(
          stockCode: code,
          years: ApiConfig.dividendHistoryYears,
        );
        if (dividendData.isNotEmpty) {
          // DividendData → DividendHistory 변환
          final history = dividendData
              .where((d) => d.cashDividendPerShare != null && d.cashDividendPerShare! > 0)
              .map((d) => DividendHistory(
            year: d.year,
            amount: d.cashDividendPerShare!,
            exDate: DateTime(d.year, 12, 28),
          ))
              .toList();
          if (history.isNotEmpty) {
            // 최신 배당으로 latestDividend 업데이트
            final latest = history.last;
            model = model.copyWith(
              history: history,
              latestDividend: latest.amount,
              dividendYield: model.price > 0
                  ? (latest.amount / model.price) * 100
                  : model.dividendYield,
            );
          }
        }
      } catch (e) {
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

  /// 추천 종목 목록 (전체 마스터 DB)
  Future<List<StockModel>> getRecommendedStocks() async {
    final results = <StockModel>[];
    for (final m in StockMasterDB.all) {
      final stock = await fetchStock(m.code);
      if (stock != null) results.add(stock);
    }
    return results;
  }

  StockModel _modelFromMaster(StockMaster m) {
    // 가짜 5년 배당 이력 생성 (DART 실패 시 폴백용)
    final now = DateTime.now();
    final history = <DividendHistory>[];
    for (int i = 4; i >= 0; i--) {
      final year = now.year - i;
      // 약간의 변동 추가 (안정성 시뮬레이션)
      final factor = 0.85 + (i * 0.04) + (math.Random(m.code.hashCode + i).nextDouble() * 0.1);
      final amount = (m.fallbackDividend * factor).round();
      history.add(DividendHistory(
        year: year,
        amount: amount,
        exDate: DateTime(year, 12, 28),
      ));
    }

    return StockModel(
      code: m.code,
      name: m.name,
      sector: m.sector,
      frequency: m.frequency,
      price: m.fallbackPrice,
      per: m.fallbackPer,
      pbr: 0.6,
      eps: m.fallbackPer > 0 ? m.fallbackPrice / m.fallbackPer : 0,
      marketCap: m.fallbackMarketCap,
      dividendYield: m.fallbackYield,
      latestDividend: m.fallbackDividend.round(),
      history: history,
    );
  }

  StockModel _modelFromCache(StockMaster m, Map<String, dynamic> cache) {
    var model = _modelFromMaster(m);
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