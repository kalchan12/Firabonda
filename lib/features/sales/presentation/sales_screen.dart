import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';

/// Sales list screen (visual sample). Real data in Phase 4.
const _sampleSales = <_SaleRow>[
  _SaleRow(
    category: 'Shirts',
    quantity: 2,
    unitPriceCents: 180000,
    unitCostCents: 120000,
    dateLabel: 'Today',
  ),
  _SaleRow(
    category: 'T-shirts',
    quantity: 5,
    unitPriceCents: 95000,
    unitCostCents: 80000,
    dateLabel: 'Today',
  ),
  _SaleRow(
    category: 'Jeans',
    quantity: 1,
    unitPriceCents: 140000,
    unitCostCents: 150000,
    dateLabel: 'Yesterday',
  ),
];

final class _SaleRow {
  const _SaleRow({
    required this.category,
    required this.quantity,
    required this.unitPriceCents,
    required this.unitCostCents,
    required this.dateLabel,
  });

  final String category;
  final int quantity;
  final int unitPriceCents;
  final int unitCostCents;
  final String dateLabel;

  int get profitCents => (unitPriceCents - unitCostCents) * quantity;
}

final class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (_sampleSales.isEmpty) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.receipt_long_outlined,
          message: 'No sales yet. Sell an item from your purchases.',
          actionLabel: 'Sell item',
          onAction: null,
        ),
      );
    }
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
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPadding,
              ),
              sliver: SliverList.builder(
                itemCount: _sampleSales.length,
                itemBuilder: (context, index) {
                  final s = _sampleSales[index];
                  final showDateHeader =
                      index == 0 ||
                      _sampleSales[index - 1].dateLabel != s.dateLabel;
                  final loss = s.profitCents < 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.m),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDateHeader)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.s,
                              top: AppSpacing.xs,
                            ),
                            child: Text(
                              s.dateLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.textMuted,
                              ),
                            ),
                          ),
                        AppCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${s.quantity}x ${s.category}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      '${Money.amount(s.unitPriceCents)} each',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: colors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${loss ? '-' : '+'} ${Money.amount(s.profitCents.abs())}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: loss ? colors.loss : colors.profit,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
    );
  }
}
