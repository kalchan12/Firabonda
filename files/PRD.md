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
| C1 | Add / edit / delete purchase & batch lot | Category, color, quantity (+1/+5/+10 quick chips), unit cost, auto total, date, optional selling price with 100% target profit helper, supplier, note, photo. Batch purchase bundle entry with Hamilton largest-remainder exact cost allocation. |
| C2 | Preset + custom categories | T-shirts, Shirts, Hoodies, Jackets, Trousers, Jeans, Shorts, Sweaters + smart default remembering last category. |
| C3 | Preset + custom colors | Black, White, Gray, Blue, Navy, Red, Green, Brown, Beige, Yellow + custom color picker. |
| C4 | Price memory | Show last price paid when category/color is chosen. |
| C5 | Quick calculator | Available on every money field and via app-shell floating action button. Includes 20-entry calculation history, clipboard copy, and "Use result" button. |
| C6 | Sales & Quick Sell | Streamlined 2-3 tap quick sale interface, 100% target profit prefill, partial payment support with automatic receivable debt creation, and stock restoration on deletion. |
| C7 | Dashboard | Calendar-based periods (Today, Yesterday, Week, Month, All, Custom) with automatic midnight rollover. Net profit hero tile with status badge, 2x2 grid, target profit gauge (100% default), recent sales list, and expandable analytics accordion (stock value, low stock alerts, best sellers, profit curve chart). |
| C8 | Search and filters | By category, color, supplier, date range. |

## 5. Secondary features (nice-to-have, kept out of the main flow, under "More")

- Stock adjustments for damaged, lost, returned, personal use, or count corrections with live cost and inventory deduction
- Cash & stock reconciliation comparing counted vs expected values with discrepancy logging
- Day close summary report with net profit, revenue, cash collected, and one-tap clipboard report export
- Optional size field (hidden by default, enabled in settings)
- Suppliers list with totals
- Expenses (rent, transport, etc.), subtracted from profit
- Debt and credit tracker (customers who owe him, suppliers he owes) with auto-generated debts from partial payment sales
- Low stock alerts (minimum quantity per category)
- Photos per item
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
