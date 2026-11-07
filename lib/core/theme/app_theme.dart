import 'package:flutter/material.dart';

import '../constants/app_dimensions.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Builds the light and dark themes from the design tokens.
final class AppTheme {
  const AppTheme._();

  static ThemeData build(Brightness brightness) {
    final c = brightness == Brightness.dark
        ? AppColorsExtension.dark
        : AppColorsExtension.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppTypography.fontFallback,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.primary,
        onPrimary: c.onPrimary,
        secondary: c.primary,
        onSecondary: c.onPrimary,
        error: c.loss,
        onError: Colors.white,
        surface: c.surface,
        onSurface: c.textPrimary,
        surfaceContainerHighest: c.surfaceVariant,
        onSurfaceVariant: c.textMuted,
        outline: c.border,
        outlineVariant: c.border,
      ),
      scaffoldBackgroundColor: c.background,
      extensions: <ThemeExtension<dynamic>>[c],
      textTheme: AppTypography.textTheme(brightness),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFallback,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: c.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: c.border),
        ),
        margin: EdgeInsets.zero,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? c.primary
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? c.onPrimary
                : c.textMuted,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: c.border)),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.button)),
            ),
          ),
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: c.textMuted,
        collapsedIconColor: c.textMuted,
        shape: const Border(),
        collapsedShape: const Border(),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surfaceVariant,
        contentTextStyle: TextStyle(color: c.textPrimary, fontSize: 15),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1),
      iconTheme: IconThemeData(color: c.textMuted),
    );
  }
}
