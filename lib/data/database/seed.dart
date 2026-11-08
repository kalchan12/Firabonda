import 'package:drift/drift.dart';

import '../../core/utils/uuid.dart';
import 'app_database.dart';

/// Preset seed data, mirrored exactly from `files/DATABASE.md`.
const seedCategories = <(String, String)>[
  ('T-shirts', 'tshirt'),
  ('Shirts', 'shirt'),
  ('Hoodies', 'hoodie'),
  ('Jackets', 'jacket'),
  ('Trousers', 'trousers'),
  ('Jeans', 'jeans'),
  ('Shorts', 'shorts'),
  ('Sweaters', 'sweater'),
];

const seedColors = <(String, String)>[
  ('Black', '#000000'),
  ('White', '#FFFFFF'),
  ('Gray', '#808080'),
  ('Blue', '#2F5BFF'),
  ('Navy', '#0B1F4B'),
  ('Red', '#E53950'),
  ('Green', '#2E9E63'),
  ('Brown', '#7A4B2A'),
  ('Beige', '#D8C3A5'),
  ('Yellow', '#F2C94C'),
];

const seedVersionValue = '1';
const seedVersionKey = 'seed.version';

/// Seeds the preset categories and colors exactly once.
Future<void> seed(AppDatabase db) {
  return db.transaction(() async {
    final marker = await (db.select(
      db.appMeta,
    )..where((row) => row.key.equals(seedVersionKey))).getSingleOrNull();
    if (marker != null) return;

    final now = DateTime.now().toUtc();

    await db.batch((batch) {
      batch.insertAll(db.categories, [
        for (final (index, (name, icon)) in seedCategories.indexed)
          CategoriesCompanion.insert(
            id: newUuid(),
            name: name,
            icon: icon,
            isPreset: true,
            isArchived: false,
            sortOrder: index,
            createdAt: now,
            updatedAt: now,
          ),
      ], mode: InsertMode.insertOrIgnore);
      batch.insertAll(db.colorOptions, [
        for (final (name, hex) in seedColors)
          ColorOptionsCompanion.insert(
            id: newUuid(),
            name: name,
            hex: hex,
            isPreset: true,
            createdAt: now,
            updatedAt: now,
          ),
      ], mode: InsertMode.insertOrIgnore);
      batch.insertAll(db.accounts, [
        AccountsCompanion.insert(
          id: 'acc_cash',
          name: 'Cash',
          type: 'cash',
          openingBalance: const Value(0),
          isArchived: const Value(false),
          createdAt: now,
          updatedAt: now,
        ),
        AccountsCompanion.insert(
          id: 'acc_bank',
          name: 'Bank',
          type: 'bank',
          openingBalance: const Value(0),
          isArchived: const Value(false),
          createdAt: now,
          updatedAt: now,
        ),
        AccountsCompanion.insert(
          id: 'acc_telebirr',
          name: 'Mobile Money',
          type: 'mobile_money',
          openingBalance: const Value(0),
          isArchived: const Value(false),
          createdAt: now,
          updatedAt: now,
        ),
      ], mode: InsertMode.insertOrIgnore);
    });

    await db
        .into(db.appMeta)
        .insert(
          AppMetaCompanion.insert(key: seedVersionKey, value: seedVersionValue),
          mode: InsertMode.insertOrIgnore,
        );
  });
}
