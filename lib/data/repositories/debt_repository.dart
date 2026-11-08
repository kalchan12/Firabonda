import 'dart:async';

import 'package:drift/drift.dart';

import '../../core/utils/uuid.dart';
import '../database/app_database.dart';
import '../models/shop_models.dart';

/// Data access for the debt and credit tracker.
abstract interface class DebtRepository {
  Future<String> add(DebtInput input);

  Stream<List<DebtRow>> watchAll();

  Future<List<DebtRow>> getAll();

  Future<void> markPaid(String id, {required bool paid});

  Future<void> softDelete(String id);

  /// Restores a soft-deleted debt record.
  Future<void> restore(String id);
}

final class LocalDebtRepository implements DebtRepository {
  LocalDebtRepository(this._db);

  final AppDatabase _db;

  @override
  Future<String> add(DebtInput input) async {
    final now = DateTime.now().toUtc();
    final id = newUuid();
    await _db
        .into(_db.debts)
        .insert(
          DebtsCompanion.insert(
            id: id,
            personName: input.personName.trim(),
            amount: input.amountCents,
            direction: input.direction.dbValue,
            dueDate: Value(input.dueDate == null ? null : _utc(input.dueDate!)),
            isPaid: false,
            note: Value(input.note),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  @override
  Stream<List<DebtRow>> watchAll() {
    return _db.select(_db.debts).watch().map(_filterAndSort);
  }

  @override
  Future<List<DebtRow>> getAll() async {
    return _filterAndSort(await _db.select(_db.debts).get());
  }

  @override
  Future<void> markPaid(String id, {required bool paid}) {
    return (_db.update(_db.debts)..where((row) => row.id.equals(id))).write(
      DebtsCompanion(
        isPaid: Value(paid),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Future<void> softDelete(String id) {
    return (_db.update(_db.debts)..where((row) => row.id.equals(id))).write(
      DebtsCompanion(deletedAt: Value(DateTime.now().toUtc())),
    );
  }

  @override
  Future<void> restore(String id) {
    return (_db.update(_db.debts)..where((row) => row.id.equals(id))).write(
      const DebtsCompanion(deletedAt: Value(null)),
    );
  }

  List<DebtRow> _filterAndSort(List<DebtRow> rows) {
    return rows.where((row) => row.deletedAt == null).toList()..sort((a, b) {
      final paidComparison = (a.isPaid ? 1 : 0).compareTo(b.isPaid ? 1 : 0);
      if (paidComparison != 0) return paidComparison;
      final dueA = a.dueDate;
      final dueB = b.dueDate;
      if (dueA != null && dueB != null) {
        return dueA.compareTo(dueB);
      }
      if (dueA != null) return -1;
      if (dueB != null) return 1;
      return a.personName.toLowerCase().compareTo(b.personName.toLowerCase());
    });
  }
}

DateTime _utc(DateTime input) => input.isUtc ? input : input.toUtc();
