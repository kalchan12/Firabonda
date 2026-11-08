import 'package:drift/native.dart';
import 'package:firabonda/data/database/app_database.dart';
import 'package:firabonda/data/models/shop_models.dart';
import 'package:firabonda/data/repositories/inventory_repository.dart';
import 'package:firabonda/data/repositories/purchase_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late LocalPurchaseRepository purchaseRepo;
  late LocalInventoryRepository inventoryRepo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.ensureSeeded();
    purchaseRepo = LocalPurchaseRepository(db);
    inventoryRepo = LocalInventoryRepository(db);
  });

  tearDown(() => db.close());

  group('Step 8: Stock adjustments and reconciliation', () {
    test('damaged stock adjustment reduces stock and registers in losses', () async {
      final categories = await db.select(db.categories).get();
      final colors = await db.select(db.colorOptions).get();

      // Purchase 10 items @ 300 ETB
      final purchaseId = await purchaseRepo.add(
        PurchaseInput(
          categoryId: categories.first.id,
          colorId: colors.first.id,
          quantity: 10,
          unitCostCents: 30000,
          date: DateTime.now(),
        ),
      );

      // Verify initial stock = 10
      expect(await purchaseRepo.stockLeftFor(purchaseId), 10);

      // Record 2 damaged items
      final adjId = await inventoryRepo.addStockAdjustment(
        StockAdjustmentInput(
          purchaseId: purchaseId,
          categoryId: categories.first.id,
          quantityChange: -2,
          reason: StockAdjustmentReason.damaged,
          valueAtCostCents: 60000, // 2 * 300 ETB = 600 ETB
          date: DateTime.now(),
          note: 'Damaged during unloading',
        ),
      );

      expect(adjId, isNotEmpty);

      // Verify stock left is now 8!
      expect(await purchaseRepo.stockLeftFor(purchaseId), 8);

      // Verify stock adjustment row in db
      final adjustments = await db.select(db.stockAdjustments).get();
      expect(adjustments.length, 1);
      final adj = adjustments.first;
      expect(adj.quantityChange, -2);
      expect(adj.reason, 'damaged');
      expect(adj.valueAtCost, 60000);
    });

    test('customer return increases stock left', () async {
      final categories = await db.select(db.categories).get();
      final colors = await db.select(db.colorOptions).get();

      final purchaseId = await purchaseRepo.add(
        PurchaseInput(
          categoryId: categories.first.id,
          colorId: colors.first.id,
          quantity: 5,
          unitCostCents: 20000,
          date: DateTime.now(),
        ),
      );

      // Sell 3 items -> stock = 2
      await purchaseRepo.recordSale(
        SaleInput(
          purchaseId: purchaseId,
          quantity: 3,
          unitPriceCents: 40000,
          date: DateTime.now(),
        ),
      );
      expect(await purchaseRepo.stockLeftFor(purchaseId), 2);

      // Customer returns 1 item -> stock becomes 3
      await inventoryRepo.addStockAdjustment(
        StockAdjustmentInput(
          purchaseId: purchaseId,
          categoryId: categories.first.id,
          quantityChange: 1,
          reason: StockAdjustmentReason.customerReturn,
          valueAtCostCents: 20000,
          date: DateTime.now(),
        ),
      );

      expect(await purchaseRepo.stockLeftFor(purchaseId), 3);
    });

    test('reconciliation logs expected vs counted and computes difference', () async {
      final recId = await inventoryRepo.addReconciliation(
        ReconciliationInput(
          type: 'cash_account',
          accountId: 'acc_cash',
          expectedCents: 500000, // 5,000 ETB
          countedCents: 485000, // 4,850 ETB (-150 ETB discrepancy)
          date: DateTime.now(),
          note: 'Evening cash count',
        ),
      );

      expect(recId, isNotEmpty);

      final reconciliations = await db.select(db.reconciliations).get();
      expect(reconciliations.length, 1);
      final rec = reconciliations.first;
      expect(rec.expected, 500000);
      expect(rec.counted, 485000);
      expect(rec.difference, -15000); // -150 ETB
    });
  });
}
