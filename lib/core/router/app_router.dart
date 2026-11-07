import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/shop_models.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/more/presentation/more_screen.dart';
import '../../features/purchases/presentation/add_purchase_screen.dart';
import '../../features/purchases/presentation/purchases_screen.dart';
import '../../features/sales/presentation/sales_screen.dart';
import '../widgets/app_shell.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildAppRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    routes: [
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/purchases',
                builder: (context, state) => const PurchasesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/sales',
                builder: (context, state) => const SalesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MoreScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/add-purchase',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => AddPurchaseScreen(
          initialPurchase: state.extra as PurchaseOverview?,
        ),
      ),
    ],
  );
}
