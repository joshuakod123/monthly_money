import 'package:flutter_dotenv/flutter_dotenv.dart';

/// ═══════════════════════════════════════════════════════════
///  API 설정 (v4) — .env 기반
///
///  ⚠️ main.dart 에서 dotenv.load() 가 호출돼야 동작함
/// ═══════════════════════════════════════════════════════════
class ApiConfig {
  // OpenDART
  static String get openDartApiKey => dotenv.env['OPENDART_API_KEY'] ?? '';
  static const String openDartBaseUrl = 'https://opendart.fss.or.kr/api';

  // KIS — 시세 조회는 반드시 "실전투자" 키
  static String get kisAppKey => dotenv.env['KIS_APP_KEY'] ?? '';
  static String get kisAppSecret => dotenv.env['KIS_APP_SECRET'] ?? '';
  static const String kisBaseUrl = 'https://openapi.koreainvestment.com:9443';

  // KRX
  static const String krxBaseUrl = 'http://data.krx.co.kr';

  // 캐시
  static const Duration priceCacheDuration = Duration(minutes: 5);
  static const Duration dividendCacheDuration = Duration(days: 1);
  static const Duration corpCodeCacheDuration = Duration(days: 7);
  static const int dividendHistoryYears = 5;

  static String? validate() {
    if (openDartApiKey.isEmpty) return 'OpenDART API 키 미입력 (.env 확인)';
    if (kisAppKey.isEmpty || kisAppSecret.isEmpty) return 'KIS API 키 미입력 (.env 확인)';
    if (kisAppKey.length != 36) return 'KIS AppKey는 36자여야 합니다';
    return null;
  }

  static bool get isConfigured => validate() == null;
}