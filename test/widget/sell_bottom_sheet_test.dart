import 'package:drift/native.dart';
import 'package:firabonda/core/theme/app_theme.dart';
import 'package:firabonda/core/utils/money.dart';
import 'package:firabonda/core/widgets/app_button.dart';
import 'package:firabonda/data/database/app_database.dart';
import 'package:firabonda/data/models/shop_models.dart';
import 'package:firabonda/features/sales/presentation/sell_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.ensureSeeded();
  });

  tearDown(() => db.close());

  Widget buildTestWidget({required PurchaseOverview purchase}) {
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: AppTheme.build(Brightness.dark),
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => showSellBottomSheet(ctx, purchase),
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'Task 6: Item with assumed price opens prefilled with On target badge',
    (tester) async {
      final purchaseWithAssumed = PurchaseOverview(
        id: 'purch_1',
        categoryId: 'cat_tshirts',
        categoryName: 'T-shirts',
        colorId: 'col_black',
        colorName: 'Black',
        colorHex: 0xFF111827,
        quantity: 10,
        stockLeft: 10,
        unitCostCents: 10000, // 100 ETB
        totalCostCents: 100000,
        sellingPriceCents: 20000, // 200 ETB assumed
        date: DateTime.now(),
        supplierId: null,
        supplierName: null,
        size: null,
        note: null,
        photoPath: null,
      );

      await tester.pumpWidget(buildTestWidget(purchase: purchaseWithAssumed));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('T-shirts • Black'), findsOneWidget);
      expect(find.text('10 in stock'), findsOneWidget);

      // Verify selling price prefilled with 200 (not 100% markup default)
      final priceField = tester.widget<TextField>(
        find.byKey(const ValueKey('sell_price_field')),
      );
      expect(priceField.controller?.text, '200');

      // Verify Live result card shows "On target"
      expect(find.text('On target (100%)'), findsOneWidget);
      expect(find.text('+${Money.etb(10000)}'), findsOneWidget); // +ETB 100.00
      expect(find.text(Money.etb(20000)), findsOneWidget); // ETB 200.00
    },
  );

  testWidgets(
    'Task 6: Item without assumed price opens empty and shows No target when price entered',
    (tester) async {
      final purchaseNoAssumed = PurchaseOverview(
        id: 'purch_2',
        categoryId: 'cat_tshirts',
        categoryName: 'T-shirts',
        colorId: 'col_black',
        colorName: 'Black',
        colorHex: 0xFF111827,
        quantity: 5,
        stockLeft: 5,
        unitCostCents: 10000, // 100 ETB
        totalCostCents: 50000,
        sellingPriceCents: null, // No assumed price
        date: DateTime.now(),
        supplierId: null,
        supplierName: null,
        size: null,
        note: null,
        photoPath: null,
      );

      await tester.pumpWidget(buildTestWidget(purchase: purchaseNoAssumed));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Verify price input is empty by default (no auto 100% markup)
      final priceField = tester.widget<TextField>(
        find.byKey(const ValueKey('sell_price_field')),
      );
      expect(priceField.controller?.text, '');

      // Verify Sell button is disabled when empty
      final sellBtn = tester.widget<AppButton>(
        find.byKey(const ValueKey('confirm_sale_button')),
      );
      expect(sellBtn.onPressed, isNull);

      // Enter 250 ETB
      await tester.enterText(
        find.byKey(const ValueKey('sell_price_field')),
        '250',
      );
      await tester.pumpAndSettle();

      // Shows "No target (+ETB 150.00)"
      expect(find.text('No target (+${Money.etb(15000)})'), findsOneWidget);
      expect(find.text('+${Money.etb(15000)}'), findsOneWidget);
      expect(find.text(Money.etb(25000)), findsOneWidget);
    },
  );

  testWidgets(
    'Task 6: Selling at loss (80 when cost 100) displays Loss state in live card',
    (tester) async {
      final purchase = PurchaseOverview(
        id: 'purch_3',
        categoryId: 'cat_tshirts',
        categoryName: 'T-shirts',
        colorId: 'col_black',
        colorName: 'Black',
        colorHex: 0xFF111827,
        quantity: 5,
        stockLeft: 5,
        unitCostCents: 10000, // 100 ETB
        totalCostCents: 50000,
        sellingPriceCents: 15000, // 150 ETB assumed
        date: DateTime.now(),
        supplierId: null,
        supplierName: null,
        size: null,
        note: null,
        photoPath: null,
      );

      await tester.pumpWidget(buildTestWidget(purchase: purchase));
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Enter 80 ETB
      await tester.enterText(
        find.byKey(const ValueKey('sell_price_field')),
        '80',
      );
      await tester.pumpAndSettle();

      // Live card turns to Net loss state
      expect(find.text('Net loss'), findsOneWidget);
      expect(find.text(Money.etb(-2000)), findsOneWidget); // ETB -20.00
      expect(find.text('Loss -${Money.etb(2000)}'), findsOneWidget);
    },
  );
}
