import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/business_logic.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/period_range.dart';
import '../../../data/models/shop_models.dart';
import '../../../data/repositories/providers.dart';
import '../../settings/application/settings_controller.dart';

/// Tracks the selected period type (Today, Yesterday, Week, Month, All, Custom).
final selectedPeriodProvider = NotifierProvider<_PeriodNotifier, Period>(
  _PeriodNotifier.new,
);

final class _PeriodNotifier extends Notifier<Period> {
  @override
  Period build() => Period.today;

  void setPeriod(Period period) {
    state = period;
    // Reset step offset when changing period type
    ref.read(periodOffsetProvider.notifier).reset();
  }
}

/// Offset for stepping through periods (+1 next, -1 previous).
final periodOffsetProvider = NotifierProvider<_PeriodOffsetNotifier, int>(
  _PeriodOffsetNotifier.new,
);

final class _PeriodOffsetNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void stepPrevious() => state = state - 1;
  void stepNext() => state = state + 1;
  void reset() => state = 0;
}

/// Custom date range selection when Period.custom is active.
final customDateRangeProvider =
    NotifierProvider<_CustomDateRangeNotifier, (DateTime, DateTime)?>(
      _CustomDateRangeNotifier.new,
    );

final class _CustomDateRangeNotifier extends Notifier<(DateTime, DateTime)?> {
  @override
  (DateTime, DateTime)? build() => null;

  void setRange(DateTime start, DateTime end) => state = (start, end);
}

/// Midnight rollover & app lifecycle observer:
/// Automatically refreshes the dashboard at midnight and on app resume.
final dashboardRolloverProvider = NotifierProvider<_RolloverNotifier, int>(
  _RolloverNotifier.new,
);

final class _RolloverNotifier extends Notifier<int>
    with WidgetsBindingObserver {
  Timer? _midnightTimer;
  DateTime _lastDate = DateTime.now();

  @override
  int build() {
    WidgetsBinding.instance.addObserver(this);
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _midnightTimer?.cancel();
    });
    _scheduleMidnightTimer();
    return 0;
  }

  void _scheduleMidnightTimer() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    _lastDate = now;
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final duration = tomorrow.difference(now) + const Duration(seconds: 1);
    _midnightTimer = Timer(duration, () {
      state = state + 1;
      _scheduleMidnightTimer();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (appState == AppLifecycleState.resumed) {
      final now = DateTime.now();
      if (now.day != _lastDate.day ||
          now.month != _lastDate.month ||
          now.year != _lastDate.year) {
        state = state + 1;
        _scheduleMidnightTimer();
      }
    }
  }
}

/// Resolves the current [PeriodRange] with calendar-accurate local boundaries.
final currentPeriodRangeProvider = Provider<PeriodRange>((ref) {
  // Watch rollover to trigger rebuild on midnight
  ref.watch(dashboardRolloverProvider);

  final clock = ref.watch(appClockProvider);
  final period = ref.watch(selectedPeriodProvider);
  final offset = ref.watch(periodOffsetProvider);
  final weekStartsOn = ref.watch(weekStartsOnProvider);
  final customRange = ref.watch(customDateRangeProvider);

  final now = clock.now();

  switch (period) {
    case Period.today:
      return PeriodRange.day(now: now, offsetDays: offset);
    case Period.yesterday:
      return PeriodRange.day(now: now, offsetDays: offset, isYesterday: true);
    case Period.week:
      return PeriodRange.week(
        now: now,
        firstDayOfWeek: weekStartsOn,
        offsetWeeks: offset,
      );
    case Period.month:
      return PeriodRange.month(now: now, offsetMonths: offset);
    case Period.all:
      return PeriodRange.all();
    case Period.custom:
      if (customRange != null) {
        return PeriodRange.custom(
          startDate: customRange.$1,
          endDate: customRange.$2,
        );
      }
      return PeriodRange.today(now: now);
  }
});

final class DashboardData {
  const DashboardData({
    required this.periodRange,
    required this.spentCents,
    required this.earnedCents,
    required this.costOfSoldCents,
    required this.salesProfitCents,
    required this.profitPercent,
    required this.expensesCents,
    required this.lossesCents,
    required this.realProfitCents,
    required this.stockValueCents,
    required this.unsoldItemsCount,
    required this.bestSellers,
    required this.lowStockItems,
    required this.periodSales,
    required this.chartPoints,
    this.totalAssumedProfitCents = 0,
    this.actualProfitForAssumedCents = 0,
    this.percentOfTarget,
    this.targetDiffCents,
  });

  final PeriodRange periodRange;
  Period get period => periodRange.period;

  final int spentCents; // Bought
  final int earnedCents; // Sold (revenue)
  final int costOfSoldCents; // Cost of sold items
  final int salesProfitCents; // Sold - Cost of sold items
  final double profitPercent; // Legacy profit % markup on cost
  final int expensesCents; // Expenses
  final int lossesCents; // Losses
  final int realProfitCents; // Net profit (Profit - Expenses - Losses)
  final int stockValueCents;
  final int unsoldItemsCount;
  final List<DashboardBestSeller> bestSellers;
  final List<PurchaseOverview> lowStockItems;
  final List<SaleOverview> periodSales;
  final List<double> chartPoints;
  final int totalAssumedProfitCents;
  final int actualProfitForAssumedCents;
  final int? percentOfTarget;
  final int? targetDiffCents;
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
  final periodRange = ref.watch(currentPeriodRangeProvider);
  final purchasesAsync = ref.watch(purchaseOverviewsStreamProvider);
  final salesAsync = ref.watch(saleOverviewsStreamProvider);
  final expensesAsync = ref.watch(expensesStreamProvider);
  final adjustmentsAsync = ref.watch(stockAdjustmentsStreamProvider);
  final lowStockThreshold = ref.watch(lowStockThresholdProvider);

  if (purchasesAsync.isLoading ||
      salesAsync.isLoading ||
      expensesAsync.isLoading ||
      adjustmentsAsync.isLoading) {
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
  final allAdjustments = adjustmentsAsync.value ?? [];

  // Map purchase IDs to unitCost for fallback if costAtSale is not yet set
  final purchaseCostMap = {for (final p in allPurchases) p.id: p.unitCostCents};

  // 1. Bought (spent in period: purchases dated in this period)
  var spentCents = 0;
  for (final p in allPurchases) {
    if (periodRange.contains(p.date)) {
      spentCents += p.totalCostCents;
    }
  }

  // 2. Sales in period
  final periodSales = allSales.where((s) {
    return periodRange.contains(s.date);
  }).toList();

  var earnedCents = 0;
  var costOfSoldCents = 0;
  var salesProfitCents = 0;
  var totalAssumedProfitCents = 0;
  var actualProfitForAssumedCents = 0;
  var assumedSalesCount = 0;

  for (final s in periodSales) {
    final revenue = s.unitPriceCents * s.quantity;
    final costPerPiece = purchaseCostMap[s.purchaseId] ?? 0;
    final totalCost = costPerPiece * s.quantity;

    earnedCents += revenue;
    costOfSoldCents += totalCost;
    salesProfitCents += s.profitCents;

    if (s.assumedPriceAtSaleCents != null &&
        s.assumedPriceAtSaleCents! > s.costAtSale) {
      assumedSalesCount++;
      final assumedProfit =
          (s.assumedPriceAtSaleCents! - s.costAtSale) * s.quantity;
      totalAssumedProfitCents += assumedProfit;
      actualProfitForAssumedCents += s.profitCents;
    }
  }

  final int? percentOfTarget;
  final int? targetDiffCents;
  if (assumedSalesCount > 0 && totalAssumedProfitCents > 0) {
    percentOfTarget =
        ((actualProfitForAssumedCents / totalAssumedProfitCents) * 100).round();
    targetDiffCents = actualProfitForAssumedCents - totalAssumedProfitCents;
  } else {
    percentOfTarget = null;
    targetDiffCents = null;
  }

  // Profit %
  final profitPercent = ShopLogic.profitPercent(
    profitCents: salesProfitCents,
    costOfSoldItemsCents: costOfSoldCents,
  );

  // 3. Expenses in period
  var expensesCents = 0;
  for (final e in allExpenses) {
    if (periodRange.contains(e.date)) {
      expensesCents += e.amount;
    }
  }

  // 4. Losses in period (Step 8 stock adjustments: damaged, lost, personal use)
  var lossesCents = 0;
  for (final a in allAdjustments) {
    if (a.reason.isLoss && periodRange.contains(a.date)) {
      lossesCents += a.valueAtCostCents;
    }
  }

  // 5. Net profit
  final netProfitCents = ShopLogic.netProfit(
    profitCents: salesProfitCents,
    expensesCents: expensesCents,
    lossesCents: lossesCents,
  );

  // 6. Stock value across active inventory
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

  // 7. Low stock items
  final lowStockItems = allPurchases
      .where((p) => p.stockLeft > 0 && p.stockLeft <= lowStockThreshold)
      .toList();

  // 8. Best sellers
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

  // 9. Profit chart points
  final chartPoints = _calculateChartPoints(
    periodRange.period,
    periodSales,
    allExpenses,
  );

  return AsyncValue.data(
    DashboardData(
      periodRange: periodRange,
      spentCents: spentCents,
      earnedCents: earnedCents,
      costOfSoldCents: costOfSoldCents,
      salesProfitCents: salesProfitCents,
      profitPercent: profitPercent,
      expensesCents: expensesCents,
      lossesCents: lossesCents,
      realProfitCents: netProfitCents,
      stockValueCents: stockValueCents,
      unsoldItemsCount: unsoldItemsCount,
      bestSellers: bestSellers,
      lowStockItems: lowStockItems,
      periodSales: periodSales,
      chartPoints: chartPoints,
      totalAssumedProfitCents: totalAssumedProfitCents,
      actualProfitForAssumedCents: actualProfitForAssumedCents,
      percentOfTarget: percentOfTarget,
      targetDiffCents: targetDiffCents,
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
    Period.yesterday => 6,
    Period.week => 7,
    Period.month => 4,
    Period.all => 6,
    Period.custom => 6,
  };

  sales.sort((a, b) => a.date.compareTo(b.date));
  final results = List<double>.filled(pointCount, 0.0);

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
