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
    final salesAsync = ref.watch(saleOverviewsStreamProvider);

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
            salesAsync.when(
              data: (sales) {
                if (sales.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.point_of_sale_outlined,
                      message:
                          'No sales recorded yet. Tap "Sell" on any item in your Purchases list to track your earnings and profit.',
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

                final grouped = _groupByDate(sales);

                return SliverList(
                  delegate: SliverChildListDelegate([
                    // Summary Banner
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenPadding,
                        AppSpacing.s,
                        AppSpacing.screenPadding,
                        AppSpacing.m,
                      ),
                      child: AppCard(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
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
                                Text(
                                  Money.etb(totalRevenue),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              height: 32,
                              width: 1,
                              color: colors.border,
                            ),
                            Column(
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
                                Text(
                                  totalProfit >= 0
                                      ? '+${Money.etb(totalProfit)}'
                                      : Money.etb(totalProfit),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: totalProfit >= 0
                                        ? colors.profit
                                        : colors.loss,
                                  ),
                                ),
                              ],
                            ),
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
    final isProfit = sale.profitCents >= 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isProfit
                    ? colors.profit.withValues(alpha: 0.15)
                    : colors.loss.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isProfit
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                color: isProfit ? colors.profit : colors.loss,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${sale.categoryName} (${sale.colorName})',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sold ${sale.quantity}x @ ${Money.etb(sale.unitPriceCents)} • Cost: ${Money.etb(sale.unitCostCents)}',
                    style: TextStyle(fontSize: 12, color: colors.textMuted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isProfit
                      ? '+${Money.etb(sale.profitCents)}'
                      : Money.etb(sale.profitCents),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isProfit ? colors.profit : colors.loss,
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
      ),
    );
  }
}
