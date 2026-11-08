import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/utils/business_logic.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../data/models/shop_models.dart';
import '../../settings/application/settings_controller.dart';
import '../application/dashboard_controller.dart';

final class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _periodLabel(Period period) => switch (period) {
    Period.today => 'Today',
    Period.yesterday => 'Yesterday',
    Period.week => 'Week',
    Period.month => 'Month',
    Period.all => 'All',
    Period.custom => 'Custom',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final selectedPeriod = ref.watch(selectedPeriodProvider);
    final dashboardAsync = ref.watch(dashboardDataProvider);
    final targetProfit = ref.watch(targetProfitPercentProvider);

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
                onSelectionChanged: (selection) async {
                  final chosen = selection.first;
                  if (chosen == Period.custom) {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      ref
                          .read(customDateRangeProvider.notifier)
                          .setRange(picked.start, picked.end);
                      ref
                          .read(selectedPeriodProvider.notifier)
                          .setPeriod(Period.custom);
                    }
                  } else {
                    ref.read(selectedPeriodProvider.notifier).setPeriod(chosen);
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.s),

            // Stepper bar (prev / label / next)
            if (selectedPeriod != Period.all &&
                selectedPeriod != Period.custom) ...[
              Consumer(
                builder: (context, ref, _) {
                  final range = ref.watch(currentPeriodRangeProvider);
                  final offset = ref.watch(periodOffsetProvider);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        tooltip: 'Previous',
                        onPressed: () => ref
                            .read(periodOffsetProvider.notifier)
                            .stepPrevious(),
                      ),
                      Text(
                        range.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        tooltip: 'Next',
                        onPressed: () =>
                            ref.read(periodOffsetProvider.notifier).stepNext(),
                      ),
                      if (offset != 0)
                        TextButton(
                          onPressed: () =>
                              ref.read(periodOffsetProvider.notifier).reset(),
                          child: const Text(
                            'Reset',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.s),
            ] else ...[
              const SizedBox(height: AppSpacing.s),
            ],

            dashboardAsync.when(
              data: (data) {
                final isProfitPositive = data.realProfitCents >= 0;
                final periodName = _periodLabel(data.period);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Net Profit Hero Tile with status badge
                    _NetProfitHeroTile(
                      periodName: periodName,
                      netProfitCents: data.realProfitCents,
                      salesProfitCents: data.salesProfitCents,
                      expensesCents: data.expensesCents,
                      lossesCents: data.lossesCents,
                      isPositive: isProfitPositive,
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // 2. 2x2 Grid: Sold, Cost of sold, Bought, Expenses
                    Row(
                      children: [
                        Expanded(
                          child: StatTile(
                            label: 'Sold / Earned ($periodName)',
                            value: Money.etb(data.earnedCents),
                            tone: StatTone.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: StatTile(
                            label: 'Cost of sold ($periodName)',
                            value: Money.etb(data.costOfSoldCents),
                            tone: StatTone.loss,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Row(
                      children: [
                        Expanded(
                          child: StatTile(
                            label: 'Bought / Spent ($periodName)',
                            value: Money.etb(data.spentCents),
                            tone: StatTone.loss,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: StatTile(
                            label: 'Expenses ($periodName)',
                            value: Money.etb(data.expensesCents),
                            tone: StatTone.loss,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // 3. Target profit gauge/bar
                    _TargetProfitCard(
                      achievedPercent: data.profitPercent,
                      targetPercent: targetProfit,
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // 4. Sales in period (recent sales)
                    _SalesPeriodListCard(
                      periodName: periodName,
                      sales: data.periodSales,
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // 5. Expandable "More details" accordion
                    _MoreDetailsAccordion(data: data, periodName: periodName),
                    const SizedBox(height: 100), // bottom nav clearance
                  ],
                );
              },
              loading: () => Column(
                children: [
                  SkeletonLoader(
                    child: Container(
                      height: 130,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
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
                      height: 160,
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

/// 1. Net Profit Hero Tile with status badge (green/red)
final class _NetProfitHeroTile extends StatelessWidget {
  const _NetProfitHeroTile({
    required this.periodName,
    required this.netProfitCents,
    required this.salesProfitCents,
    required this.expensesCents,
    required this.lossesCents,
    required this.isPositive,
  });

  final String periodName;
  final int netProfitCents;
  final int salesProfitCents;
  final int expensesCents;
  final int lossesCents;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final badgeColor = isPositive ? colors.profit : colors.loss;
    final statusText = isPositive ? 'Profitable' : 'Net Loss';

    return AppCard(
      hero: true,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colors.surfaceVariant.withValues(alpha: 0.95),
          (isPositive ? colors.profit : colors.loss).withValues(alpha: 0.12),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Real Profit ($periodName)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 14,
                      color: badgeColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              isPositive
                  ? '+ ${Money.etb(netProfitCents)}'
                  : Money.etb(netProfitCents),
              style: TextStyle(
                fontFamily: 'Sora',
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: isPositive ? colors.profit : colors.loss,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            expensesCents > 0
                ? 'Includes ${Money.etb(expensesCents)} expenses deducted'
                : lossesCents > 0
                ? 'Includes ${Money.etb(lossesCents)} losses deducted'
                : 'Formula: Sold profit minus expenses and losses',
            style: TextStyle(fontSize: 12, color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// 3. Target profit gauge/bar
final class _TargetProfitCard extends StatelessWidget {
  const _TargetProfitCard({
    required this.achievedPercent,
    required this.targetPercent,
  });

  final double achievedPercent;
  final int targetPercent;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final diff = achievedPercent - targetPercent;
    final isAhead = diff >= 0;
    final progress = targetPercent > 0
        ? (achievedPercent / targetPercent).clamp(0.0, 1.5)
        : 1.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.track_changes_rounded,
                      size: 18,
                      color: colors.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Target Profit Margin',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: colors.border),
                ),
                child: Text(
                  'Target: $targetPercent%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  '${achievedPercent.toStringAsFixed(1)}% markup',
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                isAhead
                    ? '+${diff.toStringAsFixed(1)}% vs target'
                    : '${diff.toStringAsFixed(1)}% vs target',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isAhead ? colors.profit : colors.loss,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: (progress / 1.5).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: colors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(
                isAhead ? colors.profit : colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 4. Sales in period (recent sales list)
final class _SalesPeriodListCard extends StatelessWidget {
  const _SalesPeriodListCard({required this.periodName, required this.sales});

  final String periodName;
  final List<SaleOverview> sales;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sales ($periodName)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${sales.length} total',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          if (sales.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'No sales recorded in this period yet',
                      style: TextStyle(fontSize: 13, color: colors.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/quick-sale'),
                      icon: const Icon(Icons.bolt_rounded, size: 16),
                      label: const Text('Record Quick Sale'),
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sales.take(5).length,
              separatorBuilder: (_, _) => const Divider(height: 12),
              itemBuilder: (context, index) {
                final sale = sales[index];
                final revenue = sale.unitPriceCents * sale.quantity;

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                      child: Text(
                        DateFormat.jm().format(sale.date),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sale.categoryName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${sale.colorName} • x${sale.quantity}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Money.etb(revenue),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          '+ ${Money.amount(sale.profitCents)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.profit,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

/// 5. Expandable "More details" accordion:
/// Unsold stock value, low stock alerts, best sellers, profit curve chart
final class _MoreDetailsAccordion extends StatelessWidget {
  const _MoreDetailsAccordion({required this.data, required this.periodName});

  final DashboardData data;
  final String periodName;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.l,
            vertical: AppSpacing.xs,
          ),
          title: Text(
            'More analytics & stock',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            'Stock value, low stock alerts, best sellers & chart',
            style: TextStyle(fontSize: 11, color: colors.textMuted),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            0,
            AppSpacing.l,
            AppSpacing.l,
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.m),

            // Stock value
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
                        style: TextStyle(fontSize: 11, color: colors.textMuted),
                      ),
                    ],
                  ),
                ),
                Text(
                  Money.etb(data.stockValueCents),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.l),

            // Low Stock Alert (visible if low stock items exist)
            if (data.lowStockItems.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: colors.warning,
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Text(
                    'Low stock alerts',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final item in data.lowStockItems)
                InkWell(
                  onTap: () => context.push('/add-purchase', extra: item),
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
                              fontSize: 13,
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
                            color: colors.warning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${item.stockLeft} left',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: colors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.l),
            ],

            // Best sellers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Best sellers',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  periodName,
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            if (data.bestSellers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                child: Text(
                  'No best sellers in this period yet',
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                ),
              )
            else
              for (final seller in data.bestSellers)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          seller.categoryName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${seller.quantitySold} sold',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colors.textMuted,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Text(
                        seller.profitCents >= 0
                            ? '+ ${Money.amount(seller.profitCents)}'
                            : Money.amount(seller.profitCents),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: seller.profitCents >= 0
                              ? colors.profit
                              : colors.loss,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: AppSpacing.l),

            // Profit Trend Line Chart
            _ProfitChartCard(
              periodName: periodName,
              valuesCents: data.chartPoints,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Profit trend',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              periodName,
              style: TextStyle(fontSize: 11, color: colors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        SizedBox(
          height: 160,
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
    );
  }
}
