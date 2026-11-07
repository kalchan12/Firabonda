import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/theme/theme_controller.dart';
import 'data/database/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeMode = await loadSavedThemeMode();
  final database = AppDatabase.open();
  await database.ensureSeeded();

  runApp(
    ProviderScope(
      overrides: [
        initialThemeModeProvider.overrideWithValue(themeMode),
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: const App(),
    ),
  );
}

