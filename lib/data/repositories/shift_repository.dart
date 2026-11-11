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
  Future<ShiftSummaryData> getShiftSummary(String shiftId);
  Future<void> closeShift({
    required String shiftId,
    required int actualCashCents,
    int? actualBankCents,
    int? actualDebitCents,
    String? notes,
    String? closedBy,
  });
  Future<void> autoCloseShift(
    String shiftId, {
    required DateTime cutoff,
    String reason = 'Auto-closed at 11:30 PM (missed close)',
  });
  Future<void> checkAndAutoCloseExpiredShifts([DateTime? now]);
  DateTime computeShiftCutoff(DateTime openedAtUtc);
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
        .watchSingleOrNull()
        .asyncMap((shift) async {
          if (shift != null) {
            final cutoff = computeShiftCutoff(shift.openedAt);
            if (DateTime.now().isAfter(cutoff)) {
              await autoCloseShift(shift.id, cutoff: cutoff);
              return null;
            }
          }
          return shift;
        });
  }

  @override
  Future<ShiftRow?> getCurrentShift() async {
    await checkAndAutoCloseExpiredShifts();
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
    await checkAndAutoCloseExpiredShifts();
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
    final summary = await getShiftSummary(shiftId);
    return summary.expectedCashCents;
  }

  @override
  Future<ShiftSummaryData> getShiftSummary(String shiftId) async {
    final shift = await (_db.select(
      _db.shifts,
    )..where((s) => s.id.equals(shiftId))).getSingleOrNull();

    if (shift == null) {
      return ShiftSummaryData(
        shiftId: shiftId,
        openingCashCents: 0,
        cashSalesCents: 0,
        bankSalesCents: 0,
        debitSalesCents: 0,
        totalEarnedCents: 0,
        totalSalesRevenueCents: 0,
        cashExpensesCents: 0,
        cashPurchasesCents: 0,
        expectedCashCents: 0,
        creditItems: const [],
        creditTotalCents: 0,
      );
    }

    final openingCash = shift.openingCash;

    // 1. Sales query joined with purchases, categories, and colors
    final salesQuery = _db.select(_db.sales).join([
      innerJoin(
        _db.purchases,
        _db.purchases.id.equalsExp(_db.sales.purchaseId),
      ),
      innerJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.purchases.categoryId),
      ),
      innerJoin(
        _db.colorOptions,
        _db.colorOptions.id.equalsExp(_db.purchases.colorId),
      ),
    ])..where(
        _db.sales.shiftId.equals(shiftId) & _db.sales.deletedAt.isNull(),
      );

    final rows = await salesQuery.get();

    var cashSales = 0;
    var bankSales = 0;
    var debitSales = 0;
    var totalSalesRevenue = 0;
    final creditItems = <ShiftCreditItem>[];
    var creditTotal = 0;

    for (final row in rows) {
      final sale = row.readTable(_db.sales);
      final cat = row.readTable(_db.categories);
      final col = row.readTable(_db.colorOptions);

      final totalRev = sale.unitPrice * sale.quantity;
      final paid = sale.paidAmount ?? totalRev;
      final unpaid = totalRev - paid;

      totalSalesRevenue += totalRev;

      final acc = sale.accountId ?? 'acc_cash';
      if (acc == 'acc_cash') {
        cashSales += paid;
      } else if (acc == 'acc_telebirr') {
        debitSales += paid;
      } else {
        bankSales += paid;
      }

      if (unpaid > 0) {
        creditTotal += unpaid;
        creditItems.add(
          ShiftCreditItem(
            id: sale.id,
            personName: 'Customer (credit sale)',
            itemDescription: '${cat.name} (${col.name}) x${sale.quantity}',
            totalAmountCents: totalRev,
            paidAmountCents: paid,
            creditAmountCents: unpaid,
          ),
        );
      }
    }

    // 2. Enrich credit customer names or add supplier credits from debts logged during shift
    final debts = await (_db.select(_db.debts)
          ..where(
            (d) =>
                d.createdAt.isBiggerOrEqualValue(shift.openedAt) &
                d.deletedAt.isNull(),
          ))
        .get();

    for (final d in debts) {
      if (d.direction == 'i_owe' && !d.isPaid) {
        // Supplier credit purchase
        creditItems.add(
          ShiftCreditItem(
            id: d.id,
            personName: d.personName,
            itemDescription: d.note ?? 'Supplier credit purchase',
            totalAmountCents: d.amount,
            paidAmountCents: 0,
            creditAmountCents: d.amount,
            isSupplierCredit: true,
          ),
        );
        creditTotal += d.amount;
      } else if (d.direction == 'owed_to_me') {
        // Match customer name from debt
        for (var i = 0; i < creditItems.length; i++) {
          final item = creditItems[i];
          if (!item.isSupplierCredit &&
              item.personName.startsWith('Customer') &&
              d.amount == item.creditAmountCents) {
            creditItems[i] = ShiftCreditItem(
              id: item.id,
              personName: d.personName,
              itemDescription: item.itemDescription,
              totalAmountCents: item.totalAmountCents,
              paidAmountCents: item.paidAmountCents,
              creditAmountCents: item.creditAmountCents,
            );
            break;
          }
        }
      }
    }

    // 3. Cash spent on expenses in this shift
    final expQuery = _db.selectOnly(_db.expenses)
      ..addColumns([_db.expenses.amount.sum()])
      ..where(
        _db.expenses.shiftId.equals(shiftId) &
            _db.expenses.accountId.equals('acc_cash') &
            _db.expenses.deletedAt.isNull(),
      );
    final expRow = await expQuery.getSingle();
    final cashExpenses = expRow.read(_db.expenses.amount.sum()) ?? 0;

    // 4. Cash spent on batch purchases in this shift
    final batchQuery = _db.selectOnly(_db.batches)
      ..addColumns([_db.batches.totalPaid.sum()])
      ..where(
        _db.batches.shiftId.equals(shiftId) &
            _db.batches.accountId.equals('acc_cash') &
            _db.batches.deletedAt.isNull(),
      );
    final batchRow = await batchQuery.getSingle();
    final cashPurchases = batchRow.read(_db.batches.totalPaid.sum()) ?? 0;

    final totalEarned = cashSales + bankSales + debitSales;
    final expectedCash = openingCash + cashSales - cashExpenses - cashPurchases;

    return ShiftSummaryData(
      shiftId: shiftId,
      openingCashCents: openingCash,
      cashSalesCents: cashSales,
      bankSalesCents: bankSales,
      debitSalesCents: debitSales,
      totalEarnedCents: totalEarned,
      totalSalesRevenueCents: totalSalesRevenue,
      cashExpensesCents: cashExpenses,
      cashPurchasesCents: cashPurchases,
      expectedCashCents: expectedCash,
      creditItems: creditItems,
      creditTotalCents: creditTotal,
    );
  }

  @override
  Future<void> closeShift({
    required String shiftId,
    required int actualCashCents,
    int? actualBankCents,
    int? actualDebitCents,
    String? notes,
    String? closedBy,
  }) async {
    return _db.transaction(() async {
      final summary = await getShiftSummary(shiftId);
      final diff = actualCashCents - summary.expectedCashCents;
      final now = DateTime.now().toUtc();

      await (_db.update(_db.shifts)..where((s) => s.id.equals(shiftId))).write(
        ShiftsCompanion(
          closedAt: Value(now),
          expectedCash: Value(summary.expectedCashCents),
          actualCash: Value(actualCashCents),
          cashDifference: Value(diff),
          notes: Value(notes),
          closedBy: Value(closedBy),
          updatedAt: Value(now),
        ),
      );

      // 1. Create reconciliation record for cash
      final reconId = newUuid();
      await _db
          .into(_db.reconciliations)
          .insert(
            ReconciliationsCompanion.insert(
              id: reconId,
              type: 'cash_account',
              accountId: const Value('acc_cash'),
              expected: summary.expectedCashCents,
              counted: actualCashCents,
              difference: diff,
              date: now,
              note: Value('Shift close cash: ${notes ?? ""}'),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 2. Reconcile bank if entered
      if (actualBankCents != null) {
        final bankDiff = actualBankCents - summary.bankSalesCents;
        await _db
            .into(_db.reconciliations)
            .insert(
              ReconciliationsCompanion.insert(
                id: newUuid(),
                type: 'cash_account',
                accountId: const Value('acc_bank'),
                expected: summary.bankSalesCents,
                counted: actualBankCents,
                difference: bankDiff,
                date: now,
                note: Value('Shift close bank: ${notes ?? ""}'),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }

      // 3. Reconcile debit / telebirr if entered
      if (actualDebitCents != null) {
        final debitDiff = actualDebitCents - summary.debitSalesCents;
        await _db
            .into(_db.reconciliations)
            .insert(
              ReconciliationsCompanion.insert(
                id: newUuid(),
                type: 'cash_account',
                accountId: const Value('acc_telebirr'),
                expected: summary.debitSalesCents,
                counted: actualDebitCents,
                difference: debitDiff,
                date: now,
                note: Value('Shift close debit: ${notes ?? ""}'),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
    });
  }

  @override
  DateTime computeShiftCutoff(DateTime openedAtUtc) {
    final openedLocal = openedAtUtc.toLocal();
    DateTime cutoff;
    if (openedLocal.hour < 23 ||
        (openedLocal.hour == 23 && openedLocal.minute < 30)) {
      cutoff = DateTime(
        openedLocal.year,
        openedLocal.month,
        openedLocal.day,
        23,
        30,
      );
    } else {
      final nextDay = openedLocal.add(const Duration(days: 1));
      cutoff = DateTime(
        nextDay.year,
        nextDay.month,
        nextDay.day,
        23,
        30,
      );
    }
    return cutoff;
  }

  @override
  Future<void> autoCloseShift(
    String shiftId, {
    required DateTime cutoff,
    String reason = 'Auto-closed at 11:30 PM (missed close)',
  }) async {
    return _db.transaction(() async {
      final summary = await getShiftSummary(shiftId);
      final cutoffUtc = cutoff.toUtc();

      await (_db.update(_db.shifts)..where((s) => s.id.equals(shiftId))).write(
        ShiftsCompanion(
          closedAt: Value(cutoffUtc),
          expectedCash: Value(summary.expectedCashCents),
          actualCash: Value(summary.expectedCashCents),
          cashDifference: const Value(0),
          notes: Value(reason),
          closedBy: const Value('System (Auto-close)'),
          updatedAt: Value(cutoffUtc),
        ),
      );

      final reconId = newUuid();
      await _db
          .into(_db.reconciliations)
          .insert(
            ReconciliationsCompanion.insert(
              id: reconId,
              type: 'cash_account',
              accountId: const Value('acc_cash'),
              expected: summary.expectedCashCents,
              counted: summary.expectedCashCents,
              difference: 0,
              date: cutoffUtc,
              note: Value(reason),
              createdAt: cutoffUtc,
              updatedAt: cutoffUtc,
            ),
          );
    });
  }

  @override
  Future<void> checkAndAutoCloseExpiredShifts([DateTime? now]) async {
    final unclosed = await (_db.select(_db.shifts)
          ..where((s) => s.closedAt.isNull() & s.deletedAt.isNull())
          ..orderBy([(s) => OrderingTerm.asc(s.openedAt)]))
        .get();

    final checkTime = now ?? DateTime.now();
    for (final shift in unclosed) {
      final cutoff = computeShiftCutoff(shift.openedAt);
      if (checkTime.isAfter(cutoff)) {
        await autoCloseShift(shift.id, cutoff: cutoff);
      }
    }
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
