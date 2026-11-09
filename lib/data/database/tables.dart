import 'package:drift/drift.dart';

/// Table definitions per `files/DATABASE.md`.
/// All ids are UUID strings. All money columns are integers in cents.
/// Every table has `createdAt`, `updatedAt` and nullable `deletedAt`
/// (soft delete, prepared for a future sync).

@DataClassName('CategoryRow')
@TableIndex(name: 'categories_name', columns: {#name})
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  BoolColumn get isPreset => boolean()();
  BoolColumn get isArchived => boolean()();
  IntColumn get sortOrder => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ColorRow')
class ColorOptions extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get hex => text()();
  BoolColumn get isPreset => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SupplierRow')
class Suppliers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PurchaseRow')
@TableIndex(name: 'purchases_category_date', columns: {#categoryId, #date})
class Purchases extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text()();
  TextColumn get colorId => text()();
  TextColumn get supplierId => text().nullable()();
  TextColumn get size => text().nullable()();
  IntColumn get quantity => integer()();
  IntColumn get unitCost => integer()();
  IntColumn get totalCost => integer()();
  IntColumn get sellingPrice => integer().nullable()();
  TextColumn get photoPath => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get date => dateTime()();
  TextColumn get batchId => text().nullable()();
  TextColumn get accountId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SaleRow')
@TableIndex(name: 'sales_purchase_date', columns: {#purchaseId, #date})
@TableIndex(name: 'sales_date', columns: {#date})
class Sales extends Table {
  TextColumn get id => text()();
  TextColumn get purchaseId => text()();
  IntColumn get quantity => integer()();
  IntColumn get unitPrice => integer()();
  IntColumn get costAtSale => integer().nullable()();
  IntColumn get assumedPriceAtSale => integer().nullable()();
  TextColumn get accountId => text().nullable()();
  IntColumn get paidAmount => integer().nullable()();
  TextColumn get shiftId => text().nullable()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ExpenseRow')
class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get amount => integer()();
  DateTimeColumn get date => dateTime()();
  TextColumn get accountId => text().nullable()();
  TextColumn get shiftId => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DebtRow')
class Debts extends Table {
  TextColumn get id => text()();
  TextColumn get personName => text()();
  IntColumn get amount => integer()();

  /// 'owed_to_me' or 'i_owe'.
  TextColumn get direction => text()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get isPaid => boolean()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Key/value metadata: schema version, seed version.
@DataClassName('AppMetaRow')
class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Financial accounts: Cash, Bank, Mobile money, etc.
@DataClassName('AccountRow')
class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// 'cash', 'bank', 'mobile_money', 'other'
  TextColumn get type => text()();
  IntColumn get openingBalance => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Ledger entries linking all money movements to specific accounts.
@DataClassName('AccountTransactionRow')
@TableIndex(name: 'acc_tx_account_date', columns: {#accountId, #date})
class AccountTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text()();
  IntColumn get amount => integer()();

  /// 'inflow' or 'outflow'
  TextColumn get direction => text()();

  /// 'purchase', 'sale', 'expense', 'debt_payment', 'transfer', 'deposit', 'withdrawal', 'reconciliation'
  TextColumn get type => text()();
  TextColumn get relatedId => text().nullable()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Batch purchases grouping multiple lot items into one supplier order.
@DataClassName('BatchRow')
class Batches extends Table {
  TextColumn get id => text()();
  TextColumn get supplierId => text().nullable()();
  DateTimeColumn get date => dateTime()();
  IntColumn get totalPaid => integer()();
  TextColumn get accountId => text().nullable()();
  TextColumn get shiftId => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Stock adjustments for damaged, lost, or returned items.
@DataClassName('StockAdjustmentRow')
class StockAdjustments extends Table {
  TextColumn get id => text()();
  TextColumn get purchaseId => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  IntColumn get quantityChange => integer()();

  /// 'damaged', 'lost', 'returned_to_supplier', 'customer_return', 'personal_use', 'count_correction'
  TextColumn get reason => text()();
  IntColumn get valueAtCost => integer()();
  DateTimeColumn get date => dateTime()();
  TextColumn get shiftId => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cash & stock count reconciliations.
@DataClassName('ReconciliationRow')
class Reconciliations extends Table {
  TextColumn get id => text()();

  /// 'cash_account' or 'stock'
  TextColumn get type => text()();
  TextColumn get accountId => text().nullable()();
  IntColumn get expected => integer()();
  IntColumn get counted => integer()();
  IntColumn get difference => integer()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Audit trail logging any changes or corrections to records.
@DataClassName('EditHistoryRow')
class EditHistory extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get field => text()();
  TextColumn get oldValue => text().nullable()();
  TextColumn get newValue => text().nullable()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Shifts tracking cash, transactions, and end-of-shift reconciliation.
@DataClassName('ShiftRow')
class Shifts extends Table {
  TextColumn get id => text()();
  DateTimeColumn get openedAt => dateTime()();
  DateTimeColumn get closedAt => dateTime().nullable()();
  IntColumn get openingCash => integer().withDefault(const Constant(0))();
  IntColumn get expectedCash => integer().nullable()();
  IntColumn get actualCash => integer().nullable()();
  IntColumn get cashDifference => integer().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get openedBy => text().nullable()();
  TextColumn get closedBy => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
