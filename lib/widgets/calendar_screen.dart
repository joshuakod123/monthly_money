import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolio = ref.watch(portfolioProvider);

    // 1~12월까지의 실제 월별 배당금 계산
    List<double> monthlyPayouts = List.filled(12, 0.0);
    for (int month = 1; month <= 12; month++) {
      double totalForMonth = 0;
      for (var item in portfolio) {
        totalForMonth += item.getActualDividendForMonth(month); // 새로운 로직 적용
      }
      monthlyPayouts[month - 1] = totalForMonth;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('배당 캘린더', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      body: portfolio.isEmpty
          ? const Center(
        child: Text('포트폴리오에 주식을 추가하면\n월별 배당 내역이 표시됩니다.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5)),
      )
          : ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: 12,
        itemBuilder: (context, index) {
          int month = index + 1;
          double payout = monthlyPayouts[index];

          // 해당 월에 실제로 배당을 주는 주식 리스트 필터링
          var payingStocks = portfolio.where((item) => item.getActualDividendForMonth(month) > 0).toList();

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: payout > 0 ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$month월', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    if (payout > 0)
                      Text(formatKRW(payout), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: -0.5))
                    else
                      const Text('지급 없음', style: TextStyle(fontSize: 14, color: AppColors.textHint)),
                  ],
                ),
                if (payingStocks.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 12),
                  ...payingStocks.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${item.stock.name} (${item.shares}주)', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          Text(formatKRW(item.getActualDividendForMonth(month)), style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    );
                  }),
                ]
              ],
            ),
          );
        },
      ),
    );
  }
}