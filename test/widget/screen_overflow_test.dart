import 'package:firabonda/core/theme/app_theme.dart';
import 'package:firabonda/core/widgets/floating_nav_bar.dart';
import 'package:firabonda/data/models/shop_models.dart';
import 'package:firabonda/features/sales/presentation/sell_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets(
    'FloatingNavBar renders without overflow at 360dp with textScale 1.6 in dark and light theme',
    (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 640 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      for (final brightness in [Brightness.dark, Brightness.light]) {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.build(brightness),
              home: MediaQuery(
                data: const MediaQueryData(
                  size: Size(360, 640),
                  textScaler: TextScaler.linear(1.6),
                ),
                child: Scaffold(
                  bottomNavigationBar: FloatingNavBar(
                    currentIndex: 0,
                    onDestinationTap: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'FloatingNavBar center button pushes /batch-purchase directly with no speed dial sheet',
    (tester) async {
      String? pushedLocation;
      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => Scaffold(
              bottomNavigationBar: FloatingNavBar(
                currentIndex: 0,
                onDestinationTap: (_) {},
              ),
            ),
          ),
          GoRoute(
            path: '/batch-purchase',
            builder: (context, state) {
              pushedLocation = '/batch-purchase';
              return const Scaffold(body: Text('Batch Purchase Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.build(Brightness.dark),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap center Add button
      await tester.tap(find.byTooltip('Add'));
      await tester.pumpAndSettle();

      // Verify that /batch-purchase was immediately pushed
      expect(pushedLocation, '/batch-purchase');
      expect(find.text('Batch Purchase Screen'), findsOneWidget);

      // Verify speed dial sheet is completely absent
      expect(find.text('Quick sale'), findsNothing);
      expect(find.bySemanticsLabel('Close add menu'), findsNothing);
    },
  );

  testWidgets(
    'SellBottomSheet renders without overflow at 360dp with textScale 1.6',
    (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 640 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testPurchase = PurchaseOverview(
        id: 'purch_test_1',
        categoryId: 'cat_1',
        categoryName: 'Extra Long Category Name For Testing',
        colorId: 'col_1',
        colorName: 'Midnight Blue With Highlights',
        colorHex: 0xFF1E3A8A,
        quantity: 10,
        stockLeft: 8,
        unitCostCents: 15000,
        totalCostCents: 150000,
        sellingPriceCents: 25000,
        date: DateTime.utc(2026, 11, 1, 10),
        supplierId: null,
        supplierName: null,
        size: null,
        note: null,
        photoPath: null,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.build(Brightness.dark),
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 640),
                textScaler: TextScaler.linear(1.6),
              ),
              child: Scaffold(body: SellBottomSheet(purchase: testPurchase)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'SellBottomSheet action button is visible and tappable on 360x640 with textScale 1.6 and keyboard open',
    (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 640 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testPurchase = PurchaseOverview(
        id: 'purch_test_1',
        categoryId: 'cat_1',
        categoryName: 'Denim Jeans Premium Quality',
        colorId: 'col_1',
        colorName: 'Midnight Blue',
        colorHex: 0xFF1E3A8A,
        quantity: 10,
        stockLeft: 8,
        unitCostCents: 15000,
        totalCostCents: 150000,
        sellingPriceCents: 25000,
        date: DateTime.utc(2026, 11, 1, 10),
        supplierId: null,
        supplierName: null,
        size: null,
        note: null,
        photoPath: null,
      );

      // Simulate a small 360x640 screen with 280dp keyboard inset (viewInsets.bottom = 280)
      const keyboardInset = 280.0;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.build(Brightness.dark),
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(360, 640),
                viewInsets: EdgeInsets.only(bottom: keyboardInset),
                textScaler: TextScaler.linear(1.6),
              ),
              child: Scaffold(body: SellBottomSheet(purchase: testPurchase)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      final buttonFinder = find.byKey(const ValueKey('confirm_sale_button'));
      expect(buttonFinder, findsOneWidget);

      // Verify the button rect is positioned above the keyboard (within the visible 640 - 280 = 360 vertical space)
      final rect = tester.getRect(buttonFinder);
      expect(rect.bottom, lessThanOrEqualTo(640.0 - keyboardInset + 0.1));
      expect(rect.top, greaterThanOrEqualTo(0.0));

      // Verify button is tappable without any hit-test or off-screen error
      await tester.tap(buttonFinder);
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
