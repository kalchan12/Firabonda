import 'package:drift/drift.dart';
import '../../core/utils/uuid.dart';
import '../database/app_database.dart';
import '../models/shop_models.dart';

abstract interface class ShiftRepository {
  Stream<ShiftRow?> watchCurrentShift();
  Future<ShiftRow?> getCurrentShift();
  Future<ShiftRow?> getLatestShift();
  Future<String> openShift({int openingCashCents = 0, String? openedBy});
  Future<int> computeExpectedCash(String shiftId);
  Future<void> closeShift({
    required String shiftId,
    required int actualCashCents,
    String? notes,
    String? closedBy,
  });
  Stream<List<ShiftOverview>> watchShiftHistory();
}

final class LocalShiftRepository implements ShiftRepository {
  const LocalShiftRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<ShiftRow?> watchCurrentShift() {
    return (_db.select(_db.shifts)
          ..where((s) => s.closedAt.isNull() & s.deletedAt.isNull())
          ..orderBy([(s) => OrderingTerm.desc(s.openedAt)])
          ..limit(1))
        .watchSingleOrNull();
  }

  @override
  Future<ShiftRow?> getCurrentShift() {
    return (_db.select(_db.shifts)
          ..where((s) => s.closedAt.isNull() & s.deletedAt.isNull())
          ..orderBy([(s) => OrderingTerm.desc(s.openedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  @override
  Future<ShiftRow?> getLatestShift() {
    return (_db.select(_db.shifts)
          ..where((s) => s.deletedAt.isNull())
          ..orderBy([(s) => OrderingTerm.desc(s.openedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  @override
  Future<String> openShift({int openingCashCents = 0, String? openedBy}) async {
    final existing = await getCurrentShift();
    if (existing != null) {
      return existing.id;
    }

    final id = newUuid();
    final now = DateTime.now().toUtc();
    await _db
        .into(_db.shifts)
        .insert(
          ShiftsCompanion.insert(
            id: id,
            openedAt: now,
            openingCash: Value(openingCashCents),
            openedBy: Value(openedBy),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  @override
  Future<int> computeExpectedCash(String shiftId) async {
    final shift = await (_db.select(
      _db.shifts,
    )..where((s) => s.id.equals(shiftId))).getSingleOrNull();
    if (shift == null) return 0;

    // 1. Cash from sales belonging to this shift
    final salesQuery = _db.selectOnly(_db.sales)
      ..addColumns([_db.sales.paidAmount.sum()])
      ..where(
        _db.sales.shiftId.equals(shiftId) &
            _db.sales.accountId.equals('acc_cash') &
            _db.sales.deletedAt.isNull(),
      );
    final salesRow = await salesQuery.getSingle();
    final cashSales = salesRow.read(_db.sales.paidAmount.sum()) ?? 0;

    // 2. Cash spent on expenses in this shift
    final expQuery = _db.selectOnly(_db.expenses)
      ..addColumns([_db.expenses.amount.sum()])
      ..where(
        _db.expenses.shiftId.equals(shiftId) &
            _db.expenses.accountId.equals('acc_cash') &
            _db.expenses.deletedAt.isNull(),
      );
    final expRow = await expQuery.getSingle();
    final cashExpenses = expRow.read(_db.expenses.amount.sum()) ?? 0;

    // 3. Cash spent on batch purchases in this shift
    final batchQuery = _db.selectOnly(_db.batches)
      ..addColumns([_db.batches.totalPaid.sum()])
      ..where(
        _db.batches.shiftId.equals(shiftId) &
            _db.batches.accountId.equals('acc_cash') &
            _db.batches.deletedAt.isNull(),
      );
    final batchRow = await batchQuery.getSingle();
    final cashPurchases = batchRow.read(_db.batches.totalPaid.sum()) ?? 0;

    return shift.openingCash + cashSales - cashExpenses - cashPurchases;
  }

  @override
  Future<void> closeShift({
    required String shiftId,
    required int actualCashCents,
    String? notes,
    String? closedBy,
  }) async {
    return _db.transaction(() async {
      final expected = await computeExpectedCash(shiftId);
      final diff = actualCashCents - expected;
      final now = DateTime.now().toUtc();

      await (_db.update(_db.shifts)..where((s) => s.id.equals(shiftId))).write(
        ShiftsCompanion(
          closedAt: Value(now),
          expectedCash: Value(expected),
          actualCash: Value(actualCashCents),
          cashDifference: Value(diff),
          notes: Value(notes),
          closedBy: Value(closedBy),
          updatedAt: Value(now),
        ),
      );

      // Create reconciliation record
      final reconId = newUuid();
      await _db
          .into(_db.reconciliations)
          .insert(
            ReconciliationsCompanion.insert(
              id: reconId,
              type: 'cash_account',
              accountId: const Value('acc_cash'),
              expected: expected,
              counted: actualCashCents,
              difference: diff,
              date: now,
              note: Value('Shift close reconciliation: ${notes ?? ""}'),
              createdAt: now,
              updatedAt: now,
            ),
          );
    });
  }

  @override
  Stream<List<ShiftOverview>> watchShiftHistory() {
    return (_db.select(_db.shifts)
          ..where((s) => s.deletedAt.isNull())
          ..orderBy([(s) => OrderingTerm.desc(s.openedAt)]))
        .watch()
        .asyncMap((shifts) async {
          final list = <ShiftOverview>[];
          for (final s in shifts) {
            // Sales totals for shift
            final sales =
                await (_db.select(_db.sales)..where(
                      (sale) =>
                          sale.shiftId.equals(s.id) & sale.deletedAt.isNull(),
                    ))
                    .get();

            var totalRevenue = 0;
            var totalProfit = 0;
            for (final sale in sales) {
              totalRevenue += sale.unitPrice * sale.quantity;
              final cost = sale.costAtSale ?? 0;
              totalProfit += (sale.unitPrice - cost) * sale.quantity;
            }

            // Expenses total for shift
            final expensesQuery = _db.selectOnly(_db.expenses)
              ..addColumns([_db.expenses.amount.sum()])
              ..where(
                _db.expenses.shiftId.equals(s.id) &
                    _db.expenses.deletedAt.isNull(),
              );
            final expRow = await expensesQuery.getSingle();
            final totalExpenses = expRow.read(_db.expenses.amount.sum()) ?? 0;

            list.add(
              ShiftOverview(
                id: s.id,
                openedAt: s.openedAt,
                closedAt: s.closedAt,
                openingCashCents: s.openingCash,
                expectedCashCents: s.expectedCash,
                actualCashCents: s.actualCash,
                cashDifferenceCents: s.cashDifference,
                notes: s.notes,
                openedBy: s.openedBy,
                closedBy: s.closedBy,
                totalSalesCents: totalRevenue,
                totalProfitCents: totalProfit,
                totalExpensesCents: totalExpenses,
                salesCount: sales.length,
              ),
            );
          }
          return list;
        });
  }
}
