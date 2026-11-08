/// Pure business logic for the shop. Free of Flutter and database imports
/// (`files/ARCHITECTURE.md` section 6). All money is integer cents.
library;

/// Dashboard periods supported by all aggregates.
enum Period { today, yesterday, week, month, all, custom }

/// Result of the stock check for a new sale.
enum SaleCheck { ok, invalidQuantity, exceedsStock }

/// One stock position for stock-value calculations.
final class StockPosition {
  const StockPosition({
    required this.quantityLeft,
    required this.unitCostCents,
  });

  final int quantityLeft;
  final int unitCostCents;
}

final class ShopLogic {
  const ShopLogic._();

  /// stockLeft = purchase.quantity - sum(sales.quantity)
  static int stockLeft({
    required int purchasedQuantity,
    required int soldQuantity,
  }) {
    return purchasedQuantity - soldQuantity;
  }

  /// profit(sale) = (unitPrice - costAtSale) * quantity. Can be negative (loss).
  static int saleProfit({
    required int quantity,
    required int unitPriceCents,
    required int unitCostCents,
  }) {
    return (unitPriceCents - unitCostCents) * quantity;
  }

  /// realProfit(period) = sum(profit of sales) - sum(expenses) - sum(losses)
  static int realProfit({
    required int salesProfitCents,
    required int expensesCents,
    int lossesCents = 0,
  }) {
    return salesProfitCents - expensesCents - lossesCents;
  }

  /// Net profit = Profit - Expenses - Losses
  static int netProfit({
    required int profitCents,
    required int expensesCents,
    int lossesCents = 0,
  }) {
    return profitCents - expensesCents - lossesCents;
  }

  /// Profit percentage (markup on cost) in percent (e.g. 100 for 100%).
  /// Can be negative or exceed 100%. Returns 0.0 if cost is zero.
  static double profitPercent({
    required int profitCents,
    required int costOfSoldItemsCents,
  }) {
    if (costOfSoldItemsCents <= 0) return 0.0;
    return (profitCents / costOfSoldItemsCents) * 100.0;
  }

  /// stockValue = sum(stockLeft * unitCost)
  static int stockValue(Iterable<StockPosition> positions) {
    var total = 0;
    for (final position in positions) {
      total += position.quantityLeft * position.unitCostCents;
    }
    return total;
  }

  /// Validates a sale against the remaining stock.
  static SaleCheck checkSale({required int quantity, required int stockLeft}) {
    if (quantity <= 0) return SaleCheck.invalidQuantity;
    if (quantity > stockLeft) return SaleCheck.exceedsStock;
    return SaleCheck.ok;
  }

  /// Allocates total batch cost (in cents) among items using the
  /// largest-remainder (Hamilton) method based on quantities.
  /// Guarantees that sum(allocated costs) == totalCostCents exactly,
  /// with zero fractional cents created or lost.
  static List<int> allocateBatchCost({
    required int totalCostCents,
    required List<int> quantities,
  }) {
    if (quantities.isEmpty) return const [];
    final totalQuantity = quantities.fold<int>(0, (sum, q) => sum + q);
    if (totalQuantity <= 0 || totalCostCents <= 0) {
      return List<int>.filled(quantities.length, 0);
    }

    final baseShares = List<int>.filled(quantities.length, 0);
    final remainders = List<int>.filled(quantities.length, 0);
    var allocatedSum = 0;

    for (var i = 0; i < quantities.length; i++) {
      final q = quantities[i];
      final exactShareNumerator = totalCostCents * q;
      final baseShare = exactShareNumerator ~/ totalQuantity;
      final remainder = exactShareNumerator % totalQuantity;

      baseShares[i] = baseShare;
      remainders[i] = remainder;
      allocatedSum += baseShare;
    }

    var difference = totalCostCents - allocatedSum;

    // Order indices by remainder descending
    final indices = List<int>.generate(quantities.length, (i) => i)
      ..sort((a, b) => remainders[b].compareTo(remainders[a]));

    for (final idx in indices) {
      if (difference <= 0) break;
      baseShares[idx] += 1;
      difference -= 1;
    }

    return baseShares;
  }
}
