# Database: Fira Bonda

SQLite through Drift. All ids are UUID strings. All tables include `createdAt`, `updatedAt` and `deletedAt` (nullable, for soft delete and a future sync). All money columns are integers in cents.

## Tables

### categories
| Column | Type | Notes |
|--------|------|-------|
| id | text PK | UUID |
| name | text | unique among non-deleted |
| icon | text | icon key |
| isPreset | bool | seeded on first launch |
| isArchived | bool | hidden from pickers but kept for history |
| sortOrder | int | |

### colors
| Column | Type | Notes |
|--------|------|-------|
| id | text PK | |
| name | text | |
| hex | text | `#RRGGBB` |
| isPreset | bool | |

### suppliers
| Column | Type | Notes |
|--------|------|-------|
| id | text PK | |
| name | text | |
| phone | text? | |
| note | text? | |

### purchases
| Column | Type | Notes |
|--------|------|-------|
| id | text PK | |
| categoryId | text FK | -> categories |
| colorId | text FK | -> colors |
| supplierId | text? FK | -> suppliers |
| batchId | text? FK | -> batches (nullable) |
| accountId | text? FK | -> accounts (defaults to acc_cash) |
| size | text? | optional, hidden by default |
| quantity | int | > 0 |
| unitCost | int | cents, >= 0 |
| totalCost | int | cents, equals quantity x unitCost unless edited manually |
| sellingPrice | int? | planned price per piece, cents |
| photoPath | text? | local file path |
| note | text? | |
| date | datetime | purchase date |

### sales
| Column | Type | Notes |
|--------|------|-------|
| id | text PK | |
| purchaseId | text FK | -> purchases |
| quantity | int | > 0, cannot exceed stock left |
| unitPrice | int | cents, price sold at |
| costAtSale | int? | cents per piece, frozen at time of sale |
| accountId | text? FK | -> accounts (defaults to acc_cash) |
| paidAmount | int? | cents paid at sale, remainder becomes debt |
| date | datetime | |

### expenses
| Column | Type | Notes |
|--------|------|-------|
| id | text PK | |
| title | text | |
| amount | int | cents |
| accountId | text? FK | -> accounts (defaults to acc_cash) |
| date | datetime | |
| note | text? | |

### debts
| Column | Type | Notes |
|--------|------|-------|
| id | text PK | |
| personName | text | |
| amount | int | cents |
| direction | text | `owed_to_me` or `i_owe` |
| dueDate | datetime? | |
| isPaid | bool | |
| note | text? | |

### accounts
| Column | Type | Notes |
|--------|------|-------|
| id | text PK | UUID or preset (`acc_cash`, `acc_bank`, `acc_telebirr`) |
| name | text | Account display name |
| type | text | `cash`, `bank`, `mobile_money`, `other` |
| openingBalance | int | cents (default 0) |
| isArchived | bool | archived accounts |

### account_transactions
| Column | Type | Notes |
|--------|------|-------|
| id | text PK | UUID |
| accountId | text FK | -> accounts |
| amount | int | cents (positive) |
| direction | text | `inflow` or `outflow` |
| type | text | `purchase`, `sale`, `expense`, `debt_payment`, `transfer`, `deposit`, `withdrawal`, `reconciliation` |
| relatedId | text? | ID of related sale, purchase, or expense |
| date | datetime | transaction date |
| note | text? | |

### batches
| Column | Type | Notes |
|--------|------|-------|
| id | text PK | UUID |
| supplierId | text? FK | -> suppliers |
| date | datetime | order date |
| totalPaid | int | cents |
| accountId | text? FK | -> accounts |
| note | text? | |

### stock_adjustments
| Column | Type | Notes |
|--------|------|-------|
| id | text PK | UUID |
| purchaseId | text? FK | -> purchases |
| categoryId | text? FK | -> categories |
| quantityChange | int | pieces (negative for loss, positive for return) |
| reason | text | `damaged`, `lost`, `returned_to_supplier`, `customer_return`, `personal_use`, `count_correction` |
| valueAtCost | int | cents (qty x cost) |
| date | datetime | adjustment date |
| note | text? | |
| photoPath | text? | optional photo of damage |

### reconciliations
| Column | Type | Notes |
|--------|------|-------|
| id | text PK | UUID |
| type | text | `cash_account` or `stock` |
| accountId | text? FK | -> accounts |
| expected | int | expected cents or pieces |
| counted | int | actual counted cents or pieces |
| difference | int | counted - expected |
| date | datetime | reconciliation date |
| note | text? | |

### edit_history
| Column | Type | Notes |
|--------|------|-------|
| id | text PK | UUID |
| entityType | text | `purchase`, `sale`, `expense`, etc. |
| entityId | text | ID of target entity |
| field | text | changed field name |
| oldValue | text? | stringified old value |
| newValue | text? | stringified new value |
| date | datetime | change timestamp |

### app_meta
Holds the database schema version and seed version.

## Relations

```
categories 1---* purchases *---1 colors
suppliers  1---* purchases
purchases  1---* sales
```

## Seed data (first launch only)

- Categories: T-shirts, Shirts, Hoodies, Jackets, Trousers, Jeans, Shorts, Sweaters
- Colors: Black `#000000`, White `#FFFFFF`, Gray `#808080`, Blue `#2F5BFF`, Navy `#0B1F4B`, Red `#E53950`, Green `#2E9E63`, Brown `#7A4B2A`, Beige `#D8C3A5`, Yellow `#F2C94C`

## Rules and constraints

- Deleting a category or color that is used by purchases is **not allowed**; archive it instead.
- Deleting a purchase that has sales asks for confirmation and removes (soft deletes) its sales too.
- Index: `purchases(categoryId, date)`, `sales(purchaseId, date)`, `sales(date)`.
- "Last price paid" query: latest non-deleted purchase for the same `categoryId` (and `colorId` if available), ordered by `date` descending.

## Migrations

- Use Drift's migration system. Every schema change bumps the version and has a migration plus a test.
- Never drop user data in a migration.

## Backup and restore

- Backup = copy of the SQLite file plus the photos folder, packaged as a single zip and shared through the share sheet.
- Restore validates the file (schema version, integrity check) before replacing current data, and keeps a safety copy of the current database first.
