import 'package:drift/native.dart';
import 'package:firabonda/core/theme/app_theme.dart';
import 'package:firabonda/data/database/app_database.dart';
import 'package:firabonda/data/models/shop_models.dart';
import 'package:firabonda/data/repositories/debt_repository.dart';
import 'package:firabonda/data/repositories/expense_repository.dart';
import 'package:firabonda/data/repositories/supplier_repository.dart';
import 'package:firabonda/features/categories/presentation/categories_colors_screen.dart';
import 'package:firabonda/features/debts/presentation/debts_screen.dart';
import 'package:firabonda/features/expenses/presentation/expenses_screen.dart';
import 'package:firabonda/features/export_backup/presentation/backup_restore_screen.dart';
import 'package:firabonda/features/export_backup/presentation/export_screen.dart';
import 'package:firabonda/features/settings/presentation/settings_screen.dart';
import 'package:firabonda/features/suppliers/presentation/suppliers_screen.dart';
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

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.ensureSeeded();
  });

  tearDown(() => db.close());

  group('Secondary features widget tests', () {
    testWidgets('SuppliersScreen displays empty state and supplier card',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const SuppliersScreen(),
          db: db,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('No suppliers yet. Add suppliers to track purchase history and totals.'), findsOneWidget);

      final repo = LocalSupplierRepository(db);
      await repo.add(
        const SupplierInput(
          name: 'Merkato Wholesale',
          phone: '0911000000',
          note: 'Stall 42',
        ),
      );

      await tester.pumpWidget(
        createTestApp(
          child: const SuppliersScreen(),
          db: db,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('Merkato Wholesale'), findsOneWidget);
      expect(find.text('0911000000'), findsOneWidget);
      expect(find.text('Total spent with suppliers'), findsOneWidget);

      await cleanUpWidget(tester);
    });

    testWidgets('ExpensesScreen displays empty state and added expense card',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const ExpensesScreen(),
          db: db,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('No expenses yet'), findsOneWidget);

      final repo = LocalExpenseRepository(db);
      await repo.add(
        ExpenseInput(
          title: 'Shop Rent',
          amountCents: 1500000,
          date: DateTime.now(),
          note: 'October rent',
        ),
      );

      await tester.pumpWidget(
        createTestApp(
          child: const ExpensesScreen(),
          db: db,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('Shop Rent'), findsOneWidget);
      expect(find.text('ETB 15,000.00'), findsWidgets);
      expect(find.text('Total recorded expenses'), findsOneWidget);

      await cleanUpWidget(tester);
    });

    testWidgets('DebtsScreen renders tabs and allows marking debt as paid',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = LocalDebtRepository(db);
      await repo.add(
        const DebtInput(
          personName: 'Abebe Bikila',
          amountCents: 120000,
          direction: DebtDirection.owedToMe,
          note: '2 jackets',
        ),
      );

      await tester.pumpWidget(
        createTestApp(
          child: const DebtsScreen(),
          db: db,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('Owed to me'), findsOneWidget);
      expect(find.text('I owe'), findsOneWidget);
      expect(find.text('Abebe Bikila'), findsOneWidget);
      expect(find.text('ETB 1,200.00'), findsWidgets);
      expect(find.text('PENDING'), findsOneWidget);

      // Tap checkbox to mark paid
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('PAID'), findsOneWidget);

      await cleanUpWidget(tester);
    });

    testWidgets('CategoriesColorsScreen displays seeded categories and colors',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const CategoriesColorsScreen(),
          db: db,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('T-shirts'), findsOneWidget);
      expect(find.text('Shirts'), findsOneWidget);

      // Switch to colors tab
      await tester.tap(find.text('Colors'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('Black'), findsOneWidget);
      expect(find.text('White'), findsOneWidget);

      await cleanUpWidget(tester);
    });

    testWidgets('SettingsScreen allows changing preferences', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const SettingsScreen(),
          db: db,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('Theme mode'), findsOneWidget);
      expect(find.text('Enable size field'), findsOneWidget);
      expect(find.text('Low stock alert threshold'), findsOneWidget);
      expect(find.text('Ethiopian Birr (ETB)'), findsOneWidget);

      // Tap '+' to increase low stock threshold
      await tester.tap(find.byIcon(Icons.add).first);
      await tester.pumpAndSettle();

      expect(find.text('4'), findsOneWidget);

      await cleanUpWidget(tester);
    });

    testWidgets('ExportScreen renders month preview and action buttons',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const ExportScreen(),
          db: db,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('Export as PDF'), findsOneWidget);
      expect(find.text('Export as CSV (Excel)'), findsOneWidget);
      expect(find.text('Purchases (Spent)'), findsOneWidget);
      expect(find.text('Real Net Profit'), findsOneWidget);

      await cleanUpWidget(tester);
    });

    testWidgets('BackupRestoreScreen renders backup and restore actions',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const BackupRestoreScreen(),
          db: db,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('Local Database Backup'), findsOneWidget);
      expect(find.text('Create & Share Backup'), findsOneWidget);
      expect(find.text('Restore from Backup File'), findsOneWidget);
      expect(find.text('Verify & Restore'), findsOneWidget);

      await cleanUpWidget(tester);
    });
  });
}
