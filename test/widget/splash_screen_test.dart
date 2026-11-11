import 'package:firabonda/features/splash/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('SplashScreen widget tests', () {
    testWidgets('renders branded emblem, title, badge, and features', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      var navigatedToDashboard = false;

      final router = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
            path: '/splash',
            builder: (context, state) => const SplashScreen(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) {
              navigatedToDashboard = true;
              return const Scaffold(body: Text('Dashboard Mock'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Fira Bonda'), findsOneWidget);
      expect(find.text('OFFLINE CLOTHING STORE TRACKER'), findsOneWidget);
      expect(find.text('100% Offline'), findsOneWidget);
      expect(find.text('Real Profit'), findsOneWidget);
      expect(find.text('Private Data'), findsOneWidget);
      expect(find.text('Tap anywhere to start'), findsOneWidget);

      // Tap to skip immediately
      await tester.tap(find.text('Fira Bonda'));
      await tester.pumpAndSettle();

      expect(navigatedToDashboard, isTrue);
      expect(find.text('Dashboard Mock'), findsOneWidget);
    });
  });
}
