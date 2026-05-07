import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/stock_model.dart';

/// ═══════════════════════════════════════════════════════════
///  StockDataService v7 — Supabase + GICS 11 sector mapping
/// ═══════════════════════════════════════════════════════════
class StockDataService {
  StockDataService._();
  static final instance = StockDataService._();

  static const _cacheKey = 'stocks_cache_v2';
  static const _cacheTimeKey = 'stocks_cache_time_v2';
  static const _cacheTtl = Duration(hours: 24);

  List<StockModel> _stocks = [];
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    final cached = await _loadFromCache();
    if (cached.isNotEmpty) {
      _stocks = cached;
      _initialized = true;
    }
    await _refreshIfStale();
  }

  Future<List<StockModel>> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeStr = prefs.getInt(_cacheTimeKey);
      if (timeStr == null) return [];
      final age = DateTime.now().millisecondsSinceEpoch - timeStr;
      if (age > _cacheTtl.inMilliseconds) return [];

      final cached = prefs.getString(_cacheKey);
      if (cached == null) return [];
      final list = jsonDecode(cached) as List;
      return list
          .map((m) => _modelFromMap(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveCache(List<Map<String, dynamic>> raw) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(raw));
    await prefs.setInt(
        _cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _refreshIfStale() async {
    final prefs = await SharedPreferences.getInstance();
    final timeStr = prefs.getInt(_cacheTimeKey);
    if (timeStr != null) {
      final age = DateTime.now().millisecondsSinceEpoch - timeStr;
      if (age < _cacheTtl.inMilliseconds && _stocks.isNotEmpty) return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    try {
      final res = await Supabase.instance.client
          .from('stocks')
          .select()
          .eq('is_active', true)
          .order('market_cap', ascending: false);

      final list = (res as List).cast<Map<String, dynamic>>();
      _stocks = list.map(_modelFromMap).toList();
      _initialized = true;
      await _saveCache(list);
    } catch (e) {
      if (_stocks.isEmpty) {
        // ignore: avoid_print
        print('⚠️ Supabase fetch 실패: $e');
      }
    }
  }

  StockModel _modelFromMap(Map<String, dynamic> m) {
    final sector = _parseSector(m['sector'] as String?);
    final freq = _parseFrequency(m['frequency'] as String?);
    final paymentMonths = ((m['payment_months'] as List?) ?? [])
        .map((e) => (e as num).toInt())
        .toList();
    final history = ((m['history'] as List?) ?? []).map((h) {
      final hh = Map<String, dynamic>.from(h);
      return DividendHistory(
        year: (hh['year'] as num).toInt(),
        amount: (hh['amount'] as num).toInt(),
        yieldPercent: (hh['yieldPercent'] as num? ?? 0).toDouble(),
      );
    }).toList();

    final price = (m['price'] as num? ?? 0).toDouble();
    final dps = (m['dividend_per_share'] as num? ?? 0).toInt();

    return StockModel(
      code: m['code'] as String,
      name: m['name'] as String,
      sector: sector,
      price: price,
      dividendYield: (m['dividend_yield'] as num? ?? 0).toDouble(),
      dividendPerShare: dps,
      latestDividend: dps,
      frequency: freq,
      paymentMonths: paymentMonths,
      per: (m['per'] as num? ?? 0).toDouble(),
      pbr: (m['pbr'] as num? ?? 0).toDouble(),
      roe: (m['roe'] as num? ?? 0).toDouble(),
      history: history,
      isRecommended: true,
      marketCap: (m['market_cap'] as num? ?? 0).toInt(),
      sectorColor: sector.defaultColor,
    );
  }

  /// Supabase의 sector 컬럼을 GICS 11 enum으로 매핑
  /// 구버전 데이터 (consumer 단일) 호환을 위해 fallback도 처리
  static StockSector _parseSector(String? s) {
    switch (s) {
      case 'energy':       return StockSector.energy;
      case 'materials':    return StockSector.materials;
      case 'industrial':   return StockSector.industrial;
      case 'consumerDisc':
      case 'consumer_disc':
      case 'consumerDiscretionary':
        return StockSector.consumerDisc;
      case 'consumerStpl':
      case 'consumer_stpl':
      case 'consumerStaples':
      case 'consumer':     // 구 데이터 호환 — 필수소비재로 분류
        return StockSector.consumerStpl;
      case 'healthcare':   return StockSector.healthcare;
      case 'finance':      return StockSector.finance;
      case 'tech':
      case 'it':
      case 'technology':
        return StockSector.tech;
      case 'telecom':
      case 'comm':
      case 'communication':
        return StockSector.telecom;
      case 'utilities':    return StockSector.utilities;
      case 'reit':
      case 'realestate':
      case 'real_estate':
        return StockSector.reit;
      default:             return StockSector.industrial;
    }
  }

  static DividendFrequency _parseFrequency(String? s) {
    switch (s) {
      case 'monthly':    return DividendFrequency.monthly;
      case 'quarterly':  return DividendFrequency.quarterly;
      case 'semiAnnual': return DividendFrequency.semiAnnual;
      case 'annual':     return DividendFrequency.annual;
      default:           return DividendFrequency.annual;
    }
  }

  static List<StockModel> get allStocks => instance._stocks;

  static List<StockModel> getBySector(StockSector sector) {
    if (sector == StockSector.all) return allStocks;
    return allStocks.where((s) => s.sector == sector).toList();
  }
}
