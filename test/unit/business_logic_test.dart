import 'package:flutter_test/flutter_test.dart';

import 'package:firabonda/core/utils/business_logic.dart';

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

  group('periodWindowUtc', () {
    // 2026-06-24 15:30 local (UTC+0 for the test host).
    final fixedUtc = DateTime.parse('2026-06-24T15:30:00.000Z');

    test('today covers the local calendar day', () {
      final (start, end) = ShopLogic.periodWindowUtc(Period.today, fixedUtc);
      expect(
        start.isBefore(DateTime.parse('2026-06-24T00:00:00.000Z')),
        isTrue,
      );
      expect(end.isAfter(fixedUtc), isTrue);
    });

    test('week reaches back 7 days', () {
      final (start, _) = ShopLogic.periodWindowUtc(Period.week, fixedUtc);
      expect(fixedUtc.toLocal().difference(start.toLocal()).inDays, 7);
    });

    test('month starts at the first of the calendar month', () {
      final (start, _) = ShopLogic.periodWindowUtc(Period.month, fixedUtc);
      expect(start.toLocal().day, 1);
    });

    test('all-covers everything', () {
      final (start, _) = ShopLogic.periodWindowUtc(Period.all, fixedUtc);
      expect(start.year, 1970);
    });
  });
}
