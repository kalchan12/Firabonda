# Architectural Decisions Log

## 2026-11-08: Improvement Plan V2 - Step 1
- **UI Overflow & Text Scaling:** Wrapped long item labels in `Expanded`/`Flexible`, capped bottom sheet heights to `0.9 * screenHeight`, set `FittedBox.scaleDown` on button labels, and wrapped period selector in horizontal `SingleChildScrollView` to support 360dp screens at 1.0, 1.3, and 1.6 text scales.
- **Fonts & Typography:** Switched to Sora for headings and large figures, and Inter with `FontFeature.tabularFigures()` for all numeric data and body labels.
- **Dashboard Default:** Dashboard now defaults to Today on every launch.

## 2026-11-08: Improvement Plan V2 - Step 2
- **Calendar Periods & Injectable Clock:** Introduced `AppClock` and `PeriodRange` utility. Replaced 7-day rolling window with local calendar boundaries: Today (00:00 to tomorrow 00:00), Yesterday, Week (start configurable: Monday or Sunday), Month (1st to 1st), All time, and Custom date range.
- **Stable Totals:** Standardized Bought, Sold, Cost of sold items, Profit, Profit %, Expenses, Losses, and Net Profit. Historical profit is frozen using `costAtSale`.
- **Midnight Rollover:** Added `dashboardRolloverProvider` that automatically triggers state refresh at local midnight and upon app resume from background.

## 2026-11-08: Improvement Plan V2 - Step 3
- **Drift Schema V2 Migration:**
  - Automated pre-migration safety backup copying database file to `<db>.pre_v2_backup` prior to schema changes.
  - Added new tables: `accounts`, `account_transactions`, `batches`, `stock_adjustments`, `reconciliations`, `edit_history`.
  - Added columns: `purchases.batchId`, `purchases.accountId`, `sales.costAtSale`, `sales.accountId`, `sales.paidAmount`, `expenses.accountId`.
  - Seeded default accounts: Cash (`acc_cash`), Bank (`acc_bank`), Mobile money (`acc_telebirr`).
  - Backfilled existing transactions with default Cash account and froze past sales `costAtSale` to their original purchase unit cost.
  - Added comprehensive automated migration verification test in `test/database/migration_v1_to_v2_test.dart`.
