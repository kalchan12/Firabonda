import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:firabonda/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('firabonda_migration_test');
    dbFile = File('${tempDir.path}/firabonda.sqlite');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Safe zero-data-loss migration from schema v1 to schema v2', () async {
    // 1. Build a pure Schema v1 SQLite database using NativeDatabase
    final rawDb = NativeDatabase(dbFile);
    await rawDb.ensureOpen(_FakeQueryExecutorUser());

    await rawDb.runCustom('PRAGMA user_version = 1;');

    // Schema v1 tables
    await rawDb.runCustom('''
      CREATE TABLE categories (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        is_preset INTEGER NOT NULL,
        is_archived INTEGER NOT NULL,
        sort_order INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      );
    ''');

    await rawDb.runCustom('''
      CREATE TABLE color_options (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        hex TEXT NOT NULL,
        is_preset INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      );
    ''');

    await rawDb.runCustom('''
      CREATE TABLE suppliers (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
        note TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      );
    ''');

    await rawDb.runCustom('''
      CREATE TABLE purchases (
        id TEXT NOT NULL PRIMARY KEY,
        category_id TEXT NOT NULL,
        color_id TEXT NOT NULL,
        supplier_id TEXT,
        size TEXT,
        quantity INTEGER NOT NULL,
        unit_cost INTEGER NOT NULL,
        total_cost INTEGER NOT NULL,
        selling_price INTEGER,
        photo_path TEXT,
        note TEXT,
        date INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      );
    ''');

    await rawDb.runCustom('''
      CREATE TABLE sales (
        id TEXT NOT NULL PRIMARY KEY,
        purchase_id TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price INTEGER NOT NULL,
        date INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      );
    ''');

    await rawDb.runCustom('''
      CREATE TABLE expenses (
        id TEXT NOT NULL PRIMARY KEY,
        title TEXT NOT NULL,
        amount INTEGER NOT NULL,
        date INTEGER NOT NULL,
        note TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      );
    ''');

    await rawDb.runCustom('''
      CREATE TABLE debts (
        id TEXT NOT NULL PRIMARY KEY,
        person_name TEXT NOT NULL,
        amount INTEGER NOT NULL,
        direction TEXT NOT NULL,
        due_date INTEGER,
        is_paid INTEGER NOT NULL,
        note TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      );
    ''');

    await rawDb.runCustom('''
      CREATE TABLE app_meta (
        key TEXT NOT NULL PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');

    // 2. Insert realistic sample data into Schema v1
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await rawDb.runCustom('''
      INSERT INTO categories (id, name, icon, is_preset, is_archived, sort_order, created_at, updated_at)
      VALUES ('cat_1', 'Jeans', 'jeans', 1, 0, 0, $nowMs, $nowMs);
    ''');

    await rawDb.runCustom('''
      INSERT INTO color_options (id, name, hex, is_preset, created_at, updated_at)
      VALUES ('col_1', 'Dark Blue', '#0000FF', 1, $nowMs, $nowMs);
    ''');

    await rawDb.runCustom('''
      INSERT INTO purchases (id, category_id, color_id, quantity, unit_cost, total_cost, date, created_at, updated_at)
      VALUES ('purch_1', 'cat_1', 'col_1', 10, 15000, 150000, $nowMs, $nowMs, $nowMs);
    ''');

    await rawDb.runCustom('''
      INSERT INTO sales (id, purchase_id, quantity, unit_price, date, created_at, updated_at)
      VALUES ('sale_1', 'purch_1', 2, 25000, $nowMs, $nowMs, $nowMs);
    ''');

    await rawDb.runCustom('''
      INSERT INTO expenses (id, title, amount, date, created_at, updated_at)
      VALUES ('exp_1', 'Shop Rent', 50000, $nowMs, $nowMs, $nowMs);
    ''');

    await rawDb.close();

    // 3. Open via AppDatabase (triggers automatic safety backup & Drift migration to v2)
    final db = AppDatabase.open(customPath: dbFile.path);

    // Verify user_version upgraded to 2
    final versionResult = await db
        .customSelect('PRAGMA user_version;')
        .getSingle();
    expect(versionResult.data['user_version'], 2);

    // 4. Verify safety backup file exists
    final backupFile = File('${dbFile.path}.pre_v2_backup');
    expect(backupFile.existsSync(), isTrue);

    // 5. Verify existing data preserved with zero data loss
    final purchases = await db.select(db.purchases).get();
    expect(purchases.length, 1);
    expect(purchases.first.id, 'purch_1');
    expect(purchases.first.totalCost, 150000);
    expect(purchases.first.accountId, 'acc_cash');

    final sales = await db.select(db.sales).get();
    expect(sales.length, 1);
    expect(sales.first.id, 'sale_1');
    expect(sales.first.quantity, 2);
    expect(sales.first.unitPrice, 25000);
    // Verified backfilled columns:
    expect(sales.first.costAtSale, 15000); // frozen from purchase.unitCost
    expect(sales.first.accountId, 'acc_cash');
    expect(sales.first.paidAmount, 50000); // 2 * 25000

    final expenses = await db.select(db.expenses).get();
    expect(expenses.length, 1);
    expect(expenses.first.accountId, 'acc_cash');

    // 6. Verify newly seeded accounts
    final accounts = await db.select(db.accounts).get();
    expect(accounts.length, 3);
    final accountIds = accounts.map((a) => a.id).toSet();
    expect(accountIds, containsAll(['acc_cash', 'acc_bank', 'acc_telebirr']));

    // 7. Verify new v2 tables exist and accept inserts
    final batchResult = await db
        .customSelect('SELECT count(*) as c FROM batches;')
        .getSingle();
    expect(batchResult.data['c'], 0);

    final adjResult = await db
        .customSelect('SELECT count(*) as c FROM stock_adjustments;')
        .getSingle();
    expect(adjResult.data['c'], 0);

    final recResult = await db
        .customSelect('SELECT count(*) as c FROM reconciliations;')
        .getSingle();
    expect(recResult.data['c'], 0);

    final histResult = await db
        .customSelect('SELECT count(*) as c FROM edit_history;')
        .getSingle();
    expect(histResult.data['c'], 0);

    await db.close();
  });
}

class _FakeQueryExecutorUser implements QueryExecutorUser {
  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}

  @override
  int get schemaVersion => 1;
}
