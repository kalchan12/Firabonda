import 'package:drift/native.dart';
import 'package:firabonda/core/theme/app_theme.dart';
import 'package:firabonda/data/database/app_database.dart';
import 'package:firabonda/data/models/shop_models.dart';
import 'package:firabonda/data/repositories/purchase_repository.dart';
import 'package:firabonda/features/purchases/presentation/add_purchase_screen.dart';
import 'package:firabonda/features/purchases/presentation/purchases_screen.dart';
import 'package:firabonda/features/sales/presentation/sales_screen.dart';
import 'package:firabonda/features/sales/presentation/sell_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget createTestApp({required Widget child, required AppDatabase db}) {
  return ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
    child: MaterialApp(theme: AppTheme.build(Brightness.dark), home: child),
  );
}

Future<void> cleanUpWidget(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(Duration.zero);
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.ensureSeeded();
  });

  tearDown(() => db.close());

  group('AddPurchaseScreen widget tests', () {
    testWidgets('renders categories, colors, quantity stepper, and unit cost', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const AddPurchaseScreen(), db: db),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add purchase'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('T-shirts'), findsOneWidget);
      expect(find.text('Jeans'), findsOneWidget);
      expect(find.text('Color'), findsOneWidget);
      expect(find.text('Black'), findsOneWidget);
      expect(find.text('Quantity'), findsOneWidget);
      expect(find.text('1'), findsWidgets);
      expect(find.text('Unit cost'), findsOneWidget);
      expect(find.text('Total cost'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('Save purchase'), findsOneWidget);

      await cleanUpWidget(tester);
    });

    testWidgets('stepper increments and decrements quantity', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const AddPurchaseScreen(), db: db),
      );
      await tester.pumpAndSettle();

      final plusButton = find.byKey(const ValueKey('stepper_add'));
      await tester.tap(plusButton);
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);

      final minusButton = find.byKey(const ValueKey('stepper_remove'));
      await tester.tap(minusButton);
      await tester.pumpAndSettle();

      expect(find.text('1'), findsWidgets);

      await cleanUpWidget(tester);
    });

    testWidgets('shows price memory hint when previous purchase exists', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final categories = await db.select(db.categories).get();
      final colors = await db.select(db.colorOptions).get();
      final category = categories.first;
      final color = colors.first;

      final purchaseRepo = LocalPurchaseRepository(db);
      await purchaseRepo.add(
        PurchaseInput(
          categoryId: category.id,
          colorId: color.id,
          quantity: 10,
          unitCostCents: 85000,
          date: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        createTestApp(child: const AddPurchaseScreen(), db: db),
      );
      await tester.pumpAndSettle();

      // Tap category & color chips to trigger selection state and price memory query
      await tester.tap(find.text(category.name));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text(color.name));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.textContaining('Last time: ETB 850.00 each'), findsOneWidget);

      // Tap hint to prefill
      await tester.tap(find.textContaining('Last time: ETB 850.00 each'));
      await tester.pumpAndSettle();

      expect(find.text('850.00'), findsOneWidget);

      await cleanUpWidget(tester);
    });
  });

  group('PurchasesScreen widget tests', () {
    testWidgets('shows empty state when no purchases exist', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const PurchasesScreen(), db: db),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('Purchases'), findsOneWidget);
      expect(
        find.text(
          'No purchases yet. Tap "+ Batch purchase" to record your clothing inventory.',
        ),
        findsOneWidget,
      );

      await cleanUpWidget(tester);
    });

    testWidgets('displays purchase card with stock left and sell button', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final categories = await db.select(db.categories).get();
      final colors = await db.select(db.colorOptions).get();
      final purchaseRepo = LocalPurchaseRepository(db);

      await purchaseRepo.add(
        PurchaseInput(
          categoryId: categories.first.id,
          colorId: colors.first.id,
          quantity: 5,
          unitCostCents: 50000,
          sellingPriceCents: 75000,
          date: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        createTestApp(child: const PurchasesScreen(), db: db),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Category appears in filter chip and purchase card
      expect(find.text(categories.first.name), findsWidgets);
      expect(find.text(colors.first.name), findsOneWidget);
      expect(find.text('5 left'), findsOneWidget);
      expect(find.text('Sell'), findsOneWidget);

      await cleanUpWidget(tester);
    });
  });

  group('SellBottomSheet widget tests', () {
    testWidgets(
      'renders stock left, calculates live profit, and records sale',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        final purchase = PurchaseOverview(
          id: 'p1',
          categoryId: 'cat1',
          categoryName: 'T-shirts',
          colorId: 'col1',
          colorName: 'Black',
          colorHex: 0xFF000000,
          supplierId: null,
          supplierName: null,
          size: 'L',
          quantity: 10,
          unitCostCents: 40000,
          totalCostCents: 400000,
          sellingPriceCents: 65000,
          photoPath: null,
          note: null,
          date: DateTime.now(),
          stockLeft: 10,
        );

        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(body: SellBottomSheet(purchase: purchase)),
            db: db,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('10 in stock'), findsOneWidget);
        expect(find.text('T-shirts • Black'), findsOneWidget);
        expect(find.text('Sell'), findsOneWidget);

        // Pre-filled selling price is 650
        expect(find.text('650'), findsOneWidget);
        // Expected profit for qty 1: (650 - 400) * 1 = 250
        expect(find.text('+ETB 250.00'), findsOneWidget);

        await cleanUpWidget(tester);
      },
    );
  });

  group('SalesScreen widget tests', () {
    testWidgets('shows empty state when no sales exist', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const SalesScreen(), db: db),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('Sales'), findsOneWidget);
      expect(
        find.text(
          'No sales recorded yet. Tap "Sell" on any item in your Purchases list to track your earnings and profit.',
        ),
        findsOneWidget,
      );

      await cleanUpWidget(tester);
    });

    testWidgets('displays sales item with profit badge when sales exist', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final categories = await db.select(db.categories).get();
      final colors = await db.select(db.colorOptions).get();
      final purchaseRepo = LocalPurchaseRepository(db);

      final pId = await purchaseRepo.add(
        PurchaseInput(
          categoryId: categories.first.id,
          colorId: colors.first.id,
          quantity: 10,
          unitCostCents: 30000,
          date: DateTime.now(),
        ),
      );

      await purchaseRepo.recordSale(
        SaleInput(
          purchaseId: pId,
          quantity: 2,
          unitPriceCents: 50000,
          date: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        createTestApp(child: const SalesScreen(), db: db),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('Total revenue'), findsOneWidget);
      expect(find.text('Total profit'), findsOneWidget);
      expect(find.text('+ETB 400.00'), findsWidgets); // (500 - 300) * 2 = 400
      expect(
        find.text('${categories.first.name} (${colors.first.name})'),
        findsOneWidget,
      );

      await cleanUpWidget(tester);
    });
  });
}
