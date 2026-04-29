import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stock_model.dart';
import '../services/stock_data_service.dart';
import '../services/forecast_engine.dart';

// ─────────────────────────────────────────
// 사용자 목표 설정 Provider (변경 없음)
// ─────────────────────────────────────────
class UserGoalNotifier extends StateNotifier<UserGoal> {
  UserGoalNotifier()
      : super(const UserGoal(
          monthlyTarget: 2000000,
          profile: InvestmentProfile.stable,
          preferredSectors: [StockSector.all],
          investmentBudget: 50000000,
        ));

  void updateMonthlyTarget(int amount) =>
      state = _copy(monthlyTarget: amount);
  void updateProfile(InvestmentProfile profile) => state = _copy(profile: profile);
  void updateSectors(List<StockSector> sectors) => state = _copy(sectors: sectors);
  void updateBudget(int budget) => state = _copy(budget: budget);

  UserGoal _copy({
    int? monthlyTarget,
    InvestmentProfile? profile,
    List<StockSector>? sectors,
    int? budget,
  }) =>
      UserGoal(
        monthlyTarget: monthlyTarget ?? state.monthlyTarget,
        profile: profile ?? state.profile,
        preferredSectors: sectors ?? state.preferredSectors,
        investmentBudget: budget ?? state.investmentBudget,
      );
}

final userGoalProvider =
    StateNotifierProvider<UserGoalNotifier, UserGoal>((ref) {
  return UserGoalNotifier();
});

// ─────────────────────────────────────────
// StockDataService 싱글턴 Provider
// ─────────────────────────────────────────
final stockServiceProvider = Provider<StockDataService>((ref) {
  return StockDataService.instance;
});

// ─────────────────────────────────────────
// 전체 추천 종목 (async)
// ─────────────────────────────────────────
final allStocksProvider = FutureProvider<List<StockModel>>((ref) async {
  final service = ref.watch(stockServiceProvider);
  return service.getRecommendedStocks();
});

// ─────────────────────────────────────────
// 추천 포트폴리오 (목표 + 성향 + 섹터 기반)
// ─────────────────────────────────────────
final recommendedPortfolioProvider =
    FutureProvider<Map<StockModel, int>>((ref) async {
  final goal = ref.watch(userGoalProvider);
  final service = ref.watch(stockServiceProvider);
  return service.recommendPortfolio(
    monthlyGoal: goal.monthlyTarget,
    profile: goal.profile,
    preferredSectors: goal.preferredSectors,
  );
});

// ─────────────────────────────────────────
// 포트폴리오 미래 예측
// ─────────────────────────────────────────
final portfolioForecastProvider =
    FutureProvider<PortfolioForecast>((ref) async {
  final portfolio = await ref.watch(recommendedPortfolioProvider.future);
  return ForecastEngine.forecastPortfolio(
    portfolio: portfolio,
    targetYears: 3,
  );
});

// ─────────────────────────────────────────
// 선택된 섹터 필터
// ─────────────────────────────────────────
final selectedSectorProvider =
    StateProvider<StockSector>((ref) => StockSector.all);

// ─────────────────────────────────────────
// 섹터로 필터링된 주식 리스트
// ─────────────────────────────────────────
final filteredStocksProvider =
    FutureProvider<List<StockModel>>((ref) async {
  final selectedSector = ref.watch(selectedSectorProvider);
  final goal = ref.watch(userGoalProvider);
  final all = await ref.watch(allStocksProvider.future);

  var filtered = selectedSector == StockSector.all
      ? all
      : all.where((s) => s.sector == selectedSector).toList();

  // 사용자 성향 매칭 우선 정렬
  filtered.sort((a, b) {
    bool aMatch = a.suitableFor.contains(goal.profile);
    bool bMatch = b.suitableFor.contains(goal.profile);
    if (aMatch && !bMatch) return -1;
    if (!aMatch && bMatch) return 1;
    return b.dividendYield.compareTo(a.dividendYield);
  });
  return filtered;
});

// ─────────────────────────────────────────
// 사용자 보유 포트폴리오 (보유 종목 관리)
// ─────────────────────────────────────────
class PortfolioNotifier extends StateNotifier<List<PortfolioItem>> {
  PortfolioNotifier() : super([]);

  void addStock(StockModel stock, int shares, double avgPrice) {
    state = [
      ...state,
      PortfolioItem(stock: stock, shares: shares, avgPrice: avgPrice)
    ];
  }

  void removeStock(String code) {
    state = state.where((item) => item.stock.code != code).toList();
  }

  double get totalMonthlyDividend =>
      state.fold(0.0, (sum, item) => sum + item.monthlyDividend);

  double get totalValue =>
      state.fold(0.0, (sum, item) => sum + item.totalValue);
}

final portfolioProvider =
    StateNotifierProvider<PortfolioNotifier, List<PortfolioItem>>((ref) {
  return PortfolioNotifier();
});

// ─────────────────────────────────────────
// 단일 종목 상세조회 (상세화면용)
// ─────────────────────────────────────────
final stockDetailProvider =
    FutureProvider.family<StockModel?, String>((ref, code) async {
  final service = ref.watch(stockServiceProvider);
  return service.fetchStock(code);
});
