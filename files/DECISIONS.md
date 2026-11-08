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

## 2026-11-08: Improvement Plan V2 - Step 4
- **Navigation Bar & Speed Dial:**
  - Implemented 68-72dp raised circular center button (+ icon only, no text label, semantic label/tooltip "Add", subtle accent blue glow, cutout notch effect).
  - Center button tap animates a speed-dial sheet with 3 large options: Purchase, Batch purchase, Quick sale.
  - Active destinations show filled icons in primary color; inactive show outline in muted color with light haptic feedback.

## 2026-11-08: Improvement Plan V2 - Step 5
- **Dashboard Redesign:**
  - Net profit hero tile displaying `Net profit = Profit - Expenses - Losses` prominently at top with status badge (green/red).
  - 2x2 grid: Sold (revenue), Cost of sold items, Bought (spent), Expenses.
  - Target profit gauge/bar: compares achieved profit % vs target profit % (default 100% from settings).
  - Recent sales list with time, quantity, category, color, revenue and profit.
  - Expandable "More details" accordion containing stock value, low stock alerts, best sellers ranking, and profit trend curve chart.

## 2026-11-08: Improvement Plan V2 - Step 6
- **Pricing & Quick Sell:**
  - 100% target profit default pricing helper on purchases and sales (2x cost default).
  - Streamlined Quick Sale screen with inventory search and 2-3 tap sell flow.
  - Partial payment support: customer unpaid balance is automatically logged as a receivable debt in `debts`.

## 2026-11-08: Improvement Plan V2 - Step 7
- **Batch Bundle Lot Purchase:**
  - Form supporting total lot cost, payment account, supplier, and dynamic list of items.
  - Cost allocation using Hamilton's largest-remainder method ensuring exact cent-level allocation with zero fractions of cents lost or created.

## 2026-11-08: Improvement Plan V2 - Step 8
- **Stock Adjustments, Reconciliation & Day Close:**
  - Stock adjustments screen and sheet supporting reasons (`damaged`, `lost`, `returned_to_supplier`, `customer_return`, `personal_use`, `count_correction`). Automatically adjusts purchase stock left and records in losses.
  - Cash & stock reconciliation screen comparing counted vs expected values with discrepancy logging.
  - Day close summary report with net profit, revenue, cash collected, and one-tap clipboard summary export.

## 2026-11-08: Improvement Plan V2 - Step 9
- **Quick Calculator:**
  - App-shell level quick calculator button accessible anywhere across the app.
  - 20-entry calculation history with tap-to-restore or tap-to-copy.
  - Clipboard copy and use-result actions.

## 2026-11-08: Improvement Plan V2 - Step 10
- **Speed & Usability Pass:**
  - Quick quantity stepper chips (+1, +5, +10) for rapid inventory entry.
  - Smart defaults remembering last selected category and supplier for consecutive additions.
  - Undo snackbars on soft deletions (purchases, sales, expenses, debts) giving the shop owner 4 seconds to restore accidental deletions.

