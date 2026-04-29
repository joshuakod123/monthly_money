import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

/// ═══════════════════════════════════════════════════════════
///  KIS (한국투자증권) Open API Client
///
///  - 실시간 시세 / 현재가 / PER / PBR / 시가총액 조회
///  - OAuth2 access_token 자동 관리 (24시간 유효)
///  - 무료, 모의투자 환경 지원
/// ═══════════════════════════════════════════════════════════
class KisClient {
  final Dio _dio;
  String? _accessToken;
  DateTime? _tokenExpiresAt;

  KisClient()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConfig.currentKisUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json; charset=UTF-8'},
        ));

  /// ─────────────────────────────────────────────────
  /// 1️⃣ Access Token 발급 (OAuth2)
  /// 토큰은 24시간 유효, SharedPreferences에 캐싱
  /// ─────────────────────────────────────────────────
  Future<String> _getAccessToken() async {
    // 메모리 캐시 체크
    if (_accessToken != null &&
        _tokenExpiresAt != null &&
        DateTime.now().isBefore(_tokenExpiresAt!)) {
      return _accessToken!;
    }

    // 디스크 캐시 체크
    final prefs = await SharedPreferences.getInstance();
    final cachedToken = prefs.getString('kis_access_token');
    final cachedExpiry = prefs.getInt('kis_token_expires_at');
    if (cachedToken != null && cachedExpiry != null) {
      final expiry = DateTime.fromMillisecondsSinceEpoch(cachedExpiry);
      if (DateTime.now().isBefore(expiry)) {
        _accessToken = cachedToken;
        _tokenExpiresAt = expiry;
        return _accessToken!;
      }
    }

    // 새로 발급
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/oauth2/tokenP',
        data: {
          'grant_type': 'client_credentials',
          'appkey': ApiConfig.kisAppKey,
          'appsecret': ApiConfig.kisAppSecret,
        },
      );

      final data = response.data!;
      _accessToken = data['access_token'] as String;
      // KIS 토큰은 24시간 유효 → 안전하게 23시간으로 설정
      _tokenExpiresAt = DateTime.now().add(const Duration(hours: 23));

      // 디스크 캐싱
      await prefs.setString('kis_access_token', _accessToken!);
      await prefs.setInt(
        'kis_token_expires_at',
        _tokenExpiresAt!.millisecondsSinceEpoch,
      );

      return _accessToken!;
    } on DioException catch (e) {
      throw KisException('Access Token 발급 실패: ${e.message}');
    }
  }

  /// ─────────────────────────────────────────────────
  /// 2️⃣ 주식 현재가 시세 (FHKST01010100)
  /// 가장 자주 호출되는 API. 현재가/등락률/거래량 등
  /// ─────────────────────────────────────────────────
  Future<KisPriceData?> getCurrentPrice(String stockCode) async {
    try {
      final token = await _getAccessToken();
      final response = await _dio.get<Map<String, dynamic>>(
        '/uapi/domestic-stock/v1/quotations/inquire-price',
        queryParameters: {
          'FID_COND_MRKT_DIV_CODE': 'J', // 주식 시장
          'FID_INPUT_ISCD': stockCode,
        },
        options: Options(headers: {
          'authorization': 'Bearer $token',
          'appkey': ApiConfig.kisAppKey,
          'appsecret': ApiConfig.kisAppSecret,
          'tr_id': 'FHKST01010100',
          'custtype': 'P',
        }),
      );

      final data = response.data!;
      if (data['rt_cd'] != '0') return null;

      final output = data['output'] as Map<String, dynamic>;
      return KisPriceData.fromKis(stockCode, output);
    } on DioException catch (e) {
      throw KisException('현재가 조회 실패: ${e.message}');
    }
  }

  /// ─────────────────────────────────────────────────
  /// 3️⃣ 주식 기본정보 (CTPF1604R)
  /// 종목명, 시가총액, PER, PBR 등 종목 메타데이터
  /// ─────────────────────────────────────────────────
  Future<KisStockInfo?> getStockInfo(String stockCode) async {
    try {
      final token = await _getAccessToken();
      final response = await _dio.get<Map<String, dynamic>>(
        '/uapi/domestic-stock/v1/quotations/search-stock-info',
        queryParameters: {
          'PRDT_TYPE_CD': '300', // 국내주식
          'PDNO': stockCode,
        },
        options: Options(headers: {
          'authorization': 'Bearer $token',
          'appkey': ApiConfig.kisAppKey,
          'appsecret': ApiConfig.kisAppSecret,
          'tr_id': 'CTPF1604R',
          'custtype': 'P',
        }),
      );

      final data = response.data!;
      if (data['rt_cd'] != '0') return null;

      return KisStockInfo.fromKis(data['output'] as Map<String, dynamic>);
    } on DioException {
      return null;
    }
  }

  /// ─────────────────────────────────────────────────
  /// 4️⃣ 여러 종목 일괄 조회 (병렬 처리)
  /// 처리량 제한이 있어 청크 단위로 호출
  /// ─────────────────────────────────────────────────
  Future<Map<String, KisPriceData>> getMultiplePrices(
      List<String> stockCodes) async {
    final Map<String, KisPriceData> result = {};

    // KIS 초당 20건 제한 → 안전하게 5개씩 묶어 100ms 간격
    const chunkSize = 5;
    for (var i = 0; i < stockCodes.length; i += chunkSize) {
      final chunk = stockCodes.skip(i).take(chunkSize).toList();
      final futures = chunk.map((code) => getCurrentPrice(code));
      final prices = await Future.wait(futures, eagerError: false);

      for (var j = 0; j < chunk.length; j++) {
        if (prices[j] != null) result[chunk[j]] = prices[j]!;
      }

      // Rate limit 대응
      if (i + chunkSize < stockCodes.length) {
        await Future.delayed(const Duration(milliseconds: 250));
      }
    }
    return result;
  }
}

/// 현재가 데이터 (KIS inquire-price 응답)
class KisPriceData {
  final String stockCode;
  final int currentPrice;          // stck_prpr
  final int prevClosePrice;        // stck_sdpr 전일종가
  final int changeAmount;          // prdy_vrss
  final double changePercent;      // prdy_ctrt
  final double per;                // per
  final double pbr;                // pbr
  final double eps;                // eps
  final double bps;                // bps
  final int? marketCap;            // hts_avls (시가총액, 백만원)
  final int high52w;               // w52_hgpr
  final int low52w;                // w52_lwpr

  const KisPriceData({
    required this.stockCode,
    required this.currentPrice,
    required this.prevClosePrice,
    required this.changeAmount,
    required this.changePercent,
    required this.per,
    required this.pbr,
    required this.eps,
    required this.bps,
    this.marketCap,
    required this.high52w,
    required this.low52w,
  });

  factory KisPriceData.fromKis(String stockCode, Map<String, dynamic> output) {
    int parseInt(dynamic v) =>
        int.tryParse(v?.toString().replaceAll(',', '') ?? '') ?? 0;
    double parseDouble(dynamic v) =>
        double.tryParse(v?.toString().replaceAll(',', '') ?? '') ?? 0;

    return KisPriceData(
      stockCode: stockCode,
      currentPrice: parseInt(output['stck_prpr']),
      prevClosePrice: parseInt(output['stck_sdpr']),
      changeAmount: parseInt(output['prdy_vrss']),
      changePercent: parseDouble(output['prdy_ctrt']),
      per: parseDouble(output['per']),
      pbr: parseDouble(output['pbr']),
      eps: parseDouble(output['eps']),
      bps: parseDouble(output['bps']),
      marketCap: parseInt(output['hts_avls']),
      high52w: parseInt(output['w52_hgpr']),
      low52w: parseInt(output['w52_lwpr']),
    );
  }
}

/// 종목 기본정보
class KisStockInfo {
  final String code;
  final String name;
  final String? sectorCode;
  final String? sectorName;
  final int? listingShares;

  const KisStockInfo({
    required this.code,
    required this.name,
    this.sectorCode,
    this.sectorName,
    this.listingShares,
  });

  factory KisStockInfo.fromKis(Map<String, dynamic> output) {
    return KisStockInfo(
      code: output['pdno']?.toString() ?? '',
      name: output['prdt_abrv_name']?.toString() ?? '',
      sectorCode: output['std_idst_clsf_cd']?.toString(),
      sectorName: output['std_idst_clsf_cd_name']?.toString(),
      listingShares: int.tryParse(
        (output['lstg_stqt']?.toString() ?? '').replaceAll(',', ''),
      ),
    );
  }
}

class KisException implements Exception {
  final String message;
  KisException(this.message);
  @override
  String toString() => 'KisException: $message';
}
