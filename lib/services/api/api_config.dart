/// ═══════════════════════════════════════════════════════════
///  API 설정
/// ═══════════════════════════════════════════════════════════
///
/// 발급 방법:
///
/// 1. OpenDART (배당 historical 데이터) - 무료, 즉시 발급
///    https://opendart.fss.or.kr → 인증키 신청/관리
///    → 발급된 40자 키를 OPENDART_API_KEY 에 입력
///
/// 2. 한국투자증권 KIS Open API (실시간 시세) - 무료
///    https://apiportal.koreainvestment.com → 회원가입 → 앱 등록
///    → AppKey (36자), AppSecret (180자)
///    ⚠️ 모의투자/실전투자 키가 다름. 모의는 vts.koreainvestment.com 사용
///
/// 3. KRX 정보데이터시스템 (종목 마스터)
///    http://data.krx.co.kr → 별도 키 불필요, OTP 기반
///    실제 운영시에는 종목 마스터를 미리 다운받아 캐싱하는 것을 권장
///
/// ⚠️ 보안: 실 배포에서는 .env 파일이나 secure storage(flutter_secure_storage)에 저장
///        절대 git 에 commit 하지 말 것
///
class ApiConfig {
  // ──────────────────────────────────────
  // OpenDART (금융감독원 전자공시)
  // ──────────────────────────────────────
  static const String openDartApiKey = '';
  static const String openDartBaseUrl = '';

  // ──────────────────────────────────────
  // KIS (한국투자증권)
  // ──────────────────────────────────────
  // 실전투자
  static const String kisAppKey = '';
  static const String kisAppSecret = '';
  static const String kisBaseUrl = 'https://openapi.koreainvestment.com:9443';

  // 모의투자 (개발/테스트용)
  static const String kisMockBaseUrl = 'https://openapivts.koreainvestment.com:29443';
  static const bool useMockTrading = true; // 개발 중에는 true

  static String get currentKisUrl =>
      useMockTrading ? kisMockBaseUrl : kisBaseUrl;

  // ──────────────────────────────────────
  // KRX 정보데이터
  // ──────────────────────────────────────
  static const String krxBaseUrl = 'http://data.krx.co.kr';

  // ──────────────────────────────────────
  // 캐시 정책
  // ──────────────────────────────────────
  static const Duration priceCacheDuration = Duration(minutes: 5);
  static const Duration dividendCacheDuration = Duration(days: 1);
  static const Duration corpCodeCacheDuration = Duration(days: 7);

  // 배당 historical 조회 연도 (최근 N년)
  static const int dividendHistoryYears = 5;
}
