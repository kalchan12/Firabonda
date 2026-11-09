import 'package:drift/native.dart';
import 'package:firabonda/data/database/app_database.dart';
import 'package:firabonda/data/models/shop_models.dart';
import 'package:firabonda/data/repositories/expense_repository.dart';
import 'package:firabonda/data/repositories/purchase_repository.dart';
import 'package:firabonda/data/repositories/shift_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late LocalShiftRepository shiftRepo;
  late LocalPurchaseRepository purchaseRepo;
  late LocalExpenseRepository expenseRepo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.ensureSeeded();
    shiftRepo = LocalShiftRepository(db);
    purchaseRepo = LocalPurchaseRepository(db);
    expenseRepo = LocalExpenseRepository(db);
  });

  tearDown(() => db.close());

  group('Shift repository and drawer cash calculation', () {
    test('open shift sets open status and persists opening cash', () async {
      expect(await shiftRepo.getCurrentShift(), isNull);

      final shiftId = await shiftRepo.openShift(
        openingCashCents: 50000,
        openedBy: 'Abebe',
      );

      final current = await shiftRepo.getCurrentShift();
      expect(current, isNotNull);
      expect(current!.id, shiftId);
      expect(current.openingCash, 50000);
      expect(current.openedBy, 'Abebe');
      expect(current.closedAt, isNull);
    });

    test(
      'computeExpectedCash calculates openingCash + cashSales - cashExpenses - cashPurchases',
      () async {
        final shiftId = await shiftRepo.openShift(
          openingCashCents: 50000, // 500 ETB
          openedBy: 'Dawit',
        );

        final categories = await db.select(db.categories).get();
        final colors = await db.select(db.colorOptions).get();

        // 1. Cash Purchase of stock: 10 items @ 100 ETB = 1000 ETB (100,000 cents) paid from cash
        await purchaseRepo.addBatch(
          BatchPurchaseInput(
            totalCostCents: 100000,
            date: DateTime.now(),
            accountId: 'acc_cash',
            shiftId: shiftId,
            items: [
              BatchItemInput(
                categoryId: categories.first.id,
                colorId: colors.first.id,
                quantity: 10,
                unitCostCents: 10000,
              ),
            ],
          ),
        );
        final purchaseId = (await db.select(db.purchases).get()).first.id;

        // 2. Cash Sale: 3 items @ 250 ETB = 750 ETB (75,000 cents) paid to cash
        await purchaseRepo.recordSale(
          SaleInput(
            purchaseId: purchaseId,
            quantity: 3,
            unitPriceCents: 25000,
            costAtSaleCents: 10000,
            accountId: 'acc_cash',
            shiftId: shiftId,
            date: DateTime.now(),
          ),
        );

        // 3. Bank Sale (CBE): 2 items @ 250 ETB = 500 ETB paid to bank -> must NOT alter expected drawer cash!
        await purchaseRepo.recordSale(
          SaleInput(
            purchaseId: purchaseId,
            quantity: 2,
            unitPriceCents: 25000,
            costAtSaleCents: 10000,
            accountId: 'acc_cbe',
            shiftId: shiftId,
            date: DateTime.now(),
          ),
        );

        // 4. Cash Expense: 50 ETB (5,000 cents)
        await expenseRepo.add(
          ExpenseInput(
            title: 'Broom & tea',
            amountCents: 5000,
            shiftId: shiftId,
            date: DateTime.now(),
          ),
        );

        // Expected Drawer Cash:
        // Opening cash: 50,000
        // + Cash Sales: 75,000
        // - Cash Purchases: 100,000
        // - Cash Expenses: 5,000
        // Total expected = 50,000 + 75,000 - 100,000 - 5,000 = 20,000 cents (200 ETB)
        final expected = await shiftRepo.computeExpectedCash(shiftId);
        expect(expected, 20000);

        // 5. Close shift with counted cash = 180 ETB (18,000 cents, short by 20 ETB)
        await shiftRepo.closeShift(
          shiftId: shiftId,
          actualCashCents: 18000,
          notes: 'Short 20 ETB change',
        );

        // Current shift should now be null
        expect(await shiftRepo.getCurrentShift(), isNull);

        // Check closed shift row
        final closedShift = (await db.select(db.shifts).get()).first;
        expect(closedShift.closedAt, isNotNull);
        expect(closedShift.actualCash, 18000);
        expect(closedShift.expectedCash, 20000);
        expect(closedShift.cashDifference, -2000);

        // Check reconciliation log
        final recons = await db.select(db.reconciliations).get();
        expect(recons.length, 1);
        expect(recons.first.type, 'cash_account');
        expect(recons.first.accountId, 'acc_cash');
        expect(recons.first.expected, 20000);
        expect(recons.first.counted, 18000);
        expect(recons.first.difference, -2000);
      },
    );
  });
}
