import 'package:firabonda/core/utils/business_logic.dart';
import 'package:firabonda/core/utils/period_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('stockLeft', () {
    test('subtracts sold from purchased', () {
      expect(ShopLogic.stockLeft(purchasedQuantity: 10, soldQuantity: 3), 7);
      expect(ShopLogic.stockLeft(purchasedQuantity: 10, soldQuantity: 0), 10);
      expect(ShopLogic.stockLeft(purchasedQuantity: 10, soldQuantity: 10), 0);
    });
  });

  group('saleProfit', () {
    test('computes profit', () {
      expect(
        ShopLogic.saleProfit(
          quantity: 2,
          unitPriceCents: 150000,
          unitCostCents: 100000,
        ),
        100000,
      );
    });

    test('computes loss when sold below cost', () {
      expect(
        ShopLogic.saleProfit(
          quantity: 1,
          unitPriceCents: 140000,
          unitCostCents: 150000,
        ),
        -10000,
      );
    });
  });

  group('realProfit', () {
    test('subtracts expenses from sales profit', () {
      expect(
        ShopLogic.realProfit(salesProfitCents: 65000, expensesCents: 15000),
        50000,
      );
    });

    test('can go negative with big expenses', () {
      expect(
        ShopLogic.realProfit(salesProfitCents: 20000, expensesCents: 30000),
        -10000,
      );
    });
  });

  group('stockValue', () {
    test('multiplies stock left by unit cost', () {
      final value = ShopLogic.stockValue([
        const StockPosition(quantityLeft: 4, unitCostCents: 80000),
        const StockPosition(quantityLeft: 2, unitCostCents: 150000),
      ]);
      expect(value, 620000);
    });

    test('empty stock is zero', () {
      expect(ShopLogic.stockValue(const []), 0);
    });
  });

  group('checkSale', () {
    test('ok when quantity fits stock', () {
      expect(ShopLogic.checkSale(quantity: 3, stockLeft: 7), SaleCheck.ok);
    });

    test('rejects selling more than stock', () {
      expect(
        ShopLogic.checkSale(quantity: 8, stockLeft: 7),
        SaleCheck.exceedsStock,
      );
    });

    test('rejects invalid quantity', () {
      expect(
        ShopLogic.checkSale(quantity: 0, stockLeft: 7),
        SaleCheck.invalidQuantity,
      );
      expect(
        ShopLogic.checkSale(quantity: -1, stockLeft: 7),
        SaleCheck.invalidQuantity,
      );
    });
  });

  group('PeriodRange calendar boundaries', () {
    // 2026-06-24 15:30 local.
    final fixedDate = DateTime(2026, 6, 24, 15, 30);

    test('today covers the local calendar day', () {
      final range = PeriodRange.today(now: fixedDate);
      expect(range.contains(DateTime(2026, 6, 24, 0, 0, 0)), isTrue);
      expect(range.contains(DateTime(2026, 6, 24, 23, 59, 59)), isTrue);
      expect(range.contains(DateTime(2026, 6, 25, 0, 0, 0)), isFalse);
    });

    test('week starts at start of calendar week', () {
      final range = PeriodRange.week(
        now: fixedDate,
        firstDayOfWeek: DateTime.monday,
      );
      // 2026-06-24 is Wednesday (3). Monday of that week was 2026-06-22.
      expect(range.contains(DateTime(2026, 6, 22, 0, 0, 0)), isTrue);
      expect(range.contains(DateTime(2026, 6, 28, 23, 59, 59)), isTrue);
    });

    test('month starts at the first of the calendar month', () {
      final range = PeriodRange.month(now: fixedDate);
      expect(range.contains(DateTime(2026, 6, 1, 0, 0, 0)), isTrue);
      expect(range.contains(DateTime(2026, 6, 30, 23, 59, 59)), isTrue);
      expect(range.contains(DateTime(2026, 7, 1, 0, 0, 0)), isFalse);
    });

    test('all covers everything', () {
      final range = PeriodRange.all();
      expect(range.startUtc.year, 1970);
      expect(range.endUtc.year, 3000);
    });
  });
}
