import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stock_model.dart';
import '../services/stock_data_service.dart';
import '../services/forecast_engine.dart';
import '../algorithms/persona_profile.dart';

// ─────────────────────────────────────────
// 사용자 목표 설정 Provider
// ─────────────────────────────────────────
class UserGoalNotifier extends StateNotifier<UserGoal> {
  UserGoalNotifier()
      : super(const UserGoal(
    monthlyTarget: 2000000,
    profile: InvestmentProfile.stable,
    preferredSectors: [StockSector.all],
    investmentBudget: 50000000,
  ));

  void updateMonthlyTarget(int amount) {
    state = UserGoal(
      monthlyTarget: amount,
      profile: state.profile,
      preferredSectors: state.preferredSectors,
      investmentBudget: state.investmentBudget,
    );
  }

  void updateProfile(InvestmentProfile profile) {
    state = UserGoal(
      monthlyTarget: state.monthlyTarget,
      profile: profile,
      preferredSectors: state.preferredSectors,
      investmentBudget: state.investmentBudget,
    );
  }

  void updateSectors(List<StockSector> sectors) {
    state = UserGoal(
      monthlyTarget: state.monthlyTarget,
      profile: state.profile,
      preferredSectors: sectors,
      investmentBudget: state.investmentBudget,
    );
  }

  void updateBudget(int budget) {
    state = UserGoal(
      monthlyTarget: state.monthlyTarget,
      profile: state.profile,
      preferredSectors: state.preferredSectors,
      investmentBudget: budget,
    );
  }
}

final userGoalProvider =
StateNotifierProvider<UserGoalNotifier, UserGoal>((ref) {
  return UserGoalNotifier();
});

// ─────────────────────────────────────────
// PersonaProfile Provider — 퀴즈 결과
// (퀴즈 미완료 상태는 null)
// ─────────────────────────────────────────
final personaProfileProvider = StateProvider<PersonaProfile?>((ref) => null);

// ─────────────────────────────────────────
// 추천 포트폴리오 Provider (목표 + 성향 기반)
// ─────────────────────────────────────────
final recommendedPortfolioProvider = Provider<Map<StockModel, int>>((ref) {
  final goal = ref.watch(userGoalProvider);
  return StockDataService.recommendPortfolio(
    monthlyGoal: goal.monthlyTarget,
    profile: goal.profile,
    preferredSectors: goal.preferredSectors,
  );
});

// ─────────────────────────────────────────
// 추천 포트폴리오 미래 예측 Provider
// ─────────────────────────────────────────
final portfolioForecastProvider = Provider<PortfolioForecast>((ref) {
  final portfolio = ref.watch(recommendedPortfolioProvider);
  return ForecastEngine.forecastPortfolio(
    portfolio: portfolio,
    targetYears: 3,
  );
});

// ─────────────────────────────────────────
// 선택된 섹터 필터 Provider
// ─────────────────────────────────────────
final selectedSectorProvider =
StateProvider<StockSector>((ref) => StockSector.all);

// ─────────────────────────────────────────
// 필터링된 주식 리스트 Provider
// ─────────────────────────────────────────
final filteredStocksProvider = Provider<List<StockModel>>((ref) {
  final selectedSector = ref.watch(selectedSectorProvider);
  final goal = ref.watch(userGoalProvider);

  var stocks = StockDataService.getBySector(selectedSector);
  // 성향 매칭 우선 정렬
  stocks.sort((a, b) {
    bool aMatch = a.suitableFor.contains(goal.profile);
    bool bMatch = b.suitableFor.contains(goal.profile);
    if (aMatch && !bMatch) return -1;
    if (!aMatch && bMatch) return 1;
    return b.dividendYield.compareTo(a.dividendYield);
  });
  return stocks;
});

// ─────────────────────────────────────────
// 사용자 보유 포트폴리오 Provider (실제 보유)
// ─────────────────────────────────────────
class PortfolioNotifier extends StateNotifier<List<PortfolioItem>> {
  PortfolioNotifier()
      : super(_initialDemoPortfolio());

  static List<PortfolioItem> _initialDemoPortfolio() {
    final all = StockDataService.allStocks;
    if (all.isEmpty) return [];
    final items = <PortfolioItem>[];
    items.add(PortfolioItem(
      stock: all.first,
      shares: 100,
      avgPrice: all.first.price * 0.85,
    ));
    if (all.length > 10) {
      items.add(PortfolioItem(
        stock: all[10],
        shares: 500,
        avgPrice: all[10].price * 0.9,
      ));
    }
    return items;
  }

  void addStock(StockModel stock, int shares, double avgPrice) {
    state = [
      ...state,
      PortfolioItem(stock: stock, shares: shares, avgPrice: avgPrice),
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