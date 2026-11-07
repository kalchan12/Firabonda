# Coding Standards: Fira Bonda

## General

- Follow the official Dart style guide and `flutter_lints` (strict). `flutter analyze` must report zero issues.
- Format with `dart format .` before every commit.
- Small files: a widget file should stay under about 250 lines. Split when larger.
- Meaningful names. No abbreviations except common ones (id, url).
- No dead code, no commented-out code, no leftover `print`. Use a logger.
- Prefer `const` constructors and immutable models.
- No `dynamic` unless unavoidable. Use null safety properly (no `!` without a reason).

## Naming and files

- Files: `snake_case.dart`. Classes: `PascalCase`. Members: `camelCase`.
- Screens end with `Screen`, providers with `Provider`, repositories with `Repository`.
- One public widget per file where possible.

## State management (Riverpod)

- Providers live in each feature's `application/` folder.
- UI reads state with `ref.watch` and triggers actions with `ref.read(...notifier)`.
- Keep side effects out of `build`.
- Repository providers are defined once and overridden in tests.

## UI rules

- Use theme tokens from `core/theme`. No hardcoded colors, font sizes or spacing numbers inside widgets. Use the spacing constants.
- Reuse the shared widget library. If a pattern appears twice, make it a shared widget.
- Every screen handles: loading, empty, error, data.
- Never leave a layout that can overflow. Test with large text and small screens.

## Money and dates

- Use the `Money` helper for all money. Integers in cents.
- Dates are stored in UTC and displayed in local time with `intl`.

## Errors

- Never swallow exceptions silently. Handle, log (debug only) and show a friendly message.
- Use transactions for multi-step database changes.

## Git

- Branch per phase: `phase-1-setup`, `phase-2-design`, etc. Merge to `main` after the owner approves.
- Commit messages: imperative, short, with a prefix: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`.
- One logical change per commit. Do not commit generated build output.

## Documentation

- Public classes and non-obvious logic get short doc comments (`///`).
- Update `docs/PLANNING.md` at the end of every phase.
- If a decision differs from the docs, write it in `docs/DECISIONS.md` (create it) and tell the owner.
