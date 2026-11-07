# Testing Plan: Fira Bonda

## Goals

- Profit, stock and total calculations are **always correct**.
- The app does not crash or overflow on different phones and text sizes.

## 1. Unit tests (required)

Business logic in pure Dart:
- `Money` parsing and formatting (0, large numbers, decimals, rounding)
- Total cost = quantity x unit cost
- Stock left after one or several sales
- Profit per sale, including loss (sold below cost)
- Real profit with expenses over Today / Week / Month / All boundaries
- Rejecting a sale larger than stock
- Calculator expression parser: precedence, percent, division by zero, empty input, repeated operators
- "Last price paid" lookup logic

## 2. Database tests

- Use an in-memory Drift database.
- Seed creates exactly the preset categories and colors, once.
- Foreign keys and the rule "cannot delete a used category, archive instead".
- Recording a sale is transactional.
- Migration tests for every schema version.

## 3. Widget tests

- Add purchase form: validation errors, automatic total, last price hint.
- Calculator sheet: typing, "Use result" writes to the field.
- Sell sheet: quantity limit, live profit preview.
- Dashboard shows correct numbers for a known data set.
- Empty states render.

## 4. Manual checks on the physical phone (each phase)

- [ ] Dark and light mode look correct and readable
- [ ] Text scale 1.0, 1.3 and 1.6 with no overflow
- [ ] Portrait and landscape
- [ ] Airplane mode: everything still works
- [ ] Adding 200+ purchases stays smooth (scroll, search, filters)
- [ ] Rotate, background and resume the app mid-form without losing input
- [ ] Back button behaves sensibly on every screen
- [ ] Photo add and delete
- [ ] Backup, then restore on a clean install

## 5. Commands

```
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

All three must pass before a phase is reported as done.

## 6. Test data

Provide a debug-only "Load sample data" action (hidden in release) that creates realistic sample purchases, sales and expenses so screens can be reviewed quickly.
