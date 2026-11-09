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
    Accounts,
    AccountTransactions,
    Batches,
    StockAdjustments,
    Reconciliations,
    EditHistory,
    Shifts,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Opens (or creates) the database file in the app's documents directory.
  static AppDatabase open({String? customPath}) {
    return AppDatabase(
      LazyDatabase(() async {
        final File dbFile;
        if (customPath != null) {
          dbFile = File(customPath);
        } else {
          final dir = await getApplicationDocumentsDirectory();
          dbFile = File(p.join(dir.path, dbFileName));
        }

        // Safety backup before migration
        if (dbFile.existsSync()) {
          try {
            final backupFile = File('${dbFile.path}.pre_v4_backup');
            if (!backupFile.existsSync()) {
              await dbFile.copy(backupFile.path);
            }
            final legacyBackup = File('${dbFile.path}.pre_v2_backup');
            if (!legacyBackup.existsSync()) {
              await dbFile.copy(legacyBackup.path);
            }
          } catch (_) {}
        }

        return NativeDatabase.createInBackground(dbFile);
      }),
    );
  }

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA journal_mode = WAL');
    },
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // 1. Create new tables
        await m.createTable(accounts);
        await m.createTable(accountTransactions);
        await m.createTable(batches);
        await m.createTable(stockAdjustments);
        await m.createTable(reconciliations);
        await m.createTable(editHistory);

        // 2. Add columns to existing tables
        await m.addColumn(purchases, purchases.batchId);
        await m.addColumn(purchases, purchases.accountId);
        await m.addColumn(sales, sales.costAtSale);
        await m.addColumn(sales, sales.accountId);
        await m.addColumn(sales, sales.paidAmount);
        await m.addColumn(expenses, expenses.accountId);

        // 3. Seed default accounts
        final now = DateTime.now().toUtc();
        await into(accounts).insert(
          AccountsCompanion.insert(
            id: 'acc_cash',
            name: 'Cash',
            type: 'cash',
            openingBalance: const Value(0),
            isArchived: const Value(false),
            createdAt: now,
            updatedAt: now,
          ),
        );
        await into(accounts).insert(
          AccountsCompanion.insert(
            id: 'acc_bank',
            name: 'Bank',
            type: 'bank',
            openingBalance: const Value(0),
            isArchived: const Value(false),
            createdAt: now,
            updatedAt: now,
          ),
        );
        await into(accounts).insert(
          AccountsCompanion.insert(
            id: 'acc_telebirr',
            name: 'Mobile Money',
            type: 'mobile_money',
            openingBalance: const Value(0),
            isArchived: const Value(false),
            createdAt: now,
            updatedAt: now,
          ),
        );

        // 4. Backfill existing records: assign Cash account and freeze costAtSale
        await customStatement('''
              UPDATE sales SET
                account_id = 'acc_cash',
                paid_amount = unit_price * quantity,
                cost_at_sale = COALESCE(
                  (SELECT unit_cost FROM purchases WHERE purchases.id = sales.purchase_id),
                  unit_price
                )
              WHERE cost_at_sale IS NULL
            ''');

        await customStatement('''
              UPDATE purchases SET account_id = 'acc_cash' WHERE account_id IS NULL
            ''');

        await customStatement('''
              UPDATE expenses SET account_id = 'acc_cash' WHERE account_id IS NULL
            ''');
      }

      if (from < 3) {
        await m.addColumn(sales, sales.assumedPriceAtSale);
        await customStatement('''
              UPDATE sales SET
                assumed_price_at_sale = (
                  SELECT selling_price FROM purchases WHERE purchases.id = sales.purchase_id
                )
              WHERE assumed_price_at_sale IS NULL
            ''');
      }

      if (from < 4) {
        await m.createTable(shifts);
        await m.addColumn(sales, sales.shiftId);
        await m.addColumn(expenses, expenses.shiftId);
        if (from >= 2) {
          await m.addColumn(batches, batches.shiftId);
          await m.addColumn(stockAdjustments, stockAdjustments.shiftId);
        }
      }
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
