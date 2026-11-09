/// Pure business logic for sales profit and target analysis per Fix Plan V2.1 Task 5.
/// Free of Flutter and database imports. All money is integer cents.
library;

enum ProfitStatus {
  overProfit,
  onTarget,
  underTarget,
  breakeven,
  loss,
  notAssumed,
}

final class ProfitResult {
  const ProfitResult({
    required this.costCents,
    required this.actualSellingPriceCents,
    required this.actualProfitCents,
    required this.status,
    this.assumedSellingPriceCents,
    this.assumedProfitCents,
    this.percentOfTarget,
    this.overProfitCents,
    this.quantity = 1,
  });

  final int costCents;
  final int? assumedSellingPriceCents;
  final int actualSellingPriceCents;
  final int quantity;

  final int actualProfitCents;
  final int? assumedProfitCents;
  final int? percentOfTarget;
  final int? overProfitCents;
  final ProfitStatus status;

  String get statusLabel => switch (status) {
    ProfitStatus.overProfit =>
      overProfitCents != null && overProfitCents! > 0
          ? 'Over profit (+${overProfitCents! ~/ 100} ETB)'
          : 'Over profit (${percentOfTarget ?? 100}%)',
    ProfitStatus.onTarget => '100% of target',
    ProfitStatus.underTarget => '$percentOfTarget% of target',
    ProfitStatus.breakeven => '0% of target (breakeven)',
    ProfitStatus.loss => 'Loss',
    ProfitStatus.notAssumed => 'Target: not assumed',
  };
}

final class ProfitCalculator {
  const ProfitCalculator._();

  static ProfitResult calculate({
    required int costCents,
    int? assumedSellingPriceCents,
    required int actualSellingPriceCents,
    int quantity = 1,
  }) {
    final actualProfit = (actualSellingPriceCents - costCents) * quantity;

    // Check for loss first
    if (actualProfit < 0) {
      return ProfitResult(
        costCents: costCents,
        assumedSellingPriceCents: assumedSellingPriceCents,
        actualSellingPriceCents: actualSellingPriceCents,
        actualProfitCents: actualProfit,
        status: ProfitStatus.loss,
        quantity: quantity,
      );
    }

    // If no assumed selling price or invalid target (assumed <= cost)
    if (assumedSellingPriceCents == null ||
        assumedSellingPriceCents <= costCents) {
      if (actualProfit == 0) {
        return ProfitResult(
          costCents: costCents,
          assumedSellingPriceCents: assumedSellingPriceCents,
          actualSellingPriceCents: actualSellingPriceCents,
          actualProfitCents: 0,
          status: ProfitStatus.breakeven,
          percentOfTarget: 0,
          quantity: quantity,
        );
      }
      return ProfitResult(
        costCents: costCents,
        assumedSellingPriceCents: assumedSellingPriceCents,
        actualSellingPriceCents: actualSellingPriceCents,
        actualProfitCents: actualProfit,
        status: ProfitStatus.notAssumed,
        quantity: quantity,
      );
    }

    final assumedProfit = (assumedSellingPriceCents - costCents) * quantity;

    if (actualProfit == 0) {
      return ProfitResult(
        costCents: costCents,
        assumedSellingPriceCents: assumedSellingPriceCents,
        actualSellingPriceCents: actualSellingPriceCents,
        actualProfitCents: 0,
        assumedProfitCents: assumedProfit,
        percentOfTarget: 0,
        status: ProfitStatus.breakeven,
        quantity: quantity,
      );
    }

    final percentOfTarget = ((actualProfit / assumedProfit) * 100).round();

    if (actualSellingPriceCents > assumedSellingPriceCents) {
      final overProfit =
          (actualSellingPriceCents - assumedSellingPriceCents) * quantity;
      return ProfitResult(
        costCents: costCents,
        assumedSellingPriceCents: assumedSellingPriceCents,
        actualSellingPriceCents: actualSellingPriceCents,
        actualProfitCents: actualProfit,
        assumedProfitCents: assumedProfit,
        percentOfTarget: percentOfTarget,
        overProfitCents: overProfit,
        status: ProfitStatus.overProfit,
        quantity: quantity,
      );
    } else if (actualSellingPriceCents == assumedSellingPriceCents) {
      return ProfitResult(
        costCents: costCents,
        assumedSellingPriceCents: assumedSellingPriceCents,
        actualSellingPriceCents: actualSellingPriceCents,
        actualProfitCents: actualProfit,
        assumedProfitCents: assumedProfit,
        percentOfTarget: 100,
        status: ProfitStatus.onTarget,
        quantity: quantity,
      );
    } else {
      return ProfitResult(
        costCents: costCents,
        assumedSellingPriceCents: assumedSellingPriceCents,
        actualSellingPriceCents: actualSellingPriceCents,
        actualProfitCents: actualProfit,
        assumedProfitCents: assumedProfit,
        percentOfTarget: percentOfTarget,
        status: ProfitStatus.underTarget,
        quantity: quantity,
      );
    }
  }
}
