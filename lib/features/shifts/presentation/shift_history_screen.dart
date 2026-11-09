import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/repositories/providers.dart';
import 'open_shift_sheet.dart';

final class ShiftHistoryScreen extends ConsumerWidget {
  const ShiftHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final shiftsAsync = ref.watch(shiftHistoryStreamProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Shift History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Open new shift',
            onPressed: () => showOpenShiftSheet(context),
          ),
        ],
      ),
      body: shiftsAsync.when(
        data: (shifts) {
          if (shifts.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.history_toggle_off_rounded,
                message: 'No shifts recorded yet.\nStart by opening a shift.',
                actionLabel: 'Open Shift',
                onAction: () => showOpenShiftSheet(context),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            itemCount: shifts.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
            itemBuilder: (context, index) {
              final shift = shifts[index];
              final isOpen = shift.isOpen;
              final diff = shift.cashDifferenceCents ?? 0;
              final hasDiff = shift.cashDifferenceCents != null;
              final isExact = hasDiff && diff == 0;
              final isExtra = hasDiff && diff > 0;

              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isOpen
                                    ? colors.profit
                                    : colors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isOpen ? 'Active Shift (Open)' : 'Closed Shift',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isOpen
                                    ? colors.profit
                                    : colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          DateFormat.yMMMd().format(shift.openedAt),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isOpen
                          ? 'Started at ${DateFormat.jm().format(shift.openedAt)}'
                          : '${DateFormat.jm().format(shift.openedAt)} – ${shift.closedAt != null ? DateFormat.jm().format(shift.closedAt!) : "Now"}',
                      style: TextStyle(fontSize: 12, color: colors.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Divider(color: colors.border, height: 1),
                    const SizedBox(height: AppSpacing.m),

                    // Metrics row: Sales & Profit
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sales (${shift.salesCount} sold)',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              Money.etb(shift.totalSalesCents),
                              style: const TextStyle(
                                fontFamily: 'Sora',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Real Profit',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              shift.totalProfitCents >= 0
                                  ? '+${Money.etb(shift.totalProfitCents)}'
                                  : Money.etb(shift.totalProfitCents),
                              style: TextStyle(
                                fontFamily: 'Sora',
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: shift.totalProfitCents >= 0
                                    ? colors.profit
                                    : colors.loss,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    if (!isOpen && hasDiff) ...[
                      const SizedBox(height: AppSpacing.m),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.m,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isExact || isExtra ? colors.profit : colors.loss)
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isExact
                                  ? Icons.check_circle_outline_rounded
                                  : isExtra
                                  ? Icons.add_circle_outline_rounded
                                  : Icons.warning_amber_rounded,
                              size: 16,
                              color: isExact || isExtra
                                  ? colors.profit
                                  : colors.loss,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isExact
                                  ? 'Cash matched drawer'
                                  : isExtra
                                  ? '+${Money.etb(diff)} extra cash'
                                  : '-${Money.etb(diff.abs())} short',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isExact || isExtra
                                    ? colors.profit
                                    : colors.loss,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
          itemBuilder: (_, _) => SkeletonLoader(
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
            ),
          ),
        ),
        error: (err, _) => Center(child: Text('Error loading shifts: $err')),
      ),
    );
  }
}
