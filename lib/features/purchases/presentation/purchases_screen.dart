import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../data/models/shop_models.dart';
import '../../../data/repositories/providers.dart';
import '../../sales/presentation/sell_bottom_sheet.dart';
import '../application/purchases_controller.dart';

final class PurchasesScreen extends ConsumerStatefulWidget {
  const PurchasesScreen({super.key});

  @override
  ConsumerState<PurchasesScreen> createState() => _PurchasesScreenState();
}

final class _PurchasesScreenState extends ConsumerState<PurchasesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) return 'Today';
    if (itemDate == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat.yMMMd().format(date);
  }

  Map<String, List<PurchaseOverview>> _groupByDate(
    List<PurchaseOverview> list,
  ) {
    final map = <String, List<PurchaseOverview>>{};
    for (final item in list) {
      final key = _formatDateGroup(item.date);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final purchasesAsync = ref.watch(filteredPurchasesProvider);
    final filters = ref.watch(purchaseFiltersProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: const Text('Purchases'),
              backgroundColor: colors.background,
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Batch purchase',
                  onPressed: () => context.push('/batch-purchase'),
                ),
              ],
            ),

            // Search bar & Category filter chips
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
                      controller: _searchController,
                      onChanged: (val) => ref
                          .read(purchaseFiltersProvider.notifier)
                          .setSearchQuery(val),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(purchaseFiltersProvider.notifier)
                                      .setSearchQuery('');
                                },
                              )
                            : null,
                        hintText: 'Search purchases',
                        filled: true,
                        fillColor: colors.surface,
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
                    categoriesAsync.when(
                      data: (categories) => SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            AppChip(
                              label: 'All',
                              selected: filters.categoryId == null,
                              onTap: () => ref
                                  .read(purchaseFiltersProvider.notifier)
                                  .setCategory(null),
                            ),
                            const SizedBox(width: AppSpacing.s),
                            for (final c in categories) ...[
                              AppChip(
                                label: c.name,
                                selected: filters.categoryId == c.id,
                                onTap: () => ref
                                    .read(purchaseFiltersProvider.notifier)
                                    .setCategory(
                                      filters.categoryId == c.id ? null : c.id,
                                    ),
                              ),
                              const SizedBox(width: AppSpacing.s),
                            ],
                          ],
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (err, stack) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            // Content: loading, empty or grouped list
            purchasesAsync.when(
              data: (purchases) {
                if (purchases.isEmpty) {
                  final isFiltering =
                      filters.searchQuery.isNotEmpty ||
                      filters.categoryId != null;
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: isFiltering
                          ? Icons.search_off_rounded
                          : Icons.inventory_2_outlined,
                      message: isFiltering
                          ? 'No matching purchases found. Try clearing the search or category filter.'
                          : 'No purchases yet. Tap "+ Batch purchase" to record your clothing inventory.',
                      actionLabel: isFiltering
                          ? 'Clear filters'
                          : 'Batch purchase',
                      onAction: isFiltering
                          ? () {
                              _searchController.clear();
                              ref
                                  .read(purchaseFiltersProvider.notifier)
                                  .reset();
                            }
                          : () => context.push('/batch-purchase'),
                    ),
                  );
                }

                final grouped = _groupByDate(purchases);

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final dateKey = grouped.keys.elementAt(index);
                    final items = grouped[dateKey]!;

                    return Padding(
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
                              dateKey,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          for (final purchase in items)
                            _PurchaseItemCard(
                              purchase: purchase,
                              onTap: () => context.push(
                                '/add-purchase',
                                extra: purchase,
                              ),
                              onSell: () =>
                                  showSellBottomSheet(context, purchase),
                            ),
                        ],
                      ),
                    );
                  }, childCount: grouped.length),
                );
              },
              loading: () => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  child: Column(
                    children: [
                      SkeletonLoader(
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.m),
                      SkeletonLoader(
                        child: Container(
                          height: 100,
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
                    'Error loading purchases: $err',
                    style: TextStyle(color: colors.loss),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100), // padding for floating nav
            ),
          ],
        ),
      ),
    );
  }
}

final class _PurchaseItemCard extends StatelessWidget {
  const _PurchaseItemCard({
    required this.purchase,
    required this.onTap,
    required this.onSell,
  });

  final PurchaseOverview purchase;
  final VoidCallback onTap;
  final VoidCallback onSell;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final colorVal = purchase.colorHex;
    final isLowStock = purchase.stockLeft > 0 && purchase.stockLeft <= 3;
    final isSoldOut = purchase.stockLeft == 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s),
      child: AppCard(
        onTap: onTap,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo thumbnail or category initial
                GestureDetector(
                  onTap: () {
                    final validPhotos = purchase.photoPaths
                        .where((p) => File(p).existsSync())
                        .toList();
                    if (validPhotos.isEmpty) return;

                    showDialog<void>(
                      context: context,
                      builder: (ctx) {
                        final controller = PageController();
                        return Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: const EdgeInsets.all(AppSpacing.m),
                          child: Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.card,
                                ),
                                child: Container(
                                  color: Colors.black,
                                  height: 420,
                                  child: PageView.builder(
                                    controller: controller,
                                    itemCount: validPhotos.length,
                                    itemBuilder: (context, idx) {
                                      return InteractiveViewer(
                                        child: Image.file(
                                          File(validPhotos[idx]),
                                          fit: BoxFit.contain,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              if (validPhotos.length > 1)
                                Positioned(
                                  bottom: 12,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.pill,
                                        ),
                                      ),
                                      child: Text(
                                        'Swipe to view ${validPhotos.length} photos',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              IconButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                icon: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child:
                            (purchase.firstPhotoPath != null &&
                                File(purchase.firstPhotoPath!).existsSync())
                            ? Image.file(
                                File(purchase.firstPhotoPath!),
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child: Text(
                                  purchase.categoryName.isNotEmpty
                                      ? purchase.categoryName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: colors.primary,
                                  ),
                                ),
                              ),
                      ),
                      if (purchase.photoPaths.length > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${purchase.photoPaths.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.m),

                // Title and details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              purchase.categoryName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Color(colorVal),
                              shape: BoxShape.circle,
                              border: Border.all(color: colors.border),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            purchase.colorName,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textMuted,
                            ),
                          ),
                          if (purchase.size != null) ...[
                            Text(
                              ' • ${purchase.size}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cost: ${Money.etb(purchase.unitCostCents)} each • Qty: ${purchase.quantity}',
                        style: TextStyle(fontSize: 13, color: colors.textMuted),
                      ),
                    ],
                  ),
                ),

                // Stock Left Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSoldOut
                        ? colors.surfaceVariant
                        : (isLowStock
                              ? colors.warning.withValues(alpha: 0.15)
                              : colors.profit.withValues(alpha: 0.15)),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isSoldOut ? 'Sold out' : '${purchase.stockLeft} left',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSoldOut
                          ? colors.textMuted
                          : (isLowStock ? colors.warning : colors.profit),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total invested: ${Money.etb(purchase.totalCostCents)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.textMuted,
                      ),
                    ),
                    if (purchase.sellingPriceCents != null) ...[
                      Text(
                        purchase.quantity > 1
                            ? 'Target sell: ${Money.etb(purchase.sellingPriceCents! * purchase.quantity)} (${Money.etb(purchase.sellingPriceCents!)} each)'
                            : 'Target sell: ${Money.etb(purchase.sellingPriceCents!)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colors.primary,
                        ),
                      ),
                      Text(
                        () {
                          final totalTargetProfit =
                              (purchase.sellingPriceCents! -
                                  purchase.unitCostCents) *
                              purchase.quantity;
                          final isProfit = totalTargetProfit >= 0;
                          return isProfit
                              ? 'Exp. profit: +${Money.etb(totalTargetProfit)}${purchase.quantity > 1 ? ' (+${Money.etb(purchase.sellingPriceCents! - purchase.unitCostCents)} each)' : ''}'
                              : 'Exp. loss: -${Money.etb(totalTargetProfit.abs())}';
                        }(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              (purchase.sellingPriceCents! >=
                                  purchase.unitCostCents)
                              ? colors.profit
                              : colors.loss,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: isSoldOut ? null : onSell,
                    icon: const Icon(Icons.sell_outlined, size: 16),
                    label: const Text('Sell'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      disabledBackgroundColor: colors.surfaceVariant,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
