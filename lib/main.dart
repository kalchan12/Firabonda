import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeMode = await loadSavedThemeMode();
  runApp(
    ProviderScope(
      overrides: [initialThemeModeProvider.overrideWithValue(themeMode)],
      child: const App(),
    ),
  );
}
