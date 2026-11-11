import 'package:drift/native.dart';
import 'package:firabonda/core/theme/app_theme.dart';
import 'package:firabonda/core/utils/business_logic.dart';
import 'package:firabonda/data/database/app_database.dart';
import 'package:firabonda/data/models/shop_models.dart';
import 'package:firabonda/data/repositories/purchase_repository.dart';
import 'package:firabonda/features/dashboard/application/dashboard_controller.dart';
import 'package:firabonda/features/dashboard/presentation/dashboard_screen.dart';
import 'package:firabonda/features/purchases/application/purchases_controller.dart';
import 'package:firabonda/features/purchases/presentation/purchases_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget createTestApp({required Widget child, required AppDatabase db}) {
  return ProviderScope(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
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

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.ensureSeeded();
  });

  tearDown(() => db.close());

  group('More analytics & stock dropdown filter tests', () {
    testWidgets('defaults to Today and provides modern dropdown filter', (
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

      expect(find.text('More analytics & stock'), findsOneWidget);
      expect(find.text('Unsold stock value'), findsOneWidget);
      expect(find.text('Timeframe:'), findsOneWidget);
      expect(find.text('Today'), findsWidgets);

      await cleanUpWidget(tester);
    });
  });

  group('Purchases Screen view layout modes (Grid, Row, Card)', () {
    testWidgets('switches between Card, Grid, and Row layout modes', (
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
          quantity: 10,
          unitCostCents: 200000,
          sellingPriceCents: 250000,
          date: DateTime.now(),
        ),
      );

      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.build(Brightness.dark),
            home: const PurchasesScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // 1. Default Card view shows category & details
      expect(find.text(categories.first.name), findsWidgets);
      expect(find.text('10 left'), findsWidgets);
      expect(find.text('Sell'), findsWidgets);

      // 2. Switch to Grid view
      container
          .read(purchaseViewModeProvider.notifier)
          .setViewMode(PurchaseViewMode.grid);
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
      expect(find.text(categories.first.name), findsWidgets);
      expect(find.text('10 left'), findsWidgets);
      expect(find.text('Sell'), findsWidgets);

      // 3. Switch to Row view
      container
          .read(purchaseViewModeProvider.notifier)
          .setViewMode(PurchaseViewMode.row);
      await tester.pumpAndSettle();

      expect(find.text(categories.first.name), findsWidgets);
      expect(find.text('10 left'), findsWidgets);
      expect(find.byIcon(Icons.sell_outlined), findsWidgets);

      await cleanUpWidget(tester);
    });
  });
}
