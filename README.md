# Fira Bonda (ፊራ ቦንዳ)

An offline-first Android inventory, sales, and profit tracker designed for clothing retail shops. Built with Flutter, Drift (SQLite), and Riverpod.

---

## 1. Overview & Vision

Fira Bonda is tailored for retail clothing shops (such as Merkato stalls and neighborhood boutiques) who need fast, zero-latency daily logging without requiring internet connectivity:
- **Instant purchase & bundle lot logging**: Add stock in seconds with category/color presets (including Mixed), smart defaults, price memory, existing supplier dropdown, multi-image support (up to purchase quantity) with interactive swipe viewer, and streamlined batch purchase entry with responsive layouts.
- **Fast sales & credit sales flow**: Simple sell sheet with planned price prefill, live profit scaling card (+ETB / Loss / % of target), and an intuitive "Not paid" credit sales toggle requiring customer name and auto-logging unpaid balances directly into debts.
- **Calendar-accurate Dashboard & Real Net Profit**: Calendar periods (Today, Yesterday, Week, Month, Custom) with midnight rollover; Net profit hero tile (`Profit - Expenses - Losses`), 2x2 metrics grid, "Paid with credit" stat card, target profit gauge, recent sales with credit status badges, and collapsible inventory analytics.
- **Shift System & Multi-Account Reconciliation**: Active Shift banner on Today view, automatically tracking earned money across Cash, Bank, and Telebirr/Debit, displaying credit purchases/sales today, and allowing optional multi-account drawer reconciliation.
- **Modern Dropdown Filters**: Overflow-proof modern dropdown menus across Purchases and Sales for Cloth Type (categories), Stock Status, Suppliers, Days, and Payment Method.
- **Stock adjustments & losses**: Record damaged, lost, or returned items with automatic inventory deduction and loss accounting.
- **App-shell quick calculator**: 20-entry calculation history, clipboard copy, and "Use result" action accessible anywhere.
- **Branded App Icon**: Custom adaptive and legacy Android launcher icons with anti-aliased transparency and deep navy theme background.
- **Debts & Credit**: Track customer credit ("Owed to me") and supplier credit ("I owe") with due dates, payment status, and automatic sync from credit sales.
- **Offline Data Ownership**: Full database backup and restore with automatic pre-migration backup safeguards, plus monthly business report exports to PDF and CSV through the native share sheet.

---

## 2. Architecture & Design Principles

The application strictly adheres to a layered, feature-first architecture (`files/ARCHITECTURE.md`):

```
lib/
  main.dart
  app.dart                                # MaterialApp.router & theme configuration
  core/
    constants/                            # AppSpacing, AppRadius, AppDimensions
    router/                               # go_router configuration & route map
    theme/                                # AppColors, typography, Light & Dark themes
    utils/                                # Money (cents math), ShopLogic (pure functions)
    widgets/                              # AppCard, AppButton, AppTextField, MoneyField, StatTile...
  data/
    database/                             # Drift SQLite tables, queries, DAOs, migrations, seed
    models/                               # Plain Dart domain data models
    repositories/                         # Repository interfaces & local Drift implementations
  features/
    calculator/                           # Safe expression evaluator & mini calculator sheet
    categories/                           # Category and color management
    dashboard/                            # Period filters, KPI aggregates, fl_chart profit trend
    debts/                                # Customer & supplier credit tracker
    expenses/                             # Shop operating expense logger
    export_backup/                        # PDF & CSV generator, SQLite backup & restore
    more/                                 # Secondary feature navigation hub
    purchases/                            # Add/edit/delete purchases, photo picker, search/filter
    sales/                                # Sales log, profit badge, stock restoration
    settings/                             # Theme switch, size toggle, low stock threshold
```

### Key Technical Standards
1. **Integer-cent Money**: All monetary amounts are stored and calculated as integer cents (e.g., `100.00 ETB` = `10000` cents). Floating-point round-off error is mathematically eliminated.
2. **Repository Pattern**: UI widgets and controllers interact solely with repository interfaces (`PurchaseRepository`, `ExpenseRepository`, `SupplierRepository`, etc.), allowing future cloud data sources (e.g., Supabase) to be plugged in seamlessly.
3. **Pure Business Logic**: Critical rules (`stockLeft`, `saleProfit`, `realProfit`, `periodWindowUtc`, and `stockValue`) are isolated in `core/utils/business_logic.dart`, free of Flutter or database imports.

---

## 3. Getting Started & Development

### Prerequisites
- **Flutter SDK**: `>= 3.24.0` (Dart `>= 3.5.0`)
- **Android SDK**: API 34+ (compileSdkVersion 34)
- **Physical Device / Emulator**: Android 8.0+ (API 26+)

### Installation & Run
```bash
# 1. Clone repository
git clone https://github.com/kalchan12/firabonda.git
cd firabonda

# 2. Install dependencies
flutter pub get

# 3. Generate Drift code (if database schema is modified)
dart run build_runner build --delete-conflicting-outputs

# 4. Run static analysis (strict lints, 0 warnings)
flutter analyze

# 5. Run automated test suite
flutter test

# 6. Launch on connected Android device
flutter run
```

---

## 4. Testing Suite

The project includes unit, database, and widget tests:
```bash
# Run all tests
flutter test

# Run pure business logic and money tests
flutter test test/unit/

# Run database schema, migrations, and CRUD tests
flutter test test/database/

# Run widget and UI integration tests
flutter test test/widget/
```

---

## 5. Security & Privacy

- **100% Offline**: The Android release manifest does not declare `android.permission.INTERNET`.
- **Zero Tracking**: No analytics SDKs, advertising libraries, or third-party trackers.
- **Private Sandboxed Storage**: SQLite database and item photos reside strictly within the application's private sandboxed directory (`getApplicationDocumentsDirectory()`).
- **Encrypted & Safe Backups**: Backups warn the user before sharing and validate database headers (`SQLite format 3`) prior to restoration.

---

## 6. Future Cloud Sync: Supabase Roadmap

When the owner decides to enable optional cloud backup and multi-device sync, the architecture is ready:
1. **Add Dependencies**: Add `supabase_flutter` to `pubspec.yaml`.
2. **Implement Repositories**: Create `SupabasePurchaseRepository`, `SupabaseExpenseRepository`, etc., matching the existing interfaces in `lib/data/repositories/`.
3. **Synchronization Engine**:
   - Each table already contains `id` (UUID), `createdAt`, `updatedAt`, and `deletedAt` (soft deletes) specifically designed for conflict resolution.
   - Use a local sync queue table to buffer offline operations and sync with Supabase when online.
4. **Row Level Security (RLS)**: Protect Postgres tables with RLS policies (`auth.uid() = user_id`) using Supabase anonymous or email authentication.
5. **Zero UI Changes**: Repositories are injected via Riverpod providers (`providers.dart`), allowing switching or syncing between `Local...Repository` and `Supabase...Repository` without modifying a single UI screen.
