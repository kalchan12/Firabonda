import 'package:firabonda/core/utils/profit_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Task 5: ProfitCalculator spec table tests', () {
    test(
      'Row 1: Cost 200, Assumed 400, Sold 450 -> Over profit (+250, 125% of target, +50 over)',
      () {
        final result = ProfitCalculator.calculate(
          costCents: 20000,
          assumedSellingPriceCents: 40000,
          actualSellingPriceCents: 45000,
        );

        expect(result.actualProfitCents, 25000);
        expect(result.assumedProfitCents, 20000);
        expect(result.percentOfTarget, 125);
        expect(result.overProfitCents, 5000);
        expect(result.status, ProfitStatus.overProfit);
      },
    );

    test(
      'Row 2: Cost 200, Assumed 400, Sold 400 -> On target (+200, 100% of target)',
      () {
        final result = ProfitCalculator.calculate(
          costCents: 20000,
          assumedSellingPriceCents: 40000,
          actualSellingPriceCents: 40000,
        );

        expect(result.actualProfitCents, 20000);
        expect(result.assumedProfitCents, 20000);
        expect(result.percentOfTarget, 100);
        expect(result.overProfitCents, isNull);
        expect(result.status, ProfitStatus.onTarget);
      },
    );

    test(
      'Row 3: Cost 200, Assumed 400, Sold 350 -> Under target (+150, 75% of target)',
      () {
        final result = ProfitCalculator.calculate(
          costCents: 20000,
          assumedSellingPriceCents: 40000,
          actualSellingPriceCents: 35000,
        );

        expect(result.actualProfitCents, 15000);
        expect(result.assumedProfitCents, 20000);
        expect(result.percentOfTarget, 75);
        expect(result.overProfitCents, isNull);
        expect(result.status, ProfitStatus.underTarget);
      },
    );

    test(
      'Row 4: Cost 200, Assumed 400, Sold 200 -> Breakeven (0, 0% of target)',
      () {
        final result = ProfitCalculator.calculate(
          costCents: 20000,
          assumedSellingPriceCents: 40000,
          actualSellingPriceCents: 20000,
        );

        expect(result.actualProfitCents, 0);
        expect(result.percentOfTarget, 0);
        expect(result.status, ProfitStatus.breakeven);
      },
    );

    test(
      'Row 5: Cost 200, Assumed 400, Sold 180 -> Loss (-20, Loss status)',
      () {
        final result = ProfitCalculator.calculate(
          costCents: 20000,
          assumedSellingPriceCents: 40000,
          actualSellingPriceCents: 18000,
        );

        expect(result.actualProfitCents, -2000);
        expect(result.percentOfTarget, isNull);
        expect(result.status, ProfitStatus.loss);
      },
    );

    test(
      'Row 6: Cost 200, Assumed null, Sold 300 -> Not assumed (+100, Target not assumed)',
      () {
        final result = ProfitCalculator.calculate(
          costCents: 20000,
          assumedSellingPriceCents: null,
          actualSellingPriceCents: 30000,
        );

        expect(result.actualProfitCents, 10000);
        expect(result.assumedProfitCents, isNull);
        expect(result.percentOfTarget, isNull);
        expect(result.status, ProfitStatus.notAssumed);
      },
    );

    test('Quantity scales profit and over-profit proportionally', () {
      final result = ProfitCalculator.calculate(
        costCents: 10000,
        assumedSellingPriceCents: 15000,
        actualSellingPriceCents: 18000,
        quantity: 5,
      );

      // Single item: cost 100, assumed 150, actual 180
      // 5 items: cost 500, assumed 750, actual 900
      expect(result.actualProfitCents, 40000); // 80 * 5 = 400 ETB
      expect(result.assumedProfitCents, 25000); // 50 * 5 = 250 ETB
      expect(result.overProfitCents, 15000); // 30 * 5 = 150 ETB
      expect(result.percentOfTarget, 160); // 400 / 250 = 160%
      expect(result.status, ProfitStatus.overProfit);
    });

    test('Edge case: Zero cost item', () {
      final result = ProfitCalculator.calculate(
        costCents: 0,
        assumedSellingPriceCents: 20000,
        actualSellingPriceCents: 20000,
      );

      expect(result.actualProfitCents, 20000);
      expect(result.percentOfTarget, 100);
      expect(result.status, ProfitStatus.onTarget);
    });

    test(
      'Edge case: Assumed price <= cost (invalid target -> treated as not assumed)',
      () {
        final result = ProfitCalculator.calculate(
          costCents: 20000,
          assumedSellingPriceCents: 15000, // lower than cost
          actualSellingPriceCents: 30000,
        );

        expect(result.actualProfitCents, 10000);
        expect(result.percentOfTarget, isNull);
        expect(result.status, ProfitStatus.notAssumed);
      },
    );
  });
}
