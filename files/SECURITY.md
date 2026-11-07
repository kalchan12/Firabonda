# Security and Privacy: Fira Bonda

The app stores real business numbers of a small shop. It is local only, but it must still protect the owner's data and be safe to ship.

## 1. Data and privacy

- All data stays **on the device**. No network calls in this version.
- **No analytics, no crash reporting SDKs, no ads, no tracking** of any kind.
- Do not request permissions that are not needed. Allowed: camera and/or photo access (only when the owner adds a photo). No location, contacts, microphone or storage-wide access.
- The manifest must NOT request `INTERNET` in release builds while the app is local-only. (If a package needs it, tell the owner.)

## 2. Optional app lock (Phase 6, optional feature)

- Optional PIN and/or biometric lock using `local_auth` (ask before adding the package).
- PIN is never stored in plain text: store a salted hash, or use Android Keystore through `flutter_secure_storage`.
- Auto-lock when the app goes to the background for more than 30 seconds (configurable).
- Hide content in the Android recent-apps preview when the lock is on.

## 3. Data at rest

- Default: the database sits in the app's private storage (protected by Android sandboxing).
- Do not store the database or photos on shared or public storage.
- Optional future hardening: SQLCipher encryption. Document it, do not build it unless asked.

## 4. Backups and exports

- Backup files contain all business data. Show a clear warning before sharing: "This file contains your shop data. Share it only with people you trust."
- Exports (PDF/CSV) are created in a temp directory and removed after sharing.
- Android auto backup: set `android:allowBackup="false"` unless the owner decides otherwise.

## 5. Input validation

- Validate all numbers: quantity is an integer greater than 0, prices are not negative, caps on maximum values to avoid overflow.
- Trim text fields, limit lengths (names 60 characters, notes 500).
- Use Drift's typed queries only. **Never build SQL by concatenating user input.**
- Calculator input is parsed by a small safe expression parser. Never use `eval`-style execution.

## 6. Files and photos

- Copy picked photos into the app's private folder, with random file names. Do not keep the original path.
- Compress images (max 1280 px longest side) to save space.
- When an item is deleted, delete its photo file too.

## 7. Secrets and repository hygiene

- No secrets, API keys or keystores in the repo. Ever.
- `.gitignore` must include: `*.jks`, `*.keystore`, `key.properties`, `.env`, `local.properties`, `build/`, `.dart_tool/`, `*.iml`.
- Release signing configuration reads from `key.properties`, which is not committed.
- Do not log sensitive data (amounts, names) in release builds. Use a logger that is silent in release.

## 8. Dependencies

- Only use well-known, maintained packages from the approved list in `ARCHITECTURE.md`.
- Pin versions in `pubspec.yaml` and commit `pubspec.lock`.
- Run `flutter pub outdated` before release and review changes.
- Before adding a new package: check maintenance, popularity, license, and permissions it requires. Ask the owner first.

## 9. Release build hardening

- Enable code shrinking and obfuscation: `flutter build apk --release --obfuscate --split-debug-info=build/symbols`.
- Disable debug banner and debug logs in release.
- Verify the final APK manifest: no unexpected permissions.

## 10. Future Supabase (reference only, not now)

When cloud sync is added later:
- Use Row Level Security on every table, with rows owned by the authenticated user.
- Ship only the public anon key in the app. **Never** ship the service role key.
- Use HTTPS only, authenticated users only, and validate data on the server too.
- Add an explicit privacy notice and a way to delete cloud data.

## 11. Security checklist (verify at Phase 7)

- [x] No network permission in the manifest
- [x] No secrets or keystores in git history
- [x] All SQL goes through Drift
- [x] Inputs validated and length limited
- [x] Photos stored privately and cleaned up on delete
- [x] Backup warning shown
- [x] `allowBackup` is false
- [x] Release build is obfuscated
- [x] Logs contain no business data
