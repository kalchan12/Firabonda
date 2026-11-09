import 'dart:async';
import 'dart:io';

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

  /// Restores a soft-deleted purchase row.
  Future<void> restore(String id);

  /// Purchases with category/color names, supplier name and stock left.
  Stream<List<PurchaseOverview>> watchOverviews();

  /// Purchases, including soft deleted ones (used by the dashboard).
  Future<List<PurchaseRow>> getAllIncludingDeleted();

  /// Remaining stock for one purchase.
  Future<int> stockLeftFor(String purchaseId);

  /// Records a sale in a transaction. Enforces the stock-left rule by
  /// throwing [SaleExceedsStockException] before writing anything.
  Future<String> recordSale(SaleInput input);

  /// Soft deletes a sale record, restoring the purchase stock.
  Future<void> softDeleteSale(String saleId);

  /// Restores a soft-deleted sale record.
  Future<void> restoreSale(String saleId);

  /// Sales with purchase details and computed profit.
  Stream<List<SaleOverview>> watchSaleOverviews();

  /// Last unit cost paid for a category (and color when available),
  /// newest first; null when nothing was bought yet. Money in cents.
  Future<int?> lastPricePaid({required String categoryId, String? colorId});

  /// Records a batch lot purchase and distributes total cost across items.
  Future<String> addBatch(BatchPurchaseInput input);

  /// Retrieves or lazily creates a "Mixed" color option in the database.
  Future<String> getOrCreateMixedColorId();
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
      final purchase = await (_db.select(
        _db.purchases,
      )..where((row) => row.id.equals(id))).getSingleOrNull();
      if (purchase?.photoPath != null) {
        for (final p in purchase!.photoPath!.split('|')) {
          final trimmed = p.trim();
          if (trimmed.isNotEmpty) {
            final photo = File(trimmed);
            if (photo.existsSync()) {
              try {
                await photo.delete();
              } catch (_) {}
            }
          }
        }
      }
      await (_db.update(_db.sales)..where((row) => row.purchaseId.equals(id)))
          .write(SalesCompanion(deletedAt: now));
      await (_db.update(_db.purchases)..where((row) => row.id.equals(id)))
          .write(PurchasesCompanion(deletedAt: now));
    });
  }

  @override
  Future<void> restore(String id) {
    return (_db.update(_db.purchases)..where((row) => row.id.equals(id))).write(
      const PurchasesCompanion(deletedAt: Value(null)),
    );
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
    final adjusted = await _stockAdjustedQuantity(purchaseId);
    return purchase.quantity - sold + adjusted;
  }

  @override
  Future<String> recordSale(SaleInput input) {
    return _db.transaction(() async {
      final purchase = await _purchaseOrNull(input.purchaseId);
      if (purchase == null || purchase.deletedAt != null) {
        throw const NotFoundException('Purchase not found');
      }
      final sold = await _soldQuantity(input.purchaseId);
      final adjusted = await _stockAdjustedQuantity(input.purchaseId);
      final stockLeft = purchase.quantity - sold + adjusted;
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
      final costAtSale = input.costAtSaleCents ?? purchase.unitCost;
      final assumedPriceAtSale =
          input.assumedPriceAtSaleCents ?? purchase.sellingPrice;
      final totalRevenue = input.unitPriceCents * input.quantity;
      final paidAmount = input.paidAmountCents ?? totalRevenue;

      final openShift = input.shiftId != null
          ? null
          : await (_db.select(_db.shifts)
                  ..where((s) => s.closedAt.isNull() & s.deletedAt.isNull())
                  ..orderBy([(s) => OrderingTerm.desc(s.openedAt)])
                  ..limit(1))
                .getSingleOrNull();
      final shiftId = input.shiftId ?? openShift?.id;

      await _db
          .into(_db.sales)
          .insert(
            SalesCompanion.insert(
              id: saleId,
              purchaseId: input.purchaseId,
              quantity: input.quantity,
              unitPrice: input.unitPriceCents,
              costAtSale: Value(costAtSale),
              assumedPriceAtSale: Value(assumedPriceAtSale),
              accountId: Value(input.accountId ?? 'acc_cash'),
              shiftId: Value(shiftId),
              paidAmount: Value(paidAmount),
              date: _utc(input.date),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Auto-record unpaid balance as receivable in debts (Step 6)
      final unpaid = totalRevenue - paidAmount;
      if (unpaid > 0) {
        final debtId = newUuid();
        final debtor =
            (input.customerName != null &&
                input.customerName!.trim().isNotEmpty)
            ? input.customerName!.trim()
            : 'Customer (Sale)';
        await _db
            .into(_db.debts)
            .insert(
              DebtsCompanion.insert(
                id: debtId,
                personName: debtor,
                amount: unpaid,
                direction: 'owed_to_me',
                isPaid: false,
                note: Value(
                  'Unpaid balance from sale of ${input.quantity}x items',
                ),
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
      return saleId;
    });
  }

  @override
  Future<void> softDeleteSale(String saleId) {
    final now = Value(DateTime.now().toUtc());
    return (_db.update(_db.sales)..where((row) => row.id.equals(saleId))).write(
      SalesCompanion(deletedAt: now),
    );
  }

  @override
  Future<void> restoreSale(String saleId) {
    return (_db.update(_db.sales)..where((row) => row.id.equals(saleId))).write(
      const SalesCompanion(deletedAt: Value(null)),
    );
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
        final costPerPiece = sale.costAtSale ?? purchase.unitCost;
        return SaleOverview(
          id: sale.id,
          purchaseId: sale.purchaseId,
          categoryId: category.id,
          categoryName: category.name,
          colorName: color.name,
          quantity: sale.quantity,
          unitPriceCents: sale.unitPrice,
          unitCostCents: costPerPiece,
          date: _asUtc(sale.date),
          profitCents: (sale.unitPrice - costPerPiece) * sale.quantity,
          costAtSaleCents: sale.costAtSale,
          assumedPriceAtSaleCents:
              sale.assumedPriceAtSale ?? purchase.sellingPrice,
          accountId: sale.accountId,
          paidAmountCents: sale.paidAmount,
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
        (row) =>
            row.categoryId.equals(categoryId) &
            (colorId != null
                ? row.colorId.equals(colorId)
                : const Constant(true)) &
            row.deletedAt.isNull(),
      )
      ..orderBy([(row) => OrderingTerm.desc(row.date)])
      ..limit(1);
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
      final adjusted = await _stockAdjustedQuantity(purchase.id);
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
          stockLeft: purchase.quantity - sold + adjusted,
        ),
      );
    }
    return overviews;
  }

  @override
  Future<String> addBatch(BatchPurchaseInput input) async {
    return _db.transaction(() async {
      final batchId = newUuid();
      final now = DateTime.now().toUtc();
      final dateUtc = _utc(input.date);

      final openShift = input.shiftId != null
          ? null
          : await (_db.select(_db.shifts)
                  ..where((s) => s.closedAt.isNull() & s.deletedAt.isNull())
                  ..orderBy([(s) => OrderingTerm.desc(s.openedAt)])
                  ..limit(1))
                .getSingleOrNull();
      final shiftId = input.shiftId ?? openShift?.id;

      await _db
          .into(_db.batches)
          .insert(
            BatchesCompanion.insert(
              id: batchId,
              supplierId: Value(input.supplierId),
              date: dateUtc,
              totalPaid: input.totalCostCents,
              accountId: Value(input.accountId ?? 'acc_cash'),
              shiftId: Value(shiftId),
              note: Value(input.note),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Determine costs: if each item has an explicit unit cost, use it;
      // otherwise allocate totalCostCents using largest-remainder method.
      final hasExplicitLineCosts = input.items.every(
        (i) => i.unitCostCents != null && i.unitCostCents! > 0,
      );

      final List<int> allocatedCosts;
      if (hasExplicitLineCosts) {
        allocatedCosts = input.items
            .map((i) => i.unitCostCents! * i.quantity)
            .toList();
      } else {
        final quantities = input.items.map((i) => i.quantity).toList();
        allocatedCosts = ShopLogic.allocateBatchCost(
          totalCostCents: input.totalCostCents,
          quantities: quantities,
        );
      }

      for (var idx = 0; idx < input.items.length; idx++) {
        final item = input.items[idx];
        final itemTotalCost = allocatedCosts[idx];
        final itemUnitCost =
            item.unitCostCents ?? (itemTotalCost / item.quantity).round();
        final purchaseId = newUuid();

        await _db
            .into(_db.purchases)
            .insert(
              PurchasesCompanion.insert(
                id: purchaseId,
                batchId: Value(batchId),
                categoryId: item.categoryId,
                colorId: item.colorId,
                supplierId: Value(input.supplierId),
                size: Value(item.size),
                quantity: item.quantity,
                unitCost: itemUnitCost,
                totalCost: itemTotalCost,
                sellingPrice: Value(item.sellingPriceCents),
                photoPath: Value(item.photoPath),
                note: Value(item.note ?? input.note),
                date: dateUtc,
                createdAt: now,
                updatedAt: now,
              ),
            );
      }

      return batchId;
    });
  }

  @override
  Future<String> getOrCreateMixedColorId() async {
    final existing =
        await (_db.select(_db.colorOptions)
              ..where((c) => c.name.equals('Mixed') | c.name.equals('mixed')))
            .getSingleOrNull();
    if (existing != null) return existing.id;

    final now = DateTime.now().toUtc();
    final id = newUuid();
    await _db
        .into(_db.colorOptions)
        .insert(
          ColorOptionsCompanion.insert(
            id: id,
            name: 'Mixed',
            hex: '#9E9E9E',
            isPreset: true,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
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

  Future<int> _stockAdjustedQuantity(String purchaseId) async {
    final query = _db.selectOnly(_db.stockAdjustments)
      ..addColumns([_db.stockAdjustments.quantityChange.sum()])
      ..where(
        _db.stockAdjustments.purchaseId.equals(purchaseId) &
            _db.stockAdjustments.deletedAt.isNull(),
      );
    final row = await query.getSingle();
    return row.read(_db.stockAdjustments.quantityChange.sum()) ?? 0;
  }
}

DateTime _utc(DateTime input) => input.isUtc ? input : input.toUtc();

DateTime _asUtc(DateTime stored) => stored.isUtc ? stored : stored.toUtc();
