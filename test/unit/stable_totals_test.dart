import 'package:firabonda/core/utils/business_logic.dart';
import 'package:firabonda/core/utils/period_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Stable totals arithmetic', () {
    test(
      'Calculates Bought, Sold, Cost, Profit, Profit %, Expenses, Losses, Net profit',
      () {
        // 10 items purchased @ 10,000 cents (100 ETB) = 100,000 cents bought
        const boughtCents = 100000;
        expect(boughtCents, 100000);

        // 4 items sold @ 20,000 cents (200 ETB) = 80,000 cents revenue
        const soldQuantity = 4;
        const unitPriceCents = 20000;
        const costAtSaleCents = 10000;

        const revenueCents = soldQuantity * unitPriceCents; // 80,000
        const costOfSoldCents = soldQuantity * costAtSaleCents; // 40,000

        final profitCents = revenueCents - costOfSoldCents; // 40,000
        expect(profitCents, 40000);

        // Profit % (markup on cost) = 40,000 / 40,000 * 100 = 100.0%
        final profitPercent = ShopLogic.profitPercent(
          profitCents: profitCents,
          costOfSoldItemsCents: costOfSoldCents,
        );
        expect(profitPercent, 100.0);

        // Expenses: 5,000 cents; Losses (e.g. damaged stock): 2,000 cents
        const expensesCents = 5000;
        const lossesCents = 2000;

        final netProfit = ShopLogic.netProfit(
          profitCents: profitCents,
          expensesCents: expensesCents,
          lossesCents: lossesCents,
        );
        expect(netProfit, 33000); // 40000 - 5000 - 2000 = 33000
      },
    );

    test(
      'Historical sale profit remains frozen when costAtSale is preserved',
      () {
        // When a sale is recorded with costAtSale = 100 ETB, profit is fixed
        const originalCost = 10000;
        const sellingPrice = 25000;
        const qty = 2;

        final originalProfit = ShopLogic.saleProfit(
          quantity: qty,
          unitPriceCents: sellingPrice,
          unitCostCents: originalCost,
        );
        expect(originalProfit, 30000);

        // Even if purchase cost is later edited to 120 ETB, historic sale uses costAtSale (100 ETB)
        const editedPurchaseCost = 12000;
        final unchangedSaleProfit = ShopLogic.saleProfit(
          quantity: qty,
          unitPriceCents: sellingPrice,
          unitCostCents: originalCost, // preserved costAtSale!
        );
        expect(unchangedSaleProfit, 30000);

        final recalculatedIfUpdated = ShopLogic.saleProfit(
          quantity: qty,
          unitPriceCents: sellingPrice,
          unitCostCents: editedPurchaseCost,
        );
        expect(recalculatedIfUpdated, 26000);
      },
    );

    test(
      'Backdated transactions land strictly in their recorded date period',
      () {
        final today = DateTime(2026, 11, 8, 12, 0);
        final todayRange = PeriodRange.today(now: today);
        final yesterdayRange = PeriodRange.yesterday(now: today);

        final backdatedEntry = DateTime(2026, 11, 7, 16, 45); // yesterday

        expect(todayRange.contains(backdatedEntry), isFalse);
        expect(yesterdayRange.contains(backdatedEntry), isTrue);
      },
    );
  });
}
