import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/shop_models.dart';
import '../../features/categories/presentation/categories_colors_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/debts/presentation/debts_screen.dart';
import '../../features/expenses/presentation/expenses_screen.dart';
import '../../features/export_backup/presentation/backup_restore_screen.dart';
import '../../features/export_backup/presentation/export_screen.dart';
import '../../features/more/presentation/more_screen.dart';
import '../../features/purchases/presentation/add_purchase_screen.dart';
import '../../features/purchases/presentation/purchases_screen.dart';
import '../../features/sales/presentation/sales_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/suppliers/presentation/suppliers_screen.dart';
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
      GoRoute(
        path: '/suppliers',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SuppliersScreen(),
      ),
      GoRoute(
        path: '/expenses',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ExpensesScreen(),
      ),
      GoRoute(
        path: '/debts',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DebtsScreen(),
      ),
      GoRoute(
        path: '/categories-colors',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CategoriesColorsScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/export',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ExportScreen(),
      ),
      GoRoute(
        path: '/backup-restore',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const BackupRestoreScreen(),
      ),
    ],
  );
}
