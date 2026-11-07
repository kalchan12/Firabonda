# Planning: Fira Bonda

Update the checkboxes and "Status" at the end of every phase. Work on **one phase at a time** and wait for the owner's approval.

**Current status:** Phase 2 complete — checkpoint built, awaiting approval on phone

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
- [ ] **Checkpoint:** sample Dashboard and Add Purchase screens shown on the phone and approved

## Phase 3: Database
- [ ] Drift tables per `DATABASE.md`
- [ ] Seed data
- [ ] Repository interfaces and local implementations
- [ ] Business logic functions
- [ ] Unit and database tests passing

## Phase 4: Core features
- [ ] Add / edit / delete purchase
- [ ] Category and color pickers, custom color
- [ ] Price memory hint
- [ ] Mini calculator sheet integrated in money fields
- [ ] Purchases list with search and filters
- [ ] Sell action and sales list
- [ ] Widget tests

## Phase 5: Dashboard
- [ ] Period selector and stat tiles with animated numbers
- [ ] Profit chart
- [ ] Best sellers, stock value
- [ ] Low stock alerts
- [ ] Real profit includes expenses

## Phase 6: Secondary features
- [ ] Suppliers
- [ ] Expenses
- [ ] Debts and credit tracker
- [ ] Photos
- [ ] Category and color management
- [ ] Settings (theme, size field toggle, low stock default)
- [ ] PDF and CSV export
- [ ] Backup and restore
- [ ] (Optional) app lock

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
