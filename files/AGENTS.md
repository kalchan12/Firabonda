# AGENTS.md: Start Here

This repository contains **Fira Bonda**, an offline-first Android app (Flutter) that helps a small men's clothing shop owner track money spent, money earned and profit.

## Reading order (read ALL before writing any code)

1. `AGENT_INSTRUCTIONS.md` : your role, rules and the phase-by-phase build plan
2. `docs/PRD.md` : what the app must do and what it must NOT do
3. `docs/DESIGN.md` : visual design system and UX rules
4. `docs/ARCHITECTURE.md` : structure, packages, state management
5. `docs/DATABASE.md` : tables, relations, calculations
6. `docs/SECURITY.md` : privacy and security requirements
7. `docs/CODING_STANDARDS.md` : code style and conventions
8. `docs/TESTING.md` : what to test and how
9. `docs/PLANNING.md` : phase checklist (update it as you work)

## Golden rules

- Work one phase at a time. Report, then wait for the owner's "continue".
- Money is stored as integers (cents). Never use floating point for money.
- The main purpose is **spent / earned / profit**. Everything else is secondary.
- Do not add features, packages or categories that are not in the docs without asking.
- If two documents conflict, stop and ask. Priority: `AGENT_INSTRUCTIONS.md` > `PRD.md` > other docs.
- Update `docs/PLANNING.md` at the end of every phase.
