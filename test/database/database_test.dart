import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:firabonda/data/database/app_database.dart';
import 'package:firabonda/data/database/seed.dart';
import 'package:firabonda/data/models/shop_models.dart';
import 'package:firabonda/data/repositories/category_repository.dart';
import 'package:firabonda/data/repositories/color_repository.dart';
import 'package:firabonda/data/repositories/exceptions.dart';
import 'package:firabonda/data/repositories/expense_repository.dart';
import 'package:firabonda/data/repositories/purchase_repository.dart';

AppDatabase buildTestDb() => AppDatabase(NativeDatabase.memory());

void main() {
  group('seed', () {
    late AppDatabase db;

    setUp(() {
      db = buildTestDb();
    });

    tearDown(() => db.close());

    test('creates exactly the preset categories and colors, once', () async {
      await db.ensureSeeded();
      final categories = await db.select(db.categories).get();
      final colors = await db.select(db.colorOptions).get();
      expect(categories, hasLength(seedCategories.length));
      expect(colors, hasLength(seedColors.length));
      expect(
        categories.where((row) => row.isPreset).length,
        seedCategories.length,
      );
      expect(
        categories.map((row) => row.name),
        containsAll(['T-shirts', 'Jeans', 'Sweaters']),
      );

      await db.ensureSeeded();
      expect(
        await db.select(db.categories).get(),
        hasLength(seedCategories.length),
      );
    });

    test('app_meta holds the seed version', () async {
      await db.ensureSeeded();
      final marker = await (db.select(
        db.appMeta,
      )..where((row) => row.key.equals(seedVersionKey))).getSingleOrNull();
      expect(marker?.value, seedVersionValue);
    });
  });

  group('category repository', () {
    late AppDatabase db;
    late LocalCategoryRepository categories;

    setUp(() async {
      db = buildTestDb();
      await db.ensureSeeded();
      categories = LocalCategoryRepository(db);
    });

    tearDown(() => db.close());

    test('adds a custom category', () async {
      final created = await categories.add(name: 'Caps', icon: 'cap');
      expect(created.isPreset, isFalse);
      expect(created.name, 'Caps');
    });

    test('cannot delete a used category, soft delete keeps history', () async {
      final all = await categories.getAll();
      final shirts = all.firstWhere((row) => row.name == 'Shirts');
      final colors = await LocalColorRepository(db).getAll();
      final black = colors.firstWhere((row) => row.name == 'Black');

      final purchases = LocalPurchaseRepository(db);
      await purchases.add(
        PurchaseInput(
          categoryId: shirts.id,
          colorId: black.id,
          quantity: 2,
          unitCostCents: 5000,
          date: DateTime.now().toUtc(),
        ),
      );

      expect(
        () => categories.softDelete(shirts.id),
        throwsA(isA<CategoryInUseException>()),
      );

      // Soft delete with no usage just marks deletedAt.
      final caps = await categories.add(name: 'Caps', icon: 'cap');
      await categories.softDelete(caps.id);
      final after = await (db.select(
        db.categories,
      )..where((row) => row.id.equals(caps.id))).getSingle();
      expect(after.deletedAt, isA<DateTime>());
      expect(await categories.getAll(), isNot(contains(caps)));
    });

    test('archive hides from pickers but keeps row', () async {
      final all = await categories.getAll();
      final shorts = all.firstWhere((row) => row.name == 'Shorts');
      await categories.setArchived(shorts.id, archived: true);
      final visible = await categories.getAll();
      expect(visible.map((row) => row.id), isNot(contains(shorts.id)));
      final withArchived = await categories.getAll(includeArchived: true);
      expect(withArchived.map((row) => row.id), contains(shorts.id));
    });
  });

  group('color repository', () {
    late AppDatabase db;
    late LocalColorRepository colors;
    late LocalCategoryRepository categories;

    setUp(() async {
      db = buildTestDb();
      await db.ensureSeeded();
      colors = LocalColorRepository(db);
      categories = LocalCategoryRepository(db);
    });

    tearDown(() => db.close());

    test('cannot delete a used color', () async {
      final allColors = await colors.getAll();
      final red = allColors.firstWhere((row) => row.name == 'Red');
      final allCategories = await categories.getAll();
      final tshirts = allCategories.firstWhere((row) => row.name == 'T-shirts');

      await LocalPurchaseRepository(db).add(
        PurchaseInput(
          categoryId: tshirts.id,
          colorId: red.id,
          quantity: 1,
          unitCostCents: 8000,
          date: DateTime.now().toUtc(),
        ),
      );
      expect(
        () => colors.softDelete(red.id),
        throwsA(isA<ColorInUseException>()),
      );
    });
  });

  group('purchase repository', () {
    late AppDatabase db;
    late LocalCategoryRepository categories;
    late LocalColorRepository colors;
    late LocalPurchaseRepository purchases;

    setUp(() async {
      db = buildTestDb();
      await db.ensureSeeded();
      categories = LocalCategoryRepository(db);
      colors = LocalColorRepository(db);
      purchases = LocalPurchaseRepository(db);
    });

    tearDown(() => db.close());

    Future<(String, String)> firstIds() async {
      final allCategories = await categories.getAll();
      final allColors = await colors.getAll();
      return (
        allCategories.firstWhere((row) => row.name == 'Hoodies').id,
        allColors.firstWhere((row) => row.name == 'Navy').id,
      );
    }

    test('add computes totalCost and overview exposes stock left', () async {
      final (categoryId, colorId) = await firstIds();
      final purchaseId = await purchases.add(
        PurchaseInput(
          categoryId: categoryId,
          colorId: colorId,
          quantity: 5,
          unitCostCents: 70000,
          sellingPriceCents: 110000,
          date: DateTime.now().toUtc(),
        ),
      );
      final overview = (await purchases.watchOverviews().first).first;
      expect(overview.totalCostCents, 350000);
      expect(overview.stockLeft, 5);
      expect(overview.categoryName, 'Hoodies');
      await purchases.recordSale(
        SaleInput(
          purchaseId: purchaseId,
          quantity: 2,
          unitPriceCents: 110000,
          date: DateTime.now().toUtc(),
        ),
      );
      final updated = (await purchases.watchOverviews().first).first;
      expect(updated.stockLeft, 3);
      expect(await purchases.stockLeftFor(purchaseId), 3);
    });

    test('recordSale is transactional: invalid sale writes nothing', () async {
      final (categoryId, colorId) = await firstIds();
      final purchaseId = await purchases.add(
        PurchaseInput(
          categoryId: categoryId,
          colorId: colorId,
          quantity: 2,
          unitCostCents: 70000,
          date: DateTime.now().toUtc(),
        ),
      );

      await expectLater(
        purchases.recordSale(
          SaleInput(
            purchaseId: purchaseId,
            quantity: 3,
            unitPriceCents: 100000,
            date: DateTime.now().toUtc(),
          ),
        ),
        throwsA(isA<SaleExceedsStockException>()),
      );
      final sales = await db.select(db.sales).get();
      expect(sales, isEmpty);

      await expectLater(
        purchases.recordSale(
          SaleInput(
            purchaseId: purchaseId,
            quantity: 0,
            unitPriceCents: 100000,
            date: DateTime.now().toUtc(),
          ),
        ),
        throwsA(isA<SaleQuantityException>()),
      );
      expect(await db.select(db.sales).get(), isEmpty);
    });

    test('sale overview includes computed profit including loss', () async {
      final (categoryId, colorId) = await firstIds();
      final purchaseId = await purchases.add(
        PurchaseInput(
          categoryId: categoryId,
          colorId: colorId,
          quantity: 4,
          unitCostCents: 100000,
          date: DateTime.now().toUtc(),
        ),
      );
      await purchases.recordSale(
        SaleInput(
          purchaseId: purchaseId,
          quantity: 2,
          unitPriceCents: 120000,
          date: DateTime.now().toUtc(),
        ),
      );
      await purchases.recordSale(
        SaleInput(
          purchaseId: purchaseId,
          quantity: 1,
          unitPriceCents: 80000,
          date: DateTime.now().toUtc(),
        ),
      );
      final sales = await purchases.watchSaleOverviews().first;
      expect(sales, hasLength(2));
      final profits = sales.map((sale) => sale.profitCents).toSet();
      expect(profits, {40000, -20000});
    });

    test(
      'softDelete removes sales too (soft) and clears stock tracking',
      () async {
        final (categoryId, colorId) = await firstIds();
        final purchaseId = await purchases.add(
          PurchaseInput(
            categoryId: categoryId,
            colorId: colorId,
            quantity: 3,
            unitCostCents: 90000,
            date: DateTime.now().toUtc(),
          ),
        );
        await purchases.recordSale(
          SaleInput(
            purchaseId: purchaseId,
            quantity: 1,
            unitPriceCents: 120000,
            date: DateTime.now().toUtc(),
          ),
        );
        await purchases.softDelete(purchaseId);

        final purchase = await (db.select(
          db.purchases,
        )..where((row) => row.id.equals(purchaseId))).getSingle();
        final sales =
            await (db.select(db.sales)..where(
                  (row) =>
                      row.purchaseId.equals(purchaseId) &
                      row.deletedAt.isNull(),
                ))
                .get();
        expect(purchase.deletedAt, isA<DateTime>());
        expect(sales, isEmpty);
        await expectLater(
          purchases.watchOverviews().first,
          completion(isEmpty),
        );
      },
    );

    test('lastPricePaid returns newest cost for category+color', () async {
      final (categoryId, colorId) = await firstIds();
      await purchases.add(
        PurchaseInput(
          categoryId: categoryId,
          colorId: colorId,
          quantity: 1,
          unitCostCents: 80000,
          date: DateTime.utc(2026, 1, 1),
        ),
      );
      await purchases.add(
        PurchaseInput(
          categoryId: categoryId,
          colorId: colorId,
          quantity: 1,
          unitCostCents: 85000,
          date: DateTime.utc(2026, 2, 1),
        ),
      );
      expect(
        await purchases.lastPricePaid(categoryId: categoryId, colorId: colorId),
        85000,
      );
    });
  });

  group('expense repository', () {
    late AppDatabase db;

    setUp(() => db = buildTestDb());
    tearDown(() => db.close());

    test('totalBetween sums non-deleted expenses', () async {
      final expenses = LocalExpenseRepository(db);
      await expenses.add(
        ExpenseInput(
          title: 'Rent',
          amountCents: 500000,
          date: DateTime.utc(2026, 5, 1),
        ),
      );
      await expenses.add(
        ExpenseInput(
          title: 'Transport',
          amountCents: 120000,
          date: DateTime.utc(2026, 5, 10),
        ),
      );
      expect(
        await expenses.totalBetween(
          DateTime.utc(2026, 5, 1),
          DateTime.utc(2026, 6, 1),
        ),
        620000,
      );
      final all = await expenses.getAll();
      final rent = all.firstWhere((e) => e.title == 'Rent');
      await expenses.softDelete(rent.id);
      expect(
        await expenses.totalBetween(
          DateTime.utc(2026, 5, 1),
          DateTime.utc(2026, 6, 1),
        ),
        120000,
      );
    });
  });
}
