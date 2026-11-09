import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../models/shop_models.dart';
import 'category_repository.dart';
import 'color_repository.dart';
import 'debt_repository.dart';
import 'expense_repository.dart';
import 'inventory_repository.dart';
import 'purchase_repository.dart';
import 'shift_repository.dart';
import 'supplier_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalCategoryRepository(db);
});

final colorRepositoryProvider = Provider<ColorRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalColorRepository(db);
});

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalSupplierRepository(db);
});

final purchaseRepositoryProvider = Provider<PurchaseRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalPurchaseRepository(db);
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalExpenseRepository(db);
});

final debtRepositoryProvider = Provider<DebtRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalDebtRepository(db);
});

final categoriesStreamProvider = StreamProvider<List<CategoryRow>>((ref) {
  return ref.watch(categoryRepositoryProvider).watchAll();
});

final colorsStreamProvider = StreamProvider<List<ColorRow>>((ref) {
  return ref.watch(colorRepositoryProvider).watchAll();
});

final suppliersStreamProvider = StreamProvider<List<SupplierRow>>((ref) {
  return ref.watch(supplierRepositoryProvider).watchAll();
});

final purchaseOverviewsStreamProvider = StreamProvider<List<PurchaseOverview>>((
  ref,
) {
  return ref.watch(purchaseRepositoryProvider).watchOverviews();
});

final saleOverviewsStreamProvider = StreamProvider<List<SaleOverview>>((ref) {
  return ref.watch(purchaseRepositoryProvider).watchSaleOverviews();
});

final expensesStreamProvider = StreamProvider<List<ExpenseRow>>((ref) {
  return ref.watch(expenseRepositoryProvider).watchAll();
});

final debtsStreamProvider = StreamProvider<List<DebtRow>>((ref) {
  return ref.watch(debtRepositoryProvider).watchAll();
});

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalInventoryRepository(db);
});

final stockAdjustmentsStreamProvider =
    StreamProvider<List<StockAdjustmentOverview>>((ref) {
      return ref.watch(inventoryRepositoryProvider).watchStockAdjustments();
    });

final reconciliationsStreamProvider = StreamProvider<List<ReconciliationRow>>((
  ref,
) {
  return ref.watch(inventoryRepositoryProvider).watchReconciliations();
});

final shiftRepositoryProvider = Provider<ShiftRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LocalShiftRepository(db);
});

final currentShiftStreamProvider = StreamProvider<ShiftRow?>((ref) {
  return ref.watch(shiftRepositoryProvider).watchCurrentShift();
});

final shiftHistoryStreamProvider = StreamProvider<List<ShiftOverview>>((ref) {
  return ref.watch(shiftRepositoryProvider).watchShiftHistory();
});
