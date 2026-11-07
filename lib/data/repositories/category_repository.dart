import 'dart:async';

import 'package:drift/drift.dart';

import '../../core/utils/uuid.dart';
import '../database/app_database.dart';
import 'exceptions.dart';

/// Data access for categories. Deletes are soft to keep purchase history.
abstract interface class CategoryRepository {
  Future<CategoryRow> add({
    required String name,
    required String icon,
    int sortOrder = 0,
  });

  Stream<List<CategoryRow>> watchAll({bool includeArchived = false});

  Future<List<CategoryRow>> getAll({bool includeArchived = false});

  Future<void> rename(String id, {required String name, required String icon});

  Future<void> setArchived(String id, {required bool archived});

  /// Throws [CategoryInUseException] when purchases still reference the
  /// category; archive it instead (`files/DATABASE.md`).
  Future<void> softDelete(String id);
}

final class LocalCategoryRepository implements CategoryRepository {
  LocalCategoryRepository(this._db);

  final AppDatabase _db;

  @override
  Future<CategoryRow> add({
    required String name,
    required String icon,
    int sortOrder = 0,
  }) async {
    final now = DateTime.now().toUtc();
    final companion = CategoriesCompanion.insert(
      id: newUuid(),
      name: name.trim(),
      icon: icon,
      isPreset: false,
      isArchived: false,
      sortOrder: sortOrder,
      createdAt: now,
      updatedAt: now,
    );
    await _db.into(_db.categories).insert(companion);
    final query = _db.select(_db.categories)
      ..where((row) => row.id.equals(companion.id.value));
    return query.getSingle();
  }

  @override
  Stream<List<CategoryRow>> watchAll({bool includeArchived = false}) {
    return _db
        .select(_db.categories)
        .watch()
        .map((rows) => _filterAndSort(rows, includeArchived: includeArchived));
  }

  @override
  Future<List<CategoryRow>> getAll({bool includeArchived = false}) async {
    final rows = await _db.select(_db.categories).get();
    return _filterAndSort(rows, includeArchived: includeArchived);
  }

  @override
  Future<void> rename(String id, {required String name, required String icon}) {
    return (_db.update(
      _db.categories,
    )..where((row) => row.id.equals(id))).write(
      CategoriesCompanion(
        name: Value(name.trim()),
        icon: Value(icon),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Future<void> setArchived(String id, {required bool archived}) {
    return (_db.update(
      _db.categories,
    )..where((row) => row.id.equals(id))).write(
      CategoriesCompanion(
        isArchived: Value(archived),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Future<void> softDelete(String id) async {
    final usedCount = await _alivePurchaseCount(id);
    if (usedCount > 0) {
      final category = await (_db.select(
        _db.categories,
      )..where((row) => row.id.equals(id))).getSingleOrNull();
      throw CategoryInUseException(category?.name ?? id);
    }
    await (_db.update(_db.categories)..where((row) => row.id.equals(id))).write(
      CategoriesCompanion(deletedAt: Value(DateTime.now().toUtc())),
    );
  }

  List<CategoryRow> _filterAndSort(
    List<CategoryRow> rows, {
    required bool includeArchived,
  }) {
    final kept =
        rows
            .where(
              (row) =>
                  row.deletedAt == null && (includeArchived || !row.isArchived),
            )
            .toList()
          ..sort((a, b) {
            final preset = (a.isPreset ? 0 : 1).compareTo(b.isPreset ? 0 : 1);
            if (preset != 0) return preset;
            final order = a.sortOrder.compareTo(b.sortOrder);
            if (order != 0) return order;
            return a.name.compareTo(b.name);
          });
    return kept;
  }

  Future<int> _alivePurchaseCount(String categoryId) async {
    final query = _db.selectOnly(_db.purchases)
      ..addColumns([_db.purchases.id.count()])
      ..where(
        _db.purchases.categoryId.equals(categoryId) &
            _db.purchases.deletedAt.isNull(),
      );
    final row = await query.getSingle();
    return row.read(_db.purchases.id.count()) ?? 0;
  }
}
