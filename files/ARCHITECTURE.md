# Architecture: Fira Bonda

## 1. Principles

- **Offline first, local only** for now.
- **Feature-first folders**, thin UI, logic in providers and services.
- **Repository pattern** so a Supabase implementation can be added later without touching UI.
- Simple beats clever. This is a small app.

## 2. Stack

| Concern | Choice |
|---------|--------|
| Framework | Flutter (stable), Dart |
| State management | flutter_riverpod |
| Navigation | go_router |
| Local database | drift + sqlite3_flutter_libs |
| Charts | fl_chart |
| Formatting | intl |
| Images | image_picker (stored in app documents directory) |
| Settings | shared_preferences |
| Export | pdf, printing, csv, share_plus |
| File paths | path_provider |

Do not add other packages without asking the owner.

## 3. Folder structure

```
lib/
  main.dart
  app.dart                    # MaterialApp.router, theme wiring
  core/
    theme/                    # colors, typography, light/dark themes
    router/                   # go_router config
    utils/                    # money formatter, date helpers, validators
    widgets/                  # reusable UI (buttons, cards, chips, money field, stat tile, sheets)
    constants/
  data/
    database/                 # drift database, tables, DAOs, seed data
    repositories/             # abstract interfaces + local implementations
    models/                   # plain domain models
  features/
    dashboard/
    purchases/
    sales/
    calculator/
    suppliers/
    expenses/
    debts/
    categories/
    settings/
    export_backup/
test/
  unit/
  widget/
docs/
```

Each feature folder contains `presentation/` (screens, widgets), `application/` (providers, controllers) and, if needed, `domain/`.

## 4. Layers and dependency direction

```
UI (screens/widgets)  ->  Providers/Controllers  ->  Repository interfaces  ->  Local (Drift) implementation
```

- UI never talks to the database directly.
- Repository interfaces live in `data/repositories`. Implementations are named `Local...Repository`.
- Future: `Supabase...Repository` plus a sync service. Not part of this build.

## 5. Money handling

- Store money as `int` in cents (1 ETB = 100 cents).
- A single `Money` helper formats and parses values. No raw `double` arithmetic on money anywhere.
- Calculator evaluates with decimal-safe logic, then converts to cents.

## 6. Business logic (pure Dart, unit tested)

- `stockLeft = purchase.quantity - sum(sales.quantity)`
- `profit(sale) = (sale.unitPrice - purchase.unitCost) * sale.quantity`
- `realProfit(period) = sum(profit of sales) - sum(expenses)`
- `stockValue = sum(stockLeft * unitCost)`
- Selling more than `stockLeft` must be rejected.

Keep these in `core/utils` or a `domain` folder, free of Flutter imports.

## 7. Error handling

- Repositories return typed results or throw domain exceptions. UI maps them to friendly messages.
- Global error boundary logs to console in debug, and shows a calm fallback in release.
- Database operations that touch multiple tables use transactions (for example recording a sale).

## 8. Settings stored in shared_preferences

- theme mode, show size field, low stock default, currency symbol, first launch flag.

## 9. Future: Supabase (do NOT build now)

- Add `Supabase...Repository` implementations and a sync queue.
- Each table already needs `id` (UUID), `createdAt`, `updatedAt` and `deletedAt` (soft delete) to make sync possible. Include these columns from day one.
- Document the plan in README when that phase begins.

## 10. Build and release

- Min SDK as required by packages, target latest stable.
- Release builds are signed with a keystore that is **never committed** (see `SECURITY.md`).
- Android app name: **Fira Bonda**. Package: `com.firabonda.app`.
