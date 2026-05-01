import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/stock_model.dart';
import '../services/stock_data_service.dart';
import '../services/forecast_engine.dart';
import '../algorithms/persona_profile.dart';
import '../algorithms/recommendation_engine.dart';

// ─────────────────────────────────────────
// PersonaProfile Provider (퀴즈 결과)
// SharedPreferences에 영구 저장 → 앱 재시작해도 유지
// ─────────────────────────────────────────
class PersonaProfileNotifier extends StateNotifier<PersonaProfile?> {
  PersonaProfileNotifier() : super(null) {
    _loadFromDisk();
  }

  static const _key = 'persona_profile_v1';

  Future<void> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      state = PersonaProfile(
        horizon: (m['horizon'] as num).toDouble(),
        cashflowPreference: (m['cashflowPreference'] as num).toDouble(),
        downsideTolerance: (m['downsideTolerance'] as num).toDouble(),
        taxSensitivity: (m['taxSensitivity'] as num).toDouble(),
        liquidityNeed: (m['liquidityNeed'] as num).toDouble(),
        ethicsLooseness: (m['ethicsLooseness'] as num).toDouble(),
        diversificationDemand: (m['diversificationDemand'] as num).toDouble(),
        inflationHedge: (m['inflationHedge'] as num).toDouble(),
        monthlyTarget: m['monthlyTarget'] as int,
        budget: m['budget'] as int,
        preferredSectors: List<String>.from(m['preferredSectors'] ?? []),
        excludedSectors: List<String>.from(m['excludedSectors'] ?? []),
      );
    } catch (_) {
      // 파싱 실패하면 무시 (재퀴즈하면 됨)
    }
  }

  Future<void> setProfile(PersonaProfile p) async {
    state = p;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode({
      'horizon': p.horizon,
      'cashflowPreference': p.cashflowPreference,
      'downsideTolerance': p.downsideTolerance,
      'taxSensitivity': p.taxSensitivity,
      'liquidityNeed': p.liquidityNeed,
      'ethicsLooseness': p.ethicsLooseness,
      'diversificationDemand': p.diversificationDemand,
      'inflationHedge': p.inflationHedge,
      'monthlyTarget': p.monthlyTarget,
      'budget': p.budget,
      'preferredSectors': p.preferredSectors,
      'excludedSectors': p.excludedSectors,
    }));
  }

  Future<void> clear() async {
    state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final personaProfileProvider =
StateNotifierProvider<PersonaProfileNotifier, PersonaProfile?>((ref) {
  return PersonaProfileNotifier();
});

// ─────────────────────────────────────────
// 추천 포트폴리오 Provider — 진짜 엔진 연결
// ─────────────────────────────────────────
final portfolioRecommendationProvider =
Provider<PortfolioRecommendation?>((ref) {
  final persona = ref.watch(personaProfileProvider);
  if (persona == null) return null;

  return RecommendationEngine.buildPortfolio(
    persona: persona,
    universe: StockDataService.allStocks,
  );
});

// 추천 포트폴리오를 Map<StockModel, int>로 변환 (캘린더/예측용)
final recommendedPortfolioMapProvider = Provider<Map<StockModel, int>>((ref) {
  final rec = ref.watch(portfolioRecommendationProvider);
  return rec?.toMap() ?? {};
});

// ─────────────────────────────────────────
// 추천 포트폴리오 미래 예측
// ─────────────────────────────────────────
final portfolioForecastProvider = Provider<PortfolioForecast?>((ref) {
  final portfolio = ref.watch(recommendedPortfolioMapProvider);
  if (portfolio.isEmpty) return null;
  return ForecastEngine.forecastPortfolio(
    portfolio: portfolio,
    targetYears: 3,
  );
});

// ─────────────────────────────────────────
// 추천 포트폴리오의 월별 배당금 (캘린더용)
// ─────────────────────────────────────────
final monthlyDividendCalendarProvider = Provider<List<double>>((ref) {
  final rec = ref.watch(portfolioRecommendationProvider);
  if (rec == null) return List.filled(12, 0.0);

  final monthly = List.filled(12, 0.0);
  for (final pick in rec.picks) {
    final stock = pick.stock;
    final shares = pick.shares;
    final annualPerShare =
    stock.dividendPerShare > 0 ? stock.dividendPerShare : stock.latestDividend;
    if (annualPerShare == 0 || stock.paymentMonths.isEmpty) continue;
    final perPayment = (annualPerShare / stock.paymentMonths.length) * shares;
    for (final m in stock.paymentMonths) {
      if (m >= 1 && m <= 12) monthly[m - 1] += perPayment;
    }
  }
  return monthly;
});