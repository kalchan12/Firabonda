import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/repositories/providers.dart';
import 'stock_adjustment_sheet.dart';

final class StockAdjustmentsScreen extends ConsumerWidget {
  const StockAdjustmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final adjustmentsAsync = ref.watch(stockAdjustmentsStreamProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Stock Adjustments & Losses'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showStockAdjustmentBottomSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('New adjustment'),
      ),
      body: adjustmentsAsync.when(
        data: (adjustments) {
          if (adjustments.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: colors.textMuted,
                  ),
                  const SizedBox(height: AppSpacing.m),
                  Text(
                    'No stock adjustments recorded yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    'Record damaged, lost, or returned items here.',
                    style: TextStyle(fontSize: 13, color: colors.textMuted),
                  ),
                ],
              ),
            );
          }

          final totalLosses = adjustments
              .where((a) => a.reason.isLoss)
              .fold<int>(0, (sum, a) => sum + a.valueAtCostCents);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            children: [
              // Losses summary tile
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Inventory Losses',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${adjustments.length} adjustment records',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      Money.etb(totalLosses),
                      style: TextStyle(
                        fontFamily: 'Sora',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: colors.loss,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.m),

              for (final adj in adjustments) ...[
                AppCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.s),
                        decoration: BoxDecoration(
                          color: (adj.reason.isLoss
                                  ? colors.loss
                                  : colors.primary)
                              .withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          adj.reason.isLoss
                              ? Icons.warning_rounded
                              : Icons.sync_alt_rounded,
                          color: adj.reason.isLoss
                              ? colors.loss
                              : colors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${adj.categoryName} (${adj.colorName})',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '${adj.reason.label} • ${DateFormat.yMMMd().format(adj.date)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textMuted,
                              ),
                            ),
                            if (adj.note != null && adj.note!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '"${adj.note}"',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: colors.textMuted,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            adj.quantityChange > 0
                                ? '+${adj.quantityChange}'
                                : '${adj.quantityChange}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: adj.quantityChange < 0
                                  ? colors.loss
                                  : colors.profit,
                            ),
                          ),
                          if (adj.valueAtCostCents > 0)
                            Text(
                              Money.etb(adj.valueAtCostCents),
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
