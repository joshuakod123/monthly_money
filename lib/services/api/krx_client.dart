import 'package:dio/dio.dart';
import 'api_config.dart';

/// ═══════════════════════════════════════════════════════════
///  KRX (한국거래소) 정보데이터시스템 Client
///
///  - 전체 상장종목 마스터 (KOSPI/KOSDAQ)
///  - 섹터/업종 분류 정보
///  - data.krx.co.kr 의 OTP 기반 비공식 API 사용
///
///  ⚠️ KRX는 공식 OpenAPI가 없고, 데이터센터에서
///     CSV 다운로드용 비공식 엔드포인트를 사용함
///     상업적 사용 시 별도 라이선스 협의 필요
/// ═══════════════════════════════════════════════════════════
class KrxClient {
  final Dio _dio;

  KrxClient()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConfig.krxBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
            'Referer': 'http://data.krx.co.kr/',
          },
        ));

  /// ─────────────────────────────────────────────────
  /// 전체 상장종목 리스트 조회 (KOSPI + KOSDAQ)
  /// 종목코드, 종목명, 시장구분, 업종 정보 포함
  /// ─────────────────────────────────────────────────
  Future<List<KrxStockMaster>> getAllListedStocks() async {
    try {
      // ① OTP 발급
      final otpResponse = await _dio.post<String>(
        '/comm/fileDn/GenerateOTP/generate.cmd',
        data: {
          'mktId': 'ALL', // 전체 시장
          'share': '1',
          'csvxls_isNo': 'false',
          'name': 'fileDown',
          'url': 'dbms/MDC/STAT/standard/MDC0201020506',
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          responseType: ResponseType.plain,
        ),
      );

      final otp = otpResponse.data ?? '';

      // ② OTP로 CSV 다운로드
      final csvResponse = await _dio.post<List<int>>(
        '/comm/fileDn/download_csv/download.cmd',
        data: {'code': otp},
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          responseType: ResponseType.bytes,
        ),
      );

      // KRX는 EUC-KR 인코딩
      final csvText = _decodeEucKr(csvResponse.data!);
      return _parseStockMasterCsv(csvText);
    } on DioException catch (e) {
      throw KrxException('상장종목 조회 실패: ${e.message}');
    }
  }

  // ─────────────────────────────────────
  // EUC-KR 디코딩 (Dart는 UTF-8 기본)
  // 실제로는 charset_converter 패키지 필요
  // 여기서는 fallback 으로 UTF-8 시도
  // ─────────────────────────────────────
  String _decodeEucKr(List<int> bytes) {
    try {
      // pub: charset_converter 추가 후
      // return await CharsetConverter.decode("EUC-KR", bytes);
      return String.fromCharCodes(bytes);
    } catch (_) {
      return String.fromCharCodes(bytes);
    }
  }

  List<KrxStockMaster> _parseStockMasterCsv(String csv) {
    final lines = csv.split('\n');
    if (lines.length < 2) return [];

    final List<KrxStockMaster> result = [];
    // 첫 줄은 헤더
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final cols = line.split(',').map((c) => c.replaceAll('"', '').trim()).toList();
      if (cols.length < 4) continue;

      result.add(KrxStockMaster(
        code: cols[0],
        name: cols[1],
        market: cols[2],
        sector: cols.length > 3 ? cols[3] : '',
      ));
    }
    return result;
  }
}

/// KRX 상장종목 마스터
class KrxStockMaster {
  final String code;     // 종목코드 (6자리)
  final String name;     // 종목명
  final String market;   // KOSPI / KOSDAQ
  final String sector;   // 업종 (예: 은행 / 통신서비스 / 부동산투자)

  const KrxStockMaster({
    required this.code,
    required this.name,
    required this.market,
    required this.sector,
  });

  /// 섹터명을 앱 내부 카테고리로 매핑
  /// (예: "은행" → finance, "통신서비스" → telecom)
  String mapToAppSector() {
    if (sector.contains('은행') || sector.contains('금융') || sector.contains('보험')) {
      return 'finance';
    }
    if (sector.contains('통신')) return 'telecom';
    if (sector.contains('전기') || sector.contains('가스') || sector.contains('에너지')) {
      return 'energy';
    }
    if (sector.contains('부동산') || sector.contains('리츠') || sector.contains('REIT')) {
      return 'reit';
    }
    if (sector.contains('식품') || sector.contains('음료') || sector.contains('소매')) {
      return 'consumer';
    }
    if (sector.contains('의약') || sector.contains('헬스') || sector.contains('의료')) {
      return 'healthcare';
    }
    return 'industrial';
  }
}

class KrxException implements Exception {
  final String message;
  KrxException(this.message);
  @override
  String toString() => 'KrxException: $message';
}
