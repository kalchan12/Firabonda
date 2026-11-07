/// Pure business logic for the shop. Free of Flutter and database imports
/// (`files/ARCHITECTURE.md` section 6). All money is integer cents.
library;

/// Dashboard periods supported by all aggregates.
enum Period { today, week, month, all }

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

  /// profit(sale) = (unitPrice - unitCost) * quantity. Can be negative (loss).
  static int saleProfit({
    required int quantity,
    required int unitPriceCents,
    required int unitCostCents,
  }) {
    return (unitPriceCents - unitCostCents) * quantity;
  }

  /// realProfit(period) = sum(profit of sales) - sum(expenses)
  static int realProfit({
    required int salesProfitCents,
    required int expensesCents,
  }) {
    return salesProfitCents - expensesCents;
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

  /// [startUtc, endUtc) window for a [Period], computed on local wall-clock
  /// days because dates are displayed in local time (see
  /// `files/CODING_STANDARDS.md`).
  static (DateTime, DateTime) periodWindowUtc(Period period, DateTime nowUtc) {
    final local = nowUtc.toLocal();
    var startLocal = DateTime(local.year, local.month, local.day);
    switch (period) {
      case Period.today:
        break;
      case Period.week:
        startLocal = startLocal.subtract(const Duration(days: 7));
      case Period.month:
        startLocal = DateTime(local.year, local.month);
      case Period.all:
        return (
          DateTime.utc(1970),
          nowUtc.add(const Duration(microseconds: 1)),
        );
    }
    return (startLocal.toUtc(), nowUtc.add(const Duration(microseconds: 1)));
  }
}
