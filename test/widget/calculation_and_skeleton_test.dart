import 'package:drift/native.dart';
import 'package:firabonda/core/theme/app_theme.dart';
import 'package:firabonda/data/database/app_database.dart';
import 'package:firabonda/data/models/shop_models.dart';
import 'package:firabonda/data/repositories/purchase_repository.dart';
import 'package:firabonda/features/dashboard/presentation/dashboard_screen.dart';
import 'package:firabonda/features/dashboard/presentation/widgets/dashboard_skeleton.dart';
import 'package:firabonda/features/purchases/presentation/purchases_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget createTestApp({
  required Widget child,
  required AppDatabase db,
}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
    ],
    child: MaterialApp(
      theme: AppTheme.build(Brightness.dark),
      home: child,
    ),
  );
}

Future<void> cleanUpWidget(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(Duration.zero);
}

void main() {
  late AppDatabase db;
  late PurchaseRepository purchaseRepo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.ensureSeeded();
    purchaseRepo = LocalPurchaseRepository(db);
  });

  tearDown(() => db.close());

  group('Calculation logic tests (User Scenario: 10 bought @ 2000, sell 5 @ 2500)', () {
    testWidgets('Dashboard and Purchases calculations match exact mathematical expectations', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final categories = await db.select(db.categories).get();
      final colors = await db.select(db.colorOptions).get();

      // 1. Bought: 10 items @ 2,000 ETB unit cost (200,000 cents), target sell price 2,500 ETB (250,000 cents)
      final purchaseId = await purchaseRepo.add(
        PurchaseInput(
          categoryId: categories.first.id,
          colorId: colors.first.id,
          quantity: 10,
          unitCostCents: 200000, // 2,000 ETB each -> 20,000 ETB total
          sellingPriceCents: 250000, // 2,500 ETB each -> 25,000 ETB target revenue
          date: DateTime.now(),
        ),
      );

      // Verify purchase stored
      final stockInitial = await purchaseRepo.stockLeftFor(purchaseId);
      expect(stockInitial, 10);

      // 2. Sell: 5 items @ 2,500 ETB unit price (250,000 cents)
      await purchaseRepo.recordSale(
        SaleInput(
          purchaseId: purchaseId,
          quantity: 5,
          unitPriceCents: 250000, // 2,500 ETB
          costAtSaleCents: 200000, // 2,000 ETB
          assumedPriceAtSaleCents: 250000, // 2,500 ETB
          date: DateTime.now(),
        ),
      );

      final stockAfter = await purchaseRepo.stockLeftFor(purchaseId);
      expect(stockAfter, 5);

      // Render Dashboard
      await tester.pumpWidget(
        createTestApp(
          child: const DashboardScreen(),
          db: db,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Verify Dashboard values
      // Sold / Earned = 5 * 2,500 = 12,500 ETB
      expect(find.textContaining('ETB 12,500.00'), findsWidgets);
      // Cost of sold items = 5 * 2,000 = 10,000 ETB
      expect(find.textContaining('ETB 10,000.00'), findsWidgets);
      // Bought / Spent = 10 * 2,000 = 20,000 ETB
      expect(find.textContaining('ETB 20,000.00'), findsWidgets);
      // Real Profit = 12,500 - 10,000 = +ETB 2,500.00
      expect(find.textContaining('ETB 2,500.00'), findsWidgets);

      await cleanUpWidget(tester);

      // Render Purchases screen and verify remaining target vs total lot target
      await tester.pumpWidget(
        createTestApp(
          child: const PurchasesScreen(),
          db: db,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Purchases screen must display 5 left, remaining target 12,500 ETB, and lot total target 25,000 ETB
      expect(find.text('5 left'), findsOneWidget);
      expect(find.textContaining('Target (5 left): ETB 12,500.00'), findsOneWidget);
      expect(find.textContaining('Exp. profit (5 left): +ETB 2,500.00'), findsOneWidget);
      expect(find.textContaining('Lot total target: ETB 25,000.00 (10 pcs)'), findsOneWidget);

      await cleanUpWidget(tester);
    });

    testWidgets('Dashboard does not flash skeleton loader when cached data exists', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const DashboardScreen(),
          db: db,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Dashboard content is visible
      expect(find.byType(DashboardSkeletonView), findsNothing);
      expect(find.textContaining('Real Profit'), findsOneWidget);

      // Trigger pull to refresh on Dashboard
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pump();

      // Even while refreshing, existing dashboard content is preserved and skeleton is NOT shown
      expect(find.byType(DashboardSkeletonView), findsNothing);
      expect(find.textContaining('Real Profit'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.textContaining('Real Profit'), findsOneWidget);

      await cleanUpWidget(tester);
    });
  });
}
