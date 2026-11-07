import 'dart:async';

import 'package:drift/drift.dart';

import '../../core/utils/uuid.dart';
import '../database/app_database.dart';
import 'exceptions.dart';

/// Data access for colors. Deletes are soft; a used color cannot be
/// deleted (`files/DATABASE.md`).
abstract interface class ColorRepository {
  Future<ColorRow> add({required String name, required String hex});

  Stream<List<ColorRow>> watchAll();

  Future<List<ColorRow>> getAll();

  Future<void> rename(String id, {required String name, required String hex});

  Future<void> softDelete(String id);
}

final class LocalColorRepository implements ColorRepository {
  LocalColorRepository(this._db);

  final AppDatabase _db;

  @override
  Future<ColorRow> add({required String name, required String hex}) async {
    final now = DateTime.now().toUtc();
    final companion = ColorOptionsCompanion.insert(
      id: newUuid(),
      name: name.trim(),
      hex: hex.toUpperCase(),
      isPreset: false,
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.colorOptions).insert(companion);
    final query = _db.select(_db.colorOptions)
      ..where((row) => row.id.equals(companion.id.value));
    return query.getSingle();
  }

  @override
  Stream<List<ColorRow>> watchAll() {
    return _db.select(_db.colorOptions).watch().map(_filterAndSort);
  }

  @override
  Future<List<ColorRow>> getAll() async {
    final rows = await _db.select(_db.colorOptions).get();
    return _filterAndSort(rows);
  }

  @override
  Future<void> rename(String id, {required String name, required String hex}) {
    return (_db.update(
      _db.colorOptions,
    )..where((row) => row.id.equals(id))).write(
      ColorOptionsCompanion(
        name: Value(name.trim()),
        hex: Value(hex.toUpperCase()),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Future<void> softDelete(String id) async {
    final query = _db.selectOnly(_db.purchases)
      ..addColumns([_db.purchases.id.count()])
      ..where(
        _db.purchases.colorId.equals(id) & _db.purchases.deletedAt.isNull(),
      );
    final usedCount =
        (await query.getSingle()).read(_db.purchases.id.count()) ?? 0;
    if (usedCount > 0) {
      final color = await (_db.select(
        _db.colorOptions,
      )..where((row) => row.id.equals(id))).getSingleOrNull();
      throw ColorInUseException(color?.name ?? id);
    }
    await (_db.update(_db.colorOptions)..where((row) => row.id.equals(id)))
        .write(ColorOptionsCompanion(deletedAt: Value(DateTime.now().toUtc())));
  }

  List<ColorRow> _filterAndSort(List<ColorRow> rows) {
    return rows.where((row) => row.deletedAt == null).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}
