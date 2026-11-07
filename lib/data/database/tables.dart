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
