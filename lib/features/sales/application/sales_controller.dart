import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/shop_models.dart';
import '../../../data/repositories/providers.dart';

enum SalesDateFilter {
  allTime('All time'),
  today('Today'),
  yesterday('Yesterday'),
  thisWeek('This week'),
  thisMonth('This month');

  const SalesDateFilter(this.label);
  final String label;
}

enum SalesPaymentFilter {
  all('All payments'),
  cash('Cash'),
  bank('Bank'),
  telebirr('Telebirr / Debit'),
  creditOnly('Credit (unpaid)');

  const SalesPaymentFilter(this.label);
  final String label;
}

final class SalesFilters {
  const SalesFilters({
    this.categoryId,
    this.dateFilter = SalesDateFilter.allTime,
    this.paymentFilter = SalesPaymentFilter.all,
  });

  final String? categoryId;
  final SalesDateFilter dateFilter;
  final SalesPaymentFilter paymentFilter;

  bool get hasActiveFilter =>
      categoryId != null ||
      dateFilter != SalesDateFilter.allTime ||
      paymentFilter != SalesPaymentFilter.all;

  SalesFilters copyWith({
    String? Function()? categoryId,
    SalesDateFilter? dateFilter,
    SalesPaymentFilter? paymentFilter,
  }) {
    return SalesFilters(
      categoryId: categoryId != null ? categoryId() : this.categoryId,
      dateFilter: dateFilter ?? this.dateFilter,
      paymentFilter: paymentFilter ?? this.paymentFilter,
    );
  }
}

final class SalesFiltersNotifier extends Notifier<SalesFilters> {
  @override
  SalesFilters build() => const SalesFilters();

  void setCategory(String? categoryId) {
    state = state.copyWith(categoryId: () => categoryId);
  }

  void setDateFilter(SalesDateFilter filter) {
    state = state.copyWith(dateFilter: filter);
  }

  void setPaymentFilter(SalesPaymentFilter filter) {
    state = state.copyWith(paymentFilter: filter);
  }

  void reset() {
    state = const SalesFilters();
  }
}

final salesFiltersProvider =
    NotifierProvider<SalesFiltersNotifier, SalesFilters>(
      SalesFiltersNotifier.new,
    );

final filteredSalesProvider = Provider<AsyncValue<List<SaleOverview>>>((ref) {
  final salesAsync = ref.watch(saleOverviewsStreamProvider);
  final filters = ref.watch(salesFiltersProvider);

  return salesAsync.whenData((list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final startOfWeek = today.subtract(Duration(days: now.weekday - 1));

    return list.where((item) {
      // 1. Category / Cloth Type Filter
      if (filters.categoryId != null &&
          item.categoryId != filters.categoryId) {
        return false;
      }

      // 2. Days / Date Filter
      final itemDate = DateTime(
        item.date.year,
        item.date.month,
        item.date.day,
      );
      switch (filters.dateFilter) {
        case SalesDateFilter.allTime:
          break;
        case SalesDateFilter.today:
          if (itemDate != today) return false;
        case SalesDateFilter.yesterday:
          if (itemDate != yesterday) return false;
        case SalesDateFilter.thisWeek:
          if (itemDate.isBefore(startOfWeek)) return false;
        case SalesDateFilter.thisMonth:
          if (item.date.year != now.year || item.date.month != now.month) {
            return false;
          }
      }

      // 3. Payment Filter
      switch (filters.paymentFilter) {
        case SalesPaymentFilter.all:
          break;
        case SalesPaymentFilter.cash:
          if (item.accountId != 'acc_cash' || item.isCreditSale) return false;
        case SalesPaymentFilter.bank:
          if (item.accountId != 'acc_bank') return false;
        case SalesPaymentFilter.telebirr:
          if (item.accountId != 'acc_telebirr') return false;
        case SalesPaymentFilter.creditOnly:
          if (!item.isCreditSale) return false;
      }

      return true;
    }).toList();
  });
});
