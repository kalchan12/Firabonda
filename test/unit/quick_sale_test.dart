import 'package:drift/native.dart';
import 'package:firabonda/data/database/app_database.dart';
import 'package:firabonda/data/models/shop_models.dart';
import 'package:firabonda/data/repositories/purchase_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late LocalPurchaseRepository repo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.ensureSeeded();
    repo = LocalPurchaseRepository(db);
  });

  tearDown(() => db.close());

  group('Step 6: Pricing and Quick Sell tests', () {
    test('auto-records debt receivable when sale has partial payment', () async {
      final categories = await db.select(db.categories).get();
      final colors = await db.select(db.colorOptions).get();

      // Purchase 5 items @ 200 ETB
      final purchaseId = await repo.add(
        PurchaseInput(
          categoryId: categories.first.id,
          colorId: colors.first.id,
          quantity: 5,
          unitCostCents: 20000,
          date: DateTime.now(),
        ),
      );

      // Sell 2 items @ 400 ETB = 800 ETB total revenue
      // Customer pays only 500 ETB -> 300 ETB unpaid debt
      final saleId = await repo.recordSale(
        SaleInput(
          purchaseId: purchaseId,
          quantity: 2,
          unitPriceCents: 40000,
          date: DateTime.now(),
          paidAmountCents: 50000,
          customerName: 'Alemayehu',
        ),
      );

      expect(saleId, isNotEmpty);

      // Verify sale recorded
      final sales = await db.select(db.sales).get();
      expect(sales.length, 1);
      expect(sales.first.paidAmount, 50000);
      expect(sales.first.quantity, 2);

      // Verify debt receivable auto-created
      final debts = await db.select(db.debts).get();
      expect(debts.length, 1);
      final debt = debts.first;
      expect(debt.personName, 'Alemayehu');
      expect(debt.amount, 30000); // 300 ETB unpaid
      expect(debt.direction, 'owed_to_me');
      expect(debt.isPaid, false);
    });

    test('does not create debt when sale is fully paid', () async {
      final categories = await db.select(db.categories).get();
      final colors = await db.select(db.colorOptions).get();

      final purchaseId = await repo.add(
        PurchaseInput(
          categoryId: categories.first.id,
          colorId: colors.first.id,
          quantity: 3,
          unitCostCents: 15000,
          date: DateTime.now(),
        ),
      );

      // Fully paid sale (paidAmountCents null or equal to total)
      await repo.recordSale(
        SaleInput(
          purchaseId: purchaseId,
          quantity: 1,
          unitPriceCents: 30000,
          date: DateTime.now(),
        ),
      );

      final debts = await db.select(db.debts).get();
      expect(debts, isEmpty);
    });
  });
}
