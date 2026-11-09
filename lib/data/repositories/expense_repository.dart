import 'dart:async';

import 'package:drift/drift.dart';

import '../../core/utils/uuid.dart';
import '../database/app_database.dart';
import '../models/shop_models.dart';

/// Data access for expenses (rent, transport, ...). Subtracted from
/// profit on the dashboard.
abstract interface class ExpenseRepository {
  Future<String> add(ExpenseInput input);

  Stream<List<ExpenseRow>> watchAll();

  Future<List<ExpenseRow>> getAll();

  Future<void> softDelete(String id);

  /// Restores a soft-deleted expense.
  Future<void> restore(String id);

  /// Sum of all expense amounts inside the window; money in cents.
  Future<int> totalBetween(DateTime startUtc, DateTime endUtc);
}

final class LocalExpenseRepository implements ExpenseRepository {
  LocalExpenseRepository(this._db);

  final AppDatabase _db;

  @override
  Future<String> add(ExpenseInput input) async {
    final now = DateTime.now().toUtc();
    final id = newUuid();

    final openShift = input.shiftId != null
        ? null
        : await (_db.select(_db.shifts)
                ..where((s) => s.closedAt.isNull() & s.deletedAt.isNull())
                ..orderBy([(s) => OrderingTerm.desc(s.openedAt)])
                ..limit(1))
              .getSingleOrNull();
    final shiftId = input.shiftId ?? openShift?.id;

    await _db
        .into(_db.expenses)
        .insert(
          ExpensesCompanion.insert(
            id: id,
            title: input.title.trim(),
            amount: input.amountCents,
            date: _utc(input.date),
            accountId: const Value('acc_cash'),
            shiftId: Value(shiftId),
            note: Value(input.note),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  @override
  Stream<List<ExpenseRow>> watchAll() {
    return _db.select(_db.expenses).watch().map(_filterAndSort);
  }

  @override
  Future<List<ExpenseRow>> getAll() async {
    return _filterAndSort(await _db.select(_db.expenses).get());
  }

  @override
  Future<void> softDelete(String id) {
    return (_db.update(_db.expenses)..where((row) => row.id.equals(id))).write(
      ExpensesCompanion(deletedAt: Value(DateTime.now().toUtc())),
    );
  }

  @override
  Future<void> restore(String id) {
    return (_db.update(_db.expenses)..where((row) => row.id.equals(id))).write(
      const ExpensesCompanion(deletedAt: Value(null)),
    );
  }

  @override
  Future<int> totalBetween(DateTime startUtc, DateTime endUtc) async {
    final query = _db.selectOnly(_db.expenses)
      ..addColumns([_db.expenses.amount.sum()])
      ..where(
        _db.expenses.deletedAt.isNull() &
            _db.expenses.date.isBetweenValues(startUtc, endUtc),
      );
    final row = await query.getSingle();
    return row.read(_db.expenses.amount.sum()) ?? 0;
  }

  List<ExpenseRow> _filterAndSort(List<ExpenseRow> rows) =>
      rows.where((row) => row.deletedAt == null).toList()
        ..sort((a, b) => _asUtc(b.date).compareTo(_asUtc(a.date)));
}

DateTime _utc(DateTime input) => input.isUtc ? input : input.toUtc();

DateTime _asUtc(DateTime stored) => stored.isUtc ? stored : stored.toUtc();
