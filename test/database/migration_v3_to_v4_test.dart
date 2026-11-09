import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:firabonda/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('firabonda_v3_v4_test');
    dbFile = File('${tempDir.path}/firabonda.sqlite');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Safe zero-data-loss migration from schema v3 to schema v4', () async {
    final rawDb = NativeDatabase(dbFile);
    await rawDb.ensureOpen(_FakeQueryExecutorUser());

    await rawDb.runCustom('PRAGMA user_version = 3;');

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
        hex INTEGER NOT NULL,
        is_preset INTEGER NOT NULL,
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
        batch_id TEXT,
        account_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      );
    ''');

    // Schema v3 sales (with assumed_price_at_sale, but WITHOUT shift_id)
    await rawDb.runCustom('''
      CREATE TABLE sales (
        id TEXT NOT NULL PRIMARY KEY,
        purchase_id TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price INTEGER NOT NULL,
        cost_at_sale INTEGER,
        assumed_price_at_sale INTEGER,
        account_id TEXT,
        paid_amount INTEGER,
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
        account_id TEXT,
        note TEXT,
        date INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      );
    ''');

    await rawDb.runCustom('''
      CREATE TABLE batches (
        id TEXT NOT NULL PRIMARY KEY,
        supplier_id TEXT,
        date INTEGER NOT NULL,
        total_paid INTEGER NOT NULL,
        account_id TEXT,
        note TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      );
    ''');

    await rawDb.runCustom('''
      CREATE TABLE stock_adjustments (
        id TEXT NOT NULL PRIMARY KEY,
        purchase_id TEXT,
        category_id TEXT,
        quantity_change INTEGER NOT NULL,
        reason TEXT NOT NULL,
        value_at_cost INTEGER NOT NULL,
        date INTEGER NOT NULL,
        note TEXT,
        photo_path TEXT,
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
      CREATE TABLE accounts (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        opening_balance INTEGER NOT NULL DEFAULT 0,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      );
    ''');

    await rawDb.runCustom('''
      CREATE TABLE account_transactions (
        id TEXT NOT NULL PRIMARY KEY,
        account_id TEXT NOT NULL,
        amount INTEGER NOT NULL,
        direction TEXT NOT NULL,
        type TEXT NOT NULL,
        related_id TEXT,
        date INTEGER NOT NULL,
        note TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      );
    ''');

    await rawDb.runCustom('''
      CREATE TABLE reconciliations (
        id TEXT NOT NULL PRIMARY KEY,
        type TEXT NOT NULL,
        account_id TEXT,
        expected INTEGER NOT NULL,
        counted INTEGER NOT NULL,
        difference INTEGER NOT NULL,
        date INTEGER NOT NULL,
        note TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      );
    ''');

    await rawDb.runCustom('''
      CREATE TABLE edit_history (
        id TEXT NOT NULL PRIMARY KEY,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        field TEXT NOT NULL,
        old_value TEXT,
        new_value TEXT,
        date INTEGER NOT NULL,
        created_at INTEGER NOT NULL
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
      CREATE TABLE app_meta (
        key TEXT NOT NULL PRIMARY KEY,
        value TEXT NOT NULL
      );
    ''');

    // Insert sample data
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await rawDb.runCustom('''
      INSERT INTO sales (id, purchase_id, quantity, unit_price, cost_at_sale, assumed_price_at_sale, date, created_at, updated_at)
      VALUES ('sale_v3', 'purch_1', 2, 20000, 10000, 18000, $nowMs, $nowMs, $nowMs);
    ''');

    await rawDb.runCustom('''
      INSERT INTO expenses (id, title, amount, date, created_at, updated_at)
      VALUES ('exp_v3', 'Electricity', 5000, $nowMs, $nowMs, $nowMs);
    ''');

    await rawDb.close();

    // 2. Open via AppDatabase (triggers upgrade to v4)
    final db = AppDatabase.open(customPath: dbFile.path);

    final versionResult = await db
        .customSelect('PRAGMA user_version;')
        .getSingle();
    expect(versionResult.data['user_version'], 4);

    // 3. Verify existing data preserved
    final sales = await db.select(db.sales).get();
    expect(sales.length, 1);
    expect(sales.first.id, 'sale_v3');
    expect(sales.first.assumedPriceAtSale, 18000);
    expect(sales.first.shiftId, isNull);

    final expenses = await db.select(db.expenses).get();
    expect(expenses.length, 1);
    expect(expenses.first.id, 'exp_v3');
    expect(expenses.first.shiftId, isNull);

    // 4. Verify shifts table exists and accepts inserts
    final now = DateTime.now().toUtc();
    await db
        .into(db.shifts)
        .insert(
          ShiftsCompanion.insert(
            id: 'shift_1',
            openedAt: now,
            openingCash: const Value(50000),
            createdAt: now,
            updatedAt: now,
          ),
        );

    final shifts = await db.select(db.shifts).get();
    expect(shifts.length, 1);
    expect(shifts.first.id, 'shift_1');
    expect(shifts.first.openingCash, 50000);
    expect(shifts.first.closedAt, isNull);

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
  int get schemaVersion => 3;
}
