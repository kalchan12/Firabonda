import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:firabonda/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late File dbFile;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('firabonda_v2_v3_test');
    dbFile = File('${tempDir.path}/firabonda.sqlite');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Safe zero-data-loss migration from schema v2 to schema v3', () async {
    // 1. Build a pure Schema v2 SQLite database using NativeDatabase
    final rawDb = NativeDatabase(dbFile);
    await rawDb.ensureOpen(_FakeQueryExecutorUser());

    await rawDb.runCustom('PRAGMA user_version = 2;');

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
      CREATE TABLE suppliers (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT,
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
        direction TEXT NOT NULL,
        amount INTEGER NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
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
        title TEXT,
        total_bundle_cost INTEGER NOT NULL,
        pricing_mode TEXT NOT NULL DEFAULT 'per_line',
        account_id TEXT,
        supplier_id TEXT,
        date INTEGER NOT NULL,
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

    // Schema v2 sales (WITHOUT assumed_price_at_sale)
    await rawDb.runCustom('''
      CREATE TABLE sales (
        id TEXT NOT NULL PRIMARY KEY,
        purchase_id TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price INTEGER NOT NULL,
        cost_at_sale INTEGER,
        account_id TEXT,
        paid_amount INTEGER,
        note TEXT,
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
      CREATE TABLE debts (
        id TEXT NOT NULL PRIMARY KEY,
        person_name TEXT NOT NULL,
        phone TEXT,
        amount INTEGER NOT NULL,
        direction TEXT NOT NULL,
        note TEXT,
        due_date INTEGER,
        sale_id TEXT,
        purchase_id TEXT,
        date INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      );
    ''');

    await rawDb.runCustom('''
      CREATE TABLE debt_payments (
        id TEXT NOT NULL PRIMARY KEY,
        debt_id TEXT NOT NULL,
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
      CREATE TABLE stock_adjustments (
        id TEXT NOT NULL PRIMARY KEY,
        purchase_id TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        reason TEXT NOT NULL,
        value_at_cost INTEGER NOT NULL,
        note TEXT,
        date INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER
      );
    ''');

    await rawDb.runCustom('''
      CREATE TABLE reconciliations (
        id TEXT NOT NULL PRIMARY KEY,
        account_id TEXT NOT NULL,
        system_balance INTEGER NOT NULL,
        counted_balance INTEGER NOT NULL,
        difference INTEGER NOT NULL,
        note TEXT,
        date INTEGER NOT NULL,
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
        action TEXT NOT NULL,
        changes_json TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
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

    // 2. Insert v2 sample data
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await rawDb.runCustom('''
      INSERT INTO categories (id, name, icon, is_preset, is_archived, sort_order, created_at, updated_at)
      VALUES ('cat_1', 'Jeans', 'checkroom', 1, 0, 0, $nowMs, $nowMs);
    ''');

    await rawDb.runCustom('''
      INSERT INTO color_options (id, name, hex, is_preset, created_at, updated_at)
      VALUES ('col_1', 'Blue', 4280391411, 1, $nowMs, $nowMs);
    ''');

    await rawDb.runCustom('''
      INSERT INTO purchases (id, category_id, color_id, quantity, unit_cost, total_cost, selling_price, date, created_at, updated_at)
      VALUES ('purch_1', 'cat_1', 'col_1', 10, 15000, 150000, 20000, $nowMs, $nowMs, $nowMs);
    ''');

    await rawDb.runCustom('''
      INSERT INTO sales (id, purchase_id, quantity, unit_price, cost_at_sale, date, created_at, updated_at)
      VALUES ('sale_1', 'purch_1', 2, 22000, 15000, $nowMs, $nowMs, $nowMs);
    ''');

    await rawDb.close();

    // 3. Open via AppDatabase (triggers automatic Drift migration to v3)
    final db = AppDatabase.open(customPath: dbFile.path);

    // Verify user_version upgraded to at least 3
    final versionResult = await db
        .customSelect('PRAGMA user_version;')
        .getSingle();
    expect(versionResult.data['user_version'], greaterThanOrEqualTo(3));

    // 4. Verify existing sales data preserved and assumed_price_at_sale backfilled from purchase
    final sales = await db.select(db.sales).get();
    expect(sales.length, 1);
    final sale = sales.first;
    expect(sale.id, 'sale_1');
    expect(sale.quantity, 2);
    expect(sale.unitPrice, 22000);
    expect(sale.costAtSale, 15000);
    expect(
      sale.assumedPriceAtSale,
      20000,
    ); // Backfilled from purchases.selling_price

    // 5. Verify new sale can be inserted with assumed_price_at_sale
    await db
        .into(db.sales)
        .insert(
          SalesCompanion.insert(
            id: 'sale_2',
            purchaseId: 'purch_1',
            quantity: 1,
            unitPrice: 25000,
            costAtSale: const Value(15000),
            assumedPriceAtSale: const Value(20000),
            date: DateTime.now().toUtc(),
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );

    final allSales = await db.select(db.sales).get();
    expect(allSales.length, 2);
    expect(allSales.last.id, 'sale_2');
    expect(allSales.last.assumedPriceAtSale, 20000);

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
  int get schemaVersion => 2;
}
