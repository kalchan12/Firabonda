import 'package:drift/native.dart';
import 'package:firabonda/core/theme/app_theme.dart';
import 'package:firabonda/data/database/app_database.dart';
import 'package:firabonda/data/models/shop_models.dart';
import 'package:firabonda/data/repositories/expense_repository.dart';
import 'package:firabonda/data/repositories/purchase_repository.dart';
import 'package:firabonda/features/dashboard/presentation/dashboard_screen.dart';
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

  group('Dashboard widget tests', () {
    testWidgets('renders period buttons, stat tiles and stock value', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const DashboardScreen(), db: db),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('Fira Bonda'), findsOneWidget);
      expect(find.text('Today'), findsWidgets);
      expect(find.text('Week'), findsWidgets);
      expect(find.text('Month'), findsWidgets);
      expect(find.text('All'), findsWidgets);

      expect(find.textContaining('Spent'), findsOneWidget);
      expect(find.textContaining('Earned'), findsOneWidget);
      expect(find.textContaining('Real Profit'), findsOneWidget);
      expect(find.text('Profit trend'), findsOneWidget);
      expect(find.text('Best sellers'), findsOneWidget);
      expect(find.text('Unsold stock value'), findsOneWidget);

      await cleanUpWidget(tester);
    });

    testWidgets(
      'calculates real profit including expenses and reflects in stats',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        final categories = await db.select(db.categories).get();
        final colors = await db.select(db.colorOptions).get();
        final purchaseRepo = LocalPurchaseRepository(db);
        final expenseRepo = LocalExpenseRepository(db);

        // 1. Purchase 10 items @ 400 ETB = 4,000 ETB spent
        final purchaseId = await purchaseRepo.add(
          PurchaseInput(
            categoryId: categories.first.id,
            colorId: colors.first.id,
            quantity: 10,
            unitCostCents: 40000,
            date: DateTime.now(),
          ),
        );

        // 2. Sell 3 items @ 600 ETB = 1,800 ETB earned
        // Sales profit: (600 - 400) * 3 = 600 ETB
        await purchaseRepo.recordSale(
          SaleInput(
            purchaseId: purchaseId,
            quantity: 3,
            unitPriceCents: 60000,
            date: DateTime.now(),
          ),
        );

        // 3. Add expense of 150 ETB (e.g. transport)
        // Real profit: 600 - 150 = 450 ETB
        await expenseRepo.add(
          ExpenseInput(
            title: 'Transport',
            amountCents: 15000,
            date: DateTime.now(),
          ),
        );

        await tester.pumpWidget(
          createTestApp(child: const DashboardScreen(), db: db),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        // Check spent (4,000.00)
        expect(find.text('ETB 4,000.00'), findsOneWidget);
        // Check earned (1,800.00)
        expect(find.text('ETB 1,800.00'), findsOneWidget);
        // Check real profit (+ ETB 450.00)
        expect(find.text('+ ETB 450.00'), findsOneWidget);
        // Check expenses mention
        expect(
          find.textContaining('Includes ETB 150.00 expenses deducted'),
          findsOneWidget,
        );

        // Unsold stock: 7 items left @ 400 ETB = 2,800 ETB
        expect(find.text('7 pieces in stock'), findsOneWidget);
        expect(find.text('ETB 2,800.00'), findsOneWidget);

        await cleanUpWidget(tester);
      },
    );

    testWidgets('shows low stock alerts when remaining stock is <= threshold', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final categories = await db.select(db.categories).get();
      final colors = await db.select(db.colorOptions).get();
      final purchaseRepo = LocalPurchaseRepository(db);

      // Purchase 3 items (low stock threshold is 3)
      await purchaseRepo.add(
        PurchaseInput(
          categoryId: categories.first.id,
          colorId: colors.first.id,
          quantity: 2,
          unitCostCents: 50000,
          date: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        createTestApp(child: const DashboardScreen(), db: db),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('Low stock alerts'), findsOneWidget);
      expect(find.text('2 left'), findsOneWidget);

      await cleanUpWidget(tester);
    });

    testWidgets('switches periods and updates aggregates', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const DashboardScreen(), db: db),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Tap 'Month'
      await tester.ensureVisible(find.text('Month'));
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Spent (Month)'), findsOneWidget);
      expect(find.textContaining('Real Profit (Month)'), findsOneWidget);

      // Tap 'All'
      await tester.ensureVisible(find.text('All'));
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Spent (All)'), findsOneWidget);
      expect(find.textContaining('Real Profit (All)'), findsOneWidget);

      await cleanUpWidget(tester);
    });
  });
}
