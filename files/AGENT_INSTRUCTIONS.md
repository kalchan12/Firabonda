# Fira Bonda: Agent Instructions

## Role

You are a senior Flutter engineer and UI designer. Build an Android app called **Fira Bonda** for a small men's clothing retail shop owner.

Work in phases. Finish one phase completely, run checks, report briefly, then **wait for my "continue"** before starting the next. Do not add features I did not ask for. If something is unclear, ask instead of guessing.

## Product Goal

The owner runs a small business. The app exists to track **money spent, money earned and profit**. Clothing categories exist mainly so he remembers which clothes he bought at which price. Everything else is secondary.

Keep the main flows very fast: adding a purchase and marking a sale should take only a few taps.

## Working Rules

- After each phase: list what you built, what you tested on my phone, and any problems. Then wait.
- Commit to git after each phase with a clear message.
- Keep code clean: small files, meaningful names, no dead code.
- Never invent packages or APIs. If unsure, check the documentation or ask me.
- Do not change the design direction, features or categories without my approval.
- Local storage only for now. Supabase may be added later.

---

## Phase 0: Environment Check (do this first, change nothing yet)

1. Run and show the output of:
   - `flutter --version`
   - `dart --version`
   - `flutter doctor -v`
   - `adb devices`
   - `flutter devices`
2. I use my **physical phone** to run the app, not an emulator. Confirm the phone is detected (USB debugging on). If it is not detected, tell me exactly what to fix.
3. Check the Android SDK and that licenses are accepted.
4. Report what is missing or outdated. Do not install or upgrade anything without telling me first.
5. Stop and wait for my "continue" if anything is broken.

## Phase 1: Project Setup and Architecture

- Create the project with `flutter create`, Android only, package name `com.firabonda.app`, app name **Fira Bonda**.
- Folder structure by feature:
  - `lib/core` (theme, utils, shared widgets)
  - `lib/data` (database, repositories)
  - `lib/features/<name>`
- Packages: `flutter_riverpod`, `go_router`, `drift` + `sqlite3_flutter_libs` (local SQLite), `fl_chart`, `intl`, `image_picker`, `shared_preferences`, `path_provider`, `pdf`, `printing`, `csv`, `share_plus`.
- Fonts must be bundled as assets (the app is offline first). Use a rounded modern font such as Plus Jakarta Sans or Sora.
- Put all data access behind repository interfaces so Supabase sync can be added later without rewriting the UI.
- Store all money as **integers in the smallest unit (cents)** to avoid floating point errors. Currency: ETB, formatted properly (for example `ETB 1,250.00`).
- Run `flutter analyze`. Zero errors.

## Phase 2: Design System

This decides how the app feels. Take it seriously.

**Style:** modern, Gen Z, clean, bold, playful but not childish.

**Colors**
- Dark theme: very deep navy background (around `#0B1020`), slightly lighter navy surfaces, bright electric blue accent (around `#3D6BFF`), green for profit, soft red for loss and spending.
- Light theme: white and soft gray-blue backgrounds, the same blue accent, dark navy text.
- Theme modes: **Dark, Light, System**. Toggle in settings, remembered between launches. Dark is the default.

**Look and feel**
- Big rounded corners (20 to 28 px), soft shadows or subtle borders, generous spacing.
- Large bold numbers for money, small muted labels.
- Cards with gentle gradients. Use a glass effect only where text stays readable.
- Smooth micro animations: page transitions, animated number counters on the dashboard, button press feedback. Light haptic feedback on key actions.
- Floating bottom navigation bar with a prominent center action button for **Add purchase**.
- Friendly empty states with icons and short helpful text, never blank screens.

**Flexible layout**
- Must adapt to different phone sizes, text scale settings and landscape, with no overflow errors.
- Use `LayoutBuilder` and responsive patterns. Never use fixed pixel layouts.

**Reusable widgets first**
- Build a small widget library before screens: buttons, cards, chips, text fields, money field, stat tile, bottom sheet. Reuse them everywhere.

**Accessibility**
- Good contrast in both themes. Tap targets at least 48 px.

**Checkpoint:** before building the rest of the app, show me one or two sample screens (dashboard and add purchase) on my phone for approval.

## Phase 3: Database

**Tables**
- `categories` (id, name, icon, isPreset, isArchived)
- `colors` (id, name, hex, isPreset)
- `suppliers` (id, name, phone, note)
- `purchases` (id, categoryId, colorId, supplierId nullable, size nullable, quantity, unitCost, totalCost, sellingPrice nullable, photoPath nullable, note, date)
- `sales` (id, purchaseId, quantity, unitPrice, date)
- `expenses` (id, title, amount, date, note)
- `debts` (id, personName, amount, direction [owed to me / I owe], dueDate nullable, isPaid, note)

**Rules**
- Stock left = purchased quantity minus sold quantity.
- Profit per sale = (unitPrice minus unitCost) times quantity.

**Seed presets on first launch**
- Categories: T-shirts, Shirts, Hoodies, Jackets, Trousers, Jeans, Shorts, Sweaters.
- Colors: Black, White, Gray, Blue, Navy, Red, Green, Brown, Beige, Yellow.

The owner can add, rename, archive or delete any preset. Do **not** include caps, belts, accessories, shoes, socks, underwear or tracksuits (he can add them himself).

Write unit tests for the profit and stock calculations.

## Phase 4: Core Features

1. **Add / edit purchase**
   - Category chips, color chips (with custom color picker), quantity, unit cost, automatic total, optional selling price, optional supplier, date, optional note and photo.
   - **Size is optional** and hidden by default. It appears only if enabled in settings.
2. **Price memory**
   - When a category (and color) is selected, show a small hint with the last price paid, for example "Last time: ETB 800 each".
3. **Mini calculator**
   - Every money field has a calculator icon that opens a bottom-sheet calculator: digits, `+ - × ÷`, `%`, clear, backspace.
   - "Use result" puts the value into the field.
   - Support a quick "quantity × price" so he can multiply without leaving the form.
4. **Purchases list**
   - Grouped by date, searchable, filterable by category, color, supplier and date range.
5. **Sell action**
   - Swipe or tap "Sold" on a purchase. Enter quantity and selling price (prefilled with the planned selling price). Stock updates immediately.
   - Prevent selling more than the stock left.

## Phase 5: Dashboard

- Total spent, total earned and profit for **Today / Week / Month / All** (segmented control, animated numbers).
- Profit chart over time (`fl_chart`).
- Best-selling categories, stock value, money still tied up in unsold stock.
- Low stock alerts based on a minimum quantity per category.
- Expenses are subtracted so the dashboard shows **real profit**.

## Phase 6: Secondary Features

Keep these out of the main flow. Put them in a **More** screen.

- Suppliers list with total spent per supplier.
- Expenses (rent, transport, etc.).
- Debts and credit tracker with paid / unpaid status.
- Photos for items.
- Category and color management.
- Settings: theme, currency, enable size, low stock defaults.
- Export: monthly report as PDF and CSV/Excel through the share sheet.
- Local backup and restore of the database file.

## Phase 7: Polish and Quality

- Review every screen on my physical phone in both themes. Fix spacing, overflow and contrast issues.
- Confirm the app works fully offline.
- Add confirmation dialogs for deletes and an undo snackbar where possible.
- Final `flutter analyze` and `flutter test` must pass.
- Write a `README.md` with setup steps, project structure and how to add Supabase later.

---

## Required Reading

Before Phase 0, read `AGENTS.md` and every file in `docs/`: `PRD.md`, `DESIGN.md`, `ARCHITECTURE.md`, `DATABASE.md`, `SECURITY.md`, `CODING_STANDARDS.md`, `TESTING.md`, `PLANNING.md`. These documents are binding. If anything conflicts with this file, this file wins. If anything is unclear, ask.

Update `docs/PLANNING.md` at the end of every phase.
