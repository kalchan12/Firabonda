import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'seed.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// Local SQLite (Drift) database for Fira Bonda.
@DriftDatabase(
  tables: [
    Categories,
    ColorOptions,
    Suppliers,
    Purchases,
    Sales,
    Expenses,
    Debts,
    AppMeta,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Opens (or creates) the database file in the app's documents directory.
  static AppDatabase open() {
    return AppDatabase(
      LazyDatabase(() async {
        final dir = await getApplicationDocumentsDirectory();
        final dbFile = File(p.join(dir.path, dbFileName));
        return NativeDatabase.createInBackground(dbFile);
      }),
    );
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA journal_mode = WAL');
    },
  );

  /// Inserts the preset categories and colors on first launch only,
  /// guarded by the `seed.version` key in `app_meta`.
  Future<void> ensureSeeded() => seed(this);
}

const dbFileName = 'firabonda.sqlite';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase.open();
  ref.onDispose(database.close);
  return database;
});
