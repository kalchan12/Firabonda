import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/models/shop_models.dart';
import '../../../data/repositories/providers.dart';
import '../application/sales_controller.dart';

final class SalesScreen extends ConsumerWidget {
  const SalesScreen({super.key});

  String _formatDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) return 'Today';
    if (itemDate == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat.yMMMd().format(date);
  }

  Map<String, List<SaleOverview>> _groupByDate(List<SaleOverview> list) {
    final map = <String, List<SaleOverview>>{};
    for (final item in list) {
      final key = _formatDateGroup(item.date);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final salesAsync = ref.watch(filteredSalesProvider);
    final filters = ref.watch(salesFiltersProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const Text('Sales'),
              backgroundColor: colors.background,
            ),

            // Modern Dropdown Filter Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.xs,
                  AppSpacing.screenPadding,
                  AppSpacing.m,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Cloth Types / Category Dropdown
                      _ModernSalesDropdown<String?>(
                        icon: Icons.checkroom_outlined,
                        value: filters.categoryId,
                        hint: 'All clothing',
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All clothing'),
                          ),
                          if (categoriesAsync.hasValue)
                            for (final c in categoriesAsync.value!)
                              DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                        ],
                        onChanged: (val) => ref
                            .read(salesFiltersProvider.notifier)
                            .setCategory(val),
                      ),
                      const SizedBox(width: AppSpacing.s),

                      // Days / Date Dropdown
                      _ModernSalesDropdown<SalesDateFilter>(
                        icon: Icons.calendar_today_outlined,
                        value: filters.dateFilter,
                        hint: 'All time',
                        items: [
                          for (final d in SalesDateFilter.values)
                            DropdownMenuItem(value: d, child: Text(d.label)),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref
                                .read(salesFiltersProvider.notifier)
                                .setDateFilter(val);
                          }
                        },
                      ),
                      const SizedBox(width: AppSpacing.s),

                      // Payment Method / Credit Dropdown
                      _ModernSalesDropdown<SalesPaymentFilter>(
                        icon: Icons.payments_outlined,
                        value: filters.paymentFilter,
                        hint: 'All payments',
                        items: [
                          for (final p in SalesPaymentFilter.values)
                            DropdownMenuItem(value: p, child: Text(p.label)),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref
                                .read(salesFiltersProvider.notifier)
                                .setPaymentFilter(val);
                          }
                        },
                      ),

                      // Clear filter chip if any active
                      if (filters.hasActiveFilter) ...[
                        const SizedBox(width: AppSpacing.s),
                        ActionChip(
                          avatar: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Clear'),
                          onPressed: () =>
                              ref.read(salesFiltersProvider.notifier).reset(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            salesAsync.when(
              data: (sales) {
                if (sales.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: filters.hasActiveFilter
                          ? Icons.filter_alt_off_outlined
                          : Icons.point_of_sale_outlined,
                      message: filters.hasActiveFilter
                          ? 'No sales match the selected filters.'
                          : 'No sales recorded yet. Tap "Sell" on any item in your Purchases list to track your earnings and profit.',
                      actionLabel: filters.hasActiveFilter
                          ? 'Reset filters'
                          : null,
                      onAction: filters.hasActiveFilter
                          ? () =>
                              ref.read(salesFiltersProvider.notifier).reset()
                          : null,
                    ),
                  );
                }

                final totalProfit = sales.fold<int>(
                  0,
                  (sum, s) => sum + s.profitCents,
                );
                final totalRevenue = sales.fold<int>(
                  0,
                  (sum, s) => sum + (s.unitPriceCents * s.quantity),
                );
                final totalItemsSold = sales.fold<int>(
                  0,
                  (sum, s) => sum + s.quantity,
                );
                final creditSalesAmount = sales.where((s) => s.isCreditSale).fold<int>(
                  0,
                  (sum, s) => sum + s.creditAmountCents,
                );

                final grouped = _groupByDate(sales);

                return SliverList(
                  delegate: SliverChildListDelegate([
                    // Summary Banner
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenPadding,
                        0,
                        AppSpacing.screenPadding,
                        AppSpacing.m,
                      ),
                      child: AppCard(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        'Total revenue',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: colors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          Money.etb(totalRevenue),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            fontFamily: 'Sora',
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  height: 32,
                                  width: 1,
                                  color: colors.border,
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        'Total profit',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: colors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          totalProfit >= 0
                                              ? '+${Money.etb(totalProfit)}'
                                              : Money.etb(totalProfit),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            fontFamily: 'Sora',
                                            color: totalProfit >= 0
                                                ? colors.profit
                                                : colors.loss,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  height: 32,
                                  width: 1,
                                  color: colors.border,
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        'Items sold',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: colors.textMuted,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          '$totalItemsSold pcs',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            fontFamily: 'Sora',
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (creditSalesAmount > 0) ...[
                              const SizedBox(height: AppSpacing.s),
                              Divider(color: colors.border, height: 1),
                              const SizedBox(height: AppSpacing.s),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.credit_card_off_outlined,
                                    size: 14,
                                    color: colors.warning,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Credit owed from sales: ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: colors.textMuted,
                                    ),
                                  ),
                                  Text(
                                    Money.etb(creditSalesAmount),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Sora',
                                      color: colors.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Grouped Sales List
                    for (final entry in grouped.entries) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenPadding,
                          vertical: AppSpacing.xs,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.s,
                              ),
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: colors.textMuted,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            for (final sale in entry.value)
                              _SaleItemCard(sale: sale),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 100), // padding for floating nav
                  ]),
                );
              },
              loading: () => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  child: Column(
                    children: [
                      SkeletonLoader(
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      SkeletonLoader(
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              error: (err, stack) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    'Error loading sales: $err',
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

final class _SaleItemCard extends ConsumerWidget {
  const _SaleItemCard({required this.sale});

  final SaleOverview sale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final res = sale.profitResult;
    final isLoss = res.status == ProfitStatus.loss;
    final isOver = res.status == ProfitStatus.overProfit;
    final isOnTarget = res.status == ProfitStatus.onTarget;
    final isUnder = res.status == ProfitStatus.underTarget;

    final (chipLabel, chipColor) = switch (res.status) {
      ProfitStatus.overProfit => (
        res.overProfitCents != null && res.overProfitCents! > 0
            ? 'Over profit +${Money.etb(res.overProfitCents!)}'
            : 'Over profit (${res.percentOfTarget ?? 100}%)',
        colors.profit,
      ),
      ProfitStatus.onTarget => ('On target (100%)', colors.profit),
      ProfitStatus.underTarget => (
        '${res.percentOfTarget}% of target',
        colors.warning,
      ),
      ProfitStatus.breakeven => ('Breakeven (0%)', colors.textMuted),
      ProfitStatus.loss => (
        'Loss -${Money.etb(res.actualProfitCents.abs())}',
        colors.loss,
      ),
      ProfitStatus.notAssumed => ('No target', colors.textMuted),
    };

    final paymentBadgeLabel = switch (sale.accountId) {
      'acc_bank' => 'Bank',
      'acc_telebirr' => 'Telebirr',
      _ => 'Cash',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isLoss
                        ? colors.loss.withValues(alpha: 0.15)
                        : (isOver || isOnTarget
                              ? colors.profit.withValues(alpha: 0.15)
                              : (isUnder
                                    ? colors.warning.withValues(alpha: 0.15)
                                    : colors.surfaceVariant)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isLoss
                        ? Icons.trending_down_rounded
                        : Icons.trending_up_rounded,
                    color: isLoss
                        ? colors.loss
                        : (isOver || isOnTarget
                              ? colors.profit
                              : (isUnder ? colors.warning : colors.textMuted)),
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${sale.categoryName} (${sale.colorName})',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              paymentBadgeLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: colors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${sale.quantity} pcs @ ${Money.etb(sale.unitPriceCents)} • Total ${Money.etb(sale.quantity * sale.unitPriceCents)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colors.textMuted,
                        ),
                      ),
                      if (sale.isCreditSale) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: colors.warning.withValues(alpha: 0.3),
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
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isLoss
                          ? '-${Money.etb(sale.profitCents.abs())}'
                          : '+${Money.etb(sale.profitCents)}',
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isLoss ? colors.loss : colors.profit,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      DateFormat.jm().format(sale.date),
                      style: TextStyle(fontSize: 11, color: colors.textMuted),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  tooltip: 'Delete sale',
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Sale?'),
                        content: Text(
                          'Delete sale of ${sale.quantity}x ${sale.categoryName}? The ${sale.quantity} items will be restored to inventory stock.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final nav = Navigator.of(ctx);
                              final repo = ref.read(purchaseRepositoryProvider);
                              await repo.softDeleteSale(sale.id);
                              nav.pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Sale removed. Restored ${sale.quantity}x ${sale.categoryName} to stock.',
                                  ),
                                  action: SnackBarAction(
                                    label: 'UNDO',
                                    onPressed: () async {
                                      await repo.restoreSale(sale.id);
                                    },
                                  ),
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            },
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: chipColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: chipColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                chipLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: chipColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ModernSalesDropdown<T> extends StatelessWidget {
  const _ModernSalesDropdown({
    required this.icon,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final IconData icon;
  final T value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isSelected = value != null && value != items.first.value;

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? colors.primary.withValues(alpha: 0.12)
            : colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.6)
              : colors.border,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          icon: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: isSelected ? colors.primary : colors.textMuted,
            ),
          ),
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? colors.primary : colors.textPrimary,
          ),
          dropdownColor: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
