import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefKey = 'app.theme.mode';

/// Provides the user-selected theme mode and persists it.
/// Default: dark (see `files/DESIGN.md` section 2).
///
/// `initialThemeModeProvider` is overridden at startup by [main]
/// with the value loaded from shared_preferences.
final class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.watch(initialThemeModeProvider);

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, mode.name);
  }
}

final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.dark);

final themeControllerProvider = NotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);

/// Loads the persisted theme mode before the app starts.
Future<ThemeMode> loadSavedThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString(_prefKey);
  if (saved == null) return ThemeMode.dark;
  for (final mode in ThemeMode.values) {
    if (mode.name == saved) return mode;
  }
  return ThemeMode.dark;
}
