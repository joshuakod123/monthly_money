import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

/// ═══════════════════════════════════════════════════════════
///  KIS Client v3 — 견고성 강화
///  - validateStatus 항상 true → Dio 가 throw 안하게
///  - 모든 메서드 null 반환 (한 종목 실패가 전체 무너뜨리지 않음)
///  - 토큰 캐시에 키 해시 같이 저장 (키 변경 시 자동 무효화)
/// ═══════════════════════════════════════════════════════════
class KisClient {
  final Dio _dio;
  String? _accessToken;
  DateTime? _tokenExpiresAt;
  bool _warned500 = false;

  KisClient()
      : _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.kisBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Content-Type': 'application/json; charset=UTF-8'},
    validateStatus: (_) => true,
  ));

  Future<String?> _getAccessToken() async {
    if (ApiConfig.kisAppKey.isEmpty || ApiConfig.kisAppSecret.isEmpty) {
      debugPrint('⚠️ KIS 키 미입력 — api_config.dart 확인');
      return null;
    }

    if (_accessToken != null &&
        _tokenExpiresAt != null &&
        DateTime.now().isBefore(_tokenExpiresAt!)) {
      return _accessToken;
    }

    final prefs = await SharedPreferences.getInstance();
    final keyHash = ApiConfig.kisAppKey.hashCode.toString();
    final cached = prefs.getString('kis_token');
    final cachedExpiry = prefs.getInt('kis_token_exp');
    final cachedHash = prefs.getString('kis_key_hash');

    if (cached != null && cachedExpiry != null && cachedHash == keyHash) {
      final exp = DateTime.fromMillisecondsSinceEpoch(cachedExpiry);
      if (DateTime.now().isBefore(exp)) {
        _accessToken = cached;
        _tokenExpiresAt = exp;
        return _accessToken;
      }
    }

    try {
      final res = await _dio.post('/oauth2/tokenP', data: {
        'grant_type': 'client_credentials',
        'appkey': ApiConfig.kisAppKey,
        'appsecret': ApiConfig.kisAppSecret,
      });

      if (res.statusCode != 200 || res.data == null) {
        debugPrint('❌ KIS 토큰 발급 실패 ${res.statusCode}: ${res.data}');
        return null;
      }
      final token = (res.data as Map)['access_token'] as String?;
      if (token == null) return null;

      _accessToken = token;
      _tokenExpiresAt = DateTime.now().add(const Duration(hours: 23));
      await prefs.setString('kis_token', token);
      await prefs.setInt('kis_token_exp',
          _tokenExpiresAt!.millisecondsSinceEpoch);
      await prefs.setString('kis_key_hash', keyHash);
      debugPrint('✅ KIS 토큰 발급 성공');
      return token;
    } catch (e) {
      debugPrint('❌ KIS 토큰 예외: $e');
      return null;
    }
  }

  Future<KisPriceData?> getCurrentPrice(String stockCode) async {
    final token = await _getAccessToken();
    if (token == null) return null;

    try {
      final res = await _dio.get(
        '/uapi/domestic-stock/v1/quotations/inquire-price',
        queryParameters: {
          'FID_COND_MRKT_DIV_CODE': 'J',
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

      if (res.statusCode == 500) {
        if (!_warned500) {
          debugPrint('⚠️ KIS 500 — 실전투자 키인지 확인 (모의투자 키는 시세 조회 ❌)');
          _warned500 = true;
        }
        return null;
      }
      if (res.statusCode == 401 || res.statusCode == 403) {
        _accessToken = null;
        _tokenExpiresAt = null;
        return null;
      }
      if (res.statusCode != 200 || res.data == null) return null;

      final data = res.data as Map;
      if (data['rt_cd'] != '0') {
        debugPrint('현재가 ${stockCode} 실패: ${data['msg1']}');
        return null;
      }
      final output = data['output'] as Map?;
      if (output == null) return null;
      return KisPriceData.fromKis(stockCode, Map<String, dynamic>.from(output));
    } catch (e) {
      debugPrint('현재가 ${stockCode} 예외: $e');
      return null;
    }
  }

  Future<KisStockInfo?> getStockInfo(String stockCode) async {
    final token = await _getAccessToken();
    if (token == null) return null;
    try {
      final res = await _dio.get(
        '/uapi/domestic-stock/v1/quotations/search-stock-info',
        queryParameters: {'PRDT_TYPE_CD': '300', 'PDNO': stockCode},
        options: Options(headers: {
          'authorization': 'Bearer $token',
          'appkey': ApiConfig.kisAppKey,
          'appsecret': ApiConfig.kisAppSecret,
          'tr_id': 'CTPF1604R',
          'custtype': 'P',
        }),
      );
      if (res.statusCode != 200 || res.data == null) return null;
      final data = res.data as Map;
      if (data['rt_cd'] != '0') return null;
      final output = data['output'] as Map?;
      if (output == null) return null;
      return KisStockInfo.fromKis(Map<String, dynamic>.from(output));
    } catch (e) {
      return null;
    }
  }
}

class KisPriceData {
  final String stockCode;
  final int currentPrice;
  final int prevClosePrice;
  final int changeAmount;
  final double changePercent;
  final double per;
  final double pbr;
  final double eps;
  final double bps;
  final int? marketCap;
  final int high52w; // 52주 최고가 추가
  final int low52w;  // 52주 최저가 추가

  KisPriceData({
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

  factory KisPriceData.fromKis(String code, Map<String, dynamic> o) {
    int pi(dynamic v) => int.tryParse(v?.toString().replaceAll(',', '') ?? '') ?? 0;
    double pd(dynamic v) => double.tryParse(v?.toString().replaceAll(',', '') ?? '') ?? 0;

    return KisPriceData(
      stockCode: code,
      currentPrice: pi(o['stck_prpr']),
      prevClosePrice: pi(o['stck_sdpr']),
      changeAmount: pi(o['prdy_vrss']),
      changePercent: pd(o['prdy_ctrt']),
      per: pd(o['per']),
      pbr: pd(o['pbr']),
      eps: pd(o['eps']),
      bps: pd(o['bps']),
      marketCap: pi(o['hts_avls']),
      high52w: pi(o['w52_hgpr']), // 추가된 부분 매핑
      low52w: pi(o['w52_lwpr']),  // 추가된 부분 매핑
    );
  }
}

class KisStockInfo {
  final String code;
  final String name;
  final String? sectorName;
  const KisStockInfo({required this.code, required this.name, this.sectorName});

  factory KisStockInfo.fromKis(Map<String, dynamic> o) => KisStockInfo(
    code: o['pdno']?.toString() ?? '',
    name: o['prdt_abrv_name']?.toString() ?? '',
    sectorName: o['std_idst_clsf_cd_name']?.toString(),
  );
}