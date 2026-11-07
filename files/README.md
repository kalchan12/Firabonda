# Fira Bonda

A modern, offline-first Android app for a small men's clothing shop. It tracks what was bought, what it cost, what was sold and the profit made.

## Status

See `docs/PLANNING.md` for the current phase.

## Tech stack

- Flutter (Android) and Dart
- Riverpod for state, go_router for navigation
- Drift (SQLite) for local storage
- fl_chart for charts
- Supabase may be added later (not now)

## Run the app

1. Install Flutter and the Android SDK, then run `flutter doctor`.
2. Enable USB debugging on your phone and connect it.
3. `flutter pub get`
4. `flutter run`

## Project docs

| File | Purpose |
|------|---------|
| `AGENTS.md` | Entry point for AI agents |
| `AGENT_INSTRUCTIONS.md` | Phased build instructions |
| `docs/PRD.md` | Product requirements |
| `docs/DESIGN.md` | Design system |
| `docs/ARCHITECTURE.md` | Architecture |
| `docs/DATABASE.md` | Data model |
| `docs/SECURITY.md` | Security and privacy |
| `docs/CODING_STANDARDS.md` | Code conventions |
| `docs/TESTING.md` | Testing plan |
| `docs/PLANNING.md` | Roadmap and checklist |
