/// ═══════════════════════════════════════════════════════════
///  API 설정 (v3)
///
///  ⚠️ 핵심 수정 사항:
///  1. openDartBaseUrl 누락 버그 수정
///  2. KIS 모의투자(VTS) 서버는 시세 조회 미지원 — 항상 실전 서버 사용
///  3. 키 미입력 시 명확한 에러 메시지
/// ═══════════════════════════════════════════════════════════
class ApiConfig {
  // OpenDART
  static const String openDartApiKey = '7506d1f9a3373be82bd99c11696d14ddacf887fc'; // ⚠️ 40자 키 입력
  static const String openDartBaseUrl = 'https://opendart.fss.or.kr/api'; // FIXED

  // KIS — 시세 조회는 반드시 "실전투자" 키 필요 (모의투자 키 ❌)
  static const String kisAppKey = 'PSMrdCISdPsDd6dOJbStjs3SVW80gj9Z0QG2';     // ⚠️ 36자 (실전투자)
  static const String kisAppSecret = 'T0CkXvHoFPOwHcl1jW+cZEBU3SOMGBIKA0d3AEe+tlEcyfrNCnPyukTWq9pbKNgjRgQwJLsFBm3yt+0r8Hk89DBPmkYEsBaopnx9OU4/zdTL5mJ/5Zf1YM7b9UwmEsUSnx/AkY4ol2Urcm6MYjVnP0d70FJs4AQL50vFprNibz5A51xk5jY=';  // ⚠️ 180자 (실전투자)
  static const String kisBaseUrl = 'https://openapi.koreainvestment.com:9443';

  // KRX
  static const String krxBaseUrl = 'http://data.krx.co.kr';

  // 캐시
  static const Duration priceCacheDuration = Duration(minutes: 5);
  static const Duration dividendCacheDuration = Duration(days: 1);
  static const Duration corpCodeCacheDuration = Duration(days: 7);
  static const int dividendHistoryYears = 5;

  static String? validate() {
    if (openDartApiKey.isEmpty) return 'OpenDART API 키 미입력';
    if (kisAppKey.isEmpty || kisAppSecret.isEmpty) return 'KIS API 키 미입력 (실전투자)';
    if (kisAppKey.length != 36) return 'KIS AppKey는 36자여야 합니다';
    return null;
  }

  static bool get isConfigured => validate() == null;
}