/// Inputs to create or update a purchase. Money fields are int cents.
final class PurchaseInput {
  const PurchaseInput({
    required this.categoryId,
    required this.colorId,
    this.supplierId,
    this.size,
    required this.quantity,
    required this.unitCostCents,
    this.sellingPriceCents,
    this.note,
    this.photoPath,
    required this.date,
  });

  final String categoryId;
  final String colorId;
  final String? supplierId;
  final String? size;
  final int quantity;
  final int unitCostCents;

  /// Planned price per piece; null when not set yet.
  final int? sellingPriceCents;
  final String? note;
  final String? photoPath;
  final DateTime date;
}

/// Inputs to record a sale on an existing purchase.
final class SaleInput {
  const SaleInput({
    required this.purchaseId,
    required this.quantity,
    required this.unitPriceCents,
    required this.date,
    this.costAtSaleCents,
    this.accountId = 'acc_cash',
    this.paidAmountCents,
    this.customerName,
  });

  final String purchaseId;
  final int quantity;
  final int unitPriceCents;
  final DateTime date;
  final int? costAtSaleCents;
  final String? accountId;
  final int? paidAmountCents;
  final String? customerName;
}

final class BatchItemInput {
  const BatchItemInput({
    required this.categoryId,
    required this.colorId,
    required this.quantity,
    this.sellingPriceCents,
    this.size,
  });

  final String categoryId;
  final String colorId;
  final int quantity;
  final int? sellingPriceCents;
  final String? size;
}

final class BatchPurchaseInput {
  const BatchPurchaseInput({
    this.supplierId,
    required this.totalCostCents,
    required this.date,
    this.accountId = 'acc_cash',
    this.note,
    required this.items,
  });

  final String? supplierId;
  final int totalCostCents;
  final DateTime date;
  final String? accountId;
  final String? note;
  final List<BatchItemInput> items;
}

/// A purchase row joined with its category/color names and remaining stock.
final class PurchaseOverview {
  const PurchaseOverview({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.colorId,
    required this.colorName,
    required this.colorHex,
    required this.supplierId,
    required this.supplierName,
    required this.size,
    required this.quantity,
    required this.unitCostCents,
    required this.totalCostCents,
    required this.sellingPriceCents,
    required this.photoPath,
    required this.note,
    required this.date,
    required this.stockLeft,
  });

  final String id;
  final String categoryId;
  final String categoryName;
  final String colorId;
  final String colorName;
  final int colorHex;
  final String? supplierId;
  final String? supplierName;
  final String? size;
  final int quantity;
  final int unitCostCents;
  final int totalCostCents;
  final int? sellingPriceCents;
  final String? photoPath;
  final String? note;
  final DateTime date;
  final int stockLeft;
}

/// A sale row joined with what it was sold from, with computed profit.
final class SaleOverview {
  const SaleOverview({
    required this.id,
    required this.purchaseId,
    required this.categoryName,
    required this.colorName,
    required this.quantity,
    required this.unitPriceCents,
    required this.unitCostCents,
    required this.date,
    required this.profitCents,
    this.costAtSaleCents,
    this.accountId = 'acc_cash',
    this.paidAmountCents,
  });

  final String id;
  final String purchaseId;
  final String categoryName;
  final String colorName;
  final int quantity;
  final int unitPriceCents;
  final int unitCostCents;
  final DateTime date;
  final int profitCents;
  final int? costAtSaleCents;
  final String? accountId;
  final int? paidAmountCents;
}

/// Direction of a debt entry.
enum DebtDirection {
  owedToMe('owed_to_me'),
  iOwe('i_owe');

  const DebtDirection(this.dbValue);

  final String dbValue;

  static DebtDirection fromDbValue(String value) => values.firstWhere(
    (direction) => direction.dbValue == value,
    orElse: () => owedToMe,
  );
}

/// Inputs to create a supplier entry.
final class SupplierInput {
  const SupplierInput({required this.name, this.phone, this.note});

  final String name;
  final String? phone;
  final String? note;
}

/// Inputs to create an expense entry.
final class ExpenseInput {
  const ExpenseInput({
    required this.title,
    required this.amountCents,
    required this.date,
    this.note,
  });

  final String title;
  final int amountCents;
  final DateTime date;
  final String? note;
}

/// Inputs to create a debt entry.
final class DebtInput {
  const DebtInput({
    required this.personName,
    required this.amountCents,
    required this.direction,
    this.dueDate,
    this.note,
  });

  final String personName;
  final int amountCents;
  final DebtDirection direction;
  final DateTime? dueDate;
  final String? note;
}

enum StockAdjustmentReason {
  damaged('damaged', 'Damaged in store / transit', true),
  lost('lost', 'Missing / stolen', true),
  personalUse('personal_use', 'Personal or family use', true),
  returnedToSupplier('returned_to_supplier', 'Returned to supplier', false),
  customerReturn('customer_return', 'Customer return', false),
  countCorrection('count_correction', 'Count correction', false);

  const StockAdjustmentReason(this.dbValue, this.label, this.isLoss);

  final String dbValue;
  final String label;
  final bool isLoss;

  static StockAdjustmentReason fromDbValue(String value) => values.firstWhere(
    (r) => r.dbValue == value,
    orElse: () => countCorrection,
  );
}

final class StockAdjustmentInput {
  const StockAdjustmentInput({
    required this.purchaseId,
    required this.categoryId,
    required this.quantityChange,
    required this.reason,
    required this.valueAtCostCents,
    required this.date,
    this.note,
    this.photoPath,
  });

  final String purchaseId;
  final String categoryId;
  final int quantityChange;
  final StockAdjustmentReason reason;
  final int valueAtCostCents;
  final DateTime date;
  final String? note;
  final String? photoPath;
}

final class StockAdjustmentOverview {
  const StockAdjustmentOverview({
    required this.id,
    required this.purchaseId,
    required this.categoryName,
    required this.colorName,
    required this.quantityChange,
    required this.reason,
    required this.valueAtCostCents,
    required this.date,
    this.note,
    this.photoPath,
  });

  final String id;
  final String purchaseId;
  final String categoryName;
  final String colorName;
  final int quantityChange;
  final StockAdjustmentReason reason;
  final int valueAtCostCents;
  final DateTime date;
  final String? note;
  final String? photoPath;
}

final class ReconciliationInput {
  const ReconciliationInput({
    required this.type,
    this.accountId,
    required this.expectedCents,
    required this.countedCents,
    required this.date,
    this.note,
  });

  final String type; // 'cash_account' or 'stock'
  final String? accountId;
  final int expectedCents;
  final int countedCents;
  final DateTime date;
  final String? note;
}
