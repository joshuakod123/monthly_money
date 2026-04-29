import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/stock_model.dart';
import 'api/api_config.dart';
import 'api/opendart_client.dart';
import 'api/kis_client.dart';
import 'api/krx_client.dart';

/// ═══════════════════════════════════════════════════════════
///  StockDataService v2
///
///  여러 API를 조합해 통합된 StockModel 을 만들어내는 facade.
///
///   ┌──────────────┐   ┌──────────┐   ┌──────────┐
///   │   OpenDART   │   │   KIS    │   │   KRX    │
///   │ 배당 5년치    │   │ 실시간시세│   │ 종목마스터│
///   │ ROE/EPS      │   │ PER/PBR  │   │ 섹터분류  │
///   └──────┬───────┘   └─────┬────┘   └────┬─────┘
///          └───────────┬─────┘              │
///                      ▼                    │
///              StockDataService ◄───────────┘
///                      │
///                      ▼
///                  StockModel
///                      │
///                      ▼
///              ForecastEngine 으로 전달
///
///  특징:
///    - Hive 기반 디스크 캐싱 (오프라인/Rate-limit 대응)
///    - 한 종목당 한 번만 OpenDART 5회 호출 (5년치)
///    - 시세는 5분 캐시, 배당은 24시간 캐시
/// ═══════════════════════════════════════════════════════════
class StockDataService {
  final OpenDartClient _dart = OpenDartClient();
  final KisClient _kis = KisClient();
  final KrxClient _krx = KrxClient();

  static StockDataService? _instance;
  static StockDataService get instance =>
      _instance ??= StockDataService._internal();
  StockDataService._internal();

  late Box _stockCache;
  late Box _priceCache;
  bool _initialized = false;

  /// 앱 시작 시 1회 호출
  Future<void> initialize() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _stockCache = await Hive.openBox('stocks_v2');
    _priceCache = await Hive.openBox('prices_v2');

    // OpenDART 고유번호 매핑은 처음 한 번만 다운로드 (~ 1MB)
    try {
      await _dart.loadCorpCodeMap();
    } catch (e) {
      debugPrint('OpenDART corp code load failed: $e');
    }

    _initialized = true;
  }

  /// ─────────────────────────────────────────────────
  /// 1️⃣ 단일 종목 풀 데이터 조회 (메인 API)
  /// ─────────────────────────────────────────────────
  Future<StockModel?> fetchStock(String stockCode) async {
    if (!_initialized) await initialize();

    // 1) 디스크 캐시 체크 (배당은 24시간, 종목정보는 7일)
    final cached = _readStockCache(stockCode);
    if (cached != null) {
      // 시세만 새로 갱신
      final freshPrice = await _fetchPriceWithCache(stockCode);
      if (freshPrice != null) {
        return _mergePriceIntoStock(cached, freshPrice);
      }
      return cached;
    }

    // 2) 캐시 없음 → 3개 API 병렬 호출
    final results = await Future.wait([
      _kis.getCurrentPrice(stockCode).catchError((_) => null),
      _kis.getStockInfo(stockCode).catchError((_) => null),
      _dart.getDividendHistory(stockCode: stockCode, years: 5)
          .catchError((_) => <DividendData>[]),
    ]);

    final price = results[0] as KisPriceData?;
    final info = results[1] as KisStockInfo?;
    final dividends = results[2] as List<DividendData>;

    if (price == null) {
      debugPrint('현재가 조회 실패: $stockCode');
      return null;
    }

    // 3) 가장 최근 연도 재무제표로 ROE 보강 (병렬 X — 무거우므로 별도 호출)
    final lastYear = DateTime.now().year - 1;
    final financial = await _dart.getFinancialData(
      stockCode: stockCode, year: lastYear,
    ).catchError((_) => null);

    // 4) StockModel 빌드
    final model = _buildStockModel(
      stockCode: stockCode,
      price: price,
      info: info,
      dividends: dividends,
      financial: financial,
    );

    // 5) 캐시 저장
    await _writeStockCache(stockCode, model);
    return model;
  }

  /// ─────────────────────────────────────────────────
  /// 2️⃣ 여러 종목 일괄 조회 (홈 화면용)
  /// ─────────────────────────────────────────────────
  Future<List<StockModel>> fetchStocks(List<String> stockCodes) async {
    if (!_initialized) await initialize();

    // 캐시된 것 먼저 가져오고, 없는 것만 API 호출
    final List<StockModel> result = [];
    final List<String> needFetch = [];

    for (final code in stockCodes) {
      final cached = _readStockCache(code);
      if (cached != null) {
        result.add(cached);
      } else {
        needFetch.add(code);
      }
    }

    // 미캐시 종목들을 청크 단위로 호출 (KIS rate limit 대응)
    if (needFetch.isNotEmpty) {
      const chunkSize = 3;
      for (var i = 0; i < needFetch.length; i += chunkSize) {
        final chunk = needFetch.skip(i).take(chunkSize).toList();
        final futures = chunk.map((code) => fetchStock(code));
        final stocks = await Future.wait(futures, eagerError: false);
        for (final s in stocks) {
          if (s != null) result.add(s);
        }
        if (i + chunkSize < needFetch.length) {
          await Future.delayed(const Duration(milliseconds: 400));
        }
      }
    }

    // 시세 일괄 갱신
    await _refreshPricesIfStale(result);
    return result;
  }

  /// ─────────────────────────────────────────────────
  /// 3️⃣ 배당 추천 후보 — KOSPI 200 중 배당수익률 상위
  /// 실제로는 KRX 마스터에서 시가총액 상위 + DART에서 배당있는 종목 필터링
  /// ─────────────────────────────────────────────────
  static const List<String> defaultDividendStocks = [
    '105560', // KB금융
    '055550', // 신한지주
    '086790', // 하나금융지주
    '316140', // 우리금융지주
    '030200', // KT
    '017670', // SK텔레콤
    '032640', // LG유플러스
    '015760', // 한국전력
    '036460', // 한국가스공사
    '088980', // 맥쿼리인프라
    '395400', // SK리츠
    '432320', // KODEX 리츠
    '000080', // 하이트진로
    '271560', // 오리온
    '005490', // POSCO홀딩스
    '035250', // 강원랜드
    '000270', // 기아
    '005380', // 현대차
    '012630', // HDC
    '034730', // SK
  ];

  Future<List<StockModel>> getRecommendedStocks() {
    return fetchStocks(defaultDividendStocks);
  }

  /// ─────────────────────────────────────────────────
  /// 4️⃣ 성향/섹터별 추천 (메모리 필터)
  /// ─────────────────────────────────────────────────
  Future<List<StockModel>> getByProfile(InvestmentProfile profile) async {
    final all = await getRecommendedStocks();
    return all.where((s) => s.suitableFor.contains(profile)).toList();
  }

  Future<List<StockModel>> getBySector(StockSector sector) async {
    final all = await getRecommendedStocks();
    if (sector == StockSector.all) return all;
    return all.where((s) => s.sector == sector).toList();
  }

  /// ─────────────────────────────────────────────────
  /// 5️⃣ 포트폴리오 추천 (성향 + 섹터 + 배당 목표 매칭)
  /// ─────────────────────────────────────────────────
  Future<Map<StockModel, int>> recommendPortfolio({
    required int monthlyGoal,
    required InvestmentProfile profile,
    required List<StockSector> preferredSectors,
  }) async {
    final all = await getRecommendedStocks();
    var candidates = all.where((s) {
      bool profileMatch = s.suitableFor.contains(profile);
      bool sectorMatch = preferredSectors.isEmpty ||
          preferredSectors.contains(StockSector.all) ||
          preferredSectors.contains(s.sector);
      return profileMatch && sectorMatch && s.dividendYield > 0;
    }).toList();

    candidates.sort((a, b) => b.dividendYield.compareTo(a.dividendYield));
    final top = candidates.take(5).toList();
    if (top.isEmpty) return {};

    final perStockGoal = (monthlyGoal / top.length).ceil();
    return {
      for (final s in top) s: s.sharesNeededForMonthly(perStockGoal),
    };
  }

  static double totalInvestmentNeeded(Map<StockModel, int> portfolio) {
    return portfolio.entries
        .map((e) => e.key.price * e.value)
        .fold(0.0, (a, b) => a + b);
  }

  // ═══════════════════════════════════════════════════
  // Private 헬퍼
  // ═══════════════════════════════════════════════════

  StockModel _buildStockModel({
    required String stockCode,
    required KisPriceData price,
    required KisStockInfo? info,
    required List<DividendData> dividends,
    required FinancialData? financial,
  }) {
    // 섹터 추론 (KIS 응답 → 앱 enum)
    final sector = _inferSector(info?.sectorName ?? '', stockCode);

    // 배당 히스토리 변환
    final history = dividends
        .where((d) => d.cashDividendPerShare != null)
        .map((d) => DividendHistory(
              year: d.year,
              amount: d.cashDividendPerShare!,
              yieldPercent: d.cashDividendYield ?? 0,
              isPaid: true,
            ))
        .toList();

    // 가장 최근 배당 정보
    final latestDividend = dividends.isEmpty
        ? null
        : dividends.reduce((a, b) => a.year > b.year ? a : b);

    final dividendPerShare = latestDividend?.cashDividendPerShare ?? 0;
    final dividendYield = latestDividend?.cashDividendYield ??
        (price.currentPrice > 0
            ? (dividendPerShare / price.currentPrice) * 100
            : 0);

    // 배당 주기 추론 (배당 횟수 기반 — 추후 정교화 가능)
    final frequency = _inferFrequency(stockCode);

    // 투자 성향 매칭
    final profiles = _inferProfiles(
      yieldVal: dividendYield,
      per: price.per,
      roe: financial?.roe ?? 0,
      historyCount: history.length,
    );

    // 리스크 레벨
    final risk = _calculateRisk(history, price.per);

    return StockModel(
      code: stockCode,
      name: info?.name ?? stockCode,
      nameEn: '',
      sector: sector,
      price: price.currentPrice.toDouble(),
      dividendYield: dividendYield,
      dividendPerShare: dividendPerShare,
      frequency: frequency,
      per: price.per,
      pbr: price.pbr,
      roe: financial?.roe ?? 0,
      history: history,
      isRecommended: dividendYield > 4.5,
      suitableFor: profiles,
      riskLevel: risk,
      marketCap: (price.marketCap ?? 0).toDouble(),
      sectorColor: _sectorColor(sector),
    );
  }

  StockSector _inferSector(String sectorName, String code) {
    if (sectorName.contains('은행') ||
        sectorName.contains('금융') ||
        sectorName.contains('보험') ||
        sectorName.contains('증권')) return StockSector.finance;
    if (sectorName.contains('통신')) return StockSector.telecom;
    if (sectorName.contains('전기') ||
        sectorName.contains('가스') ||
        sectorName.contains('에너지')) return StockSector.energy;
    if (sectorName.contains('부동산') ||
        sectorName.contains('리츠') ||
        sectorName.contains('REIT')) return StockSector.reit;
    if (sectorName.contains('식품') ||
        sectorName.contains('음료') ||
        sectorName.contains('주류')) return StockSector.consumer;
    if (sectorName.contains('의약') ||
        sectorName.contains('헬스') ||
        sectorName.contains('의료')) return StockSector.healthcare;
    return StockSector.industrial;
  }

  /// 배당 주기 추론 — 알려진 분기/월 배당 종목 hardcode
  /// 향후 DART 의 분기보고서 배당 데이터로 자동화 가능
  DividendFrequency _inferFrequency(String code) {
    const quarterly = {'105560', '055550', '086790', '316140', '017670', '395400', '432320'};
    const semiAnnual = {'030200', '032640', '088980', '000080'};
    const monthly = <String>{}; // 한국에 월배당 종목 거의 없음 (일부 ETF만)
    if (quarterly.contains(code)) return DividendFrequency.quarterly;
    if (semiAnnual.contains(code)) return DividendFrequency.semiAnnual;
    if (monthly.contains(code)) return DividendFrequency.monthly;
    return DividendFrequency.annual;
  }

  List<InvestmentProfile> _inferProfiles({
    required double yieldVal,
    required double per,
    required double roe,
    required int historyCount,
  }) {
    final List<InvestmentProfile> profiles = [];

    // 안정형: 5년 연속 배당 + 낮은 PER
    if (historyCount >= 5 && per > 0 && per < 12) {
      profiles.add(InvestmentProfile.stable);
    }
    // 균형형: 적정 수익률 + ROE 양호
    if (yieldVal >= 3 && yieldVal < 6 && roe >= 7) {
      profiles.add(InvestmentProfile.balanced);
    }
    // 성장형: ROE 높음
    if (roe >= 12) {
      profiles.add(InvestmentProfile.growth);
    }
    // 고배당형: 6% 이상
    if (yieldVal >= 5.5) {
      profiles.add(InvestmentProfile.highYield);
    }

    if (profiles.isEmpty) profiles.add(InvestmentProfile.balanced);
    return profiles;
  }

  String _calculateRisk(List<DividendHistory> history, double per) {
    if (history.length < 3) return '높음';
    // 배당 0이 끼어있거나 큰 변동
    final amounts = history.map((h) => h.amount).toList();
    final hasZero = amounts.any((a) => a == 0);
    if (hasZero) return '높음';
    final maxA = amounts.reduce((a, b) => a > b ? a : b);
    final minA = amounts.reduce((a, b) => a < b ? a : b);
    if (minA == 0 || (maxA / minA) > 2.5) return '높음';
    if ((maxA / minA) > 1.5 || (per > 20)) return '중간';
    return '낮음';
  }

  Color _sectorColor(StockSector sector) {
    switch (sector) {
      case StockSector.finance: return const Color(0xFFEAF0FF);
      case StockSector.telecom: return const Color(0xFFFFF0E6);
      case StockSector.energy: return const Color(0xFFFFF8E0);
      case StockSector.reit: return const Color(0xFFE8F8EF);
      case StockSector.consumer: return const Color(0xFFFFF0F5);
      case StockSector.healthcare: return const Color(0xFFE0F7FA);
      case StockSector.industrial: return const Color(0xFFF0F0F0);
      case StockSector.all: return const Color(0xFFF0F0F0);
    }
  }

  // ─── 캐싱 ─────────────────────────────────────

  Future<KisPriceData?> _fetchPriceWithCache(String code) async {
    final cached = _priceCache.get('price_$code');
    if (cached != null && cached is Map) {
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(cached['_at'] as int);
      if (DateTime.now().difference(cachedAt) < ApiConfig.priceCacheDuration) {
        return KisPriceData.fromKis(code, Map<String, dynamic>.from(cached['data']));
      }
    }

    final fresh = await _kis.getCurrentPrice(code).catchError((_) => null);
    if (fresh != null) {
      await _priceCache.put('price_$code', {
        '_at': DateTime.now().millisecondsSinceEpoch,
        'data': {
          'stck_prpr': fresh.currentPrice,
          'stck_sdpr': fresh.prevClosePrice,
          'prdy_vrss': fresh.changeAmount,
          'prdy_ctrt': fresh.changePercent,
          'per': fresh.per,
          'pbr': fresh.pbr,
          'eps': fresh.eps,
          'bps': fresh.bps,
          'hts_avls': fresh.marketCap,
          'w52_hgpr': fresh.high52w,
          'w52_lwpr': fresh.low52w,
        },
      });
    }
    return fresh;
  }

  Future<void> _refreshPricesIfStale(List<StockModel> stocks) async {
    final now = DateTime.now();
    final stale = <StockModel>[];
    for (final s in stocks) {
      final cached = _priceCache.get('price_${s.code}');
      if (cached == null) {
        stale.add(s);
      } else if (cached is Map) {
        final cachedAt = DateTime.fromMillisecondsSinceEpoch(cached['_at'] as int);
        if (now.difference(cachedAt) > ApiConfig.priceCacheDuration) {
          stale.add(s);
        }
      }
    }
    if (stale.isEmpty) return;
    final codes = stale.map((s) => s.code).toList();
    await _kis.getMultiplePrices(codes); // 캐시에만 저장됨
  }

  StockModel? _readStockCache(String code) {
    final raw = _stockCache.get('stock_$code');
    if (raw == null) return null;
    if (raw is! Map) return null;
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(raw['_at'] as int);
    if (DateTime.now().difference(cachedAt) > ApiConfig.dividendCacheDuration) {
      return null;
    }
    return _stockFromJson(Map<String, dynamic>.from(raw['data']));
  }

  Future<void> _writeStockCache(String code, StockModel s) async {
    await _stockCache.put('stock_$code', {
      '_at': DateTime.now().millisecondsSinceEpoch,
      'data': _stockToJson(s),
    });
  }

  StockModel _mergePriceIntoStock(StockModel old, KisPriceData fresh) {
    return StockModel(
      code: old.code,
      name: old.name,
      nameEn: old.nameEn,
      sector: old.sector,
      price: fresh.currentPrice.toDouble(),
      dividendYield: fresh.currentPrice > 0
          ? (old.dividendPerShare / fresh.currentPrice) * 100
          : old.dividendYield,
      dividendPerShare: old.dividendPerShare,
      frequency: old.frequency,
      per: fresh.per,
      pbr: fresh.pbr,
      roe: old.roe,
      history: old.history,
      isRecommended: old.isRecommended,
      suitableFor: old.suitableFor,
      riskLevel: old.riskLevel,
      marketCap: (fresh.marketCap ?? old.marketCap).toDouble(),
      sectorColor: old.sectorColor,
    );
  }

  Map<String, dynamic> _stockToJson(StockModel s) => {
        'code': s.code,
        'name': s.name,
        'nameEn': s.nameEn,
        'sector': s.sector.name,
        'price': s.price,
        'dividendYield': s.dividendYield,
        'dividendPerShare': s.dividendPerShare,
        'frequency': s.frequency.name,
        'per': s.per,
        'pbr': s.pbr,
        'roe': s.roe,
        'history': s.history
            .map((h) => {
                  'year': h.year,
                  'amount': h.amount,
                  'yieldPercent': h.yieldPercent,
                })
            .toList(),
        'isRecommended': s.isRecommended,
        'suitableFor': s.suitableFor.map((p) => p.name).toList(),
        'riskLevel': s.riskLevel,
        'marketCap': s.marketCap,
        'sectorColorValue': s.sectorColor.value,
      };

  StockModel _stockFromJson(Map<String, dynamic> j) => StockModel(
        code: j['code'],
        name: j['name'],
        nameEn: j['nameEn'] ?? '',
        sector: StockSector.values.firstWhere((e) => e.name == j['sector']),
        price: (j['price'] as num).toDouble(),
        dividendYield: (j['dividendYield'] as num).toDouble(),
        dividendPerShare: j['dividendPerShare'] as int,
        frequency: DividendFrequency.values
            .firstWhere((e) => e.name == j['frequency']),
        per: (j['per'] as num).toDouble(),
        pbr: (j['pbr'] as num).toDouble(),
        roe: (j['roe'] as num).toDouble(),
        history: (j['history'] as List)
            .map((h) => DividendHistory(
                  year: h['year'],
                  amount: h['amount'],
                  yieldPercent: (h['yieldPercent'] as num).toDouble(),
                ))
            .toList(),
        isRecommended: j['isRecommended'] ?? false,
        suitableFor: (j['suitableFor'] as List)
            .map((p) =>
                InvestmentProfile.values.firstWhere((e) => e.name == p))
            .toList(),
        riskLevel: j['riskLevel'],
        marketCap: (j['marketCap'] as num).toDouble(),
        sectorColor: Color(j['sectorColorValue'] as int),
      );
}
