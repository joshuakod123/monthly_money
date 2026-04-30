import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../algorithms/persona_profile.dart';
import '../algorithms/recommendation_engine.dart';
import '../models/stock_model.dart';
import '../services/stock_data_service.dart';
import '../services/forecast_engine.dart';

/// ═══════════════════════════════════════════════════════════
///  Persona-driven Providers
/// ═══════════════════════════════════════════════════════════

/// 사용자 페르소나 (스무고개 결과)
/// null이면 아직 퀴즈 안 한 상태 → 퀴즈 권유
final personaProfileProvider = StateProvider<PersonaProfile?>((ref) => null);

/// StockDataService 싱글턴
final stockServiceProvider = Provider<StockDataService>((ref) {
  return StockDataService.instance;
});

/// 전체 종목 universe
final allStocksProvider = FutureProvider<List<StockModel>>((ref) async {
  final service = ref.watch(stockServiceProvider);
  return service.getRecommendedStocks();
});

/// 페르소나 기반 추천 (퀴즈 안 했으면 빈 결과)
final personalizedRecommendationProvider =
FutureProvider<PortfolioRecommendation?>((ref) async {
  final persona = ref.watch(personaProfileProvider);
  if (persona == null) return null;
  final universe = await ref.watch(allStocksProvider.future);
  return RecommendationEngine.buildPortfolio(
    persona: persona,
    universe: universe,
  );
});

/// 미래 예측
final portfolioForecastProvider =
FutureProvider<PortfolioForecast?>((ref) async {
  final rec = await ref.watch(personalizedRecommendationProvider.future);
  if (rec == null) return null;
  return ForecastEngine.forecastPortfolio(
    portfolio: rec.toMap(),
    targetYears: 3,
  );
});

/// 섹터 필터 (홈 화면용)
final selectedSectorProvider =
StateProvider<StockSector>((ref) => StockSector.all);

/// 필터링된 종목 리스트 (페르소나 점수로 정렬)
final filteredStocksProvider =
FutureProvider<List<StockModel>>((ref) async {
  final selectedSector = ref.watch(selectedSectorProvider);
  final persona = ref.watch(personaProfileProvider);
  final all = await ref.watch(allStocksProvider.future);

  var filtered = selectedSector == StockSector.all
      ? all
      : all.where((s) => s.sector == selectedSector).toList();

  if (persona != null) {
    // 페르소나 점수로 정렬
    filtered.sort((a, b) {
      final sa = RecommendationEngine.scoreStock(stock: a, persona: persona);
      final sb = RecommendationEngine.scoreStock(stock: b, persona: persona);
      return sb.compareTo(sa);
    });
  } else {
    // 페르소나 없으면 배당수익률 순
    filtered.sort((a, b) => b.dividendYield.compareTo(a.dividendYield));
  }
  return filtered;
});

/// 보유 포트폴리오 (실제 보유 종목)
class PortfolioNotifier extends StateNotifier<List<PortfolioItem>> {
  PortfolioNotifier() : super([]);

  void add(StockModel stock, int shares, double avgPrice) {
    state = [
      ...state,
      PortfolioItem(stock: stock, shares: shares, avgPrice: avgPrice),
    ];
  }

  void remove(String code) {
    state = state.where((p) => p.stock.code != code).toList();
  }

  double get totalMonthlyDividend =>
      state.fold(0.0, (a, p) => a + p.monthlyDividend);

  double get totalValue => state.fold(0.0, (a, p) => a + p.totalValue);
}

final portfolioProvider =
StateNotifierProvider<PortfolioNotifier, List<PortfolioItem>>((ref) {
  return PortfolioNotifier();
});

/// 단일 종목 상세
final stockDetailProvider =
FutureProvider.family<StockModel?, String>((ref, code) async {
  final service = ref.watch(stockServiceProvider);
  return service.fetchStock(code);
});

/// ─────────────────────────────────────────────────
/// User Goal Notifier
/// ─────────────────────────────────────────────────
class UserGoalNotifier extends StateNotifier<UserGoal> {
  UserGoalNotifier() : super(UserGoal.initial());

  void updateMonthlyTarget(int target) {
    state = state.copyWith(monthlyTarget: target);
  }

  void updateProfile(InvestmentProfile profile) {
    state = state.copyWith(profile: profile);
  }

  void updateSectors(List<StockSector> sectors) {
    state = state.copyWith(preferredSectors: sectors);
  }
}

final userGoalProvider = StateNotifierProvider<UserGoalNotifier, UserGoal>((ref) {
  return UserGoalNotifier();
});