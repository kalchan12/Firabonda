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
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../data/database/app_database.dart';
import '../../../data/models/shop_models.dart';
import '../../../data/repositories/providers.dart';
import '../../shifts/presentation/close_shift_sheet.dart';
import '../../shifts/presentation/open_shift_sheet.dart';
import '../application/dashboard_controller.dart';
import 'widgets/dashboard_skeleton.dart';

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

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardDataProvider);
            ref.invalidate(currentShiftStreamProvider);
            ref.invalidate(purchaseOverviewsStreamProvider);
            ref.invalidate(saleOverviewsStreamProvider);
            await Future<void>.delayed(const Duration(milliseconds: 300));
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              // Top Dashboard Header & Period Container
              Container(
                padding: const EdgeInsets.all(AppSpacing.m),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.border.withValues(alpha: 0.6),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.surface,
                      colors.surfaceVariant.withValues(alpha: 0.35),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Fira Bonda',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: colors.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(color: colors.border),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.refresh_rounded,
                              color: colors.textPrimary,
                              size: 20,
                            ),
                            tooltip: 'Refresh dashboard',
                            onPressed: () {
                              ref.invalidate(dashboardDataProvider);
                              ref.invalidate(currentShiftStreamProvider);
                              ref.invalidate(purchaseOverviewsStreamProvider);
                              ref.invalidate(saleOverviewsStreamProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Dashboard refreshed'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s),
                        Semantics(
                          button: true,
                          label: Theme.of(context).brightness == Brightness.dark
                              ? 'Switch to Light mode'
                              : 'Switch to Dark mode',
                          child: Container(
                            decoration: BoxDecoration(
                              color: colors.surfaceVariant,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
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
                              tooltip:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? 'Switch to Light mode'
                                      : 'Switch to Dark mode',
                              onPressed: () {
                                final isDark =
                                    Theme.of(context).brightness ==
                                        Brightness.dark;
                                ref
                                    .read(themeControllerProvider.notifier)
                                    .setMode(
                                      isDark
                                          ? ThemeMode.light
                                          : ThemeMode.dark,
                                    );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.m),
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
                            ButtonSegment(
                              value: p,
                              label: Text(_periodLabel(p)),
                            ),
                        ],
                        selected: {selectedPeriod},
                        onSelectionChanged: (selection) async {
                          final chosen = selection.first;
                          if (chosen == Period.custom) {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
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
                            ref
                                .read(selectedPeriodProvider.notifier)
                                .setPeriod(chosen);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.m),

            if (dashboardAsync.hasValue) ...[
              () {
                final data = dashboardAsync.value!;
                final isProfitPositive = data.realProfitCents >= 0;
                final periodName = data.isShiftScoped
                    ? 'Active shift'
                    : _periodLabel(data.period);

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.m),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colors.border.withValues(alpha: 0.6),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colors.surface,
                            colors.surfaceVariant.withValues(alpha: 0.35),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Shift status banner (Today tab)
                          if (data.period == Period.today) ...[
                            _TodayShiftBanner(
                              activeShift: data.activeShift,
                              todayShiftMode: data.todayShiftMode,
                              isShiftScoped: data.isShiftScoped,
                            ),
                            const SizedBox(height: AppSpacing.m),
                          ],

                          // 1. Net Profit Hero Tile with status badge
                          _NetProfitHeroTile(
                            periodName: periodName,
                            netProfitCents: data.realProfitCents,
                            salesProfitCents: data.salesProfitCents,
                            expensesCents: data.expensesCents,
                            lossesCents: data.lossesCents,
                            isPositive: isProfitPositive,
                            targetDiffCents: data.targetDiffCents,
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

                          // 3. Unified Target & Payments Card (Cash, Bank, Credit)
                          _UnifiedTargetAndPaymentsCard(
                            data: data,
                            periodName: periodName,
                          ),
                          const SizedBox(height: AppSpacing.m),

                          // 5. Sales in period (recent sales)
                          _SalesPeriodListCard(
                            periodName: periodName,
                            sales: data.periodSales,
                          ),
                          const SizedBox(height: AppSpacing.m),

                          // 6. Expandable "More details" accordion
                          _MoreDetailsAccordion(
                            data: data,
                            periodName: periodName,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100), // bottom nav clearance
                  ],
                );
              }(),
            ] else if (dashboardAsync.isLoading) ...[
              const DashboardSkeletonView(),
            ] else if (dashboardAsync.hasError) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  child: Text(
                    'Error loading dashboard: ${dashboardAsync.error}',
                    style: TextStyle(color: colors.loss),
                  ),
                ),
              ),
            ],
          ],
        ),
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
    this.targetDiffCents,
  });

  final String periodName;
  final int netProfitCents;
  final int salesProfitCents;
  final int expensesCents;
  final int lossesCents;
  final bool isPositive;
  final int? targetDiffCents;

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
          Row(
            children: [
              if (targetDiffCents != null) ...[
                Icon(
                  targetDiffCents! >= 0
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 14,
                  color: targetDiffCents! >= 0 ? colors.profit : colors.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  targetDiffCents! >= 0
                      ? '+${Money.etb(targetDiffCents!)} over target'
                      : '-${Money.etb(targetDiffCents!.abs())} under target',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: targetDiffCents! >= 0
                        ? colors.profit
                        : colors.warning,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ] else ...[
                Text(
                  'No target set',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ],
          ),
          if (expensesCents > 0 || lossesCents > 0) ...[
            const SizedBox(height: 4),
            Text(
              expensesCents > 0
                  ? 'Includes ${Money.etb(expensesCents)} expenses deducted'
                  : 'Includes ${Money.etb(lossesCents)} losses deducted',
              style: TextStyle(fontSize: 11, color: colors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

/// 3. Unified Target Achievement & Payments Card (Cash, Bank, Credit)
final class _UnifiedTargetAndPaymentsCard extends StatelessWidget {
  const _UnifiedTargetAndPaymentsCard({
    required this.data,
    required this.periodName,
  });

  final DashboardData data;
  final String periodName;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final percent = data.percentOfTarget;
    final hasTarget = percent != null && data.totalAssumedProfitCents > 0;
    final isAhead = (percent ?? 0) >= 100;
    final progress = hasTarget
        ? ((percent / 100).clamp(0.0, 1.5))
        : 0.0;

    final hasCredit = data.creditSalesCents > 0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Target Achievement Section (Compact)
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
                        'Target Achievement',
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
                  color: !hasTarget
                      ? colors.surfaceVariant
                      : (isAhead
                          ? colors.profit.withValues(alpha: 0.15)
                          : colors.warning.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: !hasTarget
                        ? colors.border
                        : (isAhead ? colors.profit : colors.warning),
                  ),
                ),
                child: Text(
                  !hasTarget
                      ? 'No target set'
                      : (isAhead
                          ? '+$percent% vs target'
                          : '$percent% of target'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: !hasTarget
                        ? colors.textMuted
                        : (isAhead ? colors.profit : colors.warning),
                  ),
                ),
              ),
            ],
          ),
          if (hasTarget) ...[
            const SizedBox(height: AppSpacing.s),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: progress > 1.0 ? 1.0 : progress,
                minHeight: 8,
                backgroundColor: colors.surfaceVariant,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isAhead ? colors.profit : colors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Target: ${Money.etb(data.totalAssumedProfitCents)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Achieved: ${Money.etb(data.actualProfitForAssumedCents)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isAhead ? colors.profit : colors.textPrimary,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Set target selling prices on purchases to track progress here.',
              style: TextStyle(
                fontSize: 11,
                color: colors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.m),
          Divider(color: colors.border.withValues(alpha: 0.6), height: 1),
          const SizedBox(height: AppSpacing.m),

          // 2. Unified Payments Section (Cash, Bank, Credit)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 18,
                    color: colors.textPrimary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Payments ($periodName)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              if (hasCredit)
                InkWell(
                  onTap: () => context.push('/debts'),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View debts',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 14,
                          color: colors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),

          // 3 Compact Mini-Cards for Cash, Bank, Credit
          Row(
            children: [
              Expanded(
                child: _PaymentChannelTile(
                  icon: Icons.payments_rounded,
                  label: 'Cash',
                  amountCents: data.cashSalesCents,
                  accentColor: colors.profit,
                  colors: colors,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: _PaymentChannelTile(
                  icon: Icons.account_balance_rounded,
                  label: 'Bank',
                  amountCents: data.bankSalesCents,
                  accentColor: colors.primary,
                  colors: colors,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: _PaymentChannelTile(
                  icon: Icons.assignment_late_outlined,
                  label: 'Credit',
                  amountCents: data.creditSalesCents,
                  accentColor: colors.warning,
                  colors: colors,
                  badge: hasCredit ? '${data.creditSalesCount} sale' : null,
                  onTap: () => context.push('/debts'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _PaymentChannelTile extends StatelessWidget {
  const _PaymentChannelTile({
    required this.icon,
    required this.label,
    required this.amountCents,
    required this.accentColor,
    required this.colors,
    this.badge,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final int amountCents;
  final Color accentColor;
  final AppColorsExtension colors;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: colors.surfaceVariant.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: amountCents > 0
                  ? accentColor.withValues(alpha: 0.25)
                  : colors.border.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: accentColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  Money.etb(amountCents),
                  style: TextStyle(
                    fontFamily: 'Sora',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color:
                        amountCents > 0 ? colors.textPrimary : colors.textMuted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 5. Sales in period (recent sales list)
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
                          Wrap(
                            spacing: 6,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                '${sale.colorName} • x${sale.quantity}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.textMuted,
                                ),
                              ),
                              if (sale.isCreditSale) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.warning.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: colors.warning.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    sale.isFullyUnpaid
                                        ? 'Credit (unpaid)'
                                        : 'Credit • owes ${Money.etb(sale.creditAmountCents)}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: colors.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ],
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
final class _MoreDetailsAccordion extends ConsumerWidget {
  const _MoreDetailsAccordion({
    required this.data,
    required this.periodName,
  });

  final DashboardData data;
  final String periodName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final selectedPeriod = ref.watch(selectedPeriodProvider);

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

            // Modern Period Dropdown Filter for More analytics & stock
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.s,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceVariant.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(color: colors.border.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: colors.primary,
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Text(
                    'Timeframe:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.textMuted,
                    ),
                  ),
                  const Spacer(),
                  _ModernPeriodDropdown(
                    selectedPeriod: selectedPeriod,
                    onChanged: (chosen) async {
                      if (chosen == null) return;
                      if (chosen == Period.custom) {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
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
                        ref
                            .read(selectedPeriodProvider.notifier)
                            .setPeriod(chosen);
                      }
                    },
                  ),
                ],
              ),
            ),
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

final class _TodayShiftBanner extends ConsumerStatefulWidget {
  const _TodayShiftBanner({
    required this.activeShift,
    this.todayShiftMode = TodayShiftMode.activeShift,
    this.isShiftScoped = false,
  });

  final ShiftRow? activeShift;
  final TodayShiftMode todayShiftMode;
  final bool isShiftScoped;

  @override
  ConsumerState<_TodayShiftBanner> createState() => _TodayShiftBannerState();
}

final class _TodayShiftBannerState extends ConsumerState<_TodayShiftBanner> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final shift = widget.activeShift;
    final hasActiveShift = shift != null;
    final timeStr =
        hasActiveShift ? DateFormat('h:mm a').format(shift.openedAt) : null;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Collapsed / Header Bar - Tapping toggles full shift view
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.card),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.m,
                vertical: AppSpacing.s + 2,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: hasActiveShift
                          ? colors.profit.withValues(alpha: 0.15)
                          : colors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Icon(
                      hasActiveShift
                          ? Icons.timelapse_rounded
                          : Icons.access_time_filled_rounded,
                      color: hasActiveShift ? colors.profit : colors.warning,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              hasActiveShift ? 'Active Shift' : 'No Active Shift',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            if (hasActiveShift) ...[
                              const SizedBox(width: 6),
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: colors.profit,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          hasActiveShift
                              ? 'Opened at $timeStr • Base: ${Money.etb(shift.openingCash)}'
                              : 'Tap to open shift or view shift details',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.history_rounded, size: 18),
                    tooltip: 'Shift history',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => context.push('/shift-history'),
                  ),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: colors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content Display
          if (_isExpanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.m,
                0,
                AppSpacing.m,
                AppSpacing.m,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    color: colors.border.withValues(alpha: 0.6),
                    height: 1,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  if (hasActiveShift) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(color: colors.border),
                          ),
                          child: Text(
                            widget.todayShiftMode == TodayShiftMode.activeShift
                                ? 'Dashboard: Active Shift'
                                : 'Dashboard: All Today',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.textMuted,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => ref
                              .read(todayShiftModeProvider.notifier)
                              .toggle(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.swap_horiz_rounded,
                                  size: 14,
                                  color: colors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.todayShiftMode ==
                                          TodayShiftMode.activeShift
                                      ? 'Switch to All Today'
                                      : 'Switch to This Shift',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    FutureBuilder<ShiftSummaryData>(
                      future: ref
                          .read(shiftRepositoryProvider)
                          .getShiftSummary(shift.id),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const SizedBox.shrink();
                        final summary = snapshot.data!;
                        return Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.s),
                          child: Wrap(
                            spacing: AppSpacing.s,
                            runSpacing: 4,
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Earned this shift: ${Money.etb(summary.totalEarnedCents)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: colors.primary,
                                ),
                              ),
                              if (summary.hasCreditItems)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        colors.warning.withValues(alpha: 0.15),
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.pill),
                                  ),
                                  child: Text(
                                    '${summary.creditItems.length} credit items today',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: colors.warning,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.m),
                    AppButton(
                      label: 'Close shift & reconcile',
                      icon: Icons.check_circle_outline_rounded,
                      variant: AppButtonVariant.secondary,
                      onPressed: () => showCloseShiftSheet(context, shift),
                    ),
                  ] else ...[
                    if (widget.isShiftScoped ||
                        widget.todayShiftMode == TodayShiftMode.allToday) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.todayShiftMode == TodayShiftMode.activeShift
                                ? 'Shift view: Active Shift (0)'
                                : 'Shift view: All Today',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.textMuted,
                            ),
                          ),
                          InkWell(
                            onTap: () => ref
                                .read(todayShiftModeProvider.notifier)
                                .toggle(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.swap_horiz_rounded,
                                    size: 14,
                                    color: colors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.todayShiftMode ==
                                            TodayShiftMode.activeShift
                                        ? 'View all today'
                                        : 'View active shift',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: colors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s),
                    ],
                    AppButton(
                      label: 'Open shift',
                      icon: Icons.play_arrow_rounded,
                      onPressed: () => showOpenShiftSheet(context),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

final class _ModernPeriodDropdown extends StatelessWidget {
  const _ModernPeriodDropdown({
    required this.selectedPeriod,
    required this.onChanged,
  });

  final Period selectedPeriod;
  final ValueChanged<Period?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(color: colors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Period>(
          value: selectedPeriod,
          icon: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: colors.textMuted,
            ),
          ),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
          dropdownColor: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          items: const [
            DropdownMenuItem(
              value: Period.today,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.today_rounded, size: 16),
                  SizedBox(width: 8),
                  Text('Today'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: Period.yesterday,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded, size: 16),
                  SizedBox(width: 8),
                  Text('Yesterday'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: Period.week,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.date_range_rounded, size: 16),
                  SizedBox(width: 8),
                  Text('Week'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: Period.all,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.all_inclusive_rounded, size: 16),
                  SizedBox(width: 8),
                  Text('All'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: Period.month,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_month_rounded, size: 16),
                  SizedBox(width: 8),
                  Text('Month'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: Period.custom,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_calendar_rounded, size: 16),
                  SizedBox(width: 8),
                  Text('Custom'),
                ],
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
