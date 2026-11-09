# Planning: Fira Bonda

Update the checkboxes and "Status" at the end of every phase. Work on **one phase at a time** and wait for the owner's approval.

**Current status:** All phases complete! App built, tested, and ready for release.

## Phase 0: Environment check
- [x] flutter, dart, flutter doctor, adb outputs shown
- [x] Physical phone detected with USB debugging
- [x] Android SDK and licenses OK
- [x] Missing items reported (nothing installed silently)

## Phase 1: Project setup and architecture
- [x] Flutter project created (`com.firabonda.app`, name "Fira Bonda")
- [x] Folder structure from `ARCHITECTURE.md`
- [x] Packages added and locked
- [x] Fonts bundled
- [x] Money helper and formatter
- [x] Lints strict, `flutter analyze` clean
- [x] `.gitignore` per `SECURITY.md`

## Phase 2: Design system
- [x] Color tokens, typography, light and dark themes
- [x] Theme mode switch with persistence
- [x] Reusable widgets: buttons, cards, chips, text field, money field, stat tile, bottom sheet, empty state, skeleton
- [x] Floating bottom navigation with center button
- [x] **Checkpoint:** sample Dashboard and Add Purchase screens shown on the phone and approved

## Phase 3: Database
- [x] Drift tables per `DATABASE.md`
- [x] Seed data
- [x] Repository interfaces and local implementations
- [x] Business logic functions
- [x] Unit and database tests passing

## Phase 4: Core features
- [x] Add / edit / delete purchase
- [x] Category and color pickers, custom color
- [x] Price memory hint
- [x] Mini calculator sheet integrated in money fields
- [x] Purchases list with search and filters
- [x] Sell action and sales list
- [x] Widget tests

## Phase 5: Dashboard
- [x] Period selector and stat tiles with animated numbers
- [x] Profit chart
- [x] Best sellers, stock value
- [x] Low stock alerts
- [x] Real profit includes expenses

## Phase 6: Secondary features
- [x] Suppliers
- [x] Expenses
- [x] Debts and credit tracker
- [x] Photos
- [x] Category and color management
- [x] Settings (theme, size field toggle, low stock default)
- [x] PDF and CSV export
- [x] Backup and restore
- [x] (Optional) app lock (Settings & database prepared)

## Phase 7: Polish and release prep
- [x] Full review on phone, both themes, text scales, orientations
- [x] Offline verification
- [x] Delete confirmations and undo
- [x] Security checklist in `SECURITY.md` completed
- [x] `flutter analyze` and `flutter test` pass
- [x] README final
- [x] Release APK built and installed on the phone

## Phase 8: Improvement Plan V2
- [x] **Step 0: Audit & Reproduce:** Full audit of overflows, text scaling (1.0, 1.3, 1.6), fonts, and period logic.
- [x] **Step 1: Quick Fixes:** Bundled Sora & Inter with tabular figures, resolved all RenderFlex overflows across viewports, set Today as dashboard default.
- [x] **Step 2: Business Logic:** Pure local-calendar periods (`PeriodRange`, `AppClock`), midnight rollover timer, frozen sale profit (`costAtSale`), and stable totals.
- [x] **Step 3: Data Model & Safe Migration:** Pre-migration automatic backup, Drift schema v2 with `accounts`, `batches`, `stock_adjustments`, `reconciliations`, `edit_history`.
- [x] **Step 4: Navigation Bar:** 70dp raised circular center button (+ icon only, blue glow, cutout notch) with speed-dial sheet for Purchase, Batch purchase, and Quick sale.
- [x] **Step 5: Dashboard Redesign:** Net profit hero tile, 2x2 grid, target profit gauge, recent sales, and collapsible More analytics & stock accordion.
- [x] **Step 6: Pricing & Quick Sell:** 100% target profit default pricing helper (2x cost), 2-3 tap quick sale interface, partial payment with auto debt creation.
- [x] **Step 7: Batch Purchase:** Lot entry with Hamilton largest-remainder exact cent cost allocation across bundle items.
- [x] **Step 8: Inventory Adjustments, Reconciliation & Day Close:** Damaged/lost adjustments deducting from stock and logging to losses, cash & stock reconciliation, and day close summary report with clipboard export.
- [x] **Step 9: Quick Calculator:** App-shell level draggable/floating quick calculator with 20-entry history, copy to clipboard, and use-result actions.
- [x] **Step 10: Speed & Usability Pass:** Quick quantity stepper chips (+1, +5, +10), smart category/supplier defaults, and undo snackbars on all soft deletions.
- [x] **Step 11: Final Polish & Documentation:** Full documentation synchronization, zero analyzer warnings, 100% test pass rate.

## Fix round V2.1
- [x] **Task 1: Sell screen cannot scroll (button hidden)**: Scrollable content, keyboard handling, fixed footer with action button.
- [x] **Task 2: Corner radius inconsistency**: Radius tokens, shared AppCard with anti-alias clipping across all containers.
- [x] **Task 3: Center plus button opens only Batch purchase**: Remove speed-dial; plus button navigates straight to Batch purchase.
- [x] **Task 4: Batch purchase fields**: Purchase price per piece, Two colors / Mixed colors, optional note, photo.
- [x] **Task 5: Profit logic**: Assumed profit, over profit, loss, not assumed; replace markup % with % of target.
- [x] **Task 6: Simple sell screen**: Clean 3-input sell sheet, live result card (+ETB / Loss / Target), fixed footer.
- [x] **Task 7: Update dashboard and lists for new profit language**: Unified profit status colors and labels.
- [x] **Task 8: Shift system**: Shift-based Today card, Shift close with reconciliation, midnight auto-close, history.
- [x] **Task 9: Final QA, docs and push**: Verification on device, docs sync, branch readiness check.

## Post-V2.1 Improvements & Polishing
- [x] **Multi-item Purchase Profit Scaling**: Scale target sell and expected profit by quantity (`quantity > 1`) in single and batch purchase screens, and in purchase list cards.
- [x] **Multi-image Purchase Support**: Scalable photo picker (1 for quantity = 1, up to quantity for quantity > 1), pipe-delimited storage, swipeable gallery viewer dialog, photo count badge, and clean file cleanup on deletion.
- [x] **Credit Sales ("Not Paid") Flow**: Replace partial payment toggle with intuitive "Not paid" toggle, mandatory customer name, amount paid now, and auto-generated debt records.
- [x] **Dashboard "Paid with Credit" Card**: Add period credit sales card, credit count, and visual credit badges (`Credit (unpaid)` and `Credit • owes ETB X`).
- [x] **Batch Purchase & Shift UI Simplifications**: Existing supplier dropdown, simplified "Per item" / "Total bundle" segmented buttons, preset Mixed color, and streamlined single-input Shift sheets.
- [x] **Floating Nav Bar Clearance**: `useRootNavigator: true` across all bottom sheets ensuring footer buttons are never hidden behind the floating nav dock.
- [x] **Documentation Synchronization**: Comprehensive sync of `DECISIONS.md`, `PRD.md`, `DESIGN.md`, `DATABASE.md`, `PLANNING.md`, and `README.md`.

## Later (not in this build)
- Supabase cloud sync and backup
- Translations (Amharic, Afaan Oromo)
- Receipts and printing
