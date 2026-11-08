import 'package:drift/drift.dart';

import '../../core/utils/uuid.dart';
import '../database/app_database.dart';
import '../models/shop_models.dart';

abstract interface class InventoryRepository {
  Future<String> addStockAdjustment(StockAdjustmentInput input);
  Stream<List<StockAdjustmentOverview>> watchStockAdjustments();
  Future<String> addReconciliation(ReconciliationInput input);
  Stream<List<ReconciliationRow>> watchReconciliations();
  Future<int> getExpectedCashBalance();
  Stream<int> watchLossesInPeriod({
    required DateTime start,
    required DateTime end,
  });
}

final class LocalInventoryRepository implements InventoryRepository {
  LocalInventoryRepository(this._db);

  final AppDatabase _db;

  @override
  Future<String> addStockAdjustment(StockAdjustmentInput input) async {
    final id = newUuid();
    final now = DateTime.now().toUtc();
    final dateUtc = input.date.isUtc ? input.date : input.date.toUtc();

    await _db
        .into(_db.stockAdjustments)
        .insert(
          StockAdjustmentsCompanion.insert(
            id: id,
            purchaseId: Value(input.purchaseId),
            categoryId: Value(input.categoryId),
            quantityChange: input.quantityChange,
            reason: input.reason.dbValue,
            valueAtCost: input.valueAtCostCents,
            date: dateUtc,
            note: Value(input.note),
            photoPath: Value(input.photoPath),
            createdAt: now,
            updatedAt: now,
          ),
        );

    return id;
  }

  @override
  Stream<List<StockAdjustmentOverview>> watchStockAdjustments() {
    final query =
        _db.select(_db.stockAdjustments).join([
            leftOuterJoin(
              _db.purchases,
              _db.purchases.id.equalsExp(_db.stockAdjustments.purchaseId),
            ),
            leftOuterJoin(
              _db.categories,
              _db.categories.id.equalsExp(_db.stockAdjustments.categoryId),
            ),
            leftOuterJoin(
              _db.colorOptions,
              _db.colorOptions.id.equalsExp(_db.purchases.colorId),
            ),
          ])
          ..where(_db.stockAdjustments.deletedAt.isNull())
          ..orderBy([OrderingTerm.desc(_db.stockAdjustments.date)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final adj = row.readTable(_db.stockAdjustments);
        final cat = row.readTableOrNull(_db.categories);
        final col = row.readTableOrNull(_db.colorOptions);

        return StockAdjustmentOverview(
          id: adj.id,
          purchaseId: adj.purchaseId ?? '',
          categoryName: cat?.name ?? 'Unknown item',
          colorName: col?.name ?? '—',
          quantityChange: adj.quantityChange,
          reason: StockAdjustmentReason.fromDbValue(adj.reason),
          valueAtCostCents: adj.valueAtCost,
          date: adj.date.isUtc ? adj.date.toLocal() : adj.date,
          note: adj.note,
          photoPath: adj.photoPath,
        );
      }).toList();
    });
  }

  @override
  Future<String> addReconciliation(ReconciliationInput input) async {
    final id = newUuid();
    final now = DateTime.now().toUtc();
    final dateUtc = input.date.isUtc ? input.date : input.date.toUtc();
    final diff = input.countedCents - input.expectedCents;

    await _db
        .into(_db.reconciliations)
        .insert(
          ReconciliationsCompanion.insert(
            id: id,
            type: input.type,
            accountId: Value(input.accountId),
            expected: input.expectedCents,
            counted: input.countedCents,
            difference: diff,
            date: dateUtc,
            note: Value(input.note),
            createdAt: now,
            updatedAt: now,
          ),
        );

    return id;
  }

  @override
  Stream<List<ReconciliationRow>> watchReconciliations() {
    return (_db.select(_db.reconciliations)
          ..where((r) => r.deletedAt.isNull())
          ..orderBy([(r) => OrderingTerm.desc(r.date)]))
        .watch();
  }

  @override
  Future<int> getExpectedCashBalance() async {
    // 1. Cash sales paid amount
    final salesQuery = _db.selectOnly(_db.sales)
      ..addColumns([_db.sales.paidAmount.sum()])
      ..where(
        _db.sales.accountId.equals('acc_cash') & _db.sales.deletedAt.isNull(),
      );
    final salesRow = await salesQuery.getSingle();
    final cashIn = salesRow.read(_db.sales.paidAmount.sum()) ?? 0;

    // 2. Cash purchases
    final purchasesQuery = _db.selectOnly(_db.purchases)
      ..addColumns([_db.purchases.totalCost.sum()])
      ..where(
        _db.purchases.accountId.equals('acc_cash') &
            _db.purchases.deletedAt.isNull(),
      );
    final purchasesRow = await purchasesQuery.getSingle();
    final cashOutPurchases =
        purchasesRow.read(_db.purchases.totalCost.sum()) ?? 0;

    // 3. Cash expenses
    final expensesQuery = _db.selectOnly(_db.expenses)
      ..addColumns([_db.expenses.amount.sum()])
      ..where(
        _db.expenses.accountId.equals('acc_cash') &
            _db.expenses.deletedAt.isNull(),
      );
    final expensesRow = await expensesQuery.getSingle();
    final cashOutExpenses = expensesRow.read(_db.expenses.amount.sum()) ?? 0;

    return cashIn - cashOutPurchases - cashOutExpenses;
  }

  @override
  Stream<int> watchLossesInPeriod({
    required DateTime start,
    required DateTime end,
  }) {
    final startUtc = start.isUtc ? start : start.toUtc();
    final endUtc = end.isUtc ? end : end.toUtc();

    final query = _db.selectOnly(_db.stockAdjustments)
      ..addColumns([_db.stockAdjustments.valueAtCost.sum()])
      ..where(
        _db.stockAdjustments.deletedAt.isNull() &
            _db.stockAdjustments.date.isBiggerOrEqualValue(startUtc) &
            _db.stockAdjustments.date.isSmallerThanValue(endUtc) &
            (_db.stockAdjustments.reason.equals('damaged') |
                _db.stockAdjustments.reason.equals('lost') |
                _db.stockAdjustments.reason.equals('personal_use')),
      );

    return query.watchSingle().map((row) {
      return row.read(_db.stockAdjustments.valueAtCost.sum()) ?? 0;
    });
  }
}
