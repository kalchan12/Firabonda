import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/utils/business_logic.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/stat_tile.dart';
import '../application/dashboard_controller.dart';

final class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _periodLabel(Period period) => switch (period) {
    Period.today => 'Today',
    Period.week => 'Week',
    Period.month => 'Month',
    Period.all => 'All',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final dashboardAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            // Top App Bar with Light/Dark mode toggle
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Fira Bonda',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: Theme.of(context).brightness == Brightness.dark
                      ? 'Switch to Light mode'
                      : 'Switch to Dark mode',
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: colors.border),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Theme.of(context).brightness == Brightness.dark
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        color: colors.textPrimary,
                        size: 20,
                      ),
                      tooltip: Theme.of(context).brightness == Brightness.dark
                          ? 'Switch to Light mode'
                          : 'Switch to Dark mode',
                      onPressed: () {
                        final isDark =
                            Theme.of(context).brightness == Brightness.dark;
                        ref
                            .read(themeControllerProvider.notifier)
                            .setMode(isDark ? ThemeMode.light : ThemeMode.dark);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),

            // Period Selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<Period>(
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.comfortable,
                ),
                segments: [
                  for (final p in Period.values)
                    ButtonSegment(value: p, label: Text(_periodLabel(p))),
                ],
                selected: {selectedPeriod},
                onSelectionChanged: (selection) => ref
                    .read(selectedPeriodProvider.notifier)
                    .setPeriod(selection.first),
              ),
            ),
            const SizedBox(height: AppSpacing.l),

            dashboardAsync.when(
              data: (data) {
                final isProfitPositive = data.realProfitCents >= 0;
                final periodName = _periodLabel(data.period);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Spent & Earned Tiles
                    Row(
                      children: [
                        Expanded(
                          child: StatTile(
                            label: 'Spent ($periodName)',
                            value: Money.etb(data.spentCents),
                            tone: StatTone.loss,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: StatTile(
                            label: 'Earned ($periodName)',
                            value: Money.etb(data.earnedCents),
                            tone: StatTone.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Real Profit Hero Tile
                    StatTile(
                      hero: true,
                      label: 'Real Profit ($periodName)',
                      value: isProfitPositive
                          ? '+ ${Money.etb(data.realProfitCents)}'
                          : Money.etb(data.realProfitCents),
                      tone: isProfitPositive ? StatTone.profit : StatTone.loss,
                    ),
                    if (data.expensesCents > 0)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 4,
                          left: 6,
                          bottom: 4,
                        ),
                        child: Text(
                          'Includes ${Money.etb(data.expensesCents)} expenses deducted',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.m),

                    // Profit Chart
                    _ProfitChartCard(
                      periodName: periodName,
                      valuesCents: data.chartPoints,
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Best Sellers Card
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Best sellers',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                periodName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.m),
                          if (data.bestSellers.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.m,
                              ),
                              child: Center(
                                child: Text(
                                  'No sales recorded in this period yet',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colors.textMuted,
                                  ),
                                ),
                              ),
                            )
                          else
                            for (final seller in data.bestSellers)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.m,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        seller.categoryName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${seller.quantitySold} sold',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: colors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.l),
                                    Text(
                                      seller.profitCents >= 0
                                          ? '+ ${Money.amount(seller.profitCents)}'
                                          : Money.amount(seller.profitCents),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: seller.profitCents >= 0
                                            ? colors.profit
                                            : colors.loss,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          const Divider(),
                          const SizedBox(height: AppSpacing.s),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Unsold stock value',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: colors.textMuted,
                                      ),
                                    ),
                                    Text(
                                      '${data.unsoldItemsCount} pieces in stock',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                Money.etb(data.stockValueCents),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Low Stock Alert Card (visible only if there are items low in stock)
                    if (data.lowStockItems.isNotEmpty)
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 20,
                                  color: colors.warning,
                                ),
                                const SizedBox(width: AppSpacing.s),
                                Text(
                                  'Low stock alerts',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(color: colors.warning),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.s),
                            for (final item in data.lowStockItems)
                              InkWell(
                                onTap: () =>
                                    context.push('/add-purchase', extra: item),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppSpacing.xs,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${item.categoryName} (${item.colorName})',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: colors.warning.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          '${item.stockLeft} left',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: colors.warning,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 100), // bottom nav clearance
                  ],
                );
              },
              loading: () => Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SkeletonLoader(
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(
                                AppRadius.card,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: SkeletonLoader(
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(
                                AppRadius.card,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.m),
                  SkeletonLoader(
                    child: Container(
                      height: 110,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  SkeletonLoader(
                    child: Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                    ),
                  ),
                ],
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: Text(
                    'Error loading dashboard: $err',
                    style: TextStyle(color: colors.loss),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ProfitChartCard extends StatelessWidget {
  const _ProfitChartCard({required this.periodName, required this.valuesCents});

  final String periodName;
  final List<double> valuesCents;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final allZeros = valuesCents.every((v) => v == 0);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profit trend',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                periodName,
                style: TextStyle(fontSize: 12, color: colors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: colors.border, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: const FlTitlesData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => colors.surfaceVariant,
                    getTooltipItems: (spots) => [
                      for (final spot in spots)
                        LineTooltipItem(
                          Money.amount(spot.y.round()),
                          TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (final (index, value) in valuesCents.indexed)
                        FlSpot(index.toDouble(), value),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: allZeros ? colors.textMuted : colors.profit,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          (allZeros ? colors.textMuted : colors.profit)
                              .withValues(alpha: 0.2),
                          (allZeros ? colors.textMuted : colors.profit)
                              .withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
