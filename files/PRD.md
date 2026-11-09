# Product Requirements: Fira Bonda

## 1. Problem

A small clothing shop owner has no simple way to remember what he paid for each type of clothing, how much he sold, and how much profit he actually makes. He needs a fast, simple tool, not a complex accounting system.

## 2. Users

- **Primary user:** the shop owner (non-technical, uses a phone, often in a hurry in the shop).
- Single user, single device, no accounts, no login.

## 3. Product goal

Show the owner, at any time: **money spent, money earned, profit**, and let him remember **which clothes were bought at which price**.

## 4. Core features (must-have)

| ID | Feature | Notes |
|----|---------|-------|
| C1 | Add / edit / delete purchase & batch lot | Center plus button opens Batch Purchase directly. Select supplier from registered list (or create new). Items include per-piece purchase price, optional planned selling price with live profit scaling, preset Mixed color, optional notes, and compact multi-photo picker (1 photo for quantity = 1, up to quantity photos for quantity > 1). |
| C2 | Preset + custom categories | T-shirts, Shirts, Hoodies, Jackets, Trousers, Jeans, Shorts, Sweaters + smart default remembering last category. |
| C3 | Preset + custom colors | Black, White, Gray, Blue, Navy, Red, Green, Brown, Beige, Yellow, and preset Mixed color (`#8E8E93`). |
| C4 | Price memory | Show last price paid when category/color is chosen. |
| C5 | Quick calculator | Available on every money field and via app-shell floating action button. Includes 20-entry calculation history, clipboard copy, and "Use result" button. |
| C6 | Sales & Simple Sell | Streamlined sell sheet with category/color/stock header, quantity stepper with quick chips (1, 2, 3, 5, All), planned price prefill, live profit card (+ETB, Loss, % of target), "Not paid" credit sales flow requiring Customer Name and Amount paid now with automatic receivable debt logging, and stock restoration on deletion. Redesigned Sales screen with modern scrollable layout and dropdown filters (Cloth type, Days, Payment). |
| C7 | Dashboard | Calendar-based periods (Today, Yesterday, Week, Month, All, Custom) with automatic midnight rollover. Active Shift banner on Today view with auto-tracked earned money and credit items. Net profit hero tile, 2x2 grid, "Paid with credit" tracking card, % of target gauge, recent sales list with credit badges, and expandable analytics accordion. |
| C8 | Search and filters | Modern dropdown filter menus: categories, stock status (In stock, Low stock, Sold out), suppliers, date range, and payment method. |

## 5. Secondary features (nice-to-have, kept out of the main flow, under "More")

- Shift system: automatically holds money earned during shift, displays credit items/transactions today, and reconciles with optional cash drawer, bank, and debit/telebirr account inputs.
- Stock adjustments for damaged, lost, returned, personal use, or count corrections with live cost and inventory deduction
- Cash & stock reconciliation comparing counted vs expected values with discrepancy logging
- Optional size field (hidden by default, enabled in settings)
- Suppliers list with totals and easy dropdown integration in purchases
- Expenses (rent, transport, etc.), subtracted from profit
- Debt and credit tracker (customers who owe him, suppliers he owes) with auto-generated debts from unpaid and credit sales
- Low stock alerts (minimum quantity per category)
- Photos per item with compact Photo & Gallery picker (up to purchase quantity) and swipeable gallery viewer
- Export monthly report as PDF and CSV
- Local backup and restore with pre-migration automatic backups
- Theme setting (Dark, Light, System)
- Undo snackbars on all soft deletions (4-second undo window)

## 6. Out of scope (do NOT build)

- User accounts, login, multi-user, roles
- Online sync or cloud database (planned for later, not now)
- Barcode scanning, payments, receipts printing
- Default categories for caps, belts, accessories, shoes, socks, underwear, tracksuits (the owner can add them himself)
- Analytics or ad SDKs of any kind

## 7. Language and currency

- UI language: English (structure the code so translations can be added later, e.g. Amharic, Afaan Oromo).
- Currency: ETB, shown as `ETB 1,250.00`.

## 8. Success criteria

- Adding a purchase takes under 30 seconds and a few taps.
- Marking a sale takes under 10 seconds.
- Profit numbers are always correct (covered by unit tests).
- App works fully offline, with no crashes and no layout overflow on any phone size.
