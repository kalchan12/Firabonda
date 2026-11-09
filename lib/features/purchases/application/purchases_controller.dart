import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/shop_models.dart';
import '../../../data/repositories/providers.dart';

enum PurchaseStockFilter { all, inStock, lowStock, soldOut }

final class PurchaseFilters {
  const PurchaseFilters({
    this.searchQuery = '',
    this.categoryId,
    this.colorId,
    this.supplierId,
    this.dateRange,
    this.stockFilter = PurchaseStockFilter.all,
  });

  final String searchQuery;
  final String? categoryId;
  final String? colorId;
  final String? supplierId;
  final DateTimeRange? dateRange;
  final PurchaseStockFilter stockFilter;

  PurchaseFilters copyWith({
    String? searchQuery,
    String? Function()? categoryId,
    String? Function()? colorId,
    String? Function()? supplierId,
    DateTimeRange? Function()? dateRange,
    PurchaseStockFilter? stockFilter,
  }) {
    return PurchaseFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      categoryId: categoryId != null ? categoryId() : this.categoryId,
      colorId: colorId != null ? colorId() : this.colorId,
      supplierId: supplierId != null ? supplierId() : this.supplierId,
      dateRange: dateRange != null ? dateRange() : this.dateRange,
      stockFilter: stockFilter ?? this.stockFilter,
    );
  }
}

final class PurchaseFiltersNotifier extends Notifier<PurchaseFilters> {
  @override
  PurchaseFilters build() => const PurchaseFilters();

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategory(String? categoryId) {
    state = state.copyWith(categoryId: () => categoryId);
  }

  void setColor(String? colorId) {
    state = state.copyWith(colorId: () => colorId);
  }

  void setSupplier(String? supplierId) {
    state = state.copyWith(supplierId: () => supplierId);
  }

  void setDateRange(DateTimeRange? range) {
    state = state.copyWith(dateRange: () => range);
  }

  void setStockFilter(PurchaseStockFilter filter) {
    state = state.copyWith(stockFilter: filter);
  }

  void reset() {
    state = const PurchaseFilters();
  }
}

final purchaseFiltersProvider =
    NotifierProvider<PurchaseFiltersNotifier, PurchaseFilters>(
      PurchaseFiltersNotifier.new,
    );

final filteredPurchasesProvider = Provider<AsyncValue<List<PurchaseOverview>>>((
  ref,
) {
  final purchasesAsync = ref.watch(purchaseOverviewsStreamProvider);
  final filters = ref.watch(purchaseFiltersProvider);

  return purchasesAsync.whenData((list) {
    return list.where((item) {
      if (filters.categoryId != null && item.categoryId != filters.categoryId) {
        return false;
      }
      if (filters.colorId != null && item.colorId != filters.colorId) {
        return false;
      }
      if (filters.supplierId != null && item.supplierId != filters.supplierId) {
        return false;
      }
      if (filters.stockFilter == PurchaseStockFilter.inStock &&
          item.stockLeft <= 0) {
        return false;
      }
      if (filters.stockFilter == PurchaseStockFilter.lowStock &&
          (item.stockLeft <= 0 || item.stockLeft > 3)) {
        return false;
      }
      if (filters.stockFilter == PurchaseStockFilter.soldOut &&
          item.stockLeft > 0) {
        return false;
      }
      if (filters.dateRange != null) {
        final start = filters.dateRange!.start;
        final end = filters.dateRange!.end.add(const Duration(days: 1));
        if (item.date.isBefore(start) || item.date.isAfter(end)) {
          return false;
        }
      }
      if (filters.searchQuery.trim().isNotEmpty) {
        final q = filters.searchQuery.toLowerCase();
        final matchCategory = item.categoryName.toLowerCase().contains(q);
        final matchColor = item.colorName.toLowerCase().contains(q);
        final matchSupplier =
            item.supplierName?.toLowerCase().contains(q) ?? false;
        final matchNote = item.note?.toLowerCase().contains(q) ?? false;
        if (!matchCategory && !matchColor && !matchSupplier && !matchNote) {
          return false;
        }
      }
      return true;
    }).toList();
  });
});

typedef PriceMemoryQuery = ({String categoryId, String? colorId});

final priceMemoryProvider = FutureProvider.family<int?, PriceMemoryQuery>((
  ref,
  query,
) async {
  final repo = ref.watch(purchaseRepositoryProvider);
  return repo.lastPricePaid(
    categoryId: query.categoryId,
    colorId: query.colorId,
  );
});
