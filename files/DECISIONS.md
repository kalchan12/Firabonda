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

## 2026-11-09: Fix Round V2.1
- **Task 1: Sell Screen Scroll & Fixed Action Button:**
  - Implemented `isScrollControlled: true` on bottom sheets with keyboard insets padding (`MediaQuery.viewInsets.bottom`).
  - Added fixed sticky footer button ensuring primary sell/save action is always visible and tappable across 360dp screens, large text scales (1.6), and active software keyboard.
- **Task 2: Standardized Corner Radius & AppCard:**
  - Standardized theme tokens: `radiusCard = 24`, `radiusHero = 28`, `radiusButton = 16`, `radiusSheet = 28`, `radiusChip = 999`.
  - Created shared `AppCard` with anti-aliased clipping (`clipBehavior: Clip.antiAlias`) across all dashboards, list items, and form containers.
- **Task 3: Center Plus Direct to Batch Purchase:**
  - Removed speed-dial menu and animation; center 70dp raised plus button routes directly to `/batch-purchase`.
  - Batch purchase acts as the universal inventory ingress for clothes retail.
- **Task 4: Batch Purchase Enhancements:**
  - Added piece-level purchase price to every batch item line with live line total (`quantity * unitCost`).
  - Implemented two-color split (splits quantity between color A & B) and preset Mixed color option.
  - Added duplicate line, delete line, and batch-level optional notes/photos.
- **Task 5: Profit Logic Overhaul (% of Target):**
  - Removed arbitrary 100% markup default and automatic suggested price.
  - Pure model `ProfitCalculator` calculates Actual profit, Assumed profit, and `% of target` (`actual / assumed * 100`).
  - Clear states: Over profit, On target, Under target, Breakeven, Loss (red badge), and Target not assumed.
  - Drift schema v3 migration adds `sales.assumedPriceAtSale` to freeze target prices at time of sale with safe backfill.
- **Task 6: Simple Sell Screen:**
  - Simplified sell sheet into 3 key inputs: big quantity stepper with quick chips (1, 2, 3, 5, All), planned selling price prefill or empty, and live profit result card (+ETB, Loss, % of target). Collapsible "More options" accordion for account, date, and partial payment debt.
- **Task 7: Unified Profit Language:**
  - Removed all occurrences of "markup", "target profit margin", and "100% target" from UI and docs.
- **Task 8: Shift System (Replacing Day Close):**
  - Drift schema v4 adds `shifts` table and `shiftId` tracking across `sales`, `expenses`, `batches`, and `stockAdjustments`.
  - Formula: `expectedCash = openingCash + cashSales - cashExpenses - cashPurchases`.
  - Open & Close Shift modal sheets with live drawer counting and discrepancy logging to `reconciliations` table.
  - Today dashboard displays Active Shift banner with direct close/reconcile action. Shift history screen logs past shifts.

## 2026-11-09: Post-V2.1 Improvements & Polishing
- **Multi-Item Purchase Calculations & Scaling:**
  - Target selling price and expected profit calculations now scale by `quantity` when `quantity > 1`.
  - In both Single Purchase and Batch Purchase screens, live feedback displays aggregate totals alongside per-unit prices (e.g. `Target sell: ETB 1,500.00 (ETB 300.00 each) • Exp. profit: +ETB 500.00 (+ETB 100.00 each)`).
  - Fixed purchases list cards to display total target revenue and total expected profit scaled to item quantity.
- **Multi-Image Purchase Support:**
  - Optional photo picker scales dynamically: allows 1 image when `quantity = 1`, and up to `quantity` images (1 per piece) when `quantity > 1`.
  - Stored cleanly as pipe-delimited (`|`) local file paths in `purchases.photoPath`, preserving full backward compatibility without database schema changes.
  - Built reusable `PurchasePhotoPicker` with multi-image gallery selection, thumbnail strips, remove badges, and full-screen swipeable preview dialog (`PhotoGalleryViewerDialog`).
  - Purchase cards show an interactive photo count badge (`📷 X photos`) that opens the swipeable gallery on tap.
  - Deleting a purchase automatically deletes all referenced image files from device storage.
- **Credit Sales ("Not Paid") Flow & Debt Integration:**
  - Replaced ambiguous "Partial payment" toggle with an intuitive "Not paid" toggle in `sell_bottom_sheet`.
  - When toggled, prompts for Customer Name (mandatory for debt logging) and an optional "Amount paid now" field (defaults to ETB 0 for fully unpaid sales).
  - Unpaid balance (`totalPrice - paidAmount`) is automatically recorded in the `debts` table as `owed_to_me` with a clear reference note to the sale.
  - Soft-deleting a credit sale automatically cancels/removes the linked debt record.
- **Dashboard "Paid with Credit" Card & Credit Badges:**
  - Added dedicated "Paid with credit" stat card to the Dashboard for the active calendar period, showing total credit sales amount and credit transaction count.
  - Credit sales remain fully counted in total sold items and gross/net profit figures (accrual basis), while distinctly highlighting unpaid revenue.
  - Visual status badges added to Dashboard recent sales and Sales list cards: `Credit (unpaid)` (red badge) and `Credit • owes ETB X` (amber badge).
- **Batch Purchase & Shift UI Simplifications:**
  - Supplier field: replaced freeform inline text input with a dropdown selector populated from existing registered suppliers, including an inline shortcut to add a new supplier.
  - Simplified segmented button labels in batch purchase to "Per item" and "Total bundle", and updated all UI terminology from "line" to "item".
  - Removed two-color split controls to simplify entry; added standard preset `Mixed` color (`#8E8E93`).
  - Streamlined Open & Close Shift modal bottom sheets into a clean cash amount input and one primary confirmation button.
- **Floating Nav Bar Clearance:**
  - Passed `useRootNavigator: true` to bottom sheet modal invocations across the app (`sell_bottom_sheet`, `calculator_sheet`, shift sheets, etc.) to guarantee bottom action buttons are never obscured by the floating nav bar dock.

## 2026-11-09: Shift Reconciliation & Screen UI Upgrades
- **Shift Automatic Money Earned & Multi-Account Reconciliation:**
  - The active shift automatically tracks all sales money earned, broken down into Cash, Bank, and Telebirr/Debit.
  - When closing the shift, the seller reconciles drawer cash against `expectedCashCents`, and can optionally insert actual amounts for Bank and Debit/Telebirr accounts (logging separate reconciliation records). All inputs are optional.
  - If any items were purchased or sold on credit that day during the shift, the Close Shift sheet and Active Shift card automatically display a dedicated credit section with item details and unpaid totals.
- **Purchases Screen Layout & Modern Dropdown Filters:**
  - Fixed horizontal overflow in `_PurchaseItemCard` when quantities and money values are large by wrapping financial details in `Expanded` and text in `Flexible`/`FittedBox`, guaranteeing the "Sell" button is never pushed away or obscured.
  - Replaced horizontal category chips with modern dropdown filter menus: Categories dropdown, Stock Status dropdown (All stock, In stock, Low stock ≤ 3, Sold out), and Suppliers dropdown, with a quick Clear button.
- **Sales Screen Redesign & Modern Dropdown Filters:**
  - Completely redesigned `SalesScreen` with an improved layout, summary banner (Revenue, Profit, Items sold, Credit owed), and clean item cards displaying payment badges (Cash, Bank, Telebirr, Credit).
  - Added modern scrollable dropdown filters for Cloth Type (Categories), Days (All time, Today, Yesterday, This week, This month), and Payment Method (All, Cash, Bank, Telebirr, Credit only).
- **Batch Purchase Streamlining & Overflow Fixes:**
  - Removed "Total bundle" mode and logic entirely, standardizing on the per-item purchase pricing plan.
  - Removed all UI components and labels referencing "Per item" vs "Total bundle" in the bundle details section.
  - Fixed form overflows in `_BatchItemCard` and `AddPurchaseScreen` by converting target and profit preview rows into responsive layouts with `FittedBox(fit: BoxFit.scaleDown)`.
- **Photo Section Compact UI:**
  - Shortened button text from "Take photo" to a clean, compact "Photo" button with camera icon alongside "Gallery".

