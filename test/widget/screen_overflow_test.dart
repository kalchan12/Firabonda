import 'package:firabonda/core/theme/app_theme.dart';
import 'package:firabonda/core/widgets/floating_nav_bar.dart';
import 'package:firabonda/data/models/shop_models.dart';
import 'package:firabonda/features/sales/presentation/sell_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FloatingNavBar renders without overflow at 360dp with textScale 1.6', (tester) async {
    tester.view.physicalSize = const Size(360 * 2, 640 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.build(Brightness.dark),
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
  });

  testWidgets('SellBottomSheet renders without overflow at 360dp with textScale 1.6', (tester) async {
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
            child: Scaffold(
              body: SellBottomSheet(purchase: testPurchase),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
