import 'package:flutter/material.dart';

/// Typography scale per `files/DESIGN.md` section 4 and Improvement Plan V2.
/// - Sora for headings and prominent money figures.
/// - Inter for body, labels, and descriptions with tabular figures.
final class AppTypography {
  const AppTypography._();

  static const fontHeading = 'Sora';
  static const fontBody = 'Inter';
  static const fontFallback = fontBody;

  static const TextTheme _base = TextTheme(
    displayLarge: TextStyle(
      fontFamily: fontHeading,
      fontSize: 34,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
    displayMedium: TextStyle(
      fontFamily: fontHeading,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
    displaySmall: TextStyle(
      fontFamily: fontHeading,
      fontSize: 24,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
    titleLarge: TextStyle(
      fontFamily: fontHeading,
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    ),
    titleMedium: TextStyle(
      fontFamily: fontHeading,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    ),
    titleSmall: TextStyle(
      fontFamily: fontHeading,
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(
      fontFamily: fontBody,
      fontSize: 15,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontBody,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    bodySmall: TextStyle(
      fontFamily: fontBody,
      fontSize: 12,
      fontWeight: FontWeight.w400,
    ),
    labelLarge: TextStyle(
      fontFamily: fontBody,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: TextStyle(
      fontFamily: fontBody,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
    labelSmall: TextStyle(
      fontFamily: fontBody,
      fontSize: 11,
      fontWeight: FontWeight.w500,
    ),
  );

  static TextTheme textTheme(Brightness brightness) {
    final style = brightness == Brightness.dark
        ? const Color(0xFFF2F5FF)
        : const Color(0xFF0B1020);
    return _base.apply(bodyColor: style, displayColor: style);
  }

  /// Specialized style for tabular money figures across the application.
  static TextStyle moneyStyle({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: fontHeading,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFeatures: const [FontFeature.tabularFigures()],
      color: color,
    );
  }
}
