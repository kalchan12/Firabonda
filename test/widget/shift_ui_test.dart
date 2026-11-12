import 'package:drift/native.dart';
import 'package:firabonda/app.dart';
import 'package:firabonda/core/router/app_router.dart';
import 'package:firabonda/core/theme/app_theme.dart';
import 'package:firabonda/core/theme/theme_controller.dart';
import 'package:firabonda/core/widgets/app_button.dart';
import 'package:firabonda/data/database/app_database.dart';
import 'package:firabonda/data/repositories/shift_repository.dart';
import 'package:firabonda/features/shifts/presentation/close_shift_sheet.dart';
import 'package:firabonda/features/shifts/presentation/open_shift_sheet.dart';
import 'package:firabonda/features/shifts/presentation/shift_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.ensureSeeded();
  });

  tearDown(() => db.close());

  Future<void> cleanUp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  }

  testWidgets('OpenShiftSheet displays inputs and submits new shift', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.build(Brightness.dark),
          home: const Scaffold(
            body: SingleChildScrollView(child: OpenShiftSheet()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Open Shift'), findsWidgets);

    // Enter opening cash in the first text field
    final cashField = find.byType(TextField).first;
    await tester.enterText(cashField, '450');
    await tester.pump();

    // Tap Open Shift button
    await tester.tap(find.widgetWithText(AppButton, 'Open Shift'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify shift was saved in database
    final shifts = await db.select(db.shifts).get();
    expect(shifts.length, 1);
    expect(shifts.first.openingCash, 45000);
    expect(shifts.first.closedAt, isNull);

    await cleanUp(tester);
  });

  testWidgets(
    'CloseShiftSheet computes expected cash, allows entry and reconciles',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final shiftRepo = LocalShiftRepository(db);
      await shiftRepo.openShift(openingCashCents: 60000);
      final activeShift = (await shiftRepo.getCurrentShift())!;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
          child: MaterialApp(
            theme: AppTheme.build(Brightness.dark),
            home: Scaffold(
              body: SingleChildScrollView(
                child: CloseShiftSheet(shift: activeShift),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      // Allow async _loadExpectedCash to complete
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Close Shift'), findsWidgets);
      expect(find.text('Expected drawer cash'), findsOneWidget);

      // Count drawer cash field
      final countField = find.byKey(const ValueKey('count_cash_field'));
      expect(countField, findsOneWidget);

      // Enter counted cash matching expected 600
      await tester.enterText(countField, '600');
      await tester.pump();

      expect(find.textContaining('Exact match'), findsOneWidget);

      // Enter counted cash with shortage: 580
      await tester.enterText(countField, '580');
      await tester.pump();

      expect(find.textContaining('cash short'), findsOneWidget);

      // Submit close
      await tester.tap(
        find.byKey(const ValueKey('confirm_close_shift_button')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify shift is closed and diff recorded
      final closed = (await db.select(db.shifts).get()).first;
      expect(closed.closedAt, isNotNull);
      expect(closed.expectedCash, 60000);
      expect(closed.actualCash, 58000);
      expect(closed.cashDifference, -2000);

      await cleanUp(tester);
    },
  );

  testWidgets('ShiftHistoryScreen lists shifts with details', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final shiftRepo = LocalShiftRepository(db);
    final shiftId = await shiftRepo.openShift(openingCashCents: 50000);
    await shiftRepo.closeShift(shiftId: shiftId, actualCashCents: 50000);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.build(Brightness.dark),
          home: const ShiftHistoryScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Shift History'), findsOneWidget);
    expect(find.textContaining('Closed'), findsWidgets);

    await cleanUp(tester);
  });

  testWidgets(
      'OpenShiftSheet does not overflow with small screen, keyboard viewInsets, and high text scale',
      (tester) async {
    const keyboardInset = 280.0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          theme: AppTheme.build(Brightness.dark),
          home: const MediaQuery(
            data: MediaQueryData(
              size: Size(360, 640),
              viewInsets: EdgeInsets.only(bottom: keyboardInset),
              textScaler: TextScaler.linear(1.4),
            ),
            child: Scaffold(
              body: OpenShiftSheet(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Open Shift'), findsWidgets);
    expect(find.text('Opening cash in drawer'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await cleanUp(tester);
  });

  testWidgets(
      'Toggling theme mode does not reset navigation or show splash screen',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockRouter = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) =>
              const Scaffold(body: Text('Splash Screen Mock')),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) =>
              const Scaffold(body: Text('Dashboard Active')),
        ),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appRouterProvider.overrideWithValue(mockRouter),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Active'), findsOneWidget);
    expect(find.text('Splash Screen Mock'), findsNothing);

    // Toggle theme to dark
    container.read(themeControllerProvider.notifier).setMode(ThemeMode.dark);
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Active'), findsOneWidget);
    expect(find.text('Splash Screen Mock'), findsNothing);

    // Toggle theme to light
    container.read(themeControllerProvider.notifier).setMode(ThemeMode.light);
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Active'), findsOneWidget);
    expect(find.text('Splash Screen Mock'), findsNothing);

    await cleanUp(tester);
  });
}
