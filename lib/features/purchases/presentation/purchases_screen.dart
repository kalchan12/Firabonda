import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/empty_state.dart';

/// Purchases list screen (visual sample). Real data and filters in Phase 4.
const _samplePurchases = <_PurchaseRow>[
  _PurchaseRow(
    category: 'T-shirts',
    colorName: 'Black',
    colorHex: 0xFF000000,
    quantity: 12,
    unitCostCents: 80000,
    stockLeft: 7,
    dateLabel: 'Today',
  ),
  _PurchaseRow(
    category: 'Shirts',
    colorName: 'Blue',
    colorHex: 0xFF2F5BFF,
    quantity: 5,
    unitCostCents: 120000,
    stockLeft: 5,
    dateLabel: 'Today',
  ),
  _PurchaseRow(
    category: 'Jeans',
    colorName: 'Navy',
    colorHex: 0xFF0B1F4B,
    quantity: 8,
    unitCostCents: 150000,
    stockLeft: 3,
    dateLabel: 'Yesterday',
  ),
];

final class _PurchaseRow {
  const _PurchaseRow({
    required this.category,
    required this.colorName,
    required this.colorHex,
    required this.quantity,
    required this.unitCostCents,
    required this.stockLeft,
    required this.dateLabel,
  });

  final String category;
  final String colorName;
  final int colorHex;
  final int quantity;
  final int unitCostCents;
  final int stockLeft;
  final String dateLabel;
}

final class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const Text('Purchases'),
              backgroundColor: colors.background,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.s,
                  AppSpacing.screenPadding,
                  AppSpacing.m,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search purchases',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide(color: colors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide(color: colors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Wrap(
                      spacing: AppSpacing.s,
                      runSpacing: AppSpacing.s,
                      children: [
                        for (final filter in [
                          'All',
                          'T-shirts',
                          'Shirts',
                          'Jeans',
                        ])
                          AppChip(
                            label: filter,
                            selected: filter == 'All',
                            onTap: () {},
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_samplePurchases.isEmpty) ...[
              const SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.shopping_bag_outlined,
                  message: 'No purchases yet. Add your first one.',
                  actionLabel: 'Add purchase',
                  onAction: null,
                ),
              ),
            ] else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                sliver: SliverList.builder(
                  itemCount: _samplePurchases.length,
                  itemBuilder: (context, index) {
                    final p = _samplePurchases[index];
                    final showDateHeader =
                        index == 0 ||
                        _samplePurchases[index - 1].dateLabel != p.dateLabel;
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
                                p.dateLabel,
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
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Color(p.colorHex),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: colors.border),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.l),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${p.category} · ${p.colorName}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        '${p.quantity} pcs · ${Money.amount(p.unitCostCents)} each',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: colors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${p.stockLeft} left',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: colors.textMuted,
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
