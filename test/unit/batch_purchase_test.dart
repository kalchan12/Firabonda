import 'package:drift/native.dart';
import 'package:firabonda/core/utils/business_logic.dart';
import 'package:firabonda/data/database/app_database.dart';
import 'package:firabonda/data/models/shop_models.dart';
import 'package:firabonda/data/repositories/purchase_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Step 7: Batch cost allocation algorithm (largest-remainder)', () {
    test('exact division distributes evenly', () {
      // 10,000 cents (100 ETB) split across 2 items with quantities [3, 2] (total 5 pieces)
      // 3/5 = 6,000 cents, 2/5 = 4,000 cents
      final allocated = ShopLogic.allocateBatchCost(
        totalCostCents: 10000,
        quantities: [3, 2],
      );
      expect(allocated, [6000, 4000]);
      expect(allocated.reduce((a, b) => a + b), 10000);
    });

    test(
      'distributes remainders to largest fractional share without losing any cents',
      () {
        // 100 cents across 3 equal items of quantity 1
        // 100 / 3 = 33 r 1 -> [34, 33, 33]
        final allocated = ShopLogic.allocateBatchCost(
          totalCostCents: 100,
          quantities: [1, 1, 1],
        );
        expect(allocated, [34, 33, 33]);
        expect(allocated.reduce((a, b) => a + b), 100);
      },
    );

    test(
      'large bundle with multiple remainders matches total cost down to the last cent',
      () {
        // 55,555 cents (555.55 ETB) across quantities [17, 23, 11] (total 51)
        final quantities = [17, 23, 11];
        const totalCost = 55555;
        final allocated = ShopLogic.allocateBatchCost(
          totalCostCents: totalCost,
          quantities: quantities,
        );

        expect(allocated.length, 3);
        final sum = allocated.reduce((a, b) => a + b);
        expect(sum, totalCost);
      },
    );
  });

  group('Step 7: Batch purchase repository integration', () {
    late AppDatabase db;
    late LocalPurchaseRepository repo;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      await db.ensureSeeded();
      repo = LocalPurchaseRepository(db);
    });

    tearDown(() => db.close());

    test(
      'addBatch creates batch record and linked purchases with correct allocated costs',
      () async {
        final categories = await db.select(db.categories).get();
        final colors = await db.select(db.colorOptions).get();

        final batchId = await repo.addBatch(
          BatchPurchaseInput(
            totalCostCents: 100000, // 1,000.00 ETB
            date: DateTime.now(),
            accountId: 'acc_telebirr',
            note: 'Test Bale #1',
            items: [
              BatchItemInput(
                categoryId: categories[0].id,
                colorId: colors[0].id,
                quantity: 10,
              ),
              BatchItemInput(
                categoryId: categories[1].id,
                colorId: colors[1].id,
                quantity: 15,
              ),
            ],
          ),
        );

        expect(batchId, isNotEmpty);

        // Verify batch in db
        final batches = await db.select(db.batches).get();
        expect(batches.length, 1);
        final batch = batches.first;
        expect(batch.id, batchId);
        expect(batch.totalPaid, 100000);
        expect(batch.accountId, 'acc_telebirr');
        expect(batch.note, 'Test Bale #1');

        // Verify purchases linked to batch
        final purchases = await db.select(db.purchases).get();
        expect(purchases.length, 2);
        expect(purchases.every((p) => p.batchId == batchId), isTrue);

        // Total quantity: 25.
        // Item 1 (10 pieces): 100,000 * 10 / 25 = 40,000 cents (4,000 cents/piece)
        // Item 2 (15 pieces): 100,000 * 15 / 25 = 60,000 cents (4,000 cents/piece)
        expect(purchases[0].totalCost, 40000);
        expect(purchases[0].unitCost, 4000);
        expect(purchases[1].totalCost, 60000);
        expect(purchases[1].unitCost, 4000);

        // Total costs sum exactly to batch total
        final totalPurchasesCost = purchases.fold<int>(
          0,
          (sum, p) => sum + p.totalCost,
        );
        expect(totalPurchasesCost, 100000);
      },
    );
  });
}
