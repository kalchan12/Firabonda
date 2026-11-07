import 'dart:async';

import 'package:drift/drift.dart';

import '../../core/utils/business_logic.dart';
import '../../core/utils/uuid.dart';
import '../database/app_database.dart';
import '../models/shop_models.dart';
import 'exceptions.dart';

/// Data access for purchases and sales, including the transactional
/// "record sale" flow and the price memory lookup (`files/DATABASE.md`).
abstract interface class PurchaseRepository {
  Future<String> add(PurchaseInput input);

  Future<void> update(String id, PurchaseInput input);

  /// Soft deletes the purchase; when sales exist they are soft deleted
  /// in the same transaction.
  Future<void> softDelete(String id);

  /// Purchases with category/color names, supplier name and stock left.
  Stream<List<PurchaseOverview>> watchOverviews();

  /// Purchases, including soft deleted ones (used by the dashboard).
  Future<List<PurchaseRow>> getAllIncludingDeleted();

  /// Remaining stock for one purchase.
  Future<int> stockLeftFor(String purchaseId);

  /// Records a sale in a transaction. Enforces the stock-left rule by
  /// throwing [SaleExceedsStockException] before writing anything.
  Future<String> recordSale(SaleInput input);

  /// Sales with purchase details and computed profit.
  Stream<List<SaleOverview>> watchSaleOverviews();

  /// Last unit cost paid for a category (and color when available),
  /// newest first; null when nothing was bought yet. Money in cents.
  Future<int?> lastPricePaid({required String categoryId, String? colorId});
}

final class LocalPurchaseRepository implements PurchaseRepository {
  LocalPurchaseRepository(this._db);

  final AppDatabase _db;

  @override
  Future<String> add(PurchaseInput input) async {
    final now = DateTime.now().toUtc();
    final id = newUuid();
    await _db
        .into(_db.purchases)
        .insert(
          PurchasesCompanion.insert(
            id: id,
            categoryId: input.categoryId,
            colorId: input.colorId,
            supplierId: Value(input.supplierId),
            size: Value(input.size),
            quantity: input.quantity,
            unitCost: input.unitCostCents,
            totalCost: input.quantity * input.unitCostCents,
            sellingPrice: Value(input.sellingPriceCents),
            photoPath: Value(input.photoPath),
            note: Value(input.note),
            date: _utc(input.date),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  @override
  Future<void> update(String id, PurchaseInput input) {
    return (_db.update(_db.purchases)..where((row) => row.id.equals(id))).write(
      PurchasesCompanion(
        categoryId: Value(input.categoryId),
        colorId: Value(input.colorId),
        supplierId: Value(input.supplierId),
        size: Value(input.size),
        quantity: Value(input.quantity),
        unitCost: Value(input.unitCostCents),
        totalCost: Value(input.quantity * input.unitCostCents),
        sellingPrice: Value(input.sellingPriceCents),
        note: Value(input.note),
        photoPath: Value(input.photoPath),
        date: Value(_utc(input.date)),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Future<void> softDelete(String id) {
    final now = Value(DateTime.now().toUtc());
    return _db.transaction(() async {
      await (_db.update(_db.sales)..where((row) => row.purchaseId.equals(id)))
          .write(SalesCompanion(deletedAt: now));
      await (_db.update(_db.purchases)..where((row) => row.id.equals(id)))
          .write(PurchasesCompanion(deletedAt: now));
    });
  }

  @override
  Future<List<PurchaseRow>> getAllIncludingDeleted() {
    return _db.select(_db.purchases).get();
  }

  @override
  Stream<List<PurchaseOverview>> watchOverviews() {
    final query = _db.select(_db.purchases).join([
      innerJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.purchases.categoryId),
      ),
      innerJoin(
        _db.colorOptions,
        _db.colorOptions.id.equalsExp(_db.purchases.colorId),
      ),
      leftOuterJoin(
        _db.suppliers,
        _db.suppliers.id.equalsExp(_db.purchases.supplierId),
      ),
    ]);
    query.where(_db.purchases.deletedAt.isNull());
    query.orderBy([OrderingTerm.desc(_db.purchases.date)]);
    return query.watch().asyncMap(_buildOverviews);
  }

  @override
  Future<int> stockLeftFor(String purchaseId) async {
    final purchase = await _purchaseOrNull(purchaseId);
    if (purchase == null) {
      throw const NotFoundException('Purchase not found');
    }
    final sold = await _soldQuantity(purchaseId);
    return purchase.quantity - sold;
  }

  @override
  Future<String> recordSale(SaleInput input) {
    return _db.transaction(() async {
      final purchase = await _purchaseOrNull(input.purchaseId);
      if (purchase == null || purchase.deletedAt != null) {
        throw const NotFoundException('Purchase not found');
      }
      final sold = await _soldQuantity(input.purchaseId);
      final stockLeft = purchase.quantity - sold;
      switch (ShopLogic.checkSale(
        quantity: input.quantity,
        stockLeft: stockLeft,
      )) {
        case SaleCheck.ok:
          break;
        case SaleCheck.invalidQuantity:
          throw const SaleQuantityException();
        case SaleCheck.exceedsStock:
          throw SaleExceedsStockException(stockLeft);
      }
      final saleId = newUuid();
      final now = DateTime.now().toUtc();
      await _db
          .into(_db.sales)
          .insert(
            SalesCompanion.insert(
              id: saleId,
              purchaseId: input.purchaseId,
              quantity: input.quantity,
              unitPrice: input.unitPriceCents,
              date: _utc(input.date),
              createdAt: now,
              updatedAt: now,
            ),
          );
      return saleId;
    });
  }

  @override
  Stream<List<SaleOverview>> watchSaleOverviews() {
    final query = _db.select(_db.sales).join([
      innerJoin(
        _db.purchases,
        _db.purchases.id.equalsExp(_db.sales.purchaseId),
      ),
      innerJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.purchases.categoryId),
      ),
      innerJoin(
        _db.colorOptions,
        _db.colorOptions.id.equalsExp(_db.purchases.colorId),
      ),
    ]);
    query.where(_db.sales.deletedAt.isNull());
    query.orderBy([OrderingTerm.desc(_db.sales.date)]);
    return query.watch().map(
      (rows) => rows.map((row) {
        final sale = row.readTable(_db.sales);
        final purchase = row.readTable(_db.purchases);
        final category = row.readTable(_db.categories);
        final color = row.readTable(_db.colorOptions);
        return SaleOverview(
          id: sale.id,
          purchaseId: sale.purchaseId,
          categoryName: category.name,
          colorName: color.name,
          quantity: sale.quantity,
          unitPriceCents: sale.unitPrice,
          unitCostCents: purchase.unitCost,
          date: _asUtc(sale.date),
          profitCents: (sale.unitPrice - purchase.unitCost) * sale.quantity,
        );
      }).toList(),
    );
  }

  @override
  Future<int?> lastPricePaid({
    required String categoryId,
    String? colorId,
  }) async {
    final query = _db.select(_db.purchases)
      ..where(
        (row) => row.categoryId.equals(categoryId) & row.deletedAt.isNull(),
      )
      ..orderBy([(row) => OrderingTerm.desc(row.date)])
      ..limit(1);
    if (colorId != null) {
      query.where((row) => row.colorId.equals(colorId));
    }
    final row = await query.getSingleOrNull();
    return row?.unitCost;
  }

  Future<List<PurchaseOverview>> _buildOverviews(List<TypedResult> rows) async {
    final overviews = List<PurchaseOverview>.empty(growable: true);
    for (final row in rows) {
      final purchase = row.readTable(_db.purchases);
      final category = row.readTable(_db.categories);
      final color = row.readTable(_db.colorOptions);
      final supplier = row.readTableOrNull(_db.suppliers);
      final sold = await _soldQuantity(purchase.id);
      overviews.add(
        PurchaseOverview(
          id: purchase.id,
          categoryId: purchase.categoryId,
          categoryName: category.name,
          colorId: purchase.colorId,
          colorName: color.name,
          colorHex: int.parse(color.hex.replaceFirst('#', ''), radix: 16),
          supplierId: purchase.supplierId,
          supplierName: supplier?.name,
          size: purchase.size,
          quantity: purchase.quantity,
          unitCostCents: purchase.unitCost,
          totalCostCents: purchase.totalCost,
          sellingPriceCents: purchase.sellingPrice,
          photoPath: purchase.photoPath,
          note: purchase.note,
          date: _asUtc(purchase.date),
          stockLeft: purchase.quantity - sold,
        ),
      );
    }
    return overviews;
  }

  Future<PurchaseRow?> _purchaseOrNull(String id) {
    return (_db.select(
      _db.purchases,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
  }

  Future<int> _soldQuantity(String purchaseId) async {
    final query = _db.selectOnly(_db.sales)
      ..addColumns([_db.sales.quantity.sum()])
      ..where(
        _db.sales.purchaseId.equals(purchaseId) & _db.sales.deletedAt.isNull(),
      );
    final row = await query.getSingle();
    return row.read(_db.sales.quantity.sum()) ?? 0;
  }
}

DateTime _utc(DateTime input) => input.isUtc ? input : input.toUtc();

DateTime _asUtc(DateTime stored) => stored.isUtc
    ? stored
    : DateTime.utc(
        stored.year,
        stored.month,
        stored.day,
        stored.hour,
        stored.minute,
        stored.second,
        stored.millisecond,
        stored.microsecond,
      );
