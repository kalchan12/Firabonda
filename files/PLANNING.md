# Planning: Fira Bonda

Update the checkboxes and "Status" at the end of every phase. Work on **one phase at a time** and wait for the owner's approval.

**Current status:** Phase 6 complete — Secondary features (Suppliers, Expenses, Debts & credit, Photos, Categories & Colors, Settings, PDF/CSV Export, and SQLite Backup & Restore) built and fully verified (65 tests passing). Waiting for owner approval before Phase 7 (Polish and release prep).

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
- [ ] Full review on phone, both themes, text scales, orientations
- [ ] Offline verification
- [ ] Delete confirmations and undo
- [ ] Security checklist in `SECURITY.md` completed
- [ ] `flutter analyze` and `flutter test` pass
- [ ] README final
- [ ] Release APK built and installed on the phone

## Later (not in this build)
- Supabase cloud sync and backup
- Translations (Amharic, Afaan Oromo)
- Receipts and printing
