import 'package:drift/native.dart';
import 'package:firabonda/core/theme/app_theme.dart';
import 'package:firabonda/data/database/app_database.dart';
import 'package:firabonda/data/models/shop_models.dart';
import 'package:firabonda/features/dashboard/presentation/dashboard_screen.dart';
import 'package:firabonda/features/purchases/presentation/add_purchase_screen.dart';
import 'package:firabonda/features/purchases/presentation/batch_purchase_screen.dart';
import 'package:firabonda/features/sales/presentation/sales_screen.dart';
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

  Widget buildApp(Widget child) {
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        theme: AppTheme.build(Brightness.dark),
        home: Scaffold(body: child),
      ),
    );
  }

  Future<void> cleanUp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  }

  group('Task 7: Profit and target language consistency', () {
    testWidgets(
      'Dashboard does not contain "markup", "target profit margin", or "100% target"',
      (tester) async {
        await tester.pumpWidget(buildApp(const DashboardScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(
          find.textContaining(RegExp(r'markup', caseSensitive: false)),
          findsNothing,
        );
        expect(
          find.textContaining(RegExp(r'100% target', caseSensitive: false)),
          findsNothing,
        );
        expect(
          find.textContaining(
            RegExp(r'Target profit margin', caseSensitive: false),
          ),
          findsNothing,
        );

        await cleanUp(tester);
      },
    );

    testWidgets(
      'AddPurchaseScreen does not contain "markup" or "100% target"',
      (tester) async {
        await tester.pumpWidget(buildApp(const AddPurchaseScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(
          find.textContaining(RegExp(r'markup', caseSensitive: false)),
          findsNothing,
        );
        expect(
          find.textContaining(RegExp(r'100% target', caseSensitive: false)),
          findsNothing,
        );

        await cleanUp(tester);
      },
    );

    testWidgets(
      'BatchPurchaseScreen does not contain "markup" or "100% target"',
      (tester) async {
        await tester.pumpWidget(buildApp(const BatchPurchaseScreen()));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(
          find.textContaining(RegExp(r'markup', caseSensitive: false)),
          findsNothing,
        );
        expect(
          find.textContaining(RegExp(r'100% target', caseSensitive: false)),
          findsNothing,
        );

        await cleanUp(tester);
      },
    );

    testWidgets('SalesScreen does not contain "markup" or "100% target"', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp(const SalesScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.textContaining(RegExp(r'markup', caseSensitive: false)),
        findsNothing,
      );
      expect(
        find.textContaining(RegExp(r'100% target', caseSensitive: false)),
        findsNothing,
      );

      await cleanUp(tester);
    });

    testWidgets('SellBottomSheet does not contain "markup" or "100% target"', (
      tester,
    ) async {
      final purchase = PurchaseOverview(
        id: 'purch_test',
        categoryId: 'cat_tshirts',
        categoryName: 'T-shirts',
        colorId: 'col_black',
        colorName: 'Black',
        colorHex: 0xFF111827,
        quantity: 5,
        stockLeft: 5,
        unitCostCents: 10000,
        totalCostCents: 50000,
        sellingPriceCents: 15000,
        date: DateTime.now(),
        supplierId: null,
        supplierName: null,
        size: null,
        note: null,
        photoPath: null,
      );

      await tester.pumpWidget(buildApp(SellBottomSheet(purchase: purchase)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.textContaining(RegExp(r'markup', caseSensitive: false)),
        findsNothing,
      );
      expect(
        find.textContaining(RegExp(r'100% target', caseSensitive: false)),
        findsNothing,
      );

      await cleanUp(tester);
    });
  });
}
