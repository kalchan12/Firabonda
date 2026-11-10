import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/shop_models.dart';
import '../../../data/repositories/providers.dart';
import 'sell_bottom_sheet.dart';

/// Screen for recording quick sales in 2-3 taps (Step 6).
/// Displays active inventory with instant pre-filled sell actions.
final class QuickSaleScreen extends ConsumerStatefulWidget {
  const QuickSaleScreen({super.key});

  @override
  ConsumerState<QuickSaleScreen> createState() => _QuickSaleScreenState();
}

final class _QuickSaleScreenState extends ConsumerState<QuickSaleScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final purchasesAsync = ref.watch(purchaseOverviewsStreamProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Quick Sale')),
      body: purchasesAsync.when(
        data: (purchases) {
          final inStock = purchases.where((p) => p.stockLeft > 0).where((p) {
            if (_searchQuery.trim().isEmpty) return true;
            final query = _searchQuery.toLowerCase();
            return p.categoryName.toLowerCase().contains(query) ||
                p.colorName.toLowerCase().contains(query);
          }).toList();

          return Column(
            children: [
              // Search field
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.s,
                  AppSpacing.screenPadding,
                  AppSpacing.m,
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search items by category or color...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: colors.surfaceVariant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.m,
                      vertical: AppSpacing.s,
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),

              // Items in stock
              Expanded(
                child: inStock.isEmpty
                    ? Center(
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
                              _searchQuery.isNotEmpty
                                  ? 'No matching items in stock'
                                  : 'No items currently in stock',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenPadding,
                          0,
                          AppSpacing.screenPadding,
                          100, // Clearance for bottom navigation
                        ),
                        itemCount: inStock.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.s),
                        itemBuilder: (context, index) {
                          final item = inStock[index];
                          return _QuickSaleItemCard(
                            item: item,
                            onSellTap: () => showSellBottomSheet(context, item),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Error: $err', style: TextStyle(color: colors.loss)),
        ),
      ),
    );
  }
}

final class _QuickSaleItemCard extends StatelessWidget {
  const _QuickSaleItemCard({required this.item, required this.onSellTap});

  final PurchaseOverview item;
  final VoidCallback onSellTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final suggestedPrice = item.sellingPriceCents ?? (item.unitCostCents * 2);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(item.colorHex),
              border: Border.all(color: colors.border),
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.categoryName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.colorName} • ${item.stockLeft} in stock',
                  style: TextStyle(fontSize: 12, color: colors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Sell price: ${Money.etb(suggestedPrice)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.profit,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.comfortable,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 18),
            label: const Text('Sell'),
            onPressed: onSellTap,
          ),
        ],
      ),
    );
  }
}
