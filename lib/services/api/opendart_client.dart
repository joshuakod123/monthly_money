import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:xml/xml.dart' as xml;
import 'package:archive/archive.dart';
import 'api_config.dart';

/// ═══════════════════════════════════════════════════════════
///  OpenDART API Client
///
///  - 금융감독원 전자공시 시스템 OpenAPI
///  - 배당 historical 의 메인 소스 (사업보고서 기반)
///  - 무료, 일일 호출 제한 10,000회 (개인 기준)
/// ═══════════════════════════════════════════════════════════
class OpenDartClient {
  final Dio _dio;
  // 종목코드 → 고유번호(corp_code) 매핑 캐시
  static final Map<String, String> _corpCodeMap = {};
  static DateTime? _corpCodeCachedAt;

  OpenDartClient()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConfig.openDartBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ));

  /// ─────────────────────────────────────────────────
  /// 1️⃣ 종목코드 → 고유번호 매핑 (corpCode.xml)
  /// 처음 1회만 다운로드, 이후 메모리에 캐싱
  /// ─────────────────────────────────────────────────
  Future<void> loadCorpCodeMap() async {
    final isCacheValid = _corpCodeCachedAt != null &&
        DateTime.now().difference(_corpCodeCachedAt!) <
            ApiConfig.corpCodeCacheDuration;
    if (_corpCodeMap.isNotEmpty && isCacheValid) return;

    try {
      // ZIP으로 받음
      final response = await _dio.get<List<int>>(
        '/corpCode.xml',
        queryParameters: {'crtfc_key': ApiConfig.openDartApiKey},
        options: Options(responseType: ResponseType.bytes),
      );

      // ZIP 압축 해제
      final archive = ZipDecoder().decodeBytes(response.data!);
      final xmlFile = archive.firstWhere(
            (f) => f.name.toUpperCase() == 'CORPCODE.XML',
        orElse: () => throw OpenDartException('CORPCODE.xml 없음'),
      );
      final xmlContent = utf8.decode(xmlFile.content as List<int>);

      // XML 파싱
      final document = xml.XmlDocument.parse(xmlContent);
      _corpCodeMap.clear();

      for (final corp in document.findAllElements('list')) {
        final stockCode =
            corp.findElements('stock_code').firstOrNull?.innerText.trim();
        final corpCode =
            corp.findElements('corp_code').firstOrNull?.innerText.trim();

        // stock_code가 비어있지 않은 경우만 (=상장사)
        if (stockCode != null &&
            stockCode.isNotEmpty &&
            corpCode != null &&
            corpCode.isNotEmpty) {
          _corpCodeMap[stockCode] = corpCode;
        }
      }

      _corpCodeCachedAt = DateTime.now();
    } on DioException catch (e) {
      throw OpenDartException('고유번호 매핑 로드 실패: ${e.message}');
    }
  }

  String? getCorpCode(String stockCode) => _corpCodeMap[stockCode];

  /// ─────────────────────────────────────────────────
  /// 2️⃣ 배당에 관한 사항 조회 (alotMatter)
  /// 정기보고서(사업, 분기, 반기보고서) 내 배당 정보
  /// ─────────────────────────────────────────────────
  ///
  /// reprt_code:
  ///   11011: 사업보고서 (연간) ← 배당 조회는 이걸 사용
  ///   11012: 반기보고서
  ///   11013: 1분기보고서
  ///   11014: 3분기보고서
  Future<DividendData?> getDividendInfo({
    required String stockCode,
    required int year,
  }) async {
    if (_corpCodeMap.isEmpty) await loadCorpCodeMap();

    final corpCode = _corpCodeMap[stockCode];
    if (corpCode == null) {
      throw OpenDartException('종목코드 $stockCode 의 고유번호를 찾을 수 없습니다.');
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/alotMatter.json',
        queryParameters: {
          'crtfc_key': ApiConfig.openDartApiKey,
          'corp_code': corpCode,
          'bsns_year': year.toString(),
          'reprt_code': '11011', // 사업보고서
        },
      );

      final data = response.data!;
      final status = data['status'] as String?;

      if (status != '000') {
        // 013: 조회된 데이타가 없음 (해당 연도에 사업보고서 미제출 등)
        if (status == '013') return null;
        throw OpenDartException('OpenDART 에러: $status / ${data['message']}');
      }

      final list = data['list'] as List<dynamic>?;
      if (list == null || list.isEmpty) return null;

      return DividendData.fromOpenDartList(list, year);
    } on DioException catch (e) {
      throw OpenDartException('배당정보 조회 실패: ${e.message}');
    }
  }

  /// ─────────────────────────────────────────────────
  /// 3️⃣ 최근 N년치 배당 historical 일괄 조회
  /// ─────────────────────────────────────────────────
  Future<List<DividendData>> getDividendHistory({
    required String stockCode,
    int years = 5,
  }) async {
    final currentYear = DateTime.now().year;
    final startYear = currentYear - years;
    final List<DividendData> results = [];

    // 병렬로 N년치 가져오기 (속도 최적화)
    final futures = List.generate(
      years,
      (i) => getDividendInfo(stockCode: stockCode, year: currentYear - 1 - i),
    );

    final responses = await Future.wait(futures, eagerError: false);
    for (final r in responses) {
      if (r != null) results.add(r);
    }

    results.sort((a, b) => a.year.compareTo(b.year));
    return results;
  }

  /// ─────────────────────────────────────────────────
  /// 4️⃣ 재무제표 주요 항목 (ROE, EPS 추정용)
  /// fnlttSinglAcntAll API
  /// ─────────────────────────────────────────────────
  Future<FinancialData?> getFinancialData({
    required String stockCode,
    required int year,
  }) async {
    if (_corpCodeMap.isEmpty) await loadCorpCodeMap();
    final corpCode = _corpCodeMap[stockCode];
    if (corpCode == null) return null;

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/fnlttSinglAcntAll.json',
        queryParameters: {
          'crtfc_key': ApiConfig.openDartApiKey,
          'corp_code': corpCode,
          'bsns_year': year.toString(),
          'reprt_code': '11011',
          'fs_div': 'CFS', // 연결재무제표
        },
      );

      final data = response.data!;
      if (data['status'] != '000') return null;

      return FinancialData.fromOpenDart(data['list'], year);
    } on DioException {
      return null;
    }
  }
}

/// 배당 데이터 (한 회사 한 연도)
class DividendData {
  final int year;
  final int? cashDividendPerShare;     // 주당 현금배당금 (원)
  final double? cashDividendYield;     // 현금배당수익률 (%)
  final double? cashDividendPayoutRatio; // 현금배당성향 (%)
  final int? totalCashDividend;        // 현금배당금총액 (원)
  final int? eps;                      // 주당순이익
  final int? netIncome;                // 당기순이익
  final String? stockKind;             // 보통주 / 우선주

  const DividendData({
    required this.year,
    this.cashDividendPerShare,
    this.cashDividendYield,
    this.cashDividendPayoutRatio,
    this.totalCashDividend,
    this.eps,
    this.netIncome,
    this.stockKind,
  });

  /// OpenDART 배당 응답 파싱
  /// list 안에 여러 행이 있고, 각 행은 se(항목명) 별로 내용이 다름
  /// 예: se="주당 현금배당금(원)" / thstrm="3,910" / frmtrm="3,510"
  factory DividendData.fromOpenDartList(List<dynamic> list, int year) {
    int? perShare;
    double? yieldVal;
    double? payoutRatio;
    int? total;
    String? stockKind;

    for (final row in list) {
      final se = (row['se'] as String?)?.trim() ?? '';
      // 보통주만 (우선주는 별도 처리 필요)
      final kind = (row['stock_knd'] as String?)?.trim();
      if (kind != null && kind.contains('우선주')) continue;
      stockKind ??= kind;

      // 당기 값 (thstrm = 当期, 가장 최근 연도)
      final thstrm = (row['thstrm'] as String?)?.replaceAll(',', '').trim();
      if (thstrm == null || thstrm.isEmpty || thstrm == '-') continue;

      final num = double.tryParse(thstrm);
      if (num == null) continue;

      if (se.contains('주당') && se.contains('현금배당')) {
        perShare = num.toInt();
      } else if (se.contains('현금배당수익률')) {
        yieldVal = num;
      } else if (se.contains('현금배당성향')) {
        payoutRatio = num;
      } else if (se.contains('현금배당금총액')) {
        total = num.toInt();
      }
    }

    return DividendData(
      year: year,
      cashDividendPerShare: perShare,
      cashDividendYield: yieldVal,
      cashDividendPayoutRatio: payoutRatio,
      totalCashDividend: total,
      stockKind: stockKind,
    );
  }
}

/// 재무제표 데이터 (ROE 산출용)
class FinancialData {
  final int year;
  final int? totalEquity;      // 자본총계
  final int? netIncome;        // 당기순이익
  final int? totalAssets;      // 자산총계
  final int? operatingProfit;  // 영업이익
  final int? revenue;          // 매출액

  const FinancialData({
    required this.year,
    this.totalEquity,
    this.netIncome,
    this.totalAssets,
    this.operatingProfit,
    this.revenue,
  });

  /// ROE = 당기순이익 / 자본총계 × 100
  double? get roe {
    if (totalEquity == null || netIncome == null || totalEquity == 0) return null;
    return (netIncome! / totalEquity!) * 100;
  }

  /// ROA = 당기순이익 / 자산총계 × 100
  double? get roa {
    if (totalAssets == null || netIncome == null || totalAssets == 0) return null;
    return (netIncome! / totalAssets!) * 100;
  }

  factory FinancialData.fromOpenDart(dynamic list, int year) {
    int? equity, ni, assets, op, rev;
    if (list is List) {
      for (final row in list) {
        final accountId = row['account_id'] as String? ?? '';
        final amount = (row['thstrm_amount'] as String?)
            ?.replaceAll(',', '')
            .replaceAll('-', '-');
        final value = int.tryParse(amount ?? '');
        if (value == null) continue;

        // IFRS 표준 계정 ID 매핑
        if (accountId.contains('Equity')) equity = value;
        if (accountId.contains('ProfitLoss') && accountId.contains('Net')) ni = value;
        if (accountId.contains('Assets') && !accountId.contains('Current')) assets = value;
        if (accountId.contains('OperatingIncome')) op = value;
        if (accountId.contains('Revenue')) rev = value;
      }
    }
    return FinancialData(
      year: year,
      totalEquity: equity,
      netIncome: ni,
      totalAssets: assets,
      operatingProfit: op,
      revenue: rev,
    );
  }
}

class OpenDartException implements Exception {
  final String message;
  OpenDartException(this.message);
  @override
  String toString() => 'OpenDartException: $message';
}
