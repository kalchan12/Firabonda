import 'package:flutter/material.dart';

/// Typography scale per `files/DESIGN.md` section 4.
/// Sora is bundled as an asset (offline first).
final class AppTypography {
  const AppTypography._();

  static const fontFallback = 'Sora';

  static const TextTheme _base = TextTheme(
    displayLarge: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    ),
    bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
    labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  );

  static TextTheme textTheme(Brightness brightness) {
    final style = brightness == Brightness.dark
        ? const Color(0xFFF2F5FF)
        : const Color(0xFF0B1020);
    return _base.apply(bodyColor: style, displayColor: style);
  }
}
