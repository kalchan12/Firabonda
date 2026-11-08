import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/repositories/providers.dart';

final class DayCloseScreen extends ConsumerStatefulWidget {
  const DayCloseScreen({super.key});

  @override
  ConsumerState<DayCloseScreen> createState() => _DayCloseScreenState();
}

final class _DayCloseScreenState extends ConsumerState<DayCloseScreen> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    final localA = a.toLocal();
    final localB = b.toLocal();
    return localA.year == localB.year &&
        localA.month == localB.month &&
        localA.day == localB.day;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final salesAsync = ref.watch(saleOverviewsStreamProvider);
    final expensesAsync = ref.watch(expensesStreamProvider);
    final adjustmentsAsync = ref.watch(stockAdjustmentsStreamProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Day Close Summary'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          // Date selection header
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.m),
            child: Row(
              children: [
                Icon(
                  Icons.event_available_rounded,
                  color: colors.primary,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Business Day',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        DateFormat.yMMMMEEEEd().format(_selectedDate),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: _pickDate,
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),

          salesAsync.when(
            data: (allSales) {
              final daySales =
                  allSales.where((s) => _isSameDay(s.date, _selectedDate)).toList();
              final allExpenses = expensesAsync.value ?? [];
              final dayExpenses = allExpenses
                  .where((e) => _isSameDay(e.date, _selectedDate))
                  .toList();
              final allAdjustments = adjustmentsAsync.value ?? [];
              final dayAdjustments = allAdjustments
                  .where((a) => _isSameDay(a.date, _selectedDate) && a.reason.isLoss)
                  .toList();

              // Calculations
              var totalRevenue = 0;
              var totalProfit = 0;
              var totalPiecesSold = 0;
              var cashCollected = 0;

              for (final s in daySales) {
                totalRevenue += s.unitPriceCents * s.quantity;
                totalProfit += s.profitCents;
                totalPiecesSold += s.quantity;
                cashCollected += s.paidAmountCents ?? (s.unitPriceCents * s.quantity);
              }

              final totalExpenses = dayExpenses.fold<int>(
                0,
                (sum, e) => sum + e.amount,
              );
              final totalLosses = dayAdjustments.fold<int>(
                0,
                (sum, a) => sum + a.valueAtCostCents,
              );
              final netProfit = totalProfit - totalExpenses - totalLosses;
              final isProfitable = netProfit >= 0;

              return Column(
                children: [
                  // Net profit hero tile for the day
                  AppCard(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colors.surfaceVariant.withValues(alpha: 0.95),
                        (isProfitable ? colors.profit : colors.loss)
                            .withValues(alpha: 0.12),
                      ],
                    ),
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Day Net Profit',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colors.textMuted,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: (isProfitable
                                        ? colors.profit
                                        : colors.loss)
                                    .withValues(alpha: 0.2),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                isProfitable ? 'Profitable' : 'Net Loss',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isProfitable
                                      ? colors.profit
                                      : colors.loss,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            isProfitable
                                ? '+ ${Money.etb(netProfit)}'
                                : Money.etb(netProfit),
                            style: TextStyle(
                              fontFamily: 'Sora',
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: isProfitable ? colors.profit : colors.loss,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'From $totalPiecesSold pieces sold across ${daySales.length} transactions',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),

                  // Breakdown cards
                  AppCard(
                    child: Column(
                      children: [
                        _DayCloseRow(
                          label: 'Total Revenue (Sales)',
                          value: Money.etb(totalRevenue),
                          color: colors.textPrimary,
                        ),
                        const Divider(height: 16),
                        _DayCloseRow(
                          label: 'Sales Gross Profit',
                          value: Money.etb(totalProfit),
                          color: colors.profit,
                        ),
                        const Divider(height: 16),
                        _DayCloseRow(
                          label: 'Operating Expenses',
                          value: totalExpenses > 0
                              ? '- ${Money.etb(totalExpenses)}'
                              : 'ETB 0.00',
                          color: totalExpenses > 0
                              ? colors.loss
                              : colors.textMuted,
                        ),
                        const Divider(height: 16),
                        _DayCloseRow(
                          label: 'Damaged / Lost Stock',
                          value: totalLosses > 0
                              ? '- ${Money.etb(totalLosses)}'
                              : 'ETB 0.00',
                          color: totalLosses > 0 ? colors.loss : colors.textMuted,
                        ),
                        const Divider(height: 16),
                        _DayCloseRow(
                          label: 'Cash Inflow Collected',
                          value: Money.etb(cashCollected),
                          color: colors.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Close Day Button
                  AppButton(
                    label: 'Complete Day Close & Copy Summary',
                    onPressed: () async {
                      final summaryText = '''
*** Fira Bonda - Day Close Summary ***
Date: ${DateFormat.yMMMd().format(_selectedDate)}
Items sold: $totalPiecesSold pcs (${daySales.length} sales)
Total Revenue: ${Money.etb(totalRevenue)}
Gross Profit: ${Money.etb(totalProfit)}
Expenses: ${Money.etb(totalExpenses)}
Damaged/Losses: ${Money.etb(totalLosses)}
NET PROFIT: ${Money.etb(netProfit)}
Cash Inflow: ${Money.etb(cashCollected)}
**************************************''';

                      await Clipboard.setData(ClipboardData(text: summaryText));
                      await HapticFeedback.mediumImpact();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Day close summary copied to clipboard! Ready to share or save.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

final class _DayCloseRow extends StatelessWidget {
  const _DayCloseRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
            fontFamily: 'Sora',
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
