import 'dart:async';

import 'package:drift/drift.dart';

import '../../core/utils/uuid.dart';
import '../database/app_database.dart';
import '../models/shop_models.dart';

/// Data access for suppliers.
abstract interface class SupplierRepository {
  Future<SupplierRow> add(SupplierInput input);

  Stream<List<SupplierRow>> watchAll();

  Future<List<SupplierRow>> getAll();

  Future<void> update(String id, SupplierInput input);

  Future<void> softDelete(String id);
}

final class LocalSupplierRepository implements SupplierRepository {
  LocalSupplierRepository(this._db);

  final AppDatabase _db;

  @override
  Future<SupplierRow> add(SupplierInput input) async {
    final now = DateTime.now().toUtc();
    final companion = SuppliersCompanion.insert(
      id: newUuid(),
      name: input.name.trim(),
      phone: Value(input.phone),
      note: Value(input.note),
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.suppliers).insert(companion);
    final query = _db.select(_db.suppliers)
      ..where((row) => row.id.equals(companion.id.value));
    return query.getSingle();
  }

  @override
  Stream<List<SupplierRow>> watchAll() {
    return _db.select(_db.suppliers).watch().map(_filterAndSort);
  }

  @override
  Future<List<SupplierRow>> getAll() async {
    return _filterAndSort(await _db.select(_db.suppliers).get());
  }

  @override
  Future<void> update(String id, SupplierInput input) {
    return (_db.update(_db.suppliers)..where((row) => row.id.equals(id))).write(
      SuppliersCompanion(
        name: Value(input.name.trim()),
        phone: Value(input.phone),
        note: Value(input.note),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Future<void> softDelete(String id) {
    return (_db.update(_db.suppliers)..where((row) => row.id.equals(id))).write(
      SuppliersCompanion(deletedAt: Value(DateTime.now().toUtc())),
    );
  }

  List<SupplierRow> _filterAndSort(List<SupplierRow> rows) {
    return rows.where((row) => row.deletedAt == null).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }
}
