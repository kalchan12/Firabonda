import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/business_logic.dart';
import '../../../data/models/shop_models.dart';
import '../../../data/repositories/providers.dart';
import '../../settings/application/settings_controller.dart';

final selectedPeriodProvider = NotifierProvider<_PeriodNotifier, Period>(
  _PeriodNotifier.new,
);

final class _PeriodNotifier extends Notifier<Period> {
  @override
  Period build() => Period.today;

  void setPeriod(Period period) => state = period;
}

final class DashboardData {
  const DashboardData({
    required this.period,
    required this.spentCents,
    required this.earnedCents,
    required this.salesProfitCents,
    required this.expensesCents,
    required this.realProfitCents,
    required this.stockValueCents,
    required this.unsoldItemsCount,
    required this.bestSellers,
    required this.lowStockItems,
    required this.chartPoints,
  });

  final Period period;
  final int spentCents;
  final int earnedCents;
  final int salesProfitCents;
  final int expensesCents;
  final int realProfitCents;
  final int stockValueCents;
  final int unsoldItemsCount;
  final List<DashboardBestSeller> bestSellers;
  final List<PurchaseOverview> lowStockItems;
  final List<double> chartPoints;
}

final class DashboardBestSeller {
  const DashboardBestSeller({
    required this.categoryName,
    required this.quantitySold,
    required this.profitCents,
  });

  final String categoryName;
  final int quantitySold;
  final int profitCents;
}

final dashboardDataProvider = Provider<AsyncValue<DashboardData>>((ref) {
  final period = ref.watch(selectedPeriodProvider);
  final purchasesAsync = ref.watch(purchaseOverviewsStreamProvider);
  final salesAsync = ref.watch(saleOverviewsStreamProvider);
  final expensesAsync = ref.watch(expensesStreamProvider);
  final lowStockThreshold = ref.watch(lowStockThresholdProvider);

  if (purchasesAsync.isLoading ||
      salesAsync.isLoading ||
      expensesAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (purchasesAsync.hasError) {
    return AsyncValue.error(
      purchasesAsync.error!,
      purchasesAsync.stackTrace ?? StackTrace.current,
    );
  }
  if (salesAsync.hasError) {
    return AsyncValue.error(
      salesAsync.error!,
      salesAsync.stackTrace ?? StackTrace.current,
    );
  }
  if (expensesAsync.hasError) {
    return AsyncValue.error(
      expensesAsync.error!,
      expensesAsync.stackTrace ?? StackTrace.current,
    );
  }

  final allPurchases = purchasesAsync.value ?? [];
  final allSales = salesAsync.value ?? [];
  final allExpenses = expensesAsync.value ?? [];

  final nowUtc = DateTime.now().toUtc();
  final (startUtc, endUtc) = ShopLogic.periodWindowUtc(period, nowUtc);

  // 1. Spent in period (purchases created in this period)
  var spentCents = 0;
  for (final p in allPurchases) {
    final pDateUtc = p.date.isUtc ? p.date : p.date.toUtc();
    if (pDateUtc.isAfter(startUtc.subtract(const Duration(microseconds: 1))) &&
        pDateUtc.isBefore(endUtc)) {
      spentCents += p.totalCostCents;
    }
  }

  // 2. Sales in period
  final periodSales = allSales.where((s) {
    final sDateUtc = s.date.isUtc ? s.date : s.date.toUtc();
    return sDateUtc.isAfter(
          startUtc.subtract(const Duration(microseconds: 1)),
        ) &&
        sDateUtc.isBefore(endUtc);
  }).toList();

  var earnedCents = 0;
  var salesProfitCents = 0;
  for (final s in periodSales) {
    earnedCents += s.unitPriceCents * s.quantity;
    salesProfitCents += s.profitCents;
  }

  // 3. Expenses in period
  var expensesCents = 0;
  for (final e in allExpenses) {
    final eDateUtc = e.date.isUtc ? e.date : e.date.toUtc();
    if (eDateUtc.isAfter(startUtc.subtract(const Duration(microseconds: 1))) &&
        eDateUtc.isBefore(endUtc)) {
      expensesCents += e.amount;
    }
  }

  // 4. Real profit (sales profit minus expenses)
  final realProfitCents = ShopLogic.realProfit(
    salesProfitCents: salesProfitCents,
    expensesCents: expensesCents,
  );

  // 5. Stock value across active inventory
  final positions = allPurchases.map(
    (p) => StockPosition(
      quantityLeft: p.stockLeft,
      unitCostCents: p.unitCostCents,
    ),
  );
  final stockValueCents = ShopLogic.stockValue(positions);
  final unsoldItemsCount = allPurchases.fold<int>(
    0,
    (sum, p) => sum + p.stockLeft,
  );

  // 6. Low stock items
  final lowStockItems = allPurchases
      .where((p) => p.stockLeft > 0 && p.stockLeft <= lowStockThreshold)
      .toList();

  // 7. Best sellers (aggregated from period sales, or all sales if period has none)
  final salesForRanking = periodSales.isNotEmpty ? periodSales : allSales;
  final categoryTotals = <String, ({int quantity, int profit})>{};
  for (final s in salesForRanking) {
    final existing = categoryTotals[s.categoryName];
    if (existing == null) {
      categoryTotals[s.categoryName] = (
        quantity: s.quantity,
        profit: s.profitCents,
      );
    } else {
      categoryTotals[s.categoryName] = (
        quantity: existing.quantity + s.quantity,
        profit: existing.profit + s.profitCents,
      );
    }
  }

  final sortedCategories = categoryTotals.entries.toList()
    ..sort((a, b) => b.value.quantity.compareTo(a.value.quantity));

  final bestSellers = sortedCategories
      .take(4)
      .map(
        (e) => DashboardBestSeller(
          categoryName: e.key,
          quantitySold: e.value.quantity,
          profitCents: e.value.profit,
        ),
      )
      .toList();

  // 8. Profit chart points
  final chartPoints = _calculateChartPoints(period, periodSales, allExpenses);

  return AsyncValue.data(
    DashboardData(
      period: period,
      spentCents: spentCents,
      earnedCents: earnedCents,
      salesProfitCents: salesProfitCents,
      expensesCents: expensesCents,
      realProfitCents: realProfitCents,
      stockValueCents: stockValueCents,
      unsoldItemsCount: unsoldItemsCount,
      bestSellers: bestSellers,
      lowStockItems: lowStockItems,
      chartPoints: chartPoints,
    ),
  );
});

List<double> _calculateChartPoints(
  Period period,
  List<SaleOverview> sales,
  List<dynamic> expenses,
) {
  if (sales.isEmpty) {
    return const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
  }

  final pointCount = switch (period) {
    Period.today => 6,
    Period.week => 7,
    Period.month => 4,
    Period.all => 6,
  };

  // Build cumulative profit curve
  sales.sort((a, b) => a.date.compareTo(b.date));
  final results = List<double>.filled(pointCount, 0.0);

  if (period == Period.week) {
    final now = DateTime.now();
    for (var i = 0; i < 7; i++) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: 6 - i));
      var dayProfit = 0;
      for (final s in sales) {
        final local = s.date.toLocal();
        if (local.year == day.year &&
            local.month == day.month &&
            local.day == day.day) {
          dayProfit += s.profitCents;
        }
      }
      results[i] = dayProfit.toDouble();
    }
    return results;
  }

  // Distribution for today, month, all
  var cumulative = 0;
  final step = (sales.length / pointCount).ceil();
  for (var i = 0; i < pointCount; i++) {
    final targetIndex = ((i + 1) * step).clamp(0, sales.length);
    cumulative = sales
        .take(targetIndex)
        .fold<int>(0, (sum, s) => sum + s.profitCents);
    results[i] = cumulative.toDouble();
  }

  return results;
}
